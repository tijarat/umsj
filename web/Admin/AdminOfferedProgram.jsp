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
if(!adminSession.hasRightsOn("Offered Program"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Offered Program service."/><%
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
String termCde = request.getParameter("term");
if(termCde == null) termCde = "";
termCde = termCde.trim();
String progId = request.getParameter("prog");
if(progId == null) progId = "";
progId = progId.trim();
if(termCde.length() == 0)
{
try(PreparedStatement ps = con.prepareStatement("SELECT TERM_CDE FROM (SELECT TERM_CDE, START_DTE FROM UMS.TERM WHERE TERM_CDE LIKE 'F%' OR TERM_CDE LIKE 'S%' ORDER BY START_DTE DESC) WHERE ROWNUM <= 4"); ResultSet rs = ps.executeQuery()) { if(rs.next()) termCde = rs.getString("TERM_CDE"); }
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Offered Program</title>
<link href="../extra/css/style.css?v=20260904" rel="stylesheet" type="text/css">
<link href="../extra/css/ums-module.css?v=20260904" rel="stylesheet" type="text/css">
</head>
<body class="ums-admin-main-body">
<main class="ums-module-page">
<section class="ums-module-header"><div><p class="ums-module-eyebrow">Academic Setup</p><h1>Offered Program</h1><p>Define programs offered in a term for working faculty <strong><%=html(adminSession.getWorkingFaculty())%></strong>.</p></div></section>

<section class="ums-module-card">
<div class="ums-module-card-header"><h2>Add Offered Program</h2><span>* Required fields</span></div>
<form action="AdminProcessOfferedProgram.jsp" method="post" class="ums-module-form" id="offeredProgramForm">
<input type="hidden" name="effet" value="Add">
<div class="ums-form-grid">
<div class="ums-field"><label for="term">Term *</label>
<select name="term" id="term" required data-ums-search-select data-search-placeholder="Type term code..." data-search-label="Search Term">
<%
try(PreparedStatement ps = con.prepareStatement("SELECT TERM_CDE FROM (SELECT TERM_CDE, START_DTE FROM UMS.TERM WHERE TERM_CDE LIKE 'F%' OR TERM_CDE LIKE 'S%' ORDER BY START_DTE DESC) WHERE ROWNUM <= 4"))
{
try(ResultSet rs = ps.executeQuery())
{
while(rs.next())
{
String code = rs.getString("TERM_CDE");
%><option value="<%=html(code)%>" <%=code.equals(termCde) ? "selected" : ""%>><%=html(code)%></option><%
}
}
}
%>
</select></div>

<div class="ums-field"><label for="prog">Program *</label>
<select name="prog" id="prog" required data-ums-search-select data-search-placeholder="Type program code or name..." data-search-label="Search Program">
<option value="">Select Program</option>
<%
String progSql = "SELECT P.PROG_ID, P.PROG_CDE, P.PROG_NME FROM UMS.PROGRAM P WHERE P.FACULTY_ID = ? AND NOT EXISTS (SELECT 1 FROM UMS.OFFERED_PROGRAM OP WHERE OP.TERM_CDE = ? AND OP.PROG_ID = P.PROG_ID) ORDER BY P.PROG_CDE, P.PROG_NME";
try(PreparedStatement ps = con.prepareStatement(progSql))
{
ps.setString(1, adminSession.getWorkingFacultyId());
ps.setString(2, termCde);
try(ResultSet rs = ps.executeQuery())
{
while(rs.next())
{
String id = rs.getString("PROG_ID");
%><option value="<%=html(id)%>" <%=id.equals(progId) ? "selected" : ""%>><%=html(rs.getString("PROG_CDE"))%> - <%=html(rs.getString("PROG_NME"))%></option><%
}
}
}
%>
</select></div>
</div>
<div class="ums-form-actions"><button type="submit">Save Offered Program</button></div>
</form>
</section>

<% if(flashMessage != null && flashMessage.trim().length() > 0) { %><div id="umsFlashMessage" class="ums-flash-message <%="error".equals(flashType) ? "ums-flash-error" : "ums-flash-success"%>" role="alert"><%=html(flashMessage)%></div><% } %>

<section class="ums-module-card">
<div class="ums-module-card-header ums-module-card-header-tools">
<div><h2>Programs - <%=html(termCde)%></h2><span>Programs already offered in the selected term</span></div>
<div class="ums-table-tools"><div class="ums-table-search"><label for="offeredProgramSearch">Search</label><input type="search" id="offeredProgramSearch" data-ums-table-search="offeredProgramTable" placeholder="Search term or program"></div><button type="button" class="ums-export-button" data-ums-table-export="offeredProgramTable"><span class="ums-export-icon">⇩</span> Export to Excel</button></div>
</div>
<div class="ums-table-wrap">
<table class="ums-data-table" id="offeredProgramTable" data-ums-table data-export-file="Offered_Programs_<%=html(termCde)%>">
<thead><tr><th class="ums-sortable" data-column="0" data-type="number"><button type="button" class="ums-sort-button">Sr# <span class="ums-sort-indicator">↕</span></button></th><th class="ums-sortable" data-column="1" data-type="text"><button type="button" class="ums-sort-button">Term <span class="ums-sort-indicator">↕</span></button></th><th class="ums-sortable" data-column="2" data-type="text"><button type="button" class="ums-sort-button">Program Code <span class="ums-sort-indicator">↕</span></button></th><th class="ums-sortable" data-column="3" data-type="text"><button type="button" class="ums-sort-button">Program Name <span class="ums-sort-indicator">↕</span></button></th><th class="ums-actions-col">Options</th></tr></thead>
<tbody>
<%
boolean found = false;
int sr = 0;
String listSql = "SELECT OP.TERM_CDE, OP.OP_ID, P.PROG_CDE, P.PROG_NME FROM UMS.OFFERED_PROGRAM OP JOIN UMS.PROGRAM P ON P.PROG_ID = OP.PROG_ID WHERE P.FACULTY_ID = ? AND OP.TERM_CDE = ? ORDER BY P.PROG_CDE, P.PROG_ABBR";
try(PreparedStatement ps = con.prepareStatement(listSql))
{
ps.setString(1, adminSession.getWorkingFacultyId());
ps.setString(2, termCde);
try(ResultSet rs = ps.executeQuery())
{
while(rs.next())
{
found = true;
sr++;
String opId = rs.getString("OP_ID");
%><tr><td><%=sr%></td><td><%=html(rs.getString("TERM_CDE"))%></td><td><%=html(rs.getString("PROG_CDE"))%></td><td><%=html(rs.getString("PROG_NME"))%></td><td class="ums-row-actions" data-export-ignore="true"><a class="ums-action-link ums-action-delete" href="AdminProcessOfferedProgram.jsp?effet=effacer&id=<%=url(opId)%>&term=<%=url(termCde)%>" data-ums-confirm="Delete offered program <%=html(rs.getString("PROG_CDE"))%> - <%=html(rs.getString("PROG_NME"))%>?">Delete</a></td></tr><%
}
}
}
if(!found) { %><tr data-ums-empty-row><td colspan="5" class="ums-table-empty">No offered programs are defined for this term.</td></tr><% }
%>
</tbody>
</table>
</div>
<div class="ums-table-footer" data-ums-table-footer="offeredProgramTable"></div>
</section>
</main>
<script src="../extra/js/ums-module.js?v=20260904"></script>
<script>
document.addEventListener("DOMContentLoaded",function(){var term=document.getElementById("term");if(term){term.addEventListener("change",function(){window.location.href="AdminOfferedProgram.jsp?term="+encodeURIComponent(term.value);});}});
</script>
</body>
</html>
<%
}
finally
{
pool.close(con);
}
%>