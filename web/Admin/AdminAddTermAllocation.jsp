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
if(!adminSession.hasRightsOn("Term Allocation"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Term Allocation service."/><%
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
boolean canAllowAnyTerm = com.ums.functions.Functions.isUserAllowedProcess(con, "CanAllowAnyTerm", adminSession.user);
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Term Allocation</title>
<link href="../extra/css/style.css?v=20260904" rel="stylesheet" type="text/css">
<link href="../extra/css/ums-module.css?v=20260904" rel="stylesheet" type="text/css">
</head>
<body class="ums-admin-main-body">
<main class="ums-module-page">
<section class="ums-module-header">
<div><p class="ums-module-eyebrow">Administration</p><h1>Term Allocation</h1><p>Allocate access to a term for users managed by you within the current working faculty.</p></div>
</section>

<section class="ums-module-card">
<div class="ums-module-card-header"><h2>Allocate Term</h2><div><a class="ums-button-secondary" href="AdminAdvanceTermAllocation.jsp">Advance...</a></div></div>
<form action="AdminProcessAddTermAllocation.jsp" method="post" class="ums-module-form" id="termAllocationForm">
<div class="ums-form-grid">
<div class="ums-field"><label>Faculty</label><div class="ums-readonly-value"><%=html(adminSession.getWorkingFaculty())%></div></div>

<div class="ums-field">
<label for="termCode">Term Code *</label>
<select name="termCode" id="termCode" required data-ums-search-select data-search-placeholder="Type term code or name..." data-search-label="Search Term">
<option value="">Select Term</option>
<%
String termSql;
if(canAllowAnyTerm)
{
termSql = "SELECT T.TERM_CDE, T.TERM_NME, TO_CHAR(T.START_DTE,'DD-MM-YYYY') START_DTE, TO_CHAR(T.END_DTE,'DD-MM-YYYY') END_DTE, T.STATUS_TYP FROM UMS.TERM T WHERE T.TERM_CDE <> (SELECT CT.TERM_CDE FROM UMS.CURRENT_TERM CT WHERE CT.FACULTY_ID = ?) ORDER BY T.START_DTE DESC";
}
else
{
termSql = "SELECT T.TERM_CDE, T.TERM_NME, TO_CHAR(T.START_DTE,'DD-MM-YYYY') START_DTE, TO_CHAR(T.END_DTE,'DD-MM-YYYY') END_DTE, T.STATUS_TYP FROM UMS.TERM T WHERE T.START_DTE = (SELECT MAX(T1.START_DTE) FROM UMS.TERM T1 WHERE T1.START_DTE < (SELECT T2.START_DTE FROM UMS.TERM T2 JOIN UMS.CURRENT_TERM C2 ON C2.TERM_CDE = T2.TERM_CDE WHERE C2.FACULTY_ID = ?)) OR T.START_DTE BETWEEN (SELECT T3.START_DTE FROM UMS.TERM T3 JOIN UMS.CURRENT_TERM C3 ON C3.TERM_CDE = T3.TERM_CDE WHERE T3.STATUS_TYP = 'C' AND C3.FACULTY_ID = ?) AND (SELECT MAX(T4.START_DTE) FROM UMS.TERM T4 WHERE T4.START_DTE > (SELECT T5.START_DTE FROM UMS.TERM T5 JOIN UMS.CURRENT_TERM C5 ON C5.TERM_CDE = T5.TERM_CDE WHERE C5.FACULTY_ID = ?)) ORDER BY T.START_DTE DESC";
}
try(PreparedStatement ps = con.prepareStatement(termSql))
{
ps.setString(1, adminSession.getWorkingFacultyId());
if(!canAllowAnyTerm) { ps.setString(2, adminSession.getWorkingFacultyId()); ps.setString(3, adminSession.getWorkingFacultyId()); }
try(ResultSet rs = ps.executeQuery())
{
while(rs.next())
{
%><option value="<%=html(rs.getString("TERM_CDE"))%>"><%=html(rs.getString("TERM_CDE"))%> - <%=html(rs.getString("TERM_NME"))%></option><%
}
}
}
%>
</select>
</div>

<div class="ums-field">
<label for="userName">User *</label>
<select name="userName" id="userName" required data-ums-search-select data-search-placeholder="Type user name..." data-search-label="Search User">
<option value="">Select User</option>
<%
String userSql = "SELECT WUM.RIGHTS_FOR_USER USER_NME FROM UMS.WEB_USERS WU JOIN UMS.WEB_USERS_MANAGEMENT WUM ON WU.USER_NME = WUM.USER_RIGHTS_MANAGER WHERE WU.USER_NME = ? ORDER BY WUM.RIGHTS_FOR_USER";
try(PreparedStatement ps = con.prepareStatement(userSql))
{
ps.setString(1, adminSession.user);
try(ResultSet rs = ps.executeQuery())
{
while(rs.next())
{
%><option value="<%=html(rs.getString("USER_NME"))%>"><%=html(rs.getString("USER_NME"))%></option><%
}
}
}
%>
</select>
</div>

<div class="ums-field">
<label for="frmDateDisplay">From Date *</label>
<div class="ums-date-picker">
<input type="text" id="frmDateDisplay" class="ums-date-display" value="" placeholder="DD-MM-YYYY" readonly required>
<input type="hidden" name="frmDate" id="frmDate" value="">
<input type="date" id="frmDatePicker" class="ums-native-date" tabindex="-1" aria-hidden="true">
<button type="button" class="ums-date-button" aria-label="Open From Date calendar">📅</button>
</div>
</div>

<div class="ums-field">
<label for="toDateDisplay">To Date *</label>
<div class="ums-date-picker">
<input type="text" id="toDateDisplay" class="ums-date-display" value="" placeholder="DD-MM-YYYY" readonly required>
<input type="hidden" name="toDate" id="toDate" value="">
<input type="date" id="toDatePicker" class="ums-native-date" tabindex="-1" aria-hidden="true">
<button type="button" class="ums-date-button" aria-label="Open To Date calendar">📅</button>
</div>
</div>
</div>
<div class="ums-form-actions"><button type="submit">Add Allocation</button></div>
</form>
</section>

<% if(flashMessage != null && flashMessage.trim().length() > 0) { %>
<div id="umsFlashMessage" class="ums-flash-message <%="error".equals(flashType) ? "ums-flash-error" : "ums-flash-success"%>" role="alert"><%=html(flashMessage)%></div>
<% } %>

<section class="ums-module-card">
<div class="ums-module-card-header ums-module-card-header-tools">
<div><h2>Term Allocations</h2><span>Allocations for users managed by <%=html(adminSession.user)%></span></div>
<div class="ums-table-tools">
<div class="ums-table-search"><label for="termAllocationSearch">Search</label><input type="search" id="termAllocationSearch" data-ums-table-search="termAllocationTable" placeholder="Search term, user or faculty"></div>
<button type="button" class="ums-export-button" data-ums-table-export="termAllocationTable"><span class="ums-export-icon">⇩</span> Export to Excel</button>
</div>
</div>
<div class="ums-table-wrap">
<table class="ums-data-table" id="termAllocationTable" data-ums-table data-export-file="Term_Allocations">
<thead><tr>
<th class="ums-sortable" data-column="0" data-type="text"><button type="button" class="ums-sort-button">Term Code <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="1" data-type="text"><button type="button" class="ums-sort-button">Faculty <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="2" data-type="text"><button type="button" class="ums-sort-button">User <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="3" data-type="date"><button type="button" class="ums-sort-button">From Date <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="4" data-type="date"><button type="button" class="ums-sort-button">To Date <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-actions-col">Options</th>
</tr></thead>
<tbody>
<%
boolean found = false;
String allocationSql = "SELECT UTA.TERM_CDE, UTA.USER_NME, TO_CHAR(UTA.FRM_DTE,'DD-MM-YYYY') FRM_DTE, TO_CHAR(UTA.TO_DTE,'DD-MM-YYYY') TO_DTE, UTA.DISALLOW_IND, F.FACULTY_ABBREV, CASE WHEN TRUNC(SYSDATE) <= TRUNC(UTA.TO_DTE) THEN 1 ELSE 0 END COMP_DTE_IND FROM UMS.USER_TERM_ALLOCATION UTA JOIN UMS.FACULTY F ON F.FACULTY_ID = UTA.FACULTY_ID WHERE F.FACULTY_ID = ? AND UTA.USER_NME IN (SELECT WUM.RIGHTS_FOR_USER FROM UMS.WEB_USERS_MANAGEMENT WUM WHERE WUM.USER_RIGHTS_MANAGER = ?) ORDER BY UTA.FRM_DTE DESC";
try(PreparedStatement ps = con.prepareStatement(allocationSql))
{
ps.setString(1, adminSession.getWorkingFacultyId());
ps.setString(2, adminSession.user);
try(ResultSet rs = ps.executeQuery())
{
while(rs.next())
{
found = true;
String userName = rs.getString("USER_NME");
String termCode = rs.getString("TERM_CDE");
String facultyAbbrev = rs.getString("FACULTY_ABBREV");
String editUrl = "AdminEditTermAllocation.jsp?usr=" + url(userName) + "&trm=" + url(termCode) + "&fac=" + url(facultyAbbrev);
String deleteUrl = "AdminProcessDeleteTermAllocation.jsp?usr=" + url(userName) + "&trm=" + url(termCode) + "&fac=" + url(facultyAbbrev);
%>
<tr <%=rs.getInt("COMP_DTE_IND") == 1 ? "class=\"ums-current-row\"" : ""%>>
<td><%=html(termCode)%></td>
<td><%=html(facultyAbbrev)%></td>
<td><%=html(userName)%></td>
<td><%=html(rs.getString("FRM_DTE"))%></td>
<td><%=html(rs.getString("TO_DTE"))%></td>
<td class="ums-row-actions" data-export-ignore="true"><a class="ums-action-link ums-action-edit" href="<%=editUrl%>">Edit</a><a class="ums-action-link ums-action-delete" href="<%=deleteUrl%>" data-ums-confirm="Delete term allocation for <%=html(userName)%> / <%=html(termCode)%>?">Delete</a></td>
</tr>
<%
}
}
}
if(!found)
{
%><tr data-ums-empty-row><td colspan="6" class="ums-table-empty">No term allocations are defined for your managed users.</td></tr><%
}
%>
</tbody>
</table>
</div>
<div class="ums-table-footer" data-ums-table-footer="termAllocationTable"></div>
</section>
</main>
<script src="../extra/js/ums-module.js?v=20260904"></script>
<script src="../extra/js/term-allocation.js?v=20260904"></script>
</body>
</html>
<%
}
finally
{
pool.close(con);
}
%>