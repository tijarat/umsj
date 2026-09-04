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
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Course Project."/><%
return;
}
String pid = request.getParameter("pid");
String courseCode = request.getParameter("courseCode");
String pLength = request.getParameter("pLength");
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
Connection con = null;
boolean oldAutoCommit = true;
try
{
if(pid == null || !pid.matches("\\d+")) throw new SQLException("Invalid Project ID.");
if(courseCode == null || courseCode.trim().length() == 0) throw new SQLException("Project Course is required.");
if(pLength == null || !pLength.matches("\\d{1,2}") || Integer.parseInt(pLength) < 1) throw new SQLException("Project Length must be between 1 and 99 semesters.");
courseCode = courseCode.trim();
con = pool.getConnection();
oldAutoCommit = con.getAutoCommit();
con.setAutoCommit(false);
int allowedCourse = 0;
String validateSql = "SELECT COUNT(DISTINCT C.COURSE_CDE) FROM UMS.COURSE C JOIN UMS.PREREQ P ON P.COURSE_ID = C.COURSE_ID JOIN UMS.PROGRAM PR ON PR.PROG_ID = P.PROG_ID WHERE C.COURSE_CDE = ? AND PR.FACULTY_ID = ? AND C.TERM_CDE = ?";
try(PreparedStatement ps = con.prepareStatement(validateSql)) { ps.setString(1, courseCode); ps.setInt(2, adminSession.getWorkingFacultyId()); ps.setString(3, adminSession.workingTerm); try(ResultSet rs = ps.executeQuery()) { if(rs.next()) allowedCourse = rs.getInt(1); } }
if(allowedCourse == 0) throw new SQLException("Selected Course is not available for the current working faculty/term.");
String updateSql = "UPDATE UMS.COURSE_PROJECT CP SET CP.C_ID = ?, CP.PROJECT_LENGTH = ? WHERE CP.PROJECT_ID = ? AND EXISTS (SELECT 1 FROM UMS.COURSE C JOIN UMS.PREREQ P ON P.COURSE_ID = C.COURSE_ID JOIN UMS.PROGRAM PR ON PR.PROG_ID = P.PROG_ID WHERE C.COURSE_CDE = CP.C_ID AND PR.FACULTY_ID = ? AND C.TERM_CDE = ?)";
int updated = 0;
try(PreparedStatement ps = con.prepareStatement(updateSql)) { ps.setString(1, courseCode); ps.setInt(2, Integer.parseInt(pLength)); ps.setLong(3, Long.parseLong(pid)); ps.setInt(4, adminSession.getWorkingFacultyId()); ps.setString(5, adminSession.workingTerm); updated = ps.executeUpdate(); }
if(updated == 0) throw new SQLException("Project record was not found for the current working faculty/term.");
adminSession.addLog("UPDATE UMS.COURSE_PROJECT PROJECT_ID=" + pid + ", C_ID=" + courseCode + ", PROJECT_LENGTH=" + pLength, con);
con.commit();
session.setAttribute("flashType","success");
session.setAttribute("flashMessage","Course Project has been updated successfully.");
response.sendRedirect("AdminProject.jsp");
}
catch(Exception e)
{
if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
String msg = e.getMessage() == null ? "Unable to update Course Project." : e.getMessage();
if(msg.indexOf("ORA-00001") >= 0) msg = "This Course Project is already defined.";
session.setAttribute("flashType","error");
session.setAttribute("flashMessage",msg);
response.sendRedirect("AdminEditProject.jsp?pid=" + (pid == null ? "" : pid));
}
finally
{
if(con != null) try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
pool.close(con);
}
%>