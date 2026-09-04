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
String prereqId = request.getParameter("Prereq");
String seq = request.getParameter("seq");
String status = request.getParameter("status");
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
Connection con = null;
boolean oldAutoCommit = true;
try
{
if(programId == null || !programId.matches("\\d+")) throw new SQLException("Invalid Program.");
if(courseId == null || !courseId.matches("\\d+")) throw new SQLException("Invalid Course.");
if(prereqId != null && prereqId.length() > 0 && !prereqId.matches("\\d+")) throw new SQLException("Invalid Prerequisite.");
if(prereqId != null && prereqId.equals(courseId)) throw new SQLException("Course and Prerequisite cannot be the same.");
if(seq == null || !seq.matches("\\d{1,3}")) throw new SQLException("Course Sequence is required.");
if(status == null || status.trim().length() == 0) throw new SQLException("Status is required.");
con = pool.getConnection();
oldAutoCommit = con.getAutoCommit();
con.setAutoCommit(false);
String currentCode = null;
try(PreparedStatement ps = con.prepareStatement("SELECT PROG_CDE FROM UMS.PROGRAM WHERE PROG_ID = ? AND FACULTY_ID = ?")) { ps.setLong(1, Long.parseLong(programId)); ps.setInt(2, adminSession.getWorkingFacultyId()); try(ResultSet rs = ps.executeQuery()) { if(rs.next()) currentCode = rs.getString(1); } }
if(currentCode == null) throw new SQLException("Selected Program does not belong to the working faculty.");
programCode = currentCode;
String updateSql = "UPDATE UMS.PREREQ SET PREREQ_COURSE_ID = ?, COURSE_NBR = ?, STATUS_TXT = ? WHERE PREREQ_ID IN (SELECT PR.PREREQ_ID FROM UMS.PREREQ PR JOIN UMS.PROGRAM P ON P.PROG_ID = PR.PROG_ID JOIN UMS.FACULTY F ON F.FACULTY_ID = P.FACULTY_ID JOIN UMS.CAMPUS C ON C.CMP_ID = F.CMP_ID WHERE P.PROG_CDE = ? AND PR.COURSE_ID = ? AND C.UNI_ID = (SELECT C2.UNI_ID FROM UMS.CAMPUS C2 WHERE C2.CMP_ID = ?))";
try(PreparedStatement ps = con.prepareStatement(updateSql)) { if(prereqId == null || prereqId.length() == 0) ps.setNull(1, Types.NUMERIC); else ps.setLong(1, Long.parseLong(prereqId)); ps.setInt(2, Integer.parseInt(seq)); ps.setString(3, status.toUpperCase()); ps.setString(4, programCode); ps.setLong(5, Long.parseLong(courseId)); ps.setInt(6, adminSession.getCampusId()); ps.executeUpdate(); }
adminSession.addLog("UPDATE ROADMAP PROG_CDE=" + programCode + ", COURSE_ID=" + courseId + ", SEQ=" + seq, con);
con.commit();
session.setAttribute("flashType","success");
session.setAttribute("flashMessage","Roadmap course has been updated successfully.");
response.sendRedirect("AdminProgramCourseDetail.jsp?Program=" + programId);
}
catch(Exception e)
{
if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
session.setAttribute("flashType","error");
session.setAttribute("flashMessage",e.getMessage() == null ? "Unable to update Roadmap." : e.getMessage());
response.sendRedirect("AdminProgramCourseDetail.jsp?Program=" + (programId == null ? "" : programId));
}
finally
{
if(con != null) try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
pool.close(con);
}
%>