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
String facultyId = request.getParameter("facultyId");
String cmpId = request.getParameter("cmpName");
String facultyName = request.getParameter("facultyName");
String facultyAbb = request.getParameter("facultyAbb");
String facultyDsc = request.getParameter("facultyDsc");
String status = "Y".equals(request.getParameter("status")) ? "Y" : "N";
String[] selectedValues = request.getParameterValues("selectedValues");
String[] selectedValuesClass = request.getParameterValues("selectedValuesClass");
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
Connection con = null;
boolean oldAutoCommit = true;
try
{
if(facultyId == null || !facultyId.matches("\\d+")) throw new SQLException("Invalid Faculty ID.");
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
int updated = 0;
try(PreparedStatement ps = con.prepareStatement("UPDATE UMS.FACULTY SET FACULTY_NME = ?, FACULTY_ABBREV = ?, FACULTY_DSC = ?, CMP_ID = ?, ACTIVE_STATUS = ? WHERE FACULTY_ID = ?")) { ps.setString(1, facultyName); ps.setString(2, facultyAbb); ps.setString(3, facultyDsc); ps.setLong(4, Long.parseLong(cmpId)); ps.setString(5, status); ps.setLong(6, Long.parseLong(facultyId)); updated = ps.executeUpdate(); }
if(updated == 0) throw new SQLException("Faculty record was not found.");
try(PreparedStatement ps = con.prepareStatement("DELETE FROM UMS.ABSENT_LIMIT WHERE FACULTY_ID = ?")) { ps.setLong(1, Long.parseLong(facultyId)); ps.executeUpdate(); }
try(PreparedStatement ps = con.prepareStatement("DELETE FROM UMS.CREDIT_LOAD_DEFINITION WHERE FACULTY_ID = ?")) { ps.setLong(1, Long.parseLong(facultyId)); ps.executeUpdate(); }
try(PreparedStatement ps = con.prepareStatement("INSERT INTO UMS.ABSENT_LIMIT (ABSENT_LIMIT_ID, CREDIT_HRS, ABSENT_LIMIT, FACULTY_ID, FACULTY_ABBREV, ABSENT_LIMIT_SPORTS) VALUES (UMS.SEQ_ABSENT_LIMIT_ID.NEXTVAL, ?, ?, ?, ?, ?)"))
{
for(String item : selectedValues) { String[] v = item.split("\\|",-1); if(v.length != 3) throw new SQLException("Invalid absent-limit entry."); ps.setString(1, v[0]); ps.setString(2, v[1]); ps.setLong(3, Long.parseLong(facultyId)); ps.setString(4, facultyAbb); ps.setString(5, v[2]); ps.addBatch(); }
ps.executeBatch();
}
if(selectedValuesClass != null)
{
try(PreparedStatement ps = con.prepareStatement("INSERT INTO UMS.CREDIT_LOAD_DEFINITION (CREDIT_LOAD_DEFINITION_ID, CREDIT_HRS, CLASS_LIMIT, FACULTY_ID, FACULTY_ABBREV) VALUES (UMS.SEQ_CREDIT_LOAD_DEFINITION_ID.NEXTVAL, ?, ?, ?, ?)"))
{
for(String item : selectedValuesClass) { String[] v = item.split("\\|",-1); if(v.length != 2) throw new SQLException("Invalid credit-load entry."); ps.setString(1, v[0]); ps.setString(2, v[1]); ps.setLong(3, Long.parseLong(facultyId)); ps.setString(4, facultyAbb); ps.addBatch(); }
ps.executeBatch();
}
}
adminSession.addLog("UPDATE UMS.FACULTY FACULTY_ID=" + facultyId + ", FACULTY_ABBREV=" + facultyAbb, con);
con.commit();
session.setAttribute("flashType","success");
session.setAttribute("flashMessage","Faculty has been updated successfully.");
response.sendRedirect("AdminFaculty.jsp");
}
catch(Exception e)
{
if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
session.setAttribute("flashType","error");
session.setAttribute("flashMessage",e.getMessage() == null ? "Unable to update Faculty." : e.getMessage());
response.sendRedirect("AdminEditFaculty.jsp?facultyId=" + (facultyId == null ? "" : facultyId));
}
finally
{
if(con != null) try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
pool.close(con);
}
%>