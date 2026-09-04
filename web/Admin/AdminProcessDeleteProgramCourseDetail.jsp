<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<%
com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession)session.getAttribute("adminSession");
if(adminSession == null)
{
%><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><%
return;
}
if(!adminSession.hasRightsOn("Prereq"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Prereq service."/><%
return;
}
String programId = request.getParameter("Program");
String programCode = request.getParameter("prgCde");
String courseId = request.getParameter("crsId");
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
Connection con = null;
boolean oldAutoCommit = true;
try
{
if(programId == null || !programId.matches("\\d+")) throw new SQLException("Invalid Program.");
if(courseId == null || !courseId.matches("\\d+")) throw new SQLException("Invalid Course.");
if(programCode == null || programCode.trim().length() == 0) throw new SQLException("Invalid Program Code.");
con = pool.getConnection();
oldAutoCommit = con.getAutoCommit();
con.setAutoCommit(false);
String deleteSql = "DELETE FROM UMS.PREREQ WHERE PREREQ_ID IN (SELECT PR.PREREQ_ID FROM UMS.PREREQ PR JOIN UMS.PROGRAM P ON P.PROG_ID = PR.PROG_ID JOIN UMS.FACULTY F ON F.FACULTY_ID = P.FACULTY_ID JOIN UMS.CAMPUS C ON C.CMP_ID = F.CMP_ID WHERE P.PROG_CDE = ? AND PR.COURSE_ID = ? AND C.UNI_ID = (SELECT C2.UNI_ID FROM UMS.CAMPUS C2 WHERE C2.CMP_ID = ?))";
try(PreparedStatement ps = con.prepareStatement(deleteSql)) { ps.setString(1, programCode); ps.setLong(2, Long.parseLong(courseId)); ps.setInt(3, adminSession.getCampusId()); ps.executeUpdate(); }
adminSession.addLog("DELETE ROADMAP PROG_CDE=" + programCode + ", COURSE_ID=" + courseId, con);
con.commit();
session.setAttribute("flashType","success");
session.setAttribute("flashMessage","Roadmap course has been deleted successfully.");
response.sendRedirect("AdminProgramCourseDetail.jsp?Program=" + programId);
}
catch(Exception e)
{
if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
String msg = e.getMessage() == null ? "Unable to delete Roadmap course." : e.getMessage();
if(msg.indexOf("ORA-02292") >= 0) msg = "This Roadmap course contains child records and cannot be deleted.";
session.setAttribute("flashType","error");
session.setAttribute("flashMessage",msg);
response.sendRedirect("AdminProgramCourseDetail.jsp?Program=" + (programId == null ? "" : programId));
}
finally
{
if(con != null) try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
pool.close(con);
}
%>