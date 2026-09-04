<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*,java.util.*,java.net.URLEncoder" session="true" errorPage="../error.jsp" %>
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
if(!adminSession.hasRightsOn("Teacher Timetable"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over View Teacher's TimeTable service."/><%
return;
}
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
String term = adminSession.workingTerm == null ? "" : adminSession.workingTerm.trim();
String dayIndex = request.getParameter("dayIndex");
if(dayIndex == null || dayIndex.trim().length() == 0) dayIndex = "*";
dayIndex = dayIndex.trim().toUpperCase();
Set<String> validDays = new HashSet<String>(Arrays.asList("*","MONDAY","TUESDAY","WEDNESDAY","THURSDAY","FRIDAY","SATURDAY"));
if(!validDays.contains(dayIndex)) dayIndex = "*";
int tchrId = adminSession.tchrId;
String tchrParam = request.getParameter("tchrId");
if(tchrParam != null && tchrParam.matches("\\d+")) tchrId = Integer.parseInt(tchrParam);
Connection con = null;
try
{
con = pool.getConnection();
List<String[]> teachers = new ArrayList<String[]>();
String teacherSql = "SELECT DISTINCT T.TCHR_ID, T.TCHR_NME, T.TCHR_ABBR FROM UMS.TEACHER T JOIN UMS.SECTION S ON S.TCHR_ID = T.TCHR_ID JOIN UMS.SECTION_FACULTY SF ON SF.SECTION_ID = S.SECTION_ID JOIN UMS.TIME_TABLE TT ON TT.SECTION_ID = S.SECTION_ID JOIN UMS.SLOT SL ON SL.SLOT_ID = TT.SLOT_ID WHERE SL.TERM_CDE = ? AND SF.FACULTY_ID = ? ORDER BY T.TCHR_NME";
try(PreparedStatement ps = con.prepareStatement(teacherSql))
{
ps.setString(1, term);
ps.setString(2, adminSession.getWorkingFacultyId());
try(ResultSet rs = ps.executeQuery()) { while(rs.next()) teachers.add(new String[]{rs.getString("TCHR_ID"),rs.getString("TCHR_NME"),rs.getString("TCHR_ABBR")}); }
}
boolean selectedTeacherValid = false;
for(String[] teacher : teachers) { if(teacher[0].equals(String.valueOf(tchrId))) { selectedTeacherValid = true; break; } }
if(!selectedTeacherValid && !teachers.isEmpty()) tchrId = Integer.parseInt(teachers.get(0)[0]);
String selectedTeacherName = "";
for(String[] teacher : teachers) { if(teacher[0].equals(String.valueOf(tchrId))) { selectedTeacherName = teacher[1]; break; } }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Teacher Timetable</title>
<link href="../extra/css/style.css?v=20260904" rel="stylesheet" type="text/css">
<link href="../extra/css/ums-module.css?v=20260904" rel="stylesheet" type="text/css">
</head>
<body class="ums-admin-main-body">
<main class="ums-module-page">
<section class="ums-module-header">
<div><p class="ums-module-eyebrow">Academic Timetable</p><h1>Teacher Timetable</h1><p>Working Term: <strong><%=html(term)%></strong> &nbsp;|&nbsp; Faculty: <strong><%=html(adminSession.getWorkingFaculty())%></strong></p></div>
</section>

<section class="ums-module-card">
<div class="ums-module-card-header"><h2>Select Teacher</h2></div>
<form action="AdminTchrTimeTable.jsp" method="get" class="ums-module-form">
<input type="hidden" name="dayIndex" value="<%=html(dayIndex)%>">
<div class="ums-form-grid">
<div class="ums-field"><label for="tchrId">Teacher</label><select name="tchrId" id="tchrId" required data-ums-search-select data-search-placeholder="Type teacher name..." data-search-label="Search Teacher">
<% for(String[] teacher : teachers) { %><option value="<%=html(teacher[0])%>" <%=teacher[0].equals(String.valueOf(tchrId)) ? "selected" : ""%>><%=html(teacher[1])%> (<%=html(teacher[2])%>)</option><% } %>
</select></div>
</div>
<div class="ums-form-actions"><button type="submit">View Timetable</button></div>
</form>
</section>

<section class="ums-module-card">
<div class="ums-module-card-header"><h2><%=html(selectedTeacherName)%></h2><span>Filter by day</span></div>
<div class="ums-filter-tabs">
<a class="ums-filter-tab <%="*".equals(dayIndex) ? "is-active" : ""%>" href="AdminTchrTimeTable.jsp?dayIndex=*&tchrId=<%=tchrId%>">Show All</a>
<a class="ums-filter-tab <%="MONDAY".equals(dayIndex) ? "is-active" : ""%>" href="AdminTchrTimeTable.jsp?dayIndex=MONDAY&tchrId=<%=tchrId%>">MON</a>
<a class="ums-filter-tab <%="TUESDAY".equals(dayIndex) ? "is-active" : ""%>" href="AdminTchrTimeTable.jsp?dayIndex=TUESDAY&tchrId=<%=tchrId%>">TUE</a>
<a class="ums-filter-tab <%="WEDNESDAY".equals(dayIndex) ? "is-active" : ""%>" href="AdminTchrTimeTable.jsp?dayIndex=WEDNESDAY&tchrId=<%=tchrId%>">WED</a>
<a class="ums-filter-tab <%="THURSDAY".equals(dayIndex) ? "is-active" : ""%>" href="AdminTchrTimeTable.jsp?dayIndex=THURSDAY&tchrId=<%=tchrId%>">THU</a>
<a class="ums-filter-tab <%="FRIDAY".equals(dayIndex) ? "is-active" : ""%>" href="AdminTchrTimeTable.jsp?dayIndex=FRIDAY&tchrId=<%=tchrId%>">FRI</a>
<a class="ums-filter-tab <%="SATURDAY".equals(dayIndex) ? "is-active" : ""%>" href="AdminTchrTimeTable.jsp?dayIndex=SATURDAY&tchrId=<%=tchrId%>">SAT</a>
</div>
</section>

<section class="ums-module-card">
<div class="ums-module-card-header ums-module-card-header-tools">
<div><h2>Timetable</h2><span><%="*".equals(dayIndex) ? "All Days" : html(dayIndex)%></span></div>
<div class="ums-table-tools"><div class="ums-table-search"><label for="timetableSearch">Search</label><input type="search" id="timetableSearch" data-ums-table-search="teacherTimetableTable" placeholder="Search day, venue, course, section or major"></div><button type="button" class="ums-export-button" data-ums-table-export="teacherTimetableTable"><span class="ums-export-icon">⇩</span> Export to Excel</button><button type="button" class="ums-button-secondary" onclick="window.print()">Print</button></div>
</div>
<div class="ums-table-wrap">
<table class="ums-data-table" id="teacherTimetableTable" data-ums-table data-export-file="Teacher_Timetable">
<thead><tr>
<th class="ums-sortable" data-column="0" data-type="text"><button type="button" class="ums-sort-button">Day <span class="ums-sort-indicator">↕</span></button></th>
<th class="ums-sortable" data-column="1" data-type="number"><button type="button" class="ums-sort-button">Slot <span class="ums-sort-indicator">↕</span></button></th>
<th>Time</th>
<th>Venue</th>
<th>Course</th>
<th>Section</th>
<th>Teacher</th>
<th>Programs / Majors</th>
<th>Timing</th>
</tr></thead>
<tbody>
<%
boolean found = false;
String baseSql = "SELECT DISTINCT D.DAY_TXT, D.DAY_ID, SL.SLOT_ID, SL.SLOT_NBR, P.PLACE_ID, NVL((SELECT AST.TIME_TXT FROM UMS.ALTERNATE_SLOT_TIM AST WHERE AST.SLOT_ID = SL.SLOT_ID AND AST.DAY_ID = D.DAY_ID AND TRUNC(SYSDATE) BETWEEN TRUNC(AST.START_DTE) AND TRUNC(AST.END_DTE) AND ROWNUM = 1), SL.TIME_TXT) EFFECTIVE_TIME, CASE WHEN EXISTS (SELECT 1 FROM UMS.ALTERNATE_SLOT_TIM AST WHERE AST.SLOT_ID = SL.SLOT_ID AND AST.DAY_ID = D.DAY_ID AND TRUNC(SYSDATE) BETWEEN TRUNC(AST.START_DTE) AND TRUNC(AST.END_DTE)) THEN 'Y' ELSE 'N' END ALT_IND, P.PLACE_TXT, C.COURSE_ABBR, C.COURSE_CDE, S.SECTION_TXT, S.SECTION_ID, T.TCHR_ABBR FROM UMS.COURSE C JOIN UMS.SECTION S ON S.COURSE_ID = C.COURSE_ID JOIN UMS.TEACHER T ON T.TCHR_ID = S.TCHR_ID JOIN UMS.TIME_TABLE TT ON TT.SECTION_ID = S.SECTION_ID JOIN UMS.SLOT SL ON SL.SLOT_ID = TT.SLOT_ID JOIN UMS.PLACE P ON P.PLACE_ID = TT.PLACE_ID JOIN UMS.DAY D ON D.DAY_ID = TT.DAY_ID WHERE SL.TERM_CDE = ? AND T.TCHR_ID = ?";
if(!"*".equals(dayIndex)) baseSql += " AND UPPER(D.DAY_TXT) = ?";
baseSql += " ORDER BY D.DAY_ID, P.PLACE_ID, SL.SLOT_NBR";
try(PreparedStatement ps = con.prepareStatement(baseSql); PreparedStatement majorPs = con.prepareStatement("SELECT P.PROG_CDE FROM UMS.SECTION_PROGRAM SP JOIN UMS.PROGRAM P ON P.PROG_ID = SP.PROG_ID WHERE SP.SECTION_ID = ? ORDER BY P.PROG_CDE"))
{
ps.setString(1, term);
ps.setInt(2, tchrId);
if(!"*".equals(dayIndex)) ps.setString(3, dayIndex);
try(ResultSet rs = ps.executeQuery())
{
while(rs.next())
{
found = true;
StringBuilder majors = new StringBuilder();
majorPs.setInt(1, rs.getInt("SECTION_ID"));
try(ResultSet majorRs = majorPs.executeQuery()) { while(majorRs.next()) { if(majors.length() > 0) majors.append(", "); majors.append(majorRs.getString(1)); } }
%><tr <%="Y".equals(rs.getString("ALT_IND")) ? "class=\"ums-current-row\"" : ""%>><td><%=html(rs.getString("DAY_TXT"))%></td><td><%=html(rs.getString("SLOT_NBR"))%></td><td><%=html(rs.getString("EFFECTIVE_TIME"))%></td><td><%=html(rs.getString("PLACE_TXT"))%></td><td><%=html(rs.getString("COURSE_ABBR"))%> <span class="ums-muted"><%=html(rs.getString("COURSE_CDE"))%></span></td><td><%=html(rs.getString("SECTION_TXT"))%></td><td><%=html(rs.getString("TCHR_ABBR"))%></td><td><%=html(majors.toString())%></td><td><% if("Y".equals(rs.getString("ALT_IND"))) { %><span class="ums-status-badge">Alternate</span><% } else { %>Regular<% } %></td></tr><%
}
}
}
if(!found)
{
%><tr data-ums-empty-row><td colspan="9" class="ums-table-empty">No class is scheduled for <%=html("*".equals(dayIndex) ? "the selected teacher" : dayIndex)%>.</td></tr><%
}
%>
</tbody>
</table>
</div>
<div class="ums-table-footer" data-ums-table-footer="teacherTimetableTable"></div>
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