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
if(!adminSession.hasRightsOn("Campus"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Campus service."/><%
return;
}
String cmpId = request.getParameter("cmpId");
if(cmpId == null || !cmpId.trim().matches("\\d+"))
{
session.setAttribute("flashType", "error");
session.setAttribute("flashMessage", "A valid Campus ID is required.");
response.sendRedirect("AdminCampus.jsp");
return;
}
cmpId = cmpId.trim();
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
Connection con = null;
String uniId = null;
String cmpAbbrev = null;
String cmpName = null;
String cmpPrefix = null;
String franchise = null;
String cmpCode = null;
String challanApproval = null;
String subCityId = null;
String buildingId = null;
String businessUnitId = null;
try
{
con = pool.getConnection();
try(PreparedStatement ps = con.prepareStatement("SELECT UNI_ID, CMP_ABBERV, CMP_NAME, CMP_PREFIX, FRANCHISE, CMP_CDE, CHALLAN_APPROVAL_IND, SUB_CITY_ID, BUILDING_ID, BUSINESS_UNIT_ID FROM UMS.CAMPUS WHERE CMP_ID = ?"))
{
ps.setLong(1, Long.parseLong(cmpId));
try(ResultSet rs = ps.executeQuery())
{
if(rs.next())
{
uniId = rs.getString("UNI_ID");
cmpAbbrev = rs.getString("CMP_ABBERV");
cmpName = rs.getString("CMP_NAME");
cmpPrefix = rs.getString("CMP_PREFIX");
franchise = rs.getString("FRANCHISE");
cmpCode = rs.getString("CMP_CDE");
challanApproval = rs.getString("CHALLAN_APPROVAL_IND");
subCityId = rs.getString("SUB_CITY_ID");
buildingId = rs.getString("BUILDING_ID");
businessUnitId = rs.getString("BUSINESS_UNIT_ID");
}
}
}
if(uniId == null)
{
session.setAttribute("flashType", "error");
session.setAttribute("flashMessage", "Campus record was not found.");
response.sendRedirect("AdminCampus.jsp");
return;
}
%>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Edit Campus</title><link href="../extra/css/style.css?v=20260831" rel="stylesheet" type="text/css"><link href="../extra/css/ums-module.css?v=20260831" rel="stylesheet" type="text/css"></head><body class="ums-admin-main-body"><main class="ums-module-page">
<section class="ums-module-header"><div><p class="ums-module-eyebrow">Infrastructure Setup</p><h1>Campus Management</h1><p>Edit an existing campus.</p></div></section>
<section class="ums-module-card"><div class="ums-module-card-header"><h2>Edit Campus</h2><span>* Required fields</span></div>
<form action="AdminProcessEditCampus.jsp" method="post" class="ums-module-form"><input type="hidden" name="cmpId" value="<%=html(cmpId)%>"><div class="ums-form-grid">
<div class="ums-field"><label>Campus ID</label><div class="ums-readonly-value"><%=html(cmpId)%></div></div>
<div class="ums-field"><label for="uniId">University *</label><select name="uniId" id="uniId" required data-ums-search-select data-search-placeholder="Type university..." data-search-label="Search University"><option value="">Select University</option><% try(PreparedStatement ps = con.prepareStatement("SELECT UNI_ID, UNI_ABBREV, UNI_NAME FROM UMS.UNIVERSITY ORDER BY UNI_NAME"); ResultSet rs = ps.executeQuery()) { while(rs.next()) { String id = rs.getString("UNI_ID"); %><option value="<%=html(id)%>" <%=id.equals(uniId) ? "selected" : ""%>><%=html(rs.getString("UNI_ABBREV"))%> - <%=html(rs.getString("UNI_NAME"))%></option><% } } %></select></div>
<div class="ums-field"><label for="cmpAbbrev">Campus Abbreviation *</label><input type="text" name="cmpAbbrev" id="cmpAbbrev" maxlength="10" value="<%=html(cmpAbbrev)%>" required></div>
<div class="ums-field"><label for="cmpName">Campus Name *</label><input type="text" name="cmpName" id="cmpName" maxlength="250" value="<%=html(cmpName)%>" required></div>
<div class="ums-field"><label for="cmpPrefix">Campus Prefix</label><input type="text" name="cmpPrefix" id="cmpPrefix" maxlength="3" value="<%=html(cmpPrefix)%>"></div>
<div class="ums-field"><label for="cmpCode">Campus Code</label><input type="text" name="cmpCode" id="cmpCode" maxlength="15" value="<%=html(cmpCode)%>"></div>
<div class="ums-field"><label for="franchise">Franchise</label><select name="franchise" id="franchise" data-ums-search-select><option value="N" <%="N".equalsIgnoreCase(franchise) ? "selected" : ""%>>No</option><option value="Y" <%="Y".equalsIgnoreCase(franchise) ? "selected" : ""%>>Yes</option></select></div>
<div class="ums-field"><label for="challanApproval">Challan Approval</label><select name="challanApproval" id="challanApproval" data-ums-search-select><option value="N" <%="N".equalsIgnoreCase(challanApproval) ? "selected" : ""%>>No</option><option value="Y" <%="Y".equalsIgnoreCase(challanApproval) ? "selected" : ""%>>Yes</option></select></div>
<div class="ums-field"><label for="subCityId">Sub City</label><select name="subCityId" id="subCityId" data-ums-search-select data-search-placeholder="Type city or sub city..." data-search-label="Search Sub City"><option value="">No Sub City</option><% try(PreparedStatement ps = con.prepareStatement("SELECT SC.SUB_CITY_ID, SC.SUB_CITY_CODE, SC.SUB_CITY_NAME, C.CITY_NME FROM UMS.SUB_CITY SC LEFT JOIN UMS.CITY C ON C.CITY_ID = SC.CITY_ID ORDER BY C.CITY_NME, SC.SUB_CITY_NAME"); ResultSet rs = ps.executeQuery()) { while(rs.next()) { String id = rs.getString("SUB_CITY_ID"); %><option value="<%=html(id)%>" <%=id.equals(subCityId) ? "selected" : ""%>><%=html(rs.getString("CITY_NME"))%> - <%=html(rs.getString("SUB_CITY_NAME"))%> (<%=html(rs.getString("SUB_CITY_CODE"))%>)</option><% } } %></select></div>
<div class="ums-field"><label for="buildingId">Building</label><select name="buildingId" id="buildingId" data-ums-search-select data-search-placeholder="Type building..." data-search-label="Search Building"><option value="">No Building</option><% try(PreparedStatement ps = con.prepareStatement("SELECT BUILDING_ID, BUILDING_CDE, BUILDING_NME FROM UMS.BUILDING ORDER BY BUILDING_NME"); ResultSet rs = ps.executeQuery()) { while(rs.next()) { String id = rs.getString("BUILDING_ID"); %><option value="<%=html(id)%>" <%=id.equals(buildingId) ? "selected" : ""%>><%=html(rs.getString("BUILDING_CDE"))%> - <%=html(rs.getString("BUILDING_NME"))%></option><% } } %></select></div>
<div class="ums-field"><label for="businessUnitId">Business Unit</label><select name="businessUnitId" id="businessUnitId" data-ums-search-select data-search-placeholder="Type business unit..." data-search-label="Search Business Unit"><option value="">No Business Unit</option><% try(PreparedStatement ps = con.prepareStatement("SELECT BUSINESS_UNIT_ID, BUSINESS_UNIT_CDE, BUSINESS_UNIT_NME FROM UMS.BUSINESS_UNIT ORDER BY BUSINESS_UNIT_NME"); ResultSet rs = ps.executeQuery()) { while(rs.next()) { String id = rs.getString("BUSINESS_UNIT_ID"); %><option value="<%=html(id)%>" <%=id.equals(businessUnitId) ? "selected" : ""%>><%=html(rs.getString("BUSINESS_UNIT_CDE"))%> - <%=html(rs.getString("BUSINESS_UNIT_NME"))%></option><% } } %></select></div>
</div><div class="ums-form-actions"><button type="submit">Update Campus</button><a class="ums-button-secondary" href="AdminCampus.jsp">Cancel</a></div></form></section>
</main><script src="../extra/js/ums-module.js?v=20260831"></script></body></html>
<%
}
finally
{
pool.close(con);
}
%>