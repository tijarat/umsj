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
if(!adminSession.hasRightsOn("Campus"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Campus service."/><%
return;
}
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
response.setHeader("Pragma", "no-cache");
response.setHeader("Expires", "0");
response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
String flashType = (String)session.getAttribute("flashType");
String flashMessage = (String)session.getAttribute("flashMessage");
session.removeAttribute("flashType");
session.removeAttribute("flashMessage");
Connection con = null;
try
{
con = pool.getConnection();
%>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Campus Management</title><link href="../extra/css/style.css?v=20260831" rel="stylesheet" type="text/css"><link href="../extra/css/ums-module.css?v=20260831" rel="stylesheet" type="text/css"></head>
<body class="ums-admin-main-body"><main class="ums-module-page">
<section class="ums-module-header"><div><p class="ums-module-eyebrow">Infrastructure Setup</p><h1>Campus Management</h1><p>Create and maintain campuses, location, building and business-unit information.</p></div></section>
<section class="ums-module-card"><div class="ums-module-card-header"><h2>Define Campus</h2><span>* Required fields</span></div>
<form action="AdminProcessCampus.jsp" method="post" class="ums-module-form"><div class="ums-form-grid">
<div class="ums-field"><label for="cmpId">Campus ID *</label><input type="number" name="cmpId" id="cmpId" min="1" required></div>
<div class="ums-field"><label for="uniId">University *</label><select name="uniId" id="uniId" required data-ums-search-select data-search-placeholder="Type university..." data-search-label="Search University"><option value="">Select University</option><% try(PreparedStatement ps = con.prepareStatement("SELECT UNI_ID, UNI_ABBREV, UNI_NAME FROM UMS.UNIVERSITY ORDER BY UNI_NAME"); ResultSet rs = ps.executeQuery()) { while(rs.next()) { %><option value="<%=html(rs.getString("UNI_ID"))%>"><%=html(rs.getString("UNI_ABBREV"))%> - <%=html(rs.getString("UNI_NAME"))%></option><% } } %></select></div>
<div class="ums-field"><label for="cmpAbbrev">Campus Abbreviation *</label><input type="text" name="cmpAbbrev" id="cmpAbbrev" maxlength="10" required></div>
<div class="ums-field"><label for="cmpName">Campus Name *</label><input type="text" name="cmpName" id="cmpName" maxlength="250" required></div>
<div class="ums-field"><label for="cmpPrefix">Campus Prefix</label><input type="text" name="cmpPrefix" id="cmpPrefix" maxlength="3"></div>
<div class="ums-field"><label for="cmpCode">Campus Code</label><input type="text" name="cmpCode" id="cmpCode" maxlength="15"></div>
<div class="ums-field"><label for="franchise">Franchise</label><select name="franchise" id="franchise" data-ums-search-select data-search-label="Search Franchise"><option value="N" selected>No</option><option value="Y">Yes</option></select></div>
<div class="ums-field"><label for="challanApproval">Challan Approval</label><select name="challanApproval" id="challanApproval" data-ums-search-select data-search-label="Search Challan Approval"><option value="N" selected>No</option><option value="Y">Yes</option></select></div>
<div class="ums-field"><label for="subCityId">Sub City</label><select name="subCityId" id="subCityId" data-ums-search-select data-search-placeholder="Type city, sub city or code..." data-search-label="Search Sub City"><option value="">No Sub City</option><% try(PreparedStatement ps = con.prepareStatement("SELECT SC.SUB_CITY_ID, SC.SUB_CITY_CODE, SC.SUB_CITY_NAME, C.CITY_NME FROM UMS.SUB_CITY SC LEFT JOIN UMS.CITY C ON C.CITY_ID = SC.CITY_ID ORDER BY C.CITY_NME, SC.SUB_CITY_NAME"); ResultSet rs = ps.executeQuery()) { while(rs.next()) { %><option value="<%=html(rs.getString("SUB_CITY_ID"))%>"><%=html(rs.getString("CITY_NME"))%> - <%=html(rs.getString("SUB_CITY_NAME"))%> (<%=html(rs.getString("SUB_CITY_CODE"))%>)</option><% } } %></select></div>
<div class="ums-field"><label for="buildingId">Building</label><select name="buildingId" id="buildingId" data-ums-search-select data-search-placeholder="Type building code or name..." data-search-label="Search Building"><option value="">No Building</option><% try(PreparedStatement ps = con.prepareStatement("SELECT B.BUILDING_ID, B.BUILDING_CDE, B.BUILDING_NME, SC.SUB_CITY_NAME FROM UMS.BUILDING B LEFT JOIN UMS.SUB_CITY SC ON SC.SUB_CITY_ID = B.SUB_CITY_ID ORDER BY B.BUILDING_NME"); ResultSet rs = ps.executeQuery()) { while(rs.next()) { %><option value="<%=html(rs.getString("BUILDING_ID"))%>"><%=html(rs.getString("BUILDING_CDE"))%> - <%=html(rs.getString("BUILDING_NME"))%> / <%=html(rs.getString("SUB_CITY_NAME"))%></option><% } } %></select></div>
<div class="ums-field"><label for="businessUnitId">Business Unit</label><select name="businessUnitId" id="businessUnitId" data-ums-search-select data-search-placeholder="Type business unit..." data-search-label="Search Business Unit"><option value="">No Business Unit</option><% try(PreparedStatement ps = con.prepareStatement("SELECT BUSINESS_UNIT_ID, BUSINESS_UNIT_CDE, BUSINESS_UNIT_NME FROM UMS.BUSINESS_UNIT ORDER BY BUSINESS_UNIT_NME"); ResultSet rs = ps.executeQuery()) { while(rs.next()) { %><option value="<%=html(rs.getString("BUSINESS_UNIT_ID"))%>"><%=html(rs.getString("BUSINESS_UNIT_CDE"))%> - <%=html(rs.getString("BUSINESS_UNIT_NME"))%></option><% } } %></select></div>
</div><div class="ums-form-actions"><button type="submit">Add Campus</button></div></form></section>
<% if(flashMessage != null && flashMessage.trim().length() > 0) { %><div id="umsFlashMessage" class="ums-flash-message <%="error".equals(flashType) ? "ums-flash-error" : "ums-flash-success"%>" role="alert"><%=html(flashMessage)%></div><% } %>
<section class="ums-module-card"><div class="ums-module-card-header ums-module-card-header-tools"><div><h2>Campuses</h2><span>All defined campuses</span></div><div class="ums-table-tools"><div class="ums-table-search"><label for="campusSearch">Search</label><input type="search" id="campusSearch" data-ums-table-search="campusTable" placeholder="Search campus, university or location" autocomplete="off"></div><button type="button" class="ums-export-button" data-ums-table-export="campusTable" title="Export Campus list to Excel"><span class="ums-export-icon">⇩</span> Export to Excel</button></div></div>
<div class="ums-table-wrap"><table class="ums-data-table" id="campusTable" data-ums-table data-export-file="Campuses"><thead><tr>
<th class="ums-sortable" data-column="0" data-type="number" data-export-header="Campus ID"><button type="button" class="ums-sort-button">ID <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="1" data-type="text" data-export-header="Abbreviation"><button type="button" class="ums-sort-button">Abbreviation <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="2" data-type="text" data-export-header="Campus Name"><button type="button" class="ums-sort-button">Campus Name <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="3" data-type="text" data-export-header="University"><button type="button" class="ums-sort-button">University <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="4" data-type="text" data-export-header="Location"><button type="button" class="ums-sort-button">Location <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="5" data-type="text" data-export-header="Building"><button type="button" class="ums-sort-button">Building <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="6" data-type="text" data-export-header="Business Unit"><button type="button" class="ums-sort-button">Business Unit <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-actions-col">Options</th></tr></thead><tbody>
<%
try(PreparedStatement ps = con.prepareStatement("SELECT C.CMP_ID, C.CMP_ABBERV, C.CMP_NAME, C.CMP_PREFIX, C.FRANCHISE, C.CMP_CDE, C.CHALLAN_APPROVAL_IND, U.UNI_ABBREV, U.UNI_NAME, SC.SUB_CITY_NAME, CT.CITY_NME, B.BUILDING_CDE, B.BUILDING_NME, BU.BUSINESS_UNIT_CDE, BU.BUSINESS_UNIT_NME FROM UMS.CAMPUS C JOIN UMS.UNIVERSITY U ON U.UNI_ID = C.UNI_ID LEFT JOIN UMS.SUB_CITY SC ON SC.SUB_CITY_ID = C.SUB_CITY_ID LEFT JOIN UMS.CITY CT ON CT.CITY_ID = SC.CITY_ID LEFT JOIN UMS.BUILDING B ON B.BUILDING_ID = C.BUILDING_ID LEFT JOIN UMS.BUSINESS_UNIT BU ON BU.BUSINESS_UNIT_ID = C.BUSINESS_UNIT_ID ORDER BY C.CMP_NAME, C.CMP_ID"); ResultSet rs = ps.executeQuery())
{
boolean found = false;
while(rs.next())
{
found = true;
String cmpId = rs.getString("CMP_ID");
String cmpName = rs.getString("CMP_NAME");
String editUrl = "AdminEditCampus.jsp?cmpId=" + url(cmpId);
String deleteUrl = "AdminProcessDeleteCampus.jsp?cmpId=" + url(cmpId);
String location = (rs.getString("CITY_NME") == null ? "" : rs.getString("CITY_NME")) + (rs.getString("SUB_CITY_NAME") == null ? "" : " - " + rs.getString("SUB_CITY_NAME"));
String building = rs.getString("BUILDING_NME") == null ? "" : rs.getString("BUILDING_CDE") + " - " + rs.getString("BUILDING_NME");
String businessUnit = rs.getString("BUSINESS_UNIT_NME") == null ? "" : rs.getString("BUSINESS_UNIT_CDE") + " - " + rs.getString("BUSINESS_UNIT_NME");
%>
<tr><td><%=html(cmpId)%></td><td><%=html(rs.getString("CMP_ABBERV"))%></td><td><%=html(cmpName)%></td><td><%=html(rs.getString("UNI_ABBREV"))%> - <%=html(rs.getString("UNI_NAME"))%></td><td><%=html(location)%></td><td><%=html(building)%></td><td><%=html(businessUnit)%></td><td class="ums-row-actions" data-export-ignore="true"><a class="ums-action-link ums-action-edit" href="<%=editUrl%>">Edit</a><a class="ums-action-link ums-action-delete" href="<%=deleteUrl%>" data-ums-confirm="Delete campus '<%=html(cmpName)%>'?">Delete</a></td></tr>
<%
}
if(!found)
{
%><tr data-ums-empty-row><td colspan="8" class="ums-table-empty">No campuses are defined.</td></tr><%
}
}
%>
</tbody></table></div><div class="ums-table-footer" data-ums-table-footer="campusTable"></div></section>
</main><script src="../extra/js/ums-module.js?v=20260831"></script></body></html>
<%
}
finally
{
pool.close(con);
}
%>