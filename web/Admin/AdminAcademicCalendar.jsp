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
if(!adminSession.hasRightsOn("Academic Calendar"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Academic Calendar service."/><%
return;
}
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
String term = request.getParameter("termCode");
if(term == null || term.trim().length() == 0) term = adminSession.workingTerm;
term = term == null ? "" : term.trim();
String flashType = (String)session.getAttribute("flashType");
String flashMessage = (String)session.getAttribute("flashMessage");
session.removeAttribute("flashType");
session.removeAttribute("flashMessage");
Connection con = null;
try
{
con = pool.getConnection();
int termExists = 0;
try(PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM UMS.TERM WHERE TERM_CDE = ?")) { ps.setString(1, term); try(ResultSet rs = ps.executeQuery()) { if(rs.next()) termExists = rs.getInt(1); } }
if(termExists == 0 && adminSession.workingTerm != null) term = adminSession.workingTerm;
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Academic Calendar</title>
<link href="../extra/css/style.css?v=20260904" rel="stylesheet">
<link href="../extra/css/ums-module.css?v=20260904" rel="stylesheet">
</head>
<body class="ums-admin-main-body">
<main class="ums-module-page">
<section class="ums-module-header"><div><p class="ums-module-eyebrow">Academic Setup</p><h1>Academic Calendar</h1><p>Maintain activity dates for <strong><%=html(adminSession.getWorkingFaculty())%></strong>.</p></div></section>

<section class="ums-module-card">
<div class="ums-module-card-header"><h2>Select Term</h2></div>
<form action="AdminAcademicCalendar.jsp" method="get" class="ums-module-form">
<div class="ums-form-grid"><div class="ums-field"><label for="termCode">Term *</label><select name="termCode" id="termCode" required data-ums-search-select data-search-placeholder="Type term code or name..." data-search-label="Search Term">
<% try(PreparedStatement ps = con.prepareStatement("SELECT TERM_CDE, TERM_NME FROM UMS.TERM ORDER BY START_DTE DESC"); ResultSet rs = ps.executeQuery()) { while(rs.next()) { String code = rs.getString("TERM_CDE"); %><option value="<%=html(code)%>" <%=code.equals(term) ? "selected" : ""%>><%=html(code)%> - <%=html(rs.getString("TERM_NME"))%></option><% } } %>
</select></div></div>
<div class="ums-form-actions"><button type="submit">Show Calendar</button></div>
</form>
</section>

<% if(flashMessage != null && flashMessage.trim().length() > 0) { %><div id="umsFlashMessage" class="ums-flash-message <%="error".equals(flashType) ? "ums-flash-error" : "ums-flash-success"%>" role="alert"><%=html(flashMessage)%></div><% } %>

<section class="ums-module-card">
<div class="ums-module-card-header"><h2>Academic Calendar of <%=html(adminSession.getWorkingFaculty())%> for <%=html(term)%></h2><span>Dates use DD/MM/YYYY</span></div>
<form action="AdminProcessAcademicCalendar.jsp" method="post" class="ums-module-form" id="academicCalendarForm">
<input type="hidden" name="termCode" value="<%=html(term)%>">
<div class="ums-table-wrap"><table class="ums-data-table" id="academicCalendarTable">
<thead><tr><th>Activity Name</th><th>Start Date</th><th>End Date</th></tr></thead><tbody>
<%
boolean found=false;
int row=0;
String sql="SELECT ACTIVITY_ID, ACTIVITY_NAME, NVL(TO_CHAR(START_DATE,'DD/MM/YYYY'),'') START_DATE, NVL(TO_CHAR(END_DATE,'DD/MM/YYYY'),'') END_DATE FROM UMS.ACADEMIC_CALENDAR WHERE TERM_CDE = ? ORDER BY ACTIVITY_ID";
try(PreparedStatement ps=con.prepareStatement(sql))
{
ps.setString(1,term);
try(ResultSet rs=ps.executeQuery())
{
while(rs.next())
{
found=true;
row++;
String idx=String.valueOf(row);
%><tr><td><%=html(rs.getString("ACTIVITY_NAME"))%><input type="hidden" name="activityId<%=idx%>" value="<%=html(rs.getString("ACTIVITY_ID"))%>"></td>
<td><div class="ums-date-picker"><input type="text" id="startDate<%=idx%>Display" class="ums-date-display" value="<%=html(rs.getString("START_DATE"))%>" placeholder="DD/MM/YYYY" readonly required><input type="hidden" name="startDate<%=idx%>" id="startDate<%=idx%>" value="<%=html(rs.getString("START_DATE"))%>"><input type="date" id="startDate<%=idx%>Picker" class="ums-native-date" tabindex="-1" aria-hidden="true"><button type="button" class="ums-date-button" aria-label="Open Start Date calendar">📅</button></div></td>
<td><div class="ums-date-picker"><input type="text" id="endDate<%=idx%>Display" class="ums-date-display" value="<%=html(rs.getString("END_DATE"))%>" placeholder="DD/MM/YYYY" readonly><input type="hidden" name="endDate<%=idx%>" id="endDate<%=idx%>" value="<%=html(rs.getString("END_DATE"))%>"><input type="date" id="endDate<%=idx%>Picker" class="ums-native-date" tabindex="-1" aria-hidden="true"><button type="button" class="ums-date-button" aria-label="Open End Date calendar">📅</button></div></td></tr><%
}
}
}
if(!found) { %><tr data-ums-empty-row><td colspan="3" class="ums-table-empty">No Academic Calendar activities are defined for this term.</td></tr><% }
%>
</tbody></table></div>
<input type="hidden" name="count" value="<%=row%>">
<% if(found) { %><div class="ums-form-actions"><button type="submit">Update Calendar</button></div><% } %>
</form>
</section>
</main>
<script src="../extra/js/ums-module.js?v=20260904"></script>
<script src="../extra/js/academic-calendar.js?v=20260904"></script>
</body>
</html>
<%
}
finally
{
pool.close(con);
}
%>