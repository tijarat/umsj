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
if(!adminSession.hasRightsOn("Building"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Building service."/><%
return;
}
String buildingId = request.getParameter("buildingId");
if(buildingId == null || !buildingId.trim().matches("\\d+"))
{
session.setAttribute("flashType", "error");
session.setAttribute("flashMessage", "A valid Building ID is required.");
response.sendRedirect("AdminBuilding.jsp");
return;
}
buildingId = buildingId.trim();
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
Connection con = null;
String buildingCode = null;
String buildingName = null;
String subCityId = null;
String addressText = null;
try
{
con = pool.getConnection();
try(PreparedStatement ps = con.prepareStatement("SELECT BUILDING_CDE, BUILDING_NME, SUB_CITY_ID, ADDRESS_TXT FROM UMS.BUILDING WHERE BUILDING_ID = ?"))
{
ps.setLong(1, Long.parseLong(buildingId));
try(ResultSet rs = ps.executeQuery())
{
if(rs.next())
{
buildingCode = rs.getString("BUILDING_CDE");
buildingName = rs.getString("BUILDING_NME");
subCityId = rs.getString("SUB_CITY_ID");
addressText = rs.getString("ADDRESS_TXT");
}
}
}
if(buildingCode == null)
{
session.setAttribute("flashType", "error");
session.setAttribute("flashMessage", "Building record was not found.");
response.sendRedirect("AdminBuilding.jsp");
return;
}
%>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Edit Building</title><link href="../extra/css/style.css?v=20260831" rel="stylesheet" type="text/css"><link href="../extra/css/ums-module.css?v=20260831" rel="stylesheet" type="text/css"></head>
<body class="ums-admin-main-body"><main class="ums-module-page">
<section class="ums-module-header"><div><p class="ums-module-eyebrow">Infrastructure Setup</p><h1>Building Management</h1><p>Edit an existing building.</p></div></section>
<section class="ums-module-card"><div class="ums-module-card-header"><h2>Edit Building</h2><span>* Required fields</span></div>
<form action="AdminProcessEditBuilding.jsp" method="post" class="ums-module-form"><input type="hidden" name="buildingId" value="<%=html(buildingId)%>">
<div class="ums-form-grid">
<div class="ums-field"><label>Building ID</label><div class="ums-readonly-value"><%=html(buildingId)%></div></div>
<div class="ums-field"><label for="buildingCode">Building Code *</label><input type="text" name="buildingCode" id="buildingCode" maxlength="5" value="<%=html(buildingCode)%>" required></div>
<div class="ums-field"><label for="buildingName">Building Name *</label><input type="text" name="buildingName" id="buildingName" maxlength="50" value="<%=html(buildingName)%>" required></div>
<div class="ums-field"><label for="subCityId">Sub City *</label><select name="subCityId" id="subCityId" required data-ums-search-select data-search-placeholder="Type city, sub city or code..." data-search-label="Search Sub City"><option value="">Select Sub City</option>
<% try(PreparedStatement ps = con.prepareStatement("SELECT SC.SUB_CITY_ID, SC.SUB_CITY_CODE, SC.SUB_CITY_NAME, C.CITY_NME FROM UMS.SUB_CITY SC LEFT JOIN UMS.CITY C ON C.CITY_ID = SC.CITY_ID ORDER BY C.CITY_NME, SC.SUB_CITY_NAME")) { try(ResultSet rs = ps.executeQuery()) { while(rs.next()) { String id = rs.getString("SUB_CITY_ID"); %><option value="<%=html(id)%>" <%=id.equals(subCityId) ? "selected" : ""%>><%=html(rs.getString("CITY_NME"))%> - <%=html(rs.getString("SUB_CITY_NAME"))%> (<%=html(rs.getString("SUB_CITY_CODE"))%>)</option><% } } } %>
</select></div>
<div class="ums-field ums-field-full"><label for="addressText">Address</label><input type="text" name="addressText" id="addressText" maxlength="50" value="<%=html(addressText)%>"></div>
</div>
<div class="ums-form-actions"><button type="submit">Update Building</button><a class="ums-button-secondary" href="AdminBuilding.jsp">Cancel</a></div>
</form></section>
</main><script src="../extra/js/ums-module.js?v=20260831"></script></body></html>
<%
}
finally
{
pool.close(con);
}
%>