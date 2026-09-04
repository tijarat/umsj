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
if(!adminSession.hasRightsOn("Degree Requirement"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Degree Completion Requirement service."/><%
return;
}
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
Connection con = null;
try
{
con = pool.getConnection();
String prog = request.getParameter("prog");
String term = request.getParameter("term");
if(prog == null || prog.trim().length() == 0)
{
try(PreparedStatement ps = con.prepareStatement("SELECT PROG_CDE FROM UMS.PROGRAM ORDER BY PROG_CDE"); ResultSet rs = ps.executeQuery()) { if(rs.next()) prog = rs.getString(1); }
}
if(term == null || term.trim().length() == 0)
{
try(PreparedStatement ps = con.prepareStatement("SELECT TERM_CDE FROM UMS.TERM ORDER BY START_DTE DESC"); ResultSet rs = ps.executeQuery()) { if(rs.next()) term = rs.getString(1); }
}
%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Advanced Degree Completion Requirement</title><link href="../extra/css/style.css?v=20260904" rel="stylesheet"><link href="../extra/css/ums-module.css?v=20260904" rel="stylesheet"></head>
<body class="ums-admin-main-body"><main class="ums-module-page">
<section class="ums-module-header"><div><p class="ums-module-eyebrow">Academic Setup</p><h1>Advanced Degree Completion Requirement</h1><p>Compare the same program and batch term across campuses.</p></div></section>
<section class="ums-module-card">
<div class="ums-module-card-header"><h2>Selection</h2><span>Advanced cross-campus view</span></div>
<form action="AdminAdvDegreeComReq.jsp" method="get" class="ums-module-form">
<div class="ums-form-grid">
<div class="ums-field"><label for="prog">Program *</label><select name="prog" id="prog" required data-ums-search-select data-search-placeholder="Type program code..." data-search-label="Search Program">
<% try(PreparedStatement ps = con.prepareStatement("SELECT DISTINCT PROG_CDE FROM UMS.PROGRAM ORDER BY PROG_CDE"); ResultSet rs = ps.executeQuery()) { while(rs.next()) { String code = rs.getString(1); %><option value="<%=html(code)%>" <%=code.equals(prog) ? "selected" : ""%>><%=html(code)%></option><% } } %>
</select></div>
<div class="ums-field"><label for="term">Batch Term *</label><select name="term" id="term" required data-ums-search-select data-search-placeholder="Type term code..." data-search-label="Search Batch Term">
<% try(PreparedStatement ps = con.prepareStatement("SELECT TERM_CDE FROM UMS.TERM ORDER BY START_DTE DESC"); ResultSet rs = ps.executeQuery()) { while(rs.next()) { String code = rs.getString(1); %><option value="<%=html(code)%>" <%=code.equals(term) ? "selected" : ""%>><%=html(code)%></option><% } } %>
</select></div>
</div>
<div class="ums-form-actions"><button type="submit">Show Requirements</button><a class="ums-button-secondary" href="AdminDegreeComReq.jsp">Back</a></div>
</form>
</section>

<section class="ums-module-card">
<div class="ums-module-card-header ums-module-card-header-tools"><div><h2>Requirements</h2><span><%=html(prog)%> / <%=html(term)%></span></div><div class="ums-table-tools"><div class="ums-table-search"><label for="advReqSearch">Search</label><input type="search" id="advReqSearch" data-ums-table-search="advReqTable" placeholder="Search campus"></div><button type="button" class="ums-export-button" data-ums-table-export="advReqTable"><span class="ums-export-icon">⇩</span> Export to Excel</button></div></div>
<div class="ums-table-wrap">
<table class="ums-data-table" id="advReqTable" data-ums-table data-export-file="Advanced_Degree_Completion_Requirements">
<thead><tr><th>Sr#</th><th>Campus</th><th>Min Credit Hour</th><th>Min CGPA</th><th>Min Year</th><th>Max Year</th></tr></thead>
<tbody>
<%
boolean found = false;
int sr = 0;
String sql = "SELECT DISTINCT B.BATCH_ID, B.TERM_CDE, B.BATCH_NBR, P.PROG_ABBR, P.PROG_CDE, P.PROG_NME, F.FACULTY_NME, D.CR_HR_MIN, D.YEAR_MIN, D.YEAR_MAX, D.CGPA_MIN, C.CMP_NAME, P.PROG_ID FROM UMS.BATCH B JOIN UMS.PROGRAM P ON P.PROG_ID = B.PROG_ID JOIN UMS.FACULTY F ON F.FACULTY_ID = P.FACULTY_ID JOIN UMS.DEGREE_COMP_REQ D ON D.BATCH_ID = B.BATCH_ID JOIN UMS.CAMPUS C ON C.CMP_ID = F.CMP_ID WHERE P.PROG_CDE = ? AND B.TERM_CDE = ? ORDER BY C.CMP_NAME";
try(PreparedStatement ps = con.prepareStatement(sql))
{
ps.setString(1, prog);
ps.setString(2, term);
try(ResultSet rs = ps.executeQuery())
{
while(rs.next())
{
found = true;
sr++;
%><tr><td><%=sr%></td><td><%=html(rs.getString("CMP_NAME"))%></td><td><%=html(rs.getString("CR_HR_MIN"))%></td><td><%=html(rs.getString("CGPA_MIN"))%></td><td><%=html(rs.getString("YEAR_MIN"))%></td><td><%=html(rs.getString("YEAR_MAX"))%></td></tr><%
}
}
}
if(!found) { %><tr data-ums-empty-row><td colspan="6" class="ums-table-empty">No Degree Requirements found for this Program / Batch Term.</td></tr><% }
%>
</tbody></table>
</div>
<div class="ums-table-footer" data-ums-table-footer="advReqTable"></div>
<div class="ums-inline-notice">The legacy page also linked to <strong>AdminEditAdvDegreeComReq.jsp</strong> for bulk cross-campus edits. That JSP was not included in the supplied module, so this converted page preserves the cross-campus comparison without inventing missing update logic.</div>
</section>
</main>
<script src="../extra/js/ums-module.js?v=20260904"></script>
</body>
</html>
<%
}
finally
{
pool.close(con);
}
%>