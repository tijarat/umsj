<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<%
com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession)session.getAttribute("adminSession");
if(adminSession == null)
{
%><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><%
return;
}
if(!adminSession.hasRightsOn("Batch"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Batch service."/><%
return;
}
String progCode = request.getParameter("progList");
String batchNbr = request.getParameter("batch");
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
Connection con = null;
boolean oldAutoCommit = true;
try
{
if(progCode == null || progCode.trim().length() == 0) throw new SQLException("Program is required.");
if(batchNbr == null || !batchNbr.trim().matches("\\d{1,3}")) throw new SQLException("Batch must be numeric and at most 3 digits.");
progCode = progCode.trim();
batchNbr = batchNbr.trim();
con = pool.getConnection();
oldAutoCommit = con.getAutoCommit();
con.setAutoCommit(false);
long batchId = 0;
try(PreparedStatement ps = con.prepareStatement("SELECT UMS.SEQ_BATCH_ID.NEXTVAL FROM DUAL"); ResultSet rs = ps.executeQuery()) { if(rs.next()) batchId = rs.getLong(1); }
if(batchId <= 0) throw new SQLException("Unable to generate Batch ID.");
int inserted = 0;
try(PreparedStatement ps = con.prepareStatement("INSERT INTO UMS.BATCH (BATCH_ID, TERM_CDE, BATCH_NBR, PROG_ID) SELECT ?, ?, ?, PROG_ID FROM UMS.PROGRAM WHERE PROG_CDE = ? AND FACULTY_ID = ?"))
{
ps.setLong(1, batchId);
ps.setString(2, adminSession.workingTerm);
ps.setInt(3, Integer.parseInt(batchNbr));
ps.setString(4, progCode);
ps.setInt(5, adminSession.getWorkingFacultyId());
inserted = ps.executeUpdate();
}
if(inserted != 1) throw new SQLException("Selected Program does not belong to the working faculty.");
String degreeSql = "INSERT INTO UMS.DEGREE_COMP_REQ (DEGREE_COMP_REQ_ID, BATCH_ID, CR_HR_MIN, YEAR_MIN, YEAR_MAX, CGPA_MIN) SELECT UMS.SEQ_DEGREE_COMP_REQ_ID.NEXTVAL, ?, D.CR_HR_MIN, D.YEAR_MIN, D.YEAR_MAX, D.CGPA_MIN FROM UMS.DEGREE_COMP_REQ D JOIN UMS.BATCH B ON B.BATCH_ID = D.BATCH_ID JOIN UMS.PROGRAM P ON P.PROG_ID = B.PROG_ID WHERE P.PROG_CDE = ? AND D.DEGREE_COMP_REQ_ID = (SELECT MAX(D2.DEGREE_COMP_REQ_ID) FROM UMS.DEGREE_COMP_REQ D2 JOIN UMS.BATCH B2 ON B2.BATCH_ID = D2.BATCH_ID JOIN UMS.PROGRAM P2 ON P2.PROG_ID = B2.PROG_ID WHERE P2.PROG_CDE = ?)";
try(PreparedStatement ps = con.prepareStatement(degreeSql)) { ps.setLong(1, batchId); ps.setString(2, progCode); ps.setString(3, progCode); ps.executeUpdate(); }
adminSession.addLog("INSERT UMS.BATCH BATCH_ID=" + batchId + ", TERM_CDE=" + adminSession.workingTerm + ", BATCH_NBR=" + batchNbr + ", PROG_CDE=" + progCode, con);
con.commit();
session.setAttribute("flashType","success");
session.setAttribute("flashMessage","Batch " + batchNbr + " has been added successfully.");
response.sendRedirect("AdminBatch.jsp");
}
catch(Exception e)
{
if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
String msg = e.getMessage() == null ? "Unable to add Batch." : e.getMessage();
if(msg.indexOf("ORA-00001") >= 0) msg = "This Batch Number is already defined.";
session.setAttribute("flashType","error");
session.setAttribute("flashMessage",msg);
response.sendRedirect("AdminBatch.jsp");
}
finally
{
if(con != null) try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
pool.close(con);
}
%>