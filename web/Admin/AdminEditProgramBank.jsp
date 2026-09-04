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
if(!adminSession.hasRightsOn("Program Bank"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Program Bank service."/><%
return;
}
String bankId = request.getParameter("bankId");
if(bankId == null || !bankId.matches("\\d+")) { session.setAttribute("flashType","error"); session.setAttribute("flashMessage","A valid Bank ID is required."); response.sendRedirect("AdminProgramBank.jsp"); return; }
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
Connection con = null;
try
{
con = pool.getConnection();
String progCode = null;
String bankCode = null;
String bankText = null;
String acctNbr = null;
String branchTxt = null;
String challanTitle = null;
String challanPrefix = null;
String onlineInd = null;
String activeInd = null;
String showInd = null;
String showAccount = null;
String bankRemarks = null;
String sql = "SELECT P.PROG_CDE, B.BANK_CDE, B.BANK_TXT, B.ACCOUNT_NBR, B.BRANCH_TXT, B.CHALLAN_TITLE, B.BANK_CHALLAN_PREFIX, B.ONLINE_IND, B.ACTIVE_IND, B.SHOW_IND, NVL(B.SHOW_ACCOUNT,'N') SHOW_ACCOUNT, NVL(B.BANK_REMARKS,'') BANK_REMARKS FROM UMS.BANK B JOIN UMS.PROGRAM P ON P.PROG_ID = B.PROG_ID WHERE B.BANK_ID = ? AND P.FACULTY_ID = ?";
try(PreparedStatement ps = con.prepareStatement(sql))
{
ps.setLong(1, Long.parseLong(bankId));
ps.setInt(2, adminSession.getWorkingFacultyId());
try(ResultSet rs = ps.executeQuery())
{
if(rs.next()) { progCode = rs.getString("PROG_CDE"); bankCode = rs.getString("BANK_CDE"); bankText = rs.getString("BANK_TXT"); acctNbr = rs.getString("ACCOUNT_NBR"); branchTxt = rs.getString("BRANCH_TXT"); challanTitle = rs.getString("CHALLAN_TITLE"); challanPrefix = rs.getString("BANK_CHALLAN_PREFIX"); onlineInd = rs.getString("ONLINE_IND"); activeInd = rs.getString("ACTIVE_IND"); showInd = rs.getString("SHOW_IND"); showAccount = rs.getString("SHOW_ACCOUNT"); bankRemarks = rs.getString("BANK_REMARKS"); }
}
}
if(progCode == null) { session.setAttribute("flashType","error"); session.setAttribute("flashMessage","Program Bank record was not found for this faculty."); response.sendRedirect("AdminProgramBank.jsp"); return; }
boolean onlineOnly = "OL".equalsIgnoreCase(bankCode) || "CDN".equalsIgnoreCase(bankCode);
%>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Edit Program Bank</title><link href="../extra/css/style.css?v=20260831" rel="stylesheet"><link href="../extra/css/ums-module.css?v=20260831" rel="stylesheet"></head><body class="ums-admin-main-body"><main class="ums-module-page">
<section class="ums-module-header"><div><p class="ums-module-eyebrow">Finance Setup</p><h1>Program Bank</h1><p>Edit account display and status settings.</p></div></section>
<section class="ums-module-card"><div class="ums-module-card-header"><h2>Edit Program Bank</h2></div><form action="AdminProcessEditProgramBank.jsp" method="post" class="ums-module-form"><input type="hidden" name="bankId" value="<%=html(bankId)%>"><input type="hidden" name="bankCde" value="<%=html(bankCode)%>"><div class="ums-form-grid">
<div class="ums-field"><label>Program</label><div class="ums-readonly-value"><%=html(progCode)%></div></div><div class="ums-field"><label>Bank</label><div class="ums-readonly-value"><%=html(bankCode)%> - <%=html(bankText)%></div></div>
<div class="ums-field"><label for="acctNbr">Account #</label><input type="text" name="acctNbr" id="acctNbr" value="<%=html(acctNbr)%>" <%=onlineOnly ? "readonly" : ""%>></div><div class="ums-field"><label>Branch</label><div class="ums-readonly-value"><%=html(branchTxt)%></div></div>
<div class="ums-field"><label>Challan Title</label><div class="ums-readonly-value"><%=html(challanTitle)%></div></div><div class="ums-field"><label>Challan Prefix</label><div class="ums-readonly-value"><%=html(challanPrefix)%></div></div>
<div class="ums-field"><label class="ums-check-label"><input type="checkbox" name="onlineInd" value="Y" <%="Y".equalsIgnoreCase(onlineInd) ? "checked" : ""%>> Online</label></div><div class="ums-field"><label class="ums-check-label"><input type="checkbox" name="activeInd" value="Y" <%="Y".equalsIgnoreCase(activeInd) ? "checked" : ""%>> Active</label></div>
<div class="ums-field"><label class="ums-check-label"><input type="checkbox" name="showInd" value="Y" <%="Y".equalsIgnoreCase(showInd) ? "checked" : ""%> <%=onlineOnly ? "disabled" : ""%>> Show Bank on Challan</label></div><div class="ums-field"><label class="ums-check-label"><input type="checkbox" name="showAccount" value="Y" <%="Y".equalsIgnoreCase(showAccount) ? "checked" : ""%>> Show Account on Challan</label></div>
<div class="ums-field ums-field-full"><label for="bankRemarks">Bank Remarks</label><input type="text" name="bankRemarks" id="bankRemarks" maxlength="100" value="<%=html(bankRemarks)%>"></div>
</div><div class="ums-form-actions"><button type="submit">Update Program Bank</button><a class="ums-button-secondary" href="AdminProgramBank.jsp">Cancel</a></div></form></section></main><script src="../extra/js/ums-module.js?v=20260831"></script></body></html>
<%
}
finally
{
pool.close(con);
}
%>