<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<%
com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession)session.getAttribute("adminSession");
if(adminSession == null)
{
%><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><%
return;
}
if(!adminSession.hasRightsOn("Faculty"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Faculty service."/><%
return;
}
String uniId = request.getParameter("uniName");
String cmpId = request.getParameter("cmpName");
String facultyName = request.getParameter("facultyName");
String facultyAbb = request.getParameter("facultyAbb");
String facultyDsc = request.getParameter("facultyDsc");
String status = "Y".equals(request.getParameter("status")) ? "Y" : "N";
String[] selectedValues = request.getParameterValues("selectedValues");
String[] selectedValuesClass = request.getParameterValues("selectedValuesClass");
String[] selectedDisc = request.getParameterValues("selectedDisc");
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
Connection con = null;
boolean oldAutoCommit = true;
try
{
if(uniId == null || !uniId.matches("\\d+")) throw new SQLException("University is required.");
if(cmpId == null || !cmpId.matches("\\d+")) throw new SQLException("Campus is required.");
if(facultyName == null || facultyName.trim().length() == 0) throw new SQLException("Faculty Name is required.");
if(facultyAbb == null || facultyAbb.trim().length() == 0) throw new SQLException("Faculty Abbreviation is required.");
if(selectedValues == null || selectedValues.length == 0) throw new SQLException("Please define at least one absent limit.");
facultyName = facultyName.trim();
facultyAbb = facultyAbb.trim().toUpperCase();
facultyDsc = facultyDsc == null ? "" : facultyDsc.trim();
con = pool.getConnection();
oldAutoCommit = con.getAutoCommit();
con.setAutoCommit(false);
int campusOk = 0;
try(PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM UMS.CAMPUS WHERE CMP_ID = ? AND UNI_ID = ?")) { ps.setLong(1, Long.parseLong(cmpId)); ps.setLong(2, Long.parseLong(uniId)); try(ResultSet rs = ps.executeQuery()) { if(rs.next()) campusOk = rs.getInt(1); } }
if(campusOk == 0) throw new SQLException("Selected Campus does not belong to the selected University.");
long facultyId = 0;
try(PreparedStatement ps = con.prepareStatement("SELECT UMS.SEQ_FACULTY_ID.NEXTVAL FROM DUAL"); ResultSet rs = ps.executeQuery()) { if(rs.next()) facultyId = rs.getLong(1); }
try(PreparedStatement ps = con.prepareStatement("INSERT INTO UMS.FACULTY (FACULTY_ABBREV, FACULTY_NME, FACULTY_DSC, FACULTY_ID, CMP_ID, ACTIVE_STATUS) VALUES (?, ?, ?, ?, ?, ?)")) { ps.setString(1, facultyAbb); ps.setString(2, facultyName); ps.setString(3, facultyDsc); ps.setLong(4, facultyId); ps.setLong(5, Long.parseLong(cmpId)); ps.setString(6, status); ps.executeUpdate(); }
try(PreparedStatement ps = con.prepareStatement("INSERT INTO UMS.CURRENT_TERM (TERM_CDE, FACULTY_ID) VALUES (?, ?)")) { ps.setString(1, adminSession.workingTerm); ps.setLong(2, facultyId); ps.executeUpdate(); }
try(PreparedStatement ps = con.prepareStatement("INSERT INTO UMS.ABSENT_LIMIT (ABSENT_LIMIT_ID, CREDIT_HRS, ABSENT_LIMIT, FACULTY_ID, FACULTY_ABBREV, ABSENT_LIMIT_SPORTS) VALUES (UMS.SEQ_ABSENT_LIMIT_ID.NEXTVAL, ?, ?, ?, ?, ?)"))
{
for(String item : selectedValues) { String[] v = item.split("\\|",-1); if(v.length != 3) throw new SQLException("Invalid absent-limit entry."); ps.setString(1, v[0]); ps.setString(2, v[1]); ps.setLong(3, facultyId); ps.setString(4, facultyAbb); ps.setString(5, v[2]); ps.addBatch(); }
ps.executeBatch();
}
if(selectedValuesClass != null)
{
try(PreparedStatement ps = con.prepareStatement("INSERT INTO UMS.CREDIT_LOAD_DEFINITION (CREDIT_LOAD_DEFINITION_ID, CREDIT_HRS, CLASS_LIMIT, FACULTY_ID, FACULTY_ABBREV) VALUES (UMS.SEQ_CREDIT_LOAD_DEFINITION_ID.NEXTVAL, ?, ?, ?, ?)"))
{
for(String item : selectedValuesClass) { String[] v = item.split("\\|",-1); if(v.length != 2) throw new SQLException("Invalid credit-load entry."); ps.setString(1, v[0]); ps.setString(2, v[1]); ps.setLong(3, facultyId); ps.setString(4, facultyAbb); ps.addBatch(); }
ps.executeBatch();
}
}
try(PreparedStatement ps = con.prepareStatement("INSERT INTO UMS.ENV_VARIABLE (ENV_VAR_ID, VAR_NME, VAR_VAL, VAR_DSC, VAR_TYP, FACULTY_ID, FACULTY_ABBREV) SELECT UMS.SEQ_ENV_VAR_ID.NEXTVAL, VAR_NME_DFLT, VAR_VAL_DFLT, VAR_DSC_DFLT, VAR_TYP_DFLT, ?, ? FROM UMS.ENV_VARIABLE_DEFAULT")) { ps.setLong(1, facultyId); ps.setString(2, facultyAbb); ps.executeUpdate(); }
if(selectedDisc != null)
{
try(PreparedStatement ps = con.prepareStatement("INSERT INTO UMS.DISCOUNT_POLICY VALUES ((SELECT NVL(MAX(DISCOUNT_POLICY_ID),0)+1 FROM UMS.DISCOUNT_POLICY), ?, ?, ?, ?, ?, ?, 23843)"))
{
for(String item : selectedDisc) { String[] v = item.split("\\|",-1); if(v.length != 5) throw new SQLException("Invalid discount-policy entry."); ps.setLong(1, facultyId); ps.setString(2, v[0]); ps.setString(3, v[1]); ps.setString(4, v[2]); ps.setString(5, v[3]); ps.setString(6, v[4]); ps.executeUpdate(); }
}
}
adminSession.addLog("INSERT UMS.FACULTY FACULTY_ID=" + facultyId + ", FACULTY_ABBREV=" + facultyAbb + ", FACULTY_NME=" + facultyName, con);
con.commit();
session.setAttribute("flashType","success");
session.setAttribute("flashMessage","Faculty " + facultyName + " has been added successfully.");
response.sendRedirect("AdminFaculty.jsp");
}
catch(Exception e)
{
if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
String msg = e.getMessage() == null ? "Unable to add Faculty." : e.getMessage();
if(msg.indexOf("ORA-00001") >= 0) msg = "This Faculty is already defined.";
session.setAttribute("flashType","error");
session.setAttribute("flashMessage",msg);
response.sendRedirect("AdminFaculty.jsp");
}
finally
{
if(con != null) try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
pool.close(con);
}
%>