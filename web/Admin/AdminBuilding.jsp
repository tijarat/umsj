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
if(!adminSession.hasRightsOn("Building"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Building service."/><%
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
PreparedStatement subCityStmt = null;
PreparedStatement listStmt = null;
ResultSet subCityRs = null;
ResultSet listRs = null;
try
{
con = pool.getConnection();
subCityStmt = con.prepareStatement("SELECT SC.SUB_CITY_ID, SC.SUB_CITY_CODE, SC.SUB_CITY_NAME, C.CITY_NME FROM UMS.SUB_CITY SC LEFT JOIN UMS.CITY C ON C.CITY_ID = SC.CITY_ID WHERE NVL(SC.ACTIVE_IND,'Y') = 'Y' ORDER BY C.CITY_NME, SC.SUB_CITY_NAME");
subCityRs = subCityStmt.executeQuery();
listStmt = con.prepareStatement("SELECT B.BUILDING_ID, B.BUILDING_CDE, B.BUILDING_NME, B.SUB_CITY_ID, B.ADDRESS_TXT, SC.SUB_CITY_CODE, SC.SUB_CITY_NAME, C.CITY_NME FROM UMS.BUILDING B JOIN UMS.SUB_CITY SC ON SC.SUB_CITY_ID = B.SUB_CITY_ID LEFT JOIN UMS.CITY C ON C.CITY_ID = SC.CITY_ID ORDER BY B.BUILDING_NME, B.BUILDING_ID");
listRs = listStmt.executeQuery();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Building Management</title>
<link href="../extra/css/style.css?v=20260831" rel="stylesheet" type="text/css">
<link href="../extra/css/ums-module.css?v=20260831" rel="stylesheet" type="text/css">
</head>
<body class="ums-admin-main-body">
<main class="ums-module-page">
<section class="ums-module-header"><div><p class="ums-module-eyebrow">Infrastructure Setup</p><h1>Building Management</h1><p>Create and maintain buildings and their Sub City locations.</p></div></section>
<section class="ums-module-card">
<div class="ums-module-card-header"><h2>Define Building</h2><span>* Required fields</span></div>
<form action="AdminProcessBuilding.jsp" method="post" class="ums-module-form">
<div class="ums-form-grid">
<div class="ums-field"><label for="buildingId">Building ID *</label><input type="number" name="buildingId" id="buildingId" min="1" required></div>
<div class="ums-field"><label for="buildingCode">Building Code *</label><input type="text" name="buildingCode" id="buildingCode" maxlength="5" autocomplete="off" required></div>
<div class="ums-field"><label for="buildingName">Building Name *</label><input type="text" name="buildingName" id="buildingName" maxlength="50" autocomplete="off" required></div>
<div class="ums-field"><label for="subCityId">Sub City *</label><select name="subCityId" id="subCityId" required data-ums-search-select data-search-placeholder="Type city, sub city or code..." data-search-label="Search Sub City"><option value="">Select Sub City</option><% while(subCityRs.next()) { %><option value="<%=html(subCityRs.getString("SUB_CITY_ID"))%>"><%=html(subCityRs.getString("CITY_NME"))%> - <%=html(subCityRs.getString("SUB_CITY_NAME"))%> (<%=html(subCityRs.getString("SUB_CITY_CODE"))%>)</option><% } %></select></div>
<div class="ums-field ums-field-full"><label for="addressText">Address</label><input type="text" name="addressText" id="addressText" maxlength="50" autocomplete="off"></div>
</div>
<div class="ums-form-actions"><button type="submit">Add Building</button></div>
</form>
</section>
<% if(flashMessage != null && flashMessage.trim().length() > 0) { %><div id="umsFlashMessage" class="ums-flash-message <%="error".equals(flashType) ? "ums-flash-error" : "ums-flash-success"%>" role="alert"><%=html(flashMessage)%></div><% } %>
<section class="ums-module-card">
<div class="ums-module-card-header ums-module-card-header-tools"><div><h2>Buildings</h2><span>All defined buildings</span></div><div class="ums-table-tools"><div class="ums-table-search"><label for="buildingSearch">Search</label><input type="search" id="buildingSearch" data-ums-table-search="buildingTable" placeholder="Search code, building or location" autocomplete="off"></div><button type="button" class="ums-export-button" data-ums-table-export="buildingTable" title="Export Building list to Excel"><span class="ums-export-icon">⇩</span> Export to Excel</button></div></div>
<div class="ums-table-wrap"><table class="ums-data-table" id="buildingTable" data-ums-table data-export-file="Buildings"><thead><tr>
<th class="ums-sortable" data-column="0" data-type="number" data-export-header="Building ID"><button type="button" class="ums-sort-button">ID <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="1" data-type="text" data-export-header="Building Code"><button type="button" class="ums-sort-button">Code <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="2" data-type="text" data-export-header="Building Name"><button type="button" class="ums-sort-button">Building Name <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="3" data-type="text" data-export-header="Sub City"><button type="button" class="ums-sort-button">Sub City <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="4" data-type="text" data-export-header="Address"><button type="button" class="ums-sort-button">Address <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-actions-col">Options</th>
</tr></thead><tbody>
<%
boolean found = false;
while(listRs.next())
{
found = true;
String buildingId = listRs.getString("BUILDING_ID");
String buildingName = listRs.getString("BUILDING_NME");
String editUrl = "AdminEditBuilding.jsp?buildingId=" + url(buildingId);
String deleteUrl = "AdminProcessDeleteBuilding.jsp?buildingId=" + url(buildingId);
%>
<tr><td><%=html(buildingId)%></td><td><%=html(listRs.getString("BUILDING_CDE"))%></td><td><%=html(buildingName)%></td><td><%=html(listRs.getString("CITY_NME"))%> - <%=html(listRs.getString("SUB_CITY_NAME"))%></td><td><%=html(listRs.getString("ADDRESS_TXT"))%></td><td class="ums-row-actions" data-export-ignore="true"><a class="ums-action-link ums-action-edit" href="<%=editUrl%>">Edit</a><a class="ums-action-link ums-action-delete" href="<%=deleteUrl%>" data-ums-confirm="Delete building '<%=html(buildingName)%>'?">Delete</a></td></tr>
<%
}
if(!found)
{
%><tr data-ums-empty-row><td colspan="6" class="ums-table-empty">No buildings are defined.</td></tr><%
}
%>
</tbody></table></div><div class="ums-table-footer" data-ums-table-footer="buildingTable"></div>
</section>
</main>
<script src="../extra/js/ums-module.js?v=20260831"></script>
</body>
</html>
<%
}
finally
{
if(listRs != null) try { listRs.close(); } catch(SQLException ignored) {}
if(listStmt != null) try { listStmt.close(); } catch(SQLException ignored) {}
if(subCityRs != null) try { subCityRs.close(); } catch(SQLException ignored) {}
if(subCityStmt != null) try { subCityStmt.close(); } catch(SQLException ignored) {}
pool.close(con);
}
%>