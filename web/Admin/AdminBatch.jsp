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
if(!adminSession.hasRightsOn("Batch"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Batch service."/><%
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
<title>Batch Management</title>
<link href="../extra/css/style.css?v=20260831" rel="stylesheet" type="text/css">
<link href="../extra/css/ums-module.css?v=20260831" rel="stylesheet" type="text/css">
</head>
<body class="ums-admin-main-body">
<main class="ums-module-page">
<section class="ums-module-header"><div><p class="ums-module-eyebrow">Academic Setup</p><h1>Batch Management</h1><p>Define program batches for working term <strong><%=html(adminSession.workingTerm)%></strong>.</p></div></section>
<section class="ums-module-card">
<div class="ums-module-card-header"><h2>Define Batch</h2><span>* Required fields</span></div>
<form action="AdminProcessBatch.jsp" method="post" class="ums-module-form">
<div class="ums-form-grid">
<div class="ums-field"><label>Working Term</label><div class="ums-readonly-value"><%=html(adminSession.workingTerm)%></div></div>
<div class="ums-field"><label for="progList">Program *</label><select name="progList" id="progList" required data-ums-search-select data-search-placeholder="Type program code or name..." data-search-label="Search Program"><option value="">Select Program</option>
<% try(PreparedStatement ps = con.prepareStatement("SELECT PROG_CDE, PROG_NME FROM UMS.PROGRAM WHERE FACULTY_ID = ? ORDER BY PROG_CDE")) { ps.setString(1, adminSession.getWorkingFacultyId()); try(ResultSet rs = ps.executeQuery()) { while(rs.next()) { %><option value="<%=html(rs.getString("PROG_CDE"))%>"><%=html(rs.getString("PROG_CDE"))%> - <%=html(rs.getString("PROG_NME"))%></option><% } } } %>
</select></div>
<div class="ums-field"><label for="batch">Batch *</label><input name="batch" type="number" id="batch" min="0" max="999" maxlength="3" required></div>
</div>
<div class="ums-form-actions"><button type="submit">Add Batch</button></div>
</form>
</section>
<% if(flashMessage != null && flashMessage.trim().length() > 0) { %><div id="umsFlashMessage" class="ums-flash-message <%="error".equals(flashType) ? "ums-flash-error" : "ums-flash-success"%>" role="alert"><%=html(flashMessage)%></div><% } %>
<section class="ums-module-card">
<div class="ums-module-card-header ums-module-card-header-tools"><div><h2>Batches</h2><span>Programs of the current working faculty</span></div><div class="ums-table-tools"><div class="ums-table-search"><label for="batchSearch">Search</label><input type="search" id="batchSearch" data-ums-table-search="batchTable" placeholder="Search term, program or batch"></div><button type="button" class="ums-export-button" data-ums-table-export="batchTable"><span class="ums-export-icon">⇩</span> Export to Excel</button></div></div>
<div class="ums-table-wrap"><table class="ums-data-table" id="batchTable" data-ums-table data-export-file="Batches"><thead><tr>
<th class="ums-sortable" data-column="0" data-type="text"><button type="button" class="ums-sort-button">Term <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="1" data-type="text"><button type="button" class="ums-sort-button">Program <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="2" data-type="number"><button type="button" class="ums-sort-button">Batch <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-actions-col">Options</th></tr></thead><tbody>
<%
boolean found = false;
try(PreparedStatement ps = con.prepareStatement("SELECT B.TERM_CDE, P.PROG_CDE, P.PROG_NME, B.BATCH_NBR, B.BATCH_ID FROM UMS.BATCH B JOIN UMS.PROGRAM P ON P.PROG_ID = B.PROG_ID WHERE P.FACULTY_ID = ? ORDER BY B.BATCH_ID DESC"))
{
ps.setString(1, adminSession.getWorkingFacultyId());
try(ResultSet rs = ps.executeQuery())
{
while(rs.next())
{
found = true;
String batchId = rs.getString("BATCH_ID");
String termCode = rs.getString("TERM_CDE");
String progCode = rs.getString("PROG_CDE");
String batchNbr = rs.getString("BATCH_NBR");
String editUrl = "AdminEditBatch.jsp?batchId=" + url(batchId);
String deleteUrl = "AdminProcessDeleteBatch.jsp?batchId=" + url(batchId);
%><tr <%=termCode.equals(adminSession.workingTerm) ? "class=\"ums-current-row\"" : ""%>><td><%=html(termCode)%></td><td><%=html(progCode)%> - <%=html(rs.getString("PROG_NME"))%></td><td><%=html(batchNbr)%></td><td class="ums-row-actions" data-export-ignore="true"><a class="ums-action-link ums-action-edit" href="<%=editUrl%>">Edit</a><a class="ums-action-link ums-action-delete" href="<%=deleteUrl%>" data-ums-confirm="Delete batch <%=html(batchNbr)%> of <%=html(progCode)%>?">Delete</a></td></tr><%
}
}
}
if(!found) { %><tr data-ums-empty-row><td colspan="4" class="ums-table-empty">No batches are defined.</td></tr><% }
%>
</tbody></table></div><div class="ums-table-footer" data-ums-table-footer="batchTable"></div>
</section>
</main>
<script src="../extra/js/ums-module.js?v=20260831"></script>
</body>
</html>
<%
}
finally
{
pool.close(con);
}
%>