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
if(!adminSession.hasRightsOn("Batch"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Batch service."/><%
return;
}
String batchId = request.getParameter("batchId");
if(batchId == null || !batchId.matches("\\d+")) { session.setAttribute("flashType","error"); session.setAttribute("flashMessage","A valid Batch ID is required."); response.sendRedirect("AdminBatch.jsp"); return; }
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
Connection con = null;
try
{
con = pool.getConnection();
String termCode = null;
String progCode = null;
String progName = null;
String batchNbr = null;
try(PreparedStatement ps = con.prepareStatement("SELECT B.TERM_CDE, B.BATCH_NBR, P.PROG_CDE, P.PROG_NME FROM UMS.BATCH B JOIN UMS.PROGRAM P ON P.PROG_ID = B.PROG_ID WHERE B.BATCH_ID = ? AND P.FACULTY_ID = ?"))
{
ps.setLong(1, Long.parseLong(batchId));
ps.setInt(2, adminSession.getWorkingFacultyId());
try(ResultSet rs = ps.executeQuery()) { if(rs.next()) { termCode = rs.getString("TERM_CDE"); batchNbr = rs.getString("BATCH_NBR"); progCode = rs.getString("PROG_CDE"); progName = rs.getString("PROG_NME"); } }
}
if(termCode == null) { session.setAttribute("flashType","error"); session.setAttribute("flashMessage","Batch record was not found for this faculty."); response.sendRedirect("AdminBatch.jsp"); return; }
%>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Edit Batch</title><link href="../extra/css/style.css?v=20260831" rel="stylesheet"><link href="../extra/css/ums-module.css?v=20260831" rel="stylesheet"></head>
<body class="ums-admin-main-body"><main class="ums-module-page"><section class="ums-module-header"><div><p class="ums-module-eyebrow">Academic Setup</p><h1>Batch Management</h1><p>Edit the selected batch number.</p></div></section>
<section class="ums-module-card"><div class="ums-module-card-header"><h2>Edit Batch</h2><span>* Required fields</span></div><form action="AdminProcessEditBatch.jsp" method="post" class="ums-module-form"><input type="hidden" name="batchId" value="<%=html(batchId)%>"><div class="ums-form-grid"><div class="ums-field"><label>Term</label><div class="ums-readonly-value"><%=html(termCode)%></div></div><div class="ums-field"><label>Program</label><div class="ums-readonly-value"><%=html(progCode)%> - <%=html(progName)%></div></div><div class="ums-field"><label for="batch">Batch *</label><input name="batch" type="number" id="batch" min="0" max="999" value="<%=html(batchNbr)%>" required></div></div><div class="ums-form-actions"><button type="submit">Update Batch</button><a class="ums-button-secondary" href="AdminBatch.jsp">Cancel</a></div></form></section></main><script src="../extra/js/ums-module.js?v=20260831"></script></body></html>
<%
}
finally
{
pool.close(con);
}
%>