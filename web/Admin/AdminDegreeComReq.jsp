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
if(!adminSession.hasRightsOn("Degree Requirement"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Degree Completion Requirement service."/><%
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
<title>Degree Completion Requirement</title>
<link href="../extra/css/style.css?v=20260904" rel="stylesheet" type="text/css">
<link href="../extra/css/ums-module.css?v=20260904" rel="stylesheet" type="text/css">
</head>
<body class="ums-admin-main-body">
<main class="ums-module-page">
<section class="ums-module-header"><div><p class="ums-module-eyebrow">Academic Setup</p><h1>Degree Completion Requirement</h1><p>Maintain minimum credit hours, CGPA and completion years for batches in the current working faculty.</p></div></section>

<% if(flashMessage != null && flashMessage.trim().length() > 0) { %><div id="umsFlashMessage" class="ums-flash-message <%="error".equals(flashType) ? "ums-flash-error" : "ums-flash-success"%>" role="alert"><%=html(flashMessage)%></div><% } %>

<section class="ums-module-card">
<div class="ums-module-card-header ums-module-card-header-tools">
<div><h2>Requirements</h2><span>Working Faculty: <%=html(adminSession.getWorkingFaculty())%></span></div>
<div class="ums-table-tools">
<a class="ums-button-secondary" href="AdminAdvDegreeComReq.jsp">Advanced</a>
<div class="ums-table-search"><label for="degreeReqSearch">Search</label><input type="search" id="degreeReqSearch" data-ums-table-search="degreeReqTable" placeholder="Search batch, term or program"></div>
<button type="button" class="ums-export-button" data-ums-table-export="degreeReqTable"><span class="ums-export-icon">⇩</span> Export to Excel</button>
</div>
</div>
<div class="ums-table-wrap">
<table class="ums-data-table" id="degreeReqTable" data-ums-table data-export-file="Degree_Completion_Requirements">
<thead><tr>
<th class="ums-sortable" data-column="0" data-type="number"><button type="button" class="ums-sort-button">Batch Number <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="1" data-type="text"><button type="button" class="ums-sort-button">Batch Term <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="2" data-type="text"><button type="button" class="ums-sort-button">Program <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="3" data-type="number"><button type="button" class="ums-sort-button">Min Credit Hour <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="4" data-type="number"><button type="button" class="ums-sort-button">Min CGPA <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="5" data-type="number"><button type="button" class="ums-sort-button">Min Year <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="6" data-type="number"><button type="button" class="ums-sort-button">Max Year <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-actions-col">Options</th>
</tr></thead>
<tbody>
<%
boolean found = false;
String sql = "SELECT DISTINCT B.BATCH_ID, B.TERM_CDE, B.BATCH_NBR, P.PROG_ABBR, P.PROG_CDE, P.PROG_NME, F.FACULTY_NME, D.CR_HR_MIN, D.YEAR_MIN, D.YEAR_MAX, D.CGPA_MIN FROM UMS.BATCH B JOIN UMS.PROGRAM P ON P.PROG_ID = B.PROG_ID JOIN UMS.FACULTY F ON F.FACULTY_ID = P.FACULTY_ID JOIN UMS.DEGREE_COMP_REQ D ON D.BATCH_ID = B.BATCH_ID WHERE F.FACULTY_ID = ? ORDER BY P.PROG_ABBR, B.TERM_CDE DESC, B.BATCH_NBR DESC";
try(PreparedStatement ps = con.prepareStatement(sql))
{
ps.setString(1, adminSession.getWorkingFacultyId());
try(ResultSet rs = ps.executeQuery())
{
while(rs.next())
{
found = true;
String batchId = rs.getString("BATCH_ID");
%><tr><td><%=html(rs.getString("BATCH_NBR"))%></td><td><%=html(rs.getString("TERM_CDE"))%></td><td><%=html(rs.getString("PROG_CDE"))%> - <%=html(rs.getString("PROG_NME"))%></td><td><%=html(rs.getString("CR_HR_MIN"))%></td><td><%=html(rs.getString("CGPA_MIN"))%></td><td><%=html(rs.getString("YEAR_MIN"))%></td><td><%=html(rs.getString("YEAR_MAX"))%></td><td class="ums-row-actions" data-export-ignore="true"><a class="ums-action-link ums-action-edit" href="AdminEditDegreeComReq.jsp?batchId=<%=url(batchId)%>">Edit</a></td></tr><%
}
}
}
if(!found) { %><tr data-ums-empty-row><td colspan="8" class="ums-table-empty">No Degree Completion Requirements are defined for this faculty.</td></tr><% }
%>
</tbody>
</table>
</div>
<div class="ums-table-footer" data-ums-table-footer="degreeReqTable"></div>
</section>
</main>
<script src="../extra/js/ums-module.js?v=20260904"></script>
</body>
</html>
<%
}
finally
{
pool.close(con);
}
%>