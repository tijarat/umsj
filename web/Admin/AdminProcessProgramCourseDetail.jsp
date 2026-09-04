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
String act = request.getParameter("act");
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
Connection con = null;
boolean oldAutoCommit = true;
try
{
if(programId == null || !programId.matches("\\d+")) throw new SQLException("Program is required.");
con = pool.getConnection();
oldAutoCommit = con.getAutoCommit();
con.setAutoCommit(false);
String programCode = null;
try(PreparedStatement ps = con.prepareStatement("SELECT PROG_CDE FROM UMS.PROGRAM WHERE PROG_ID = ? AND PROG_TYP = 'R' AND FACULTY_ID = ?")) { ps.setLong(1, Long.parseLong(programId)); ps.setInt(2, adminSession.getWorkingFacultyId()); try(ResultSet rs = ps.executeQuery()) { if(rs.next()) programCode = rs.getString(1); } }
if(programCode == null) throw new SQLException("Selected Program does not belong to the working faculty.");
if(act != null && ("Y".equalsIgnoreCase(act) || "N".equalsIgnoreCase(act)))
{
if("N".equalsIgnoreCase(act) && !com.ums.functions.Functions.isUserAllowedProcess(con, "CanUnlockPrereq", adminSession.user)) throw new SQLException("You are not authorized to unlock this Roadmap.");
String lockSql = "UPDATE UMS.PREREQ SET LOCKED_IND = ? WHERE PREREQ_ID IN (SELECT PR.PREREQ_ID FROM UMS.PREREQ PR JOIN UMS.PROGRAM P ON P.PROG_ID = PR.PROG_ID JOIN UMS.COURSE CR ON CR.COURSE_ID = PR.COURSE_ID JOIN UMS.FACULTY F ON F.FACULTY_ID = P.FACULTY_ID JOIN UMS.CAMPUS C ON C.CMP_ID = F.CMP_ID WHERE P.PROG_CDE = ? AND CR.TERM_CDE = ? AND C.UNI_ID = (SELECT C2.UNI_ID FROM UMS.CAMPUS C2 WHERE C2.CMP_ID = ?))";
try(PreparedStatement ps = con.prepareStatement(lockSql)) { ps.setString(1, act.toUpperCase()); ps.setString(2, programCode); ps.setString(3, adminSession.workingTerm); ps.setInt(4, adminSession.getCampusId()); ps.executeUpdate(); }
adminSession.addLog("UPDATE ROADMAP LOCKED_IND=" + act + ", PROG_CDE=" + programCode + ", TERM_CDE=" + adminSession.workingTerm, con);
con.commit();
session.setAttribute("flashType","success");
session.setAttribute("flashMessage","Roadmap has been " + ("Y".equalsIgnoreCase(act) ? "locked" : "unlocked") + " successfully.");
response.sendRedirect("AdminProgramCourseDetail.jsp?Program=" + programId);
return;
}
String courseId = request.getParameter("Course");
String prereqId = request.getParameter("Prereq");
String seq = request.getParameter("seq");
String status = request.getParameter("status");
if(courseId == null || !courseId.matches("\\d+")) throw new SQLException("Course is required.");
if(prereqId != null && prereqId.length() > 0 && !prereqId.matches("\\d+")) throw new SQLException("Invalid Prerequisite.");
if(prereqId != null && prereqId.equals(courseId)) throw new SQLException("Course and Prerequisite cannot be the same.");
if(seq == null || !seq.matches("\\d{1,3}")) throw new SQLException("Course Sequence is required.");
if(status == null || status.trim().length() == 0) throw new SQLException("Status is required.");
String insertSql = "INSERT INTO UMS.PREREQ (PREREQ_ID, COURSE_ID, PREREQ_COURSE_ID, COURSE_NBR, STATUS_TXT, LOCKED_IND, PROG_ID, REMARKS_TXT) SELECT UMS.SEQ_PREREQ_ID.NEXTVAL, ?, ?, ?, ?, NULL, P.PROG_ID, NULL FROM UMS.PROGRAM P JOIN UMS.FACULTY F ON F.FACULTY_ID = P.FACULTY_ID JOIN UMS.CAMPUS C ON C.CMP_ID = F.CMP_ID WHERE P.PROG_CDE = ? AND C.UNI_ID = (SELECT C2.UNI_ID FROM UMS.CAMPUS C2 WHERE C2.CMP_ID = ?) AND NOT EXISTS (SELECT 1 FROM UMS.PREREQ PR1 WHERE PR1.PROG_ID = P.PROG_ID AND PR1.COURSE_ID = ? AND PR1.COURSE_NBR = ?)";
try(PreparedStatement ps = con.prepareStatement(insertSql))
{
ps.setLong(1, Long.parseLong(courseId)); if(prereqId == null || prereqId.length() == 0) ps.setNull(2, Types.NUMERIC); else ps.setLong(2, Long.parseLong(prereqId)); ps.setInt(3, Integer.parseInt(seq)); ps.setString(4, status.toUpperCase()); ps.setString(5, programCode); ps.setInt(6, adminSession.getCampusId()); ps.setLong(7, Long.parseLong(courseId)); ps.setInt(8, Integer.parseInt(seq)); int inserted = ps.executeUpdate(); if(inserted == 0) throw new SQLException("This course/sequence is already defined in the Roadmap.");
}
adminSession.addLog("INSERT ROADMAP PROG_CDE=" + programCode + ", COURSE_ID=" + courseId + ", SEQ=" + seq, con);
con.commit();
session.setAttribute("flashType","success");
session.setAttribute("flashMessage","Roadmap course has been added successfully.");
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