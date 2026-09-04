<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*,java.net.URLEncoder" session="true" errorPage="../error.jsp" %>
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
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
String flashType = (String)session.getAttribute("flashType");
String flashMessage = (String)session.getAttribute("flashMessage");
session.removeAttribute("flashType");
session.removeAttribute("flashMessage");
Connection con = null;
try
{
con = pool.getConnection();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Course Project</title>
<link href="../extra/css/style.css?v=20260904" rel="stylesheet" type="text/css">
<link href="../extra/css/ums-module.css?v=20260904" rel="stylesheet" type="text/css">
</head>
<body class="ums-admin-main-body">
<main class="ums-module-page">
<section class="ums-module-header"><div><p class="ums-module-eyebrow">Academic Setup</p><h1>Course Project</h1><p>Define project courses and their project duration for working term <strong><%=html(adminSession.workingTerm)%></strong>.</p></div></section>

<section class="ums-module-card">
<div class="ums-module-card-header"><h2>Define Project</h2><span>* Required fields</span></div>
<form action="AdminProcessProject.jsp" method="post" class="ums-module-form" id="projectForm">
<div class="ums-form-grid">
<div class="ums-field"><label for="courseCode">Project Course *</label>
<select name="courseCode" id="courseCode" required data-ums-search-select data-search-placeholder="Type course code or name..." data-search-label="Search Project Course">
<option value="">Select Course</option>
<%
String courseSql = "SELECT DISTINCT C.COURSE_CDE, C.COURSE_NME, C.COURSE_ABBR FROM UMS.COURSE C JOIN UMS.PREREQ P ON P.COURSE_ID = C.COURSE_ID JOIN UMS.PROGRAM PR ON PR.PROG_ID = P.PROG_ID WHERE PR.FACULTY_ID = ? AND C.TERM_CDE = ? ORDER BY C.COURSE_CDE";
try(PreparedStatement ps = con.prepareStatement(courseSql))
{
ps.setString(1, adminSession.getWorkingFacultyId());
ps.setString(2, adminSession.workingTerm);
try(ResultSet rs = ps.executeQuery())
{
while(rs.next())
{
%><option value="<%=html(rs.getString("COURSE_CDE"))%>"><%=html(rs.getString("COURSE_CDE"))%> - <%=html(rs.getString("COURSE_NME"))%> (<%=html(rs.getString("COURSE_ABBR"))%>)</option><%
}
}
}
%>
</select></div>
<div class="ums-field"><label for="pLength">Project Length *</label><div class="ums-input-suffix"><input type="number" name="pLength" id="pLength" min="1" max="99" required><span>Semester(s)</span></div></div>
</div>
<div class="ums-form-actions"><button type="submit">Add Project</button></div>
</form>
</section>

<% if(flashMessage != null && flashMessage.trim().length() > 0) { %><div id="umsFlashMessage" class="ums-flash-message <%="error".equals(flashType) ? "ums-flash-error" : "ums-flash-success"%>" role="alert"><%=html(flashMessage)%></div><% } %>

<section class="ums-module-card">
<div class="ums-module-card-header ums-module-card-header-tools"><div><h2>Projects</h2><span>Current working faculty and term</span></div><div class="ums-table-tools"><div class="ums-table-search"><label for="projectSearch">Search</label><input type="search" id="projectSearch" data-ums-table-search="projectTable" placeholder="Search project code or name"></div><button type="button" class="ums-export-button" data-ums-table-export="projectTable"><span class="ums-export-icon">⇩</span> Export to Excel</button></div></div>
<div class="ums-table-wrap"><table class="ums-data-table" id="projectTable" data-ums-table data-export-file="Course_Projects">
<thead><tr><th class="ums-sortable" data-column="0" data-type="number"><button type="button" class="ums-sort-button">Sr# <span class="ums-sort-indicator">↕</span></button></th><th class="ums-sortable" data-column="1" data-type="text"><button type="button" class="ums-sort-button">Project Code <span class="ums-sort-indicator">↕</span></button></th><th class="ums-sortable" data-column="2" data-type="text"><button type="button" class="ums-sort-button">Name <span class="ums-sort-indicator">↕</span></button></th><th class="ums-sortable" data-column="3" data-type="number"><button type="button" class="ums-sort-button">Length <span class="ums-sort-indicator">↕</span></button></th><th class="ums-actions-col">Options</th></tr></thead>
<tbody>
<%
boolean found = false;
int sr = 0;
String listSql = "SELECT DISTINCT C.COURSE_CDE, C.COURSE_NME, CP.PROJECT_LENGTH, CP.PROJECT_ID FROM UMS.COURSE_PROJECT CP JOIN UMS.COURSE C ON CP.C_ID = C.COURSE_CDE JOIN UMS.PREREQ P ON P.COURSE_ID = C.COURSE_ID JOIN UMS.PROGRAM PR ON PR.PROG_ID = P.PROG_ID WHERE PR.FACULTY_ID = ? AND C.TERM_CDE = ? ORDER BY C.COURSE_CDE";
try(PreparedStatement ps = con.prepareStatement(listSql))
{
ps.setString(1, adminSession.getWorkingFacultyId());
ps.setString(2, adminSession.workingTerm);
try(ResultSet rs = ps.executeQuery())
{
while(rs.next())
{
found = true;
sr++;
String pid = rs.getString("PROJECT_ID");
%><tr><td><%=sr%></td><td><%=html(rs.getString("COURSE_CDE"))%></td><td><%=html(rs.getString("COURSE_NME"))%></td><td><%=html(rs.getString("PROJECT_LENGTH"))%> Semester(s)</td><td class="ums-row-actions" data-export-ignore="true"><a class="ums-action-link ums-action-edit" href="AdminEditProject.jsp?pid=<%=url(pid)%>">Edit</a><a class="ums-action-link ums-action-delete" href="AdminProcessDeleteProject.jsp?pid=<%=url(pid)%>" data-ums-confirm="Delete this Course Project?">Delete</a></td></tr><%
}
}
}
if(!found) { %><tr data-ums-empty-row><td colspan="5" class="ums-table-empty">No course projects are defined for the current working term.</td></tr><% }
%>
</tbody></table></div><div class="ums-table-footer" data-ums-table-footer="projectTable"></div>
</section>
</main>
<script src="../extra/js/ums-module.js?v=20260904"></script>
<script src="../extra/js/project.js?v=20260904"></script>
</body>
</html>
<%
}
finally
{
pool.close(con);
}
%>