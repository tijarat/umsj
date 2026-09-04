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
if(!adminSession.hasRightsOn("Prereq"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Prereq service."/><%
return;
}
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
Connection con = null;
String flashType = (String)session.getAttribute("flashType");
String flashMessage = (String)session.getAttribute("flashMessage");
session.removeAttribute("flashType");
session.removeAttribute("flashMessage");
try
{
con = pool.getConnection();
String prog = request.getParameter("Program");
String programCode = "";
if(prog == null || !prog.matches("\\d+"))
{
try(PreparedStatement ps = con.prepareStatement("SELECT PROG_ID, PROG_CDE FROM UMS.PROGRAM WHERE PROG_TYP = 'R' AND FACULTY_ID = ? ORDER BY PROG_CDE")) { ps.setString(1, adminSession.getWorkingFacultyId()); try(ResultSet rs = ps.executeQuery()) { if(rs.next()) { prog = rs.getString("PROG_ID"); programCode = rs.getString("PROG_CDE"); } } }
}
else
{
try(PreparedStatement ps = con.prepareStatement("SELECT PROG_CDE FROM UMS.PROGRAM WHERE PROG_ID = ? AND PROG_TYP = 'R' AND FACULTY_ID = ?")) { ps.setLong(1, Long.parseLong(prog)); ps.setString(2, adminSession.getWorkingFacultyId()); try(ResultSet rs = ps.executeQuery()) { if(rs.next()) programCode = rs.getString(1); } }
}
String lockInd = "";
if(prog != null && prog.matches("\\d+"))
{
try(PreparedStatement ps = con.prepareStatement("SELECT DISTINCT NVL(PR.LOCKED_IND,'N') FROM UMS.PREREQ PR JOIN UMS.COURSE C ON C.COURSE_ID = PR.COURSE_ID WHERE PR.PROG_ID = ? AND C.TERM_CDE = ?")) { ps.setLong(1, Long.parseLong(prog)); ps.setString(2, adminSession.workingTerm); try(ResultSet rs = ps.executeQuery()) { if(rs.next()) lockInd = rs.getString(1); } }
}
boolean locked = "Y".equalsIgnoreCase(lockInd);
boolean canUnlock = com.ums.functions.Functions.isUserAllowedProcess(con, "CanUnlockPrereq", adminSession.user);
%>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Program Course Detail</title><link href="../extra/css/style.css?v=20260831" rel="stylesheet"><link href="../extra/css/ums-module.css?v=20260831" rel="stylesheet"></head><body class="ums-admin-main-body"><main class="ums-module-page">
<section class="ums-module-header"><div><p class="ums-module-eyebrow">Academic Roadmap</p><h1>Program Course Detail</h1><p>Define Roadmap / Prerequisite rules for working term <strong><%=html(adminSession.workingTerm)%></strong>.</p></div></section>
<section class="ums-module-card"><div class="ums-module-card-header"><h2>Roadmap</h2><span>Rights service: Prereq</span></div>
<form action="AdminProgramCourseDetail.jsp" method="get" class="ums-module-form"><div class="ums-form-grid"><div class="ums-field"><label>Working Term</label><div class="ums-readonly-value"><%=html(adminSession.workingTerm)%></div></div><div class="ums-field"><label for="Program">Program *</label><select name="Program" id="Program" required data-ums-search-select data-search-placeholder="Type program..." data-search-label="Search Program"><% try(PreparedStatement ps = con.prepareStatement("SELECT PROG_ID, PROG_CDE, PROG_NME FROM UMS.PROGRAM WHERE PROG_TYP = 'R' AND FACULTY_ID = ? ORDER BY PROG_CDE")) { ps.setString(1, adminSession.getWorkingFacultyId()); try(ResultSet rs = ps.executeQuery()) { while(rs.next()) { String id = rs.getString("PROG_ID"); %><option value="<%=html(id)%>" <%=id.equals(prog) ? "selected" : ""%>><%=html(rs.getString("PROG_CDE"))%> - <%=html(rs.getString("PROG_NME"))%></option><% } } } %></select></div></div><div class="ums-form-actions"><button type="submit">Show Roadmap</button></div></form>
<% if(prog != null && prog.matches("\\d+")) { %><div class="ums-inline-notice">Program <strong><%=html(programCode)%></strong> is <strong><%=locked ? "Locked" : "Unlocked"%></strong>. <% if(!locked) { %><a class="ums-action-link" href="AdminProcessProgramCourseDetail.jsp?act=Y&Program=<%=url(prog)%>" data-ums-confirm="Lock this roadmap?">Lock Roadmap</a><% } else if(canUnlock) { %><a class="ums-action-link" href="AdminProcessProgramCourseDetail.jsp?act=N&Program=<%=url(prog)%>" data-ums-confirm="Unlock this roadmap?">Unlock Roadmap</a><% } %></div><% } %>
</section>
<% if(flashMessage != null && flashMessage.trim().length() > 0) { %><div id="umsFlashMessage" class="ums-flash-message <%="error".equals(flashType) ? "ums-flash-error" : "ums-flash-success"%>" role="alert"><%=html(flashMessage)%></div><% } %>
<% if(prog != null && prog.matches("\\d+") && !locked) { %>
<section class="ums-module-card"><div class="ums-module-card-header"><h2>Add Roadmap Course</h2><span>* Required fields</span></div><form action="AdminProcessProgramCourseDetail.jsp" method="post" class="ums-module-form" id="prereqForm"><input type="hidden" name="Program" value="<%=html(prog)%>"><div class="ums-form-grid">
<div class="ums-field"><label for="Course">Course *</label><select name="Course" id="Course" required data-ums-search-select data-search-placeholder="Type course code or name..." data-search-label="Search Course"><option value="">Select Course</option><% try(PreparedStatement ps = con.prepareStatement("SELECT COURSE_ID, COURSE_CDE, COURSE_NME, COURSE_ABBR FROM UMS.COURSE WHERE TERM_CDE = ? ORDER BY COURSE_CDE, COURSE_NME")) { ps.setString(1, adminSession.workingTerm); try(ResultSet rs = ps.executeQuery()) { while(rs.next()) { %><option value="<%=html(rs.getString("COURSE_ID"))%>"><%=html(rs.getString("COURSE_CDE"))%> - <%=html(rs.getString("COURSE_NME"))%> (<%=html(rs.getString("COURSE_ABBR"))%>)</option><% } } } %></select></div>
<div class="ums-field"><label for="Prereq">Prerequisite</label><select name="Prereq" id="Prereq" data-ums-search-select data-search-placeholder="Type prerequisite..." data-search-label="Search Prerequisite"><option value="">No Prerequisite</option><% try(PreparedStatement ps = con.prepareStatement("SELECT COURSE_ID, COURSE_CDE, COURSE_NME, COURSE_ABBR FROM UMS.COURSE WHERE TERM_CDE = ? ORDER BY COURSE_CDE, COURSE_NME")) { ps.setString(1, adminSession.workingTerm); try(ResultSet rs = ps.executeQuery()) { while(rs.next()) { %><option value="<%=html(rs.getString("COURSE_ID"))%>"><%=html(rs.getString("COURSE_CDE"))%> - <%=html(rs.getString("COURSE_NME"))%> (<%=html(rs.getString("COURSE_ABBR"))%>)</option><% } } } %></select></div>
<div class="ums-field"><label for="status">Status *</label><select name="status" id="status" required data-ums-search-select><option value="">Select Status</option><% try(PreparedStatement ps = con.prepareStatement("SELECT STATUS_NME FROM UMS.COURSE_STATUS ORDER BY STATUS_NME"); ResultSet rs = ps.executeQuery()) { while(rs.next()) { %><option value="<%=html(rs.getString(1))%>"><%=html(rs.getString(1))%></option><% } } %></select></div>
<div class="ums-field"><label for="seq">Course Sequence *</label><input name="seq" type="number" id="seq" min="0" max="999" required></div>
</div><div class="ums-form-actions"><button type="submit">Add Roadmap Course</button></div></form></section>
<% } %>
<% if(prog != null && prog.matches("\\d+")) { %>
<section class="ums-module-card"><div class="ums-module-card-header ums-module-card-header-tools"><div><h2>Roadmap of <%=html(programCode)%></h2><span><%=html(adminSession.workingTerm)%></span></div><div class="ums-table-tools"><div class="ums-table-search"><label for="roadmapSearch">Search</label><input type="search" id="roadmapSearch" data-ums-table-search="roadmapTable" placeholder="Search course or prerequisite"></div><button type="button" class="ums-export-button" data-ums-table-export="roadmapTable"><span class="ums-export-icon">⇩</span> Export to Excel</button></div></div>
<div class="ums-table-wrap"><table class="ums-data-table" id="roadmapTable" data-ums-table data-export-file="Roadmap_<%=html(programCode)%>"><thead><tr><th>Course Code</th><th>Title</th><th>Prereq Code</th><th>Prereq Title</th><th>Sequence</th><th>Status</th><% if(!locked) { %><th class="ums-actions-col">Options</th><% } %></tr></thead><tbody>
<%
boolean found = false;
String roadmapSql = "SELECT PR.COURSE_ID, PR.PREREQ_COURSE_ID, PR.COURSE_NBR, C.COURSE_CDE, C.COURSE_NME, NVL(PC.COURSE_CDE,'-') PREREQ_CDE, NVL(PC.COURSE_NME,'-') PREREQ_NME, PR.PREREQ_ID, NVL(PR.STATUS_TXT,' ') STATUS_TXT, NVL(PR.LOCKED_IND,'N') LOCKED_IND, P.PROG_CDE FROM UMS.PREREQ PR JOIN UMS.COURSE C ON C.COURSE_ID = PR.COURSE_ID JOIN UMS.PROGRAM P ON P.PROG_ID = PR.PROG_ID LEFT JOIN UMS.COURSE PC ON PC.COURSE_ID = PR.PREREQ_COURSE_ID WHERE C.TERM_CDE = ? AND PR.PROG_ID = ? AND P.FACULTY_ID = ? ORDER BY PR.COURSE_NBR, C.COURSE_CDE";
try(PreparedStatement ps = con.prepareStatement(roadmapSql))
{
ps.setString(1, adminSession.workingTerm); ps.setLong(2, Long.parseLong(prog)); ps.setString(3, adminSession.getWorkingFacultyId());
try(ResultSet rs = ps.executeQuery())
{
while(rs.next())
{
found = true;
String preqId = rs.getString("PREREQ_ID");
String courseId = rs.getString("COURSE_ID");
String editUrl = "AdminEditProgramCourseDetail.jsp?Program=" + url(prog) + "&preqid=" + url(preqId) + "&cid=" + url(courseId);
String delUrl = "AdminProcessDeleteProgramCourseDetail.jsp?Program=" + url(prog) + "&prgCde=" + url(rs.getString("PROG_CDE")) + "&crsId=" + url(courseId);
%><tr><td><%=html(rs.getString("COURSE_CDE"))%></td><td><%=html(rs.getString("COURSE_NME"))%></td><td><%="-".equals(rs.getString("PREREQ_CDE")) ? "" : html(rs.getString("PREREQ_CDE"))%></td><td><%="-".equals(rs.getString("PREREQ_NME")) ? "" : html(rs.getString("PREREQ_NME"))%></td><td><%=html(rs.getString("COURSE_NBR"))%></td><td><%=html(rs.getString("STATUS_TXT"))%></td><% if(!locked) { %><td class="ums-row-actions" data-export-ignore="true"><a class="ums-action-link ums-action-edit" href="<%=editUrl%>">Edit</a><a class="ums-action-link ums-action-delete" href="<%=delUrl%>" data-ums-confirm="Delete roadmap course '<%=html(rs.getString("COURSE_NME"))%>'?">Delete</a></td><% } %></tr><%
}
}
}
if(!found) { %><tr data-ums-empty-row><td colspan="<%=locked ? "6" : "7"%>" class="ums-table-empty">No Roadmap has been defined for <%=html(programCode)%>.</td></tr><% }
%>
</tbody></table></div><div class="ums-table-footer" data-ums-table-footer="roadmapTable"></div></section>
<% } %>
</main><script src="../extra/js/ums-module.js?v=20260831"></script><script src="../extra/js/program-course-detail.js?v=20260831"></script></body></html>
<%
}
finally
{
pool.close(con);
}
%>