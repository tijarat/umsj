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
if(!adminSession.hasRightsOn("Project"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Course Project."/><%
return;
}
String pid = request.getParameter("pid");
if(pid == null || !pid.matches("\\d+")) { session.setAttribute("flashType","error"); session.setAttribute("flashMessage","A valid Project ID is required."); response.sendRedirect("AdminProject.jsp"); return; }
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
Connection con = null;
try
{
con = pool.getConnection();
String currentCourse = null;
String projectLength = null;
String currentName = null;
String fetchSql = "SELECT DISTINCT CP.C_ID, CP.PROJECT_LENGTH, C.COURSE_NME FROM UMS.COURSE_PROJECT CP JOIN UMS.COURSE C ON C.COURSE_CDE = CP.C_ID JOIN UMS.PREREQ P ON P.COURSE_ID = C.COURSE_ID JOIN UMS.PROGRAM PR ON PR.PROG_ID = P.PROG_ID WHERE CP.PROJECT_ID = ? AND PR.FACULTY_ID = ? AND C.TERM_CDE = ?";
try(PreparedStatement ps = con.prepareStatement(fetchSql))
{
ps.setLong(1, Long.parseLong(pid));
ps.setInt(2, adminSession.getWorkingFacultyId());
ps.setString(3, adminSession.workingTerm);
try(ResultSet rs = ps.executeQuery()) { if(rs.next()) { currentCourse = rs.getString("C_ID"); projectLength = rs.getString("PROJECT_LENGTH"); currentName = rs.getString("COURSE_NME"); } }
}
if(currentCourse == null) { session.setAttribute("flashType","error"); session.setAttribute("flashMessage","Project record was not found for the current working faculty/term."); response.sendRedirect("AdminProject.jsp"); return; }
%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Edit Course Project</title><link href="../extra/css/style.css?v=20260904" rel="stylesheet"><link href="../extra/css/ums-module.css?v=20260904" rel="stylesheet"></head>
<body class="ums-admin-main-body"><main class="ums-module-page">
<section class="ums-module-header"><div><p class="ums-module-eyebrow">Academic Setup</p><h1>Course Project</h1><p>Edit the selected project course and project duration.</p></div></section>
<section class="ums-module-card"><div class="ums-module-card-header"><h2>Edit Project</h2><span>* Required fields</span></div>
<form action="AdminProcessEditProject.jsp" method="post" class="ums-module-form" id="projectForm"><input type="hidden" name="pid" value="<%=html(pid)%>">
<div class="ums-form-grid">
<div class="ums-field"><label for="courseCode">Project Course *</label><select name="courseCode" id="courseCode" required data-ums-search-select data-search-placeholder="Type course code or name..." data-search-label="Search Project Course">
<%
String courseSql = "SELECT DISTINCT C.COURSE_CDE, C.COURSE_NME, C.COURSE_ABBR FROM UMS.COURSE C JOIN UMS.PREREQ P ON P.COURSE_ID = C.COURSE_ID JOIN UMS.PROGRAM PR ON PR.PROG_ID = P.PROG_ID WHERE PR.FACULTY_ID = ? AND C.TERM_CDE = ? ORDER BY C.COURSE_CDE";
try(PreparedStatement ps = con.prepareStatement(courseSql))
{
ps.setInt(1, adminSession.getWorkingFacultyId());
ps.setString(2, adminSession.workingTerm);
try(ResultSet rs = ps.executeQuery())
{
while(rs.next())
{
String code = rs.getString("COURSE_CDE");
%><option value="<%=html(code)%>" <%=code.equals(currentCourse) ? "selected" : ""%>><%=html(code)%> - <%=html(rs.getString("COURSE_NME"))%> (<%=html(rs.getString("COURSE_ABBR"))%>)</option><%
}
}
}
%>
</select></div>
<div class="ums-field"><label for="pLength">Project Length *</label><div class="ums-input-suffix"><input type="number" name="pLength" id="pLength" min="1" max="99" value="<%=html(projectLength)%>" required><span>Semester(s)</span></div></div>
</div>
<div class="ums-form-actions"><button type="submit">Update Project</button><a class="ums-button-secondary" href="AdminProject.jsp">Cancel</a></div>
</form></section>
</main><script src="../extra/js/ums-module.js?v=20260904"></script><script src="../extra/js/project.js?v=20260904"></script></body></html>
<%
}
finally
{
pool.close(con);
}
%>