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
com.ums.packages.LocalSession adminSession=(com.ums.packages.LocalSession)session.getAttribute("adminSession");
if(adminSession==null)
{
%><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><%
return;
}
if(!adminSession.hasRightsOn("Teacher Timetable"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Teacher Timetable service."/><%
return;
}
com.ums.db.Pool pool=(com.ums.db.Pool)application.getAttribute("pool");
if(pool==null) throw new ServletException("Database pool is not initialized.");
Connection con=null;
try
{
con=pool.getConnection();
String facultyId=adminSession.getWorkingFacultyId();
String campusId="";
try(PreparedStatement ps=con.prepareStatement("SELECT CMP_ID FROM UMS.FACULTY WHERE FACULTY_ID = ?"))
{
ps.setString(1,facultyId);
try(ResultSet rs=ps.executeQuery()) { if(rs.next()) campusId=rs.getString("CMP_ID"); }
}
if(campusId.length()==0) throw new ServletException("Campus is not configured for the working faculty.");
String sdte=request.getParameter("sdte");
String edte=request.getParameter("edte");
%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Makeup Time Table</title><link href="../extra/css/style.css?v=20260904" rel="stylesheet"><link href="../extra/css/ums-module.css?v=20260904" rel="stylesheet"></head>
<body class="ums-admin-main-body"><main class="ums-module-page">
<section class="ums-module-header"><div><p class="ums-module-eyebrow">Timetable</p><h1>Makeup Time Table</h1><p>Create and review makeup timetable entries for <strong><%=html(adminSession.getWorkingFaculty())%></strong> / <strong><%=html(adminSession.workingTerm)%></strong>.</p></div></section>

<section class="ums-module-card"><div class="ums-module-card-header"><h2>Select Week</h2></div><div class="ums-form-grid"><div class="ums-field"><label for="weekDate">Any Date in Week</label><input type="date" id="weekDate"></div><div class="ums-field"><label>Selected Range</label><div class="ums-readonly-value"><span id="weekRange">Choose a date</span></div></div></div></section>

<section class="ums-module-card"><div class="ums-module-card-header"><h2>Add Makeup Time Table</h2><span>* Required fields</span></div>
<form id="makeupEntryForm" class="ums-module-form">
<div class="ums-form-grid">
<div class="ums-field"><label for="placeId">Room *</label><select id="placeId" name="placeId" required data-ums-search-select data-search-placeholder="Type room..." data-search-label="Search Room"><option value="">Select Room</option>
<% try(PreparedStatement ps=con.prepareStatement("SELECT PLACE_ID, PLACE_TXT FROM UMS.PLACE WHERE ACTIVE_IND = 'Y' AND CMP_ID = ? ORDER BY PLACE_TXT")) { ps.setString(1,campusId); try(ResultSet rs=ps.executeQuery()) { while(rs.next()) { %><option value="<%=html(rs.getString("PLACE_ID"))%>"><%=html(rs.getString("PLACE_TXT"))%></option><% } } } %>
</select></div>
<div class="ums-field"><label for="section">Section *</label><select id="section" name="sectionId" required data-ums-search-select data-search-placeholder="Type teacher, course or section..." data-search-label="Search Section"><option value="">Select Section</option>
<%
String sectionSql="SELECT DISTINCT S.SECTION_ID, T.TCHR_NME, C.COURSE_CDE, C.COURSE_NME, S.SECTION_TXT FROM UMS.COURSE C JOIN UMS.SECTION S ON S.COURSE_ID = C.COURSE_ID JOIN UMS.TEACHER T ON S.TCHR_ID = T.TCHR_ID JOIN UMS.SECTION_FACULTY SF ON S.SECTION_ID = SF.SECTION_ID JOIN UMS.FACULTY F ON SF.FACULTY_ID = F.FACULTY_ID WHERE C.TERM_CDE = ? AND F.FACULTY_ID = ? ORDER BY T.TCHR_NME, C.COURSE_CDE, S.SECTION_TXT";
try(PreparedStatement ps=con.prepareStatement(sectionSql)) { ps.setString(1,adminSession.workingTerm); ps.setString(2,facultyId); try(ResultSet rs=ps.executeQuery()) { while(rs.next()) { %><option value="<%=html(rs.getString("SECTION_ID"))%>"><%=html(rs.getString("TCHR_NME"))%> : [<%=html(rs.getString("COURSE_CDE"))%>] <%=html(rs.getString("COURSE_NME"))%> (<%=html(rs.getString("SECTION_TXT"))%>)</option><% } } }
%>
</select></div>
<div class="ums-field"><label for="slot">Slot *</label><select id="slot" name="slotId" required data-ums-search-select data-search-placeholder="Type slot..." data-search-label="Search Slot"><option value="">Select Slot</option>
<% try(PreparedStatement ps=con.prepareStatement("SELECT SLOT_ID, TO_CHAR(SLOT_START_TIME,'HH:MI AM') SLOT_START_TIME, TO_CHAR(SLOT_END_TIME,'HH:MI AM') SLOT_END_TIME FROM UMS.SLOT WHERE TERM_CDE = ? AND CMP_ID = ? ORDER BY SLOT_START_TIME")) { ps.setString(1,adminSession.workingTerm); ps.setString(2,campusId); try(ResultSet rs=ps.executeQuery()) { while(rs.next()) { %><option value="<%=html(rs.getString("SLOT_ID"))%>"><%=html(rs.getString("SLOT_START_TIME"))%> - <%=html(rs.getString("SLOT_END_TIME"))%></option><% } } } %>
</select></div>
</div>
<div class="ums-module-card-header"><h3>Repeat Days</h3><span>Monday to Saturday</span></div>
<div class="ums-form-grid" id="makeupDays">
<div class="ums-field"><label class="ums-check-label"><input type="checkbox" id="repeatAll"> All Days</label></div>
<div class="ums-field"><label class="ums-check-label"><input type="checkbox" name="repeat" id="Mon"> <span id="monDay">Mon</span></label></div>
<div class="ums-field"><label class="ums-check-label"><input type="checkbox" name="repeat" id="Tu"> <span id="tuDay">Tue</span></label></div>
<div class="ums-field"><label class="ums-check-label"><input type="checkbox" name="repeat" id="Wed"> <span id="wedDay">Wed</span></label></div>
<div class="ums-field"><label class="ums-check-label"><input type="checkbox" name="repeat" id="Th"> <span id="thDay">Thu</span></label></div>
<div class="ums-field"><label class="ums-check-label"><input type="checkbox" name="repeat" id="Fri"> <span id="friDay">Fri</span></label></div>
<div class="ums-field"><label class="ums-check-label"><input type="checkbox" name="repeat" id="Sat"> <span id="satDay">Sat</span></label></div>
</div>
<div class="ums-form-actions"><button type="submit">Add Time Table</button></div>
</form>
<div id="makeupStatus"></div>
</section>

<section class="ums-module-card"><div class="ums-module-card-header"><h2>View Makeup Time Table</h2></div>
<form action="AdminMakeupTimeTableNew.jsp" method="get" class="ums-module-form"><div class="ums-form-grid">
<div class="ums-field"><label for="sdte">From Date *</label><input type="text" name="sdte" id="sdte" value="<%=html(sdte)%>" placeholder="DD-MM-YYYY" readonly required></div>
<div class="ums-field"><label for="edte">To Date *</label><input type="text" name="edte" id="edte" value="<%=html(edte)%>" placeholder="DD-MM-YYYY" readonly required></div>
</div><div class="ums-form-actions"><button type="submit">View Time Table</button></div></form>
</section>

<% if(sdte!=null && edte!=null && sdte.matches("\\d{2}-\\d{2}-\\d{4}") && edte.matches("\\d{2}-\\d{2}-\\d{4}")) { %>
<section class="ums-module-card"><div class="ums-module-card-header ums-module-card-header-tools"><div><h2>Makeup Time Table</h2><span><%=html(sdte)%> to <%=html(edte)%></span></div><div class="ums-table-tools"><div class="ums-table-search"><label for="makeupSearch">Search</label><input type="search" id="makeupSearch" data-ums-table-search="makeupTable" placeholder="Search course, section, teacher or venue"></div><button type="button" class="ums-export-button" data-ums-table-export="makeupTable"><span class="ums-export-icon">⇩</span> Export to Excel</button></div></div>
<div class="ums-table-wrap"><table class="ums-data-table" id="makeupTable" data-ums-table data-export-file="Makeup_Time_Table"><thead><tr><th>S#</th><th>Date</th><th>Time</th><th>Course</th><th>Section</th><th>Teacher</th><th>Venue</th><th class="ums-actions-col">Option</th></tr></thead><tbody>
<%
boolean found=false;
int count=0;
String listSql="SELECT TM.TM_ID, TD.TD_ID, S.SECTION_TXT, TO_CHAR(TD.SCHEDULE_DATE,'DD-MM-YYYY') SCHEDULE_DATE, C.TERM_CDE, C.COURSE_CDE, T.TCHR_ABBR, P.PLACE_TXT, TO_CHAR(SL.SLOT_START_TIME,'HH:MI') SLOT_START_TIME, TO_CHAR(SL.SLOT_END_TIME,'HH:MI') SLOT_END_TIME, (SELECT CH.CLASS_ID FROM UMS.CLASS_HELD CH WHERE CH.SECTION_ID = S.SECTION_ID AND TRUNC(CH.CLASS_DTE) = TRUNC(TD.SCHEDULE_DATE) AND CH.SLOT_ID = SL.SLOT_ID AND CH.CLASS_TYP = 'M') CONFIRM FROM UMS.TIMETABLE_MASTER TM JOIN UMS.TIMETABLE_DETAIL TD ON TM.TM_ID = TD.TM_ID JOIN UMS.SECTION S ON TM.SECTION_ID = S.SECTION_ID JOIN UMS.COURSE C ON C.COURSE_ID = S.COURSE_ID JOIN UMS.TEACHER T ON T.TCHR_ID = S.TCHR_ID JOIN UMS.PLACE P ON P.PLACE_ID = TM.PLACE_ID JOIN UMS.SLOT SL ON SL.SLOT_ID = TM.SLOT_ID JOIN UMS.SECTION_FACULTY SF ON S.SECTION_ID = SF.SECTION_ID WHERE SF.FACULTY_ID = ? AND C.TERM_CDE = SL.TERM_CDE AND TD.SCHEDULE_DATE BETWEEN TO_DATE(?,'DD-MM-YYYY') AND TO_DATE(?,'DD-MM-YYYY') ORDER BY TD.SCHEDULE_DATE DESC";
try(PreparedStatement ps=con.prepareStatement(listSql))
{
ps.setString(1,facultyId);
ps.setString(2,sdte);
ps.setString(3,edte);
try(ResultSet rs=ps.executeQuery())
{
while(rs.next())
{
found=true;
count++;
%><tr><td><%=count%></td><td><%=html(rs.getString("SCHEDULE_DATE"))%></td><td><%=html(rs.getString("SLOT_START_TIME"))%>-<%=html(rs.getString("SLOT_END_TIME"))%></td><td><%=html(rs.getString("COURSE_CDE"))%></td><td><%=html(rs.getString("SECTION_TXT"))%></td><td><%=html(rs.getString("TCHR_ABBR"))%></td><td><%=html(rs.getString("PLACE_TXT"))%></td><td class="ums-row-actions" data-export-ignore="true"><% if(rs.getString("CONFIRM")==null) { %><a class="ums-action-link ums-action-delete" href="AdminProcessDeleteTimeTble.jsp?tdId=<%=url(rs.getString("TD_ID"))%>" data-ums-confirm="Delete this makeup timetable entry?">Delete</a><% } %></td></tr><%
}
}
}
if(!found) { %><tr data-ums-empty-row><td colspan="8" class="ums-table-empty">No makeup timetable entries found for this date range.</td></tr><% }
%>
</tbody></table></div><div class="ums-table-footer" data-ums-table-footer="makeupTable"></div></section>
<% } %>
</main>
<script src="../extra/js/ums-module.js?v=20260904"></script>
<script src="../extra/js/makeup-timetable.js?v=20260904"></script>
</body></html>
<%
}
finally
{
pool.close(con);
}
%>