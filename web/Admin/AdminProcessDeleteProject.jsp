<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<%
com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession)session.getAttribute("adminSession");
if(adminSession == null)
{
%><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><%
return;
}
if(!adminSession.hasRightsOn("Project"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Project service."/><%
return;
}
String pid = request.getParameter("pid");
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
Connection con = null;
boolean oldAutoCommit = true;
try
{
if(pid == null || !pid.matches("\\d+")) throw new SQLException("Invalid Project ID.");
con = pool.getConnection();
oldAutoCommit = con.getAutoCommit();
con.setAutoCommit(false);
String deleteSql = "DELETE FROM UMS.COURSE_PROJECT CP WHERE CP.PROJECT_ID = ? AND EXISTS (SELECT 1 FROM UMS.COURSE C JOIN UMS.PREREQ P ON P.COURSE_ID = C.COURSE_ID JOIN UMS.PROGRAM PR ON PR.PROG_ID = P.PROG_ID WHERE C.COURSE_CDE = CP.C_ID AND PR.FACULTY_ID = ? AND C.TERM_CDE = ?)";
int deleted = 0;
try(PreparedStatement ps = con.prepareStatement(deleteSql)) { ps.setLong(1, Long.parseLong(pid)); ps.setInt(2, adminSession.getWorkingFacultyId()); ps.setString(3, adminSession.workingTerm); deleted = ps.executeUpdate(); }
if(deleted == 0) throw new SQLException("Project record was not found for the current working faculty/term.");
adminSession.addLog("DELETE FROM UMS.COURSE_PROJECT WHERE PROJECT_ID=" + pid, con);
con.commit();
session.setAttribute("flashType","success");
session.setAttribute("flashMessage","Course Project has been deleted successfully.");
response.sendRedirect("AdminProject.jsp");
}
catch(Exception e)
{
if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
String msg = e.getMessage() == null ? "Unable to delete Course Project." : e.getMessage();
if(msg.indexOf("ORA-02292") >= 0) msg = "This Course Project contains child records and cannot be deleted.";
session.setAttribute("flashType","error");
session.setAttribute("flashMessage",msg);
response.sendRedirect("AdminProject.jsp");
}
finally
{
if(con != null) try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
pool.close(con);
}
%>