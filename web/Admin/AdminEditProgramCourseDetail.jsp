<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<%!
private String html(String value)
{
    if(value == null) return "";
    return value.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
}
private String url(String value) throws Exception
{
    return java.net.URLEncoder.encode(value == null ? "" : value, "UTF-8");
}
%>
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
String prereqId = request.getParameter("preqid");
String courseId = request.getParameter("cid");
if(programId == null || !programId.matches("\\d+") || prereqId == null || !prereqId.matches("\\d+") || courseId == null || !courseId.matches("\\d+")) { response.sendRedirect("AdminProgramCourseDetail.jsp"); return; }
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
Connection con = null;
try
{
con = pool.getConnection();
String programCode = null;
String courseCode = null;
String courseName = null;
String currentPrereq = null;
String currentSeq = null;
String currentStatus = null;
String sql = "SELECT P.PROG_CDE, C.COURSE_CDE, C.COURSE_NME, PR.PREREQ_COURSE_ID, PR.COURSE_NBR, PR.STATUS_TXT FROM UMS.PREREQ PR JOIN UMS.PROGRAM P ON P.PROG_ID = PR.PROG_ID JOIN UMS.COURSE C ON C.COURSE_ID = PR.COURSE_ID WHERE PR.PREREQ_ID = ? AND PR.PROG_ID = ? AND PR.COURSE_ID = ? AND P.FACULTY_ID = ?";
try(PreparedStatement ps = con.prepareStatement(sql))
{
ps.setLong(1, Long.parseLong(prereqId)); ps.setLong(2, Long.parseLong(programId)); ps.setLong(3, Long.parseLong(courseId)); ps.setInt(4, adminSession.getWorkingFacultyId());
try(ResultSet rs = ps.executeQuery()) { if(rs.next()) { programCode = rs.getString("PROG_CDE"); courseCode = rs.getString("COURSE_CDE"); courseName = rs.getString("COURSE_NME"); currentPrereq = rs.getString("PREREQ_COURSE_ID"); currentSeq = rs.getString("COURSE_NBR"); currentStatus = rs.getString("STATUS_TXT"); } }
}
if(programCode == null) { response.sendRedirect("AdminProgramCourseDetail.jsp?Program=" + programId); return; }
%>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Edit Roadmap</title><link href="../extra/css/style.css?v=20260831" rel="stylesheet"><link href="../extra/css/ums-module.css?v=20260831" rel="stylesheet"></head><body class="ums-admin-main-body"><main class="ums-module-page">
<section class="ums-module-header"><div><p class="ums-module-eyebrow">Academic Roadmap</p><h1>Edit Roadmap Course</h1><p>Update prerequisite, sequence and status.</p></div></section>
<section class="ums-module-card"><div class="ums-module-card-header"><h2><%=html(programCode)%> / <%=html(courseCode)%></h2></div><form action="AdminProcessEditProgramCourseDetail.jsp" method="post" class="ums-module-form" id="prereqForm"><input type="hidden" name="Program" value="<%=html(programId)%>"><input type="hidden" name="preqid" value="<%=html(prereqId)%>"><input type="hidden" name="crsId" value="<%=html(courseId)%>"><input type="hidden" name="prgCde" value="<%=html(programCode)%>"><div class="ums-form-grid">
<div class="ums-field"><label>Working Term</label><div class="ums-readonly-value"><%=html(adminSession.workingTerm)%></div></div><div class="ums-field"><label>Program</label><div class="ums-readonly-value"><%=html(programCode)%></div></div><div class="ums-field ums-field-full"><label>Course</label><div class="ums-readonly-value"><%=html(courseCode)%> - <%=html(courseName)%></div></div>
<div class="ums-field"><label for="Prereq">Prerequisite</label><select name="Prereq" id="Prereq" data-ums-search-select data-search-placeholder="Type prerequisite..." data-search-label="Search Prerequisite"><option value="">No Prerequisite</option><% try(PreparedStatement ps = con.prepareStatement("SELECT COURSE_ID, COURSE_CDE, COURSE_NME FROM UMS.COURSE WHERE TERM_CDE = ? AND COURSE_ID <> ? ORDER BY COURSE_CDE, COURSE_NME")) { ps.setString(1, adminSession.workingTerm); ps.setLong(2, Long.parseLong(courseId)); try(ResultSet rs = ps.executeQuery()) { while(rs.next()) { String id = rs.getString("COURSE_ID"); %><option value="<%=html(id)%>" <%=id.equals(currentPrereq) ? "selected" : ""%>><%=html(rs.getString("COURSE_CDE"))%> - <%=html(rs.getString("COURSE_NME"))%></option><% } } } %></select></div>
<div class="ums-field"><label for="status">Status *</label><select name="status" id="status" required data-ums-search-select><% try(PreparedStatement ps = con.prepareStatement("SELECT STATUS_NME FROM UMS.COURSE_STATUS ORDER BY STATUS_NME"); ResultSet rs = ps.executeQuery()) { while(rs.next()) { String status = rs.getString(1); %><option value="<%=html(status)%>" <%=status.equals(currentStatus) ? "selected" : ""%>><%=html(status)%></option><% } } %></select></div>
<div class="ums-field"><label for="seq">Course Sequence *</label><input name="seq" type="number" id="seq" min="0" max="999" value="<%=html(currentSeq)%>" required></div>
</div><div class="ums-form-actions"><button type="submit">Update Roadmap Course</button><a class="ums-button-secondary" href="AdminProgramCourseDetail.jsp?Program=<%=html(programId)%>">Cancel</a></div></form></section></main><script src="../extra/js/ums-module.js?v=20260831"></script><script src="../extra/js/program-course-detail.js?v=20260831"></script></body></html>
<%
}
finally
{
pool.close(con);
}
%>