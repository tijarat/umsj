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
if(!adminSession.hasRightsOn("Program Bank"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Program Bank service."/><%
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
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Program Bank</title><link href="../extra/css/style.css?v=20260831" rel="stylesheet"><link href="../extra/css/ums-module.css?v=20260831" rel="stylesheet"></head>
<body class="ums-admin-main-body"><main class="ums-module-page">
<section class="ums-module-header"><div><p class="ums-module-eyebrow">Finance Setup</p><h1>Program Bank</h1><p>Maintain bank and challan settings for programs of the working faculty.</p></div></section>
<section class="ums-module-card"><div class="ums-module-card-header"><h2>Define Program Bank</h2><span>* Required fields</span></div>
<form action="AdminProcessProgramBank.jsp" method="post" class="ums-module-form"><div class="ums-form-grid">
<div class="ums-field"><label for="progId">Program *</label><select name="progId" id="progId" required data-ums-search-select data-search-placeholder="Type program..." data-search-label="Search Program"><option value="">Select Program</option><% try(PreparedStatement ps = con.prepareStatement("SELECT PROG_ID, PROG_CDE, PROG_NME FROM UMS.PROGRAM WHERE FACULTY_ID = ? ORDER BY PROG_CDE")) { ps.setString(1, adminSession.getWorkingFacultyId()); try(ResultSet rs = ps.executeQuery()) { while(rs.next()) { %><option value="<%=html(rs.getString("PROG_ID"))%>"><%=html(rs.getString("PROG_CDE"))%> - <%=html(rs.getString("PROG_NME"))%></option><% } } } %></select></div>
<div class="ums-field"><label for="bankCde">Bank *</label><select name="bankCde" id="bankCde" required data-ums-search-select data-search-placeholder="Type bank code or name..." data-search-label="Search Bank"><option value="">Select Bank</option><% try(PreparedStatement ps = con.prepareStatement("SELECT BANK_CDE, BANK_NAME FROM UMS.BANK_MASTER ORDER BY BANK_NAME"); ResultSet rs = ps.executeQuery()) { while(rs.next()) { %><option value="<%=html(rs.getString("BANK_CDE"))%>"><%=html(rs.getString("BANK_CDE"))%> - <%=html(rs.getString("BANK_NAME"))%></option><% } } %></select></div>
<div class="ums-field"><label for="acctNbr">Account # *</label><input type="text" name="acctNbr" id="acctNbr" minlength="8" maxlength="50" inputmode="numeric" required></div>
<div class="ums-field"><label for="branchTxt">Branch *</label><input type="text" name="branchTxt" id="branchTxt" maxlength="100" value="Any Branch" required></div>
<div class="ums-field"><label for="challanTitle">Challan Title *</label><input type="text" name="challanTitle" id="challanTitle" maxlength="43" required></div>
<div class="ums-field"><label for="challanPrefix">Challan Prefix *</label><input type="number" name="challanPrefix" id="challanPrefix" min="700" max="999" required></div>
<div class="ums-field"><label class="ums-check-label"><input type="checkbox" name="onlineInd" value="Y"> Online</label></div>
<div class="ums-field"><label class="ums-check-label"><input type="checkbox" name="activeInd" value="Y"> Active</label></div>
<div class="ums-field ums-field-full"><label for="bankRemarks">Bank Remarks</label><input type="text" name="bankRemarks" id="bankRemarks" maxlength="100" pattern="[a-zA-Z0-9\s.()\-]*"></div>
</div><div class="ums-form-actions"><button type="submit">Add Program Bank</button></div></form></section>
<% if(flashMessage != null && flashMessage.trim().length() > 0) { %><div id="umsFlashMessage" class="ums-flash-message <%="error".equals(flashType) ? "ums-flash-error" : "ums-flash-success"%>" role="alert"><%=html(flashMessage)%></div><% } %>
<section class="ums-module-card"><div class="ums-module-card-header ums-module-card-header-tools"><div><h2>Program Banks</h2><span>Configured bank accounts</span></div><div class="ums-table-tools"><div class="ums-table-search"><label for="pbSearch">Search</label><input type="search" id="pbSearch" data-ums-table-search="pbTable" placeholder="Search program, bank or account"></div><button type="button" class="ums-export-button" data-ums-table-export="pbTable"><span class="ums-export-icon">⇩</span> Export to Excel</button></div></div>
<div class="ums-table-wrap"><table class="ums-data-table" id="pbTable" data-ums-table data-export-file="Program_Banks"><thead><tr><th class="ums-sortable" data-column="0" data-type="text"><button type="button" class="ums-sort-button">Program <span class="ums-sort-indicator">↕</span></button></th><th>Bank</th><th>Account</th><th>Branch</th><th>Challan</th><th>Prefix</th><th>Online</th><th>Active</th><th>Show Bank</th><th>Show Account</th><th>Remarks</th><th class="ums-actions-col">Options</th></tr></thead><tbody>
<%
boolean found = false;
String sql = "SELECT P.PROG_CDE, B.BANK_CDE, B.BANK_TXT, DECODE(B.ACCOUNT_NBR,'0','-','000','-',B.ACCOUNT_NBR) ACCOUNT_NBR, B.BRANCH_TXT, B.CHALLAN_TITLE, B.BANK_CHALLAN_PREFIX, B.ONLINE_IND, B.ACTIVE_IND, B.SHOW_IND, NVL(B.SHOW_ACCOUNT,'N') SHOW_ACCOUNT, NVL(B.BANK_REMARKS,'-') BANK_REMARKS, B.BANK_ID FROM UMS.BANK B JOIN UMS.PROGRAM P ON P.PROG_ID = B.PROG_ID WHERE P.FACULTY_ID = ? ORDER BY P.PROG_CDE, B.BANK_TXT, B.ACTIVE_IND";
try(PreparedStatement ps = con.prepareStatement(sql))
{
ps.setString(1, adminSession.getWorkingFacultyId());
try(ResultSet rs = ps.executeQuery())
{
while(rs.next())
{
found = true;
String bankId = rs.getString("BANK_ID");
%><tr><td><%=html(rs.getString("PROG_CDE"))%></td><td><%=html(rs.getString("BANK_CDE"))%> - <%=html(rs.getString("BANK_TXT"))%></td><td><%=html(rs.getString("ACCOUNT_NBR"))%></td><td><%=html(rs.getString("BRANCH_TXT"))%></td><td><%=html(rs.getString("CHALLAN_TITLE"))%></td><td><%=html(rs.getString("BANK_CHALLAN_PREFIX"))%></td><td><%=html(rs.getString("ONLINE_IND"))%></td><td><%=html(rs.getString("ACTIVE_IND"))%></td><td><%=html(rs.getString("SHOW_IND"))%></td><td><%=html(rs.getString("SHOW_ACCOUNT"))%></td><td><%=html(rs.getString("BANK_REMARKS"))%></td><td class="ums-row-actions" data-export-ignore="true"><a class="ums-action-link ums-action-edit" href="AdminEditProgramBank.jsp?bankId=<%=url(bankId)%>">Edit</a><a class="ums-action-link ums-action-delete" href="AdminProcessDeleteProgramBank.jsp?bankId=<%=url(bankId)%>" data-ums-confirm="Delete this program bank?">Delete</a></td></tr><%
}
}
}
if(!found) { %><tr data-ums-empty-row><td colspan="12" class="ums-table-empty">No program banks are defined.</td></tr><% }
%>
</tbody></table></div><div class="ums-table-footer" data-ums-table-footer="pbTable"></div></section>
</main><script src="../extra/js/ums-module.js?v=20260831"></script></body></html>
<%
}
finally
{
pool.close(con);
}
%>