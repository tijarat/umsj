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
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
Connection con = null;
boolean oldAutoCommit = true;
try
{
if(facultyId == null || !facultyId.matches("\\d+")) throw new SQLException("Invalid Faculty ID.");
con = pool.getConnection();
oldAutoCommit = con.getAutoCommit();
con.setAutoCommit(false);
String[] cleanup = {"DELETE FROM UMS.CURRENT_TERM WHERE FACULTY_ID = ?","DELETE FROM UMS.ABSENT_LIMIT WHERE FACULTY_ID = ?","DELETE FROM UMS.CREDIT_LOAD_DEFINITION WHERE FACULTY_ID = ?","DELETE FROM UMS.DISCOUNT_POLICY WHERE FACULTY_ID = ?","DELETE FROM UMS.ENV_VARIABLE WHERE FACULTY_ID = ?"};
for(String sql : cleanup) { try(PreparedStatement ps = con.prepareStatement(sql)) { ps.setLong(1, Long.parseLong(facultyId)); ps.executeUpdate(); } }
int deleted = 0;
try(PreparedStatement ps = con.prepareStatement("DELETE FROM UMS.FACULTY WHERE FACULTY_ID = ?")) { ps.setLong(1, Long.parseLong(facultyId)); deleted = ps.executeUpdate(); }
if(deleted == 0) throw new SQLException("Faculty record was not found.");
adminSession.addLog("DELETE FROM UMS.FACULTY WHERE FACULTY_ID=" + facultyId, con);
con.commit();
session.setAttribute("flashType","success");
session.setAttribute("flashMessage","Faculty and its faculty-level settings have been deleted successfully.");
response.sendRedirect("AdminFaculty.jsp");
}
catch(Exception e)
{
if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
String msg = e.getMessage() == null ? "Unable to delete Faculty." : e.getMessage();
if(msg.indexOf("ORA-02292") >= 0) msg = "This Faculty contains child records and cannot be deleted.";
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