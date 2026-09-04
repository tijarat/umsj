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
if(!adminSession.hasRightsOn("Faculty"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Faculty service."/><%
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
%>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Faculty Management</title><link href="../extra/css/style.css?v=20260831" rel="stylesheet"><link href="../extra/css/ums-module.css?v=20260831" rel="stylesheet"></head><body class="ums-admin-main-body"><main class="ums-module-page">
<section class="ums-module-header"><div><p class="ums-module-eyebrow">Organization Setup</p><h1>Faculty Management</h1><p>Create faculties with campus, absence limits, credit-load definitions and default environment settings.</p></div></section>
<section class="ums-module-card"><div class="ums-module-card-header"><h2>Define Faculty</h2><span>* Required fields</span></div>
<form action="AdminProcessFaculty.jsp" method="post" class="ums-module-form" id="facultyForm">
<div class="ums-form-grid">
<div class="ums-field"><label for="uniName">University *</label><select id="uniName" name="uniName" required data-ums-search-select data-search-placeholder="Type university..." data-search-label="Search University"><option value="">Select University</option><% try(PreparedStatement ps = con.prepareStatement("SELECT UNI_ID, UNI_NAME FROM UMS.UNIVERSITY ORDER BY UNI_NAME"); ResultSet rs = ps.executeQuery()) { while(rs.next()) { %><option value="<%=html(rs.getString("UNI_ID"))%>"><%=html(rs.getString("UNI_NAME"))%></option><% } } %></select></div>
<div class="ums-field"><label for="cmpName">Campus *</label><select id="cmpName" name="cmpName" required data-ums-search-select data-search-placeholder="Type campus..." data-search-label="Search Campus"><option value="">Select Campus</option><% try(PreparedStatement ps = con.prepareStatement("SELECT C.CMP_ID, C.CMP_NAME, U.UNI_NAME FROM UMS.CAMPUS C JOIN UMS.UNIVERSITY U ON U.UNI_ID = C.UNI_ID ORDER BY U.UNI_NAME, C.CMP_NAME"); ResultSet rs = ps.executeQuery()) { while(rs.next()) { %><option value="<%=html(rs.getString("CMP_ID"))%>"><%=html(rs.getString("UNI_NAME"))%> - <%=html(rs.getString("CMP_NAME"))%></option><% } } %></select></div>
<div class="ums-field"><label for="facultyName">Faculty Name *</label><input name="facultyName" type="text" id="facultyName" maxlength="250" required></div>
<div class="ums-field"><label for="facultyAbb">Faculty Abbreviation *</label><input name="facultyAbb" type="text" id="facultyAbb" maxlength="10" required></div>
<div class="ums-field ums-field-full"><label for="facultyDsc">Faculty Description</label><textarea name="facultyDsc" id="facultyDsc" maxlength="500" rows="3"></textarea></div>
<div class="ums-field"><label class="ums-check-label"><input name="status" type="checkbox" value="Y" checked> Active</label></div>
</div>
<div class="ums-module-card-header"><h3>Absent Limit</h3><span>At least one entry is required</span></div>
<div class="ums-form-grid"><div class="ums-field"><label for="CrHr">Credit Hours</label><select id="CrHr"><option>1</option><option>2</option><option>3</option><option>4</option><option>5</option><option>6</option></select></div><div class="ums-field"><label for="absentLimit">Absent Limit</label><input type="number" id="absentLimit" min="0"></div><div class="ums-field"><label for="absentLimitSports">Sports Limit</label><input type="number" id="absentLimitSports" min="0"></div><div class="ums-field"><label>Options</label><div class="ums-inline-actions"><button type="button" id="addAbsent">Add</button><button type="button" class="ums-button-secondary" id="removeAbsent">Remove</button></div></div><div class="ums-field ums-field-full"><label for="selectedValues">Defined Limits</label><select id="selectedValues" name="selectedValues" multiple size="5"></select></div></div>
<div class="ums-module-card-header"><h3>Credit Load Definition</h3></div>
<div class="ums-form-grid"><div class="ums-field"><label for="creditHrs">Credit Hours</label><select id="creditHrs"><option>1</option><option>2</option><option>3</option><option>4</option><option>5</option><option>6</option></select></div><div class="ums-field"><label for="classLimit">Class Limit</label><input type="number" id="classLimit" min="0"></div><div class="ums-field"><label>Options</label><div class="ums-inline-actions"><button type="button" id="addClass">Add</button><button type="button" class="ums-button-secondary" id="removeClass">Remove</button></div></div><div class="ums-field ums-field-full"><label for="selectedValuesClass">Defined Loads</label><select id="selectedValuesClass" name="selectedValuesClass" multiple size="5"></select></div></div>
<div class="ums-module-card-header"><h3>Discount Policy</h3><span>Optional</span></div>
<div class="ums-form-grid"><div class="ums-field"><label for="frmCgpa">From CGPA</label><input type="number" step="0.01" id="frmCgpa"></div><div class="ums-field"><label for="toCgpa">To CGPA</label><input type="number" step="0.01" id="toCgpa"></div><div class="ums-field"><label for="frmBatch">From Term</label><select id="frmBatch" data-ums-search-select><option value="">Select Term</option><% try(PreparedStatement ps = con.prepareStatement("SELECT TERM_CDE FROM UMS.TERM ORDER BY START_DTE DESC"); ResultSet rs = ps.executeQuery()) { while(rs.next()) { %><option value="<%=html(rs.getString(1))%>"><%=html(rs.getString(1))%></option><% } } %></select></div><div class="ums-field"><label for="toBatch">To Term</label><select id="toBatch" data-ums-search-select><option value="">Open Ended</option><% try(PreparedStatement ps = con.prepareStatement("SELECT TERM_CDE FROM UMS.TERM ORDER BY START_DTE DESC"); ResultSet rs = ps.executeQuery()) { while(rs.next()) { %><option value="<%=html(rs.getString(1))%>"><%=html(rs.getString(1))%></option><% } } %></select></div><div class="ums-field"><label for="disc">Discount %</label><input type="number" step="0.01" id="disc"></div><div class="ums-field"><label>Options</label><div class="ums-inline-actions"><button type="button" id="addDiscount">Add</button><button type="button" class="ums-button-secondary" id="removeDiscount">Remove</button></div></div><div class="ums-field ums-field-full"><label for="selectedDisc">Defined Discount Policies</label><select id="selectedDisc" name="selectedDisc" multiple size="5"></select></div></div>
<div class="ums-form-actions"><button type="submit">Save Faculty</button></div>
</form></section>
<% if(flashMessage != null && flashMessage.trim().length() > 0) { %><div id="umsFlashMessage" class="ums-flash-message <%="error".equals(flashType) ? "ums-flash-error" : "ums-flash-success"%>" role="alert"><%=html(flashMessage)%></div><% } %>
<section class="ums-module-card"><div class="ums-module-card-header ums-module-card-header-tools"><div><h2>Faculties</h2><span>All universities and campuses</span></div><div class="ums-table-tools"><div class="ums-table-search"><label for="facultySearch">Search</label><input type="search" id="facultySearch" data-ums-table-search="facultyTable" placeholder="Search university, campus or faculty"></div><button type="button" class="ums-export-button" data-ums-table-export="facultyTable"><span class="ums-export-icon">⇩</span> Export to Excel</button></div></div>
<div class="ums-table-wrap"><table class="ums-data-table" id="facultyTable" data-ums-table data-export-file="Faculties"><thead><tr><th>University</th><th>Campus</th><th>Faculty Name</th><th>Abbreviation</th><th>Description</th><th>Status</th><th class="ums-actions-col">Options</th></tr></thead><tbody>
<%
boolean found = false;
String facultySql = "SELECT F.FACULTY_ID, F.FACULTY_NME, F.FACULTY_ABBREV, F.FACULTY_DSC, C.CMP_NAME, U.UNI_NAME, U.UNI_ID, DECODE(F.ACTIVE_STATUS,'Y','Active','N','Disabled',NULL,'-',F.ACTIVE_STATUS) ACTIVE_STATUS FROM UMS.FACULTY F JOIN UMS.CAMPUS C ON C.CMP_ID = F.CMP_ID JOIN UMS.UNIVERSITY U ON U.UNI_ID = C.UNI_ID ORDER BY U.UNI_NAME, C.CMP_NAME, F.FACULTY_NME";
try(PreparedStatement ps = con.prepareStatement(facultySql); ResultSet rs = ps.executeQuery())
{
while(rs.next())
{
found = true;
String facultyId = rs.getString("FACULTY_ID");
String editUrl = "AdminEditFaculty.jsp?facultyId=" + url(facultyId);
String deleteUrl = "AdminProcessDeleteFaculty.jsp?facultyId=" + url(facultyId);
%><tr <%="Disabled".equalsIgnoreCase(rs.getString("ACTIVE_STATUS")) ? "class=\"ums-disabled-row\"" : ""%>><td><%=html(rs.getString("UNI_NAME"))%></td><td><%=html(rs.getString("CMP_NAME"))%></td><td><%=html(rs.getString("FACULTY_NME"))%></td><td><%=html(rs.getString("FACULTY_ABBREV"))%></td><td><%=html(rs.getString("FACULTY_DSC"))%></td><td><%=html(rs.getString("ACTIVE_STATUS"))%></td><td class="ums-row-actions" data-export-ignore="true"><a class="ums-action-link ums-action-edit" href="<%=editUrl%>">Edit</a><a class="ums-action-link ums-action-delete" href="<%=deleteUrl%>" data-ums-confirm="Delete faculty '<%=html(rs.getString("FACULTY_NME"))%>' and its faculty-level settings?">Delete</a></td></tr><%
}
}
if(!found) { %><tr data-ums-empty-row><td colspan="7" class="ums-table-empty">No faculties are defined.</td></tr><% }
%>
</tbody></table></div><div class="ums-table-footer" data-ums-table-footer="facultyTable"></div></section>
</main><script src="../extra/js/ums-module.js?v=20260831"></script><script src="../extra/js/faculty.js?v=20260831"></script></body></html>
<%
}
finally
{
pool.close(con);
}
%>