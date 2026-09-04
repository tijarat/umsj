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
if(!adminSession.hasRightsOn("Faculty"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Faculty service."/><%
return;
}
String facultyId = request.getParameter("facultyId");
if(facultyId == null || !facultyId.matches("\\d+")) { session.setAttribute("flashType","error"); session.setAttribute("flashMessage","A valid Faculty ID is required."); response.sendRedirect("AdminFaculty.jsp"); return; }
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
Connection con = null;
try
{
con = pool.getConnection();
String facultyName = null;
String facultyAbb = null;
String facultyDsc = null;
String cmpId = null;
String activeStatus = null;
try(PreparedStatement ps = con.prepareStatement("SELECT FACULTY_NME, FACULTY_ABBREV, FACULTY_DSC, CMP_ID, ACTIVE_STATUS FROM UMS.FACULTY WHERE FACULTY_ID = ?"))
{
ps.setLong(1, Long.parseLong(facultyId));
try(ResultSet rs = ps.executeQuery()) { if(rs.next()) { facultyName = rs.getString("FACULTY_NME"); facultyAbb = rs.getString("FACULTY_ABBREV"); facultyDsc = rs.getString("FACULTY_DSC"); cmpId = rs.getString("CMP_ID"); activeStatus = rs.getString("ACTIVE_STATUS"); } }
}
if(facultyName == null) { session.setAttribute("flashType","error"); session.setAttribute("flashMessage","Faculty record was not found."); response.sendRedirect("AdminFaculty.jsp"); return; }
%>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Edit Faculty</title><link href="../extra/css/style.css?v=20260831" rel="stylesheet"><link href="../extra/css/ums-module.css?v=20260831" rel="stylesheet"></head><body class="ums-admin-main-body"><main class="ums-module-page">
<section class="ums-module-header"><div><p class="ums-module-eyebrow">Organization Setup</p><h1>Faculty Management</h1><p>Edit faculty, absent limits and credit-load definitions.</p></div></section>
<section class="ums-module-card"><div class="ums-module-card-header"><h2>Edit Faculty</h2><span>* Required fields</span></div><form action="AdminProcessEditFaculty.jsp" method="post" class="ums-module-form" id="facultyForm"><input type="hidden" name="facultyId" value="<%=html(facultyId)%>"><div class="ums-form-grid">
<div class="ums-field"><label for="cmpName">Campus *</label><select name="cmpName" id="cmpName" required data-ums-search-select data-search-placeholder="Type university or campus..." data-search-label="Search Campus"><% try(PreparedStatement ps = con.prepareStatement("SELECT C.CMP_ID, C.CMP_NAME, U.UNI_NAME FROM UMS.CAMPUS C JOIN UMS.UNIVERSITY U ON U.UNI_ID = C.UNI_ID ORDER BY U.UNI_NAME, C.CMP_NAME"); ResultSet rs = ps.executeQuery()) { while(rs.next()) { String id = rs.getString("CMP_ID"); %><option value="<%=html(id)%>" <%=id.equals(cmpId) ? "selected" : ""%>><%=html(rs.getString("UNI_NAME"))%> - <%=html(rs.getString("CMP_NAME"))%></option><% } } %></select></div>
<div class="ums-field"><label for="facultyName">Faculty Name *</label><input name="facultyName" type="text" id="facultyName" maxlength="250" value="<%=html(facultyName)%>" required></div><div class="ums-field"><label for="facultyAbb">Faculty Abbreviation *</label><input name="facultyAbb" type="text" id="facultyAbb" maxlength="10" value="<%=html(facultyAbb)%>" required></div><div class="ums-field ums-field-full"><label for="facultyDsc">Faculty Description</label><textarea name="facultyDsc" id="facultyDsc" maxlength="500" rows="3"><%=html(facultyDsc)%></textarea></div><div class="ums-field"><label class="ums-check-label"><input name="status" type="checkbox" value="Y" <%="Y".equalsIgnoreCase(activeStatus) ? "checked" : ""%>> Active</label></div></div>
<div class="ums-module-card-header"><h3>Absent Limit</h3></div><div class="ums-form-grid"><div class="ums-field"><label for="CrHr">Credit Hours</label><select id="CrHr"><option>1</option><option>2</option><option>3</option><option>4</option><option>5</option><option>6</option></select></div><div class="ums-field"><label for="absentLimit">Absent Limit</label><input type="number" id="absentLimit" min="0"></div><div class="ums-field"><label for="absentLimitSports">Sports Limit</label><input type="number" id="absentLimitSports" min="0"></div><div class="ums-field"><label>Options</label><div class="ums-inline-actions"><button type="button" id="addAbsent">Add</button><button type="button" class="ums-button-secondary" id="removeAbsent">Remove</button></div></div><div class="ums-field ums-field-full"><label for="selectedValues">Defined Limits</label><select id="selectedValues" name="selectedValues" multiple size="5"><% try(PreparedStatement ps = con.prepareStatement("SELECT CREDIT_HRS, ABSENT_LIMIT, ABSENT_LIMIT_SPORTS FROM UMS.ABSENT_LIMIT WHERE FACULTY_ID = ? ORDER BY CREDIT_HRS")) { ps.setLong(1, Long.parseLong(facultyId)); try(ResultSet rs = ps.executeQuery()) { while(rs.next()) { String v = rs.getString(1) + "|" + rs.getString(2) + "|" + rs.getString(3); %><option value="<%=html(v)%>" selected><%=html("CrHr: " + rs.getString(1) + " | Absent: " + rs.getString(2) + " | Sports: " + rs.getString(3))%></option><% } } } %></select></div></div>
<div class="ums-module-card-header"><h3>Credit Load Definition</h3></div><div class="ums-form-grid"><div class="ums-field"><label for="creditHrs">Credit Hours</label><select id="creditHrs"><option>1</option><option>2</option><option>3</option><option>4</option><option>5</option><option>6</option></select></div><div class="ums-field"><label for="classLimit">Class Limit</label><input type="number" id="classLimit" min="0"></div><div class="ums-field"><label>Options</label><div class="ums-inline-actions"><button type="button" id="addClass">Add</button><button type="button" class="ums-button-secondary" id="removeClass">Remove</button></div></div><div class="ums-field ums-field-full"><label for="selectedValuesClass">Defined Loads</label><select id="selectedValuesClass" name="selectedValuesClass" multiple size="5"><% try(PreparedStatement ps = con.prepareStatement("SELECT CREDIT_HRS, CLASS_LIMIT FROM UMS.CREDIT_LOAD_DEFINITION WHERE FACULTY_ID = ? ORDER BY CREDIT_HRS")) { ps.setLong(1, Long.parseLong(facultyId)); try(ResultSet rs = ps.executeQuery()) { while(rs.next()) { String v = rs.getString(1) + "|" + rs.getString(2); %><option value="<%=html(v)%>" selected><%=html("CrHr: " + rs.getString(1) + " | Class Limit: " + rs.getString(2))%></option><% } } } %></select></div></div>
<div class="ums-inline-notice">Existing Discount Policy rows are intentionally left unchanged on Edit, matching the legacy processor behavior.</div>
<div class="ums-form-actions"><button type="submit">Update Faculty</button><a class="ums-button-secondary" href="AdminFaculty.jsp">Cancel</a></div></form></section></main><script src="../extra/js/ums-module.js?v=20260831"></script><script src="../extra/js/faculty.js?v=20260831"></script></body></html>
<%
}
finally
{
pool.close(con);
}
%>