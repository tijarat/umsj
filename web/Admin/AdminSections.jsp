<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*,java.util.*" session="true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<%!
    private void log(String message, String user) {
        System.out.println(new java.util.Date() + "::AdminSections.jsp::" + user + "::" + message);
    }

    private String html(String value) {
        if(value == null) return "";
        return value.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
    }
%>
<%
    com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession) session.getAttribute("adminSession");
    if(adminSession == null) {
        log("Session Not Found", "Invalid");
%>
        <jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/>
<%
        return;
    }
    if(!adminSession.hasRightsOn("Section")) {
%>
        <jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Section service."/>
<%
        return;
    }
    if(!response.isCommitted()) {
        response.setHeader("Pragma", "no-cache");
        response.setHeader("Expires", "0");
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    }
    String flashType = (String) session.getAttribute("flashType");
    String flashMessage = (String) session.getAttribute("flashMessage");
    session.removeAttribute("flashType");
    session.removeAttribute("flashMessage");
    String selectedCourseValue = request.getParameter("Course");
    String selectedTeacherValue = request.getParameter("Teacher");
    int workingFacultyId = Integer.parseInt(adminSession.getWorkingFacultyId());
    Connection con = null;
    try {
        con = pool.getConnection();
        int selectedCourseId = 0;
        String firstCourseValue = null;
        String courseSql = "SELECT COURSE_ID, COURSE_CDE, COURSE_NME, COURSE_ABBR FROM UMS.COURSE WHERE TERM_CDE = ? ORDER BY COURSE_CDE, COURSE_NME";
        List<String[]> courseRows = new ArrayList<String[]>();
        try(PreparedStatement courseStmt = con.prepareStatement(courseSql)) {
            courseStmt.setString(1, adminSession.workingTerm);
            try(ResultSet courseRs = courseStmt.executeQuery()) {
                while(courseRs.next()) {
                    String courseIdText = String.valueOf(courseRs.getInt("COURSE_ID"));
                    if(firstCourseValue == null) firstCourseValue = courseIdText;
                    courseRows.add(new String[]{courseIdText, courseRs.getString("COURSE_CDE"), courseRs.getString("COURSE_NME"), courseRs.getString("COURSE_ABBR")});
                }
            }
        }
        if(selectedCourseValue == null || !selectedCourseValue.matches("\\d+")) selectedCourseValue = firstCourseValue;
        if(selectedCourseValue != null) selectedCourseId = Integer.parseInt(selectedCourseValue);
        List<String[]> teacherRows = new ArrayList<String[]>();
        String teacherSql = "SELECT T.TCHR_ID, T.TCHR_ABBR, T.TCHR_NME FROM UMS.TEACHER T JOIN UMS.WEB_USERS WU ON WU.TCHR_ID = T.TCHR_ID JOIN UMS.WEB_USERS_FACULTY WUF ON WUF.USER_NME = WU.USER_NME WHERE T.STATUS_IND = 'A' AND WUF.FACULTY_ID = ? ORDER BY T.TCHR_NME";
        try(PreparedStatement teacherStmt = con.prepareStatement(teacherSql)) {
            teacherStmt.setInt(1, workingFacultyId);
            try(ResultSet teacherRs = teacherStmt.executeQuery()) {
                while(teacherRs.next()) teacherRows.add(new String[]{String.valueOf(teacherRs.getInt("TCHR_ID")), teacherRs.getString("TCHR_NME"), teacherRs.getString("TCHR_ABBR")});
            }
        }
        if((selectedTeacherValue == null || !selectedTeacherValue.matches("\\d+")) && !teacherRows.isEmpty()) selectedTeacherValue = teacherRows.get(0)[0];
        List<String[]> programRows = new ArrayList<String[]>();
        if(selectedCourseId > 0) {
            String programSql = "SELECT PR.PROG_CDE, PR.PROG_ID FROM UMS.PREREQ P JOIN UMS.PROGRAM PR ON PR.PROG_ID = P.PROG_ID WHERE PR.FACULTY_ID = ? AND P.COURSE_ID = ? ORDER BY PR.PROG_CDE";
            try(PreparedStatement programStmt = con.prepareStatement(programSql)) {
                programStmt.setInt(1, workingFacultyId);
                programStmt.setInt(2, selectedCourseId);
                try(ResultSet programRs = programStmt.executeQuery()) {
                    while(programRs.next()) programRows.add(new String[]{programRs.getString("PROG_CDE"), String.valueOf(programRs.getInt("PROG_ID"))});
                }
            }
        }
        Map<Integer,StringBuilder> programMap = new HashMap<Integer,StringBuilder>();
        String sectionProgramSql = "SELECT SP.SECTION_ID, P.PROG_CDE FROM UMS.SECTION_PROGRAM SP JOIN UMS.PROGRAM P ON P.PROG_ID = SP.PROG_ID JOIN UMS.SECTION S ON S.SECTION_ID = SP.SECTION_ID JOIN UMS.COURSE C ON C.COURSE_ID = S.COURSE_ID WHERE C.TERM_CDE = ? ORDER BY SP.SECTION_ID, P.PROG_CDE";
        try(PreparedStatement sectionProgramStmt = con.prepareStatement(sectionProgramSql)) {
            sectionProgramStmt.setString(1, adminSession.workingTerm);
            try(ResultSet sectionProgramRs = sectionProgramStmt.executeQuery()) {
                while(sectionProgramRs.next()) {
                    int mapSectionId = sectionProgramRs.getInt("SECTION_ID");
                    StringBuilder mapPrograms = programMap.get(mapSectionId);
                    if(mapPrograms == null) {
                        mapPrograms = new StringBuilder();
                        programMap.put(mapSectionId, mapPrograms);
                    }
                    if(mapPrograms.length() > 0) mapPrograms.append(", ");
                    mapPrograms.append(sectionProgramRs.getString("PROG_CDE"));
                }
            }
        }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Section Management</title>
    <link href="../extra/css/style.css?v=20260830" rel="stylesheet" type="text/css">
    <link href="../extra/css/ums-module.css?v=20260830-section" rel="stylesheet" type="text/css">
</head>
<body class="ums-admin-main-body">
<main class="ums-module-page">
    <section class="ums-module-header">
        <div>
            <p class="ums-module-eyebrow">Academic Setup</p>
            <h1>Section Management</h1>
            <p>Create and maintain course sections, teacher assignments, strength and eligible programs for the working term.</p>
        </div>
    </section>

    <section class="ums-module-card">
        <div class="ums-module-card-header">
            <h2>Define Section</h2>
            <span>* Required fields</span>
        </div>
        <form action="AdminProcessSections.jsp" method="post" name="sectionForm" id="sectionForm" class="ums-module-form" data-ums-section-form="add">
            <div class="ums-info-strip">
                <div><strong>Working Term:</strong> <%=html(adminSession.workingTerm)%></div>
                <div><strong>Faculty:</strong> <%=html(adminSession.getWorkingFaculty())%></div>
            </div>
            <div class="ums-form-grid">
                <div class="ums-field ums-field-wide">
                    <label for="Course">Course *</label>
                    <select name="Course" id="Course" data-ums-section-course required>
<% for(String[] row : courseRows) { %>
                        <option value="<%=row[0]%>" <%=row[0].equals(selectedCourseValue) ? "selected" : ""%>><%=html(row[1])%> [<%=html(row[2])%>] (<%=html(row[3])%>)</option>
<% } %>
                    </select>
                    <small>Changing Course reloads its roadmap Programs.</small>
                </div>
                <div class="ums-field ums-field-wide">
                    <label for="Teacher">Teacher *</label>
                    <select name="Teacher" id="Teacher" required>
<% for(String[] row : teacherRows) { %>
                        <option value="<%=row[0]%>" <%=row[0].equals(selectedTeacherValue) ? "selected" : ""%>><%=html(row[1])%> (<%=html(row[2])%>)</option>
<% } %>
                    </select>
                </div>
                <div class="ums-field">
                    <label for="section">Section *</label>
                    <input name="section" type="text" id="section" maxlength="5" autocomplete="off" required>
                    <small>Letters and numbers only.</small>
                </div>
                <div class="ums-field">
                    <label for="strength">Strength *</label>
                    <input name="strength" type="number" id="strength" min="0" max="999" step="1" value="40" required>
                </div>
                <div class="ums-field ums-field-wide">
                    <label>Programs *</label>
<% if(programRows.isEmpty()) { %>
                    <div class="ums-inline-notice ums-inline-notice-warning">This course has not been defined in any roadmap.</div>
<% } else { %>
                    <div class="ums-checkbox-grid" data-ums-program-list>
<% for(String[] row : programRows) { %>
                        <label class="ums-check-label"><input name="programs" type="checkbox" value="<%=row[1]%>"><span><%=html(row[0])%></span></label>
<% } %>
                    </div>
<% } %>
                </div>
            </div>
            <div class="ums-form-actions">
                <button type="submit" <%=courseRows.isEmpty() ? "disabled" : ""%>>Add Section</button>
            </div>
        </form>
    </section>

<% if(flashMessage != null && flashMessage.trim().length() > 0) { %>
    <div id="umsFlashMessage" class="ums-flash-message <%= "error".equals(flashType) ? "ums-flash-error" : "ums-flash-success" %>" role="alert"><%=html(flashMessage)%></div>
<% } %>

    <section class="ums-module-card">
        <div class="ums-module-card-header ums-module-card-header-tools">
            <div>
                <h2>Sections</h2>
                <span>Sections defined for <%=html(adminSession.workingTerm)%></span>
            </div>
            <div class="ums-table-tools">
                <div class="ums-table-search">
                    <label for="sectionSearch">Search</label>
                    <input type="search" id="sectionSearch" data-ums-table-search="sectionTable" placeholder="Search course, teacher, section or program" autocomplete="off">
                </div>
                <button type="button" class="ums-export-button" data-ums-table-export="sectionTable" title="Export current Section list to Excel"><span class="ums-export-icon">⇩</span>Export to Excel</button>
            </div>
        </div>
        <div class="ums-table-wrap">
            <table class="ums-data-table" id="sectionTable" data-ums-table data-export-file="Sections">
                <thead>
                    <tr>
                        <th class="ums-sortable" data-column="0" data-type="number" data-export-header="Sr No."><button type="button" class="ums-sort-button">Sr No. <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-sortable" data-column="1" data-type="text" data-export-header="Course Code"><button type="button" class="ums-sort-button">Course Code <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-sortable" data-column="2" data-type="text" data-export-header="Course"><button type="button" class="ums-sort-button">Course <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-sortable" data-column="3" data-type="text" data-export-header="Teacher"><button type="button" class="ums-sort-button">Teacher <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-sortable" data-column="4" data-type="text" data-export-header="Section"><button type="button" class="ums-sort-button">Section <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-sortable" data-column="5" data-type="number" data-export-header="Strength"><button type="button" class="ums-sort-button">Strength <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-sortable" data-column="6" data-type="text" data-export-header="Programs"><button type="button" class="ums-sort-button">Programs <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-sortable" data-column="7" data-type="text" data-export-header="Faculty"><button type="button" class="ums-sort-button">Faculty <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-actions-col">Options</th>
                    </tr>
                </thead>
                <tbody>
<%
        boolean foundSection = false;
        int serialNo = 0;
        String sectionSql = "SELECT C.COURSE_ABBR, T.TCHR_ABBR, S.SECTION_TXT, S.STRENGTH_NBR, S.SECTION_ID, T.TCHR_ID, C.COURSE_CDE, C.COURSE_ID, F.FACULTY_ABBREV, F.FACULTY_ID FROM UMS.SECTION S JOIN UMS.COURSE C ON C.COURSE_ID = S.COURSE_ID JOIN UMS.TEACHER T ON T.TCHR_ID = S.TCHR_ID LEFT JOIN UMS.SECTION_FACULTY SF ON SF.SECTION_ID = S.SECTION_ID LEFT JOIN UMS.FACULTY F ON F.FACULTY_ID = SF.FACULTY_ID WHERE C.TERM_CDE = ? AND SF.FACULTY_ID = ? ORDER BY C.COURSE_CDE, S.SECTION_TXT";
        try(PreparedStatement sectionStmt = con.prepareStatement(sectionSql)) {
            sectionStmt.setString(1, adminSession.workingTerm);
            sectionStmt.setInt(2, workingFacultyId);
            try(ResultSet sectionRs = sectionStmt.executeQuery()) {
                while(sectionRs.next()) {
                    foundSection = true;
                    serialNo++;
                    int sectionId = sectionRs.getInt("SECTION_ID");
                    String programs = programMap.containsKey(sectionId) ? programMap.get(sectionId).toString() : "";
                    String editUrl = "AdminEditSections.jsp?sectionId=" + sectionId;
                    String deleteUrl = "AdminProcessDeleteSections.jsp?sectionId=" + sectionId;
%>
                    <tr>
                        <td data-sort-value="<%=serialNo%>"><%=serialNo%></td>
                        <td><strong><%=html(sectionRs.getString("COURSE_CDE"))%></strong></td>
                        <td><%=html(sectionRs.getString("COURSE_ABBR"))%></td>
                        <td><%=html(sectionRs.getString("TCHR_ABBR"))%></td>
                        <td><%=html(sectionRs.getString("SECTION_TXT"))%></td>
                        <td data-sort-value="<%=sectionRs.getInt("STRENGTH_NBR")%>"><%=sectionRs.getInt("STRENGTH_NBR")%></td>
                        <td><%=html(programs)%></td>
                        <td><%=html(sectionRs.getString("FACULTY_ABBREV"))%></td>
                        <td class="ums-row-actions"><a class="ums-action-link" href="<%=editUrl%>">Edit</a><a class="ums-action-link ums-action-danger" href="<%=deleteUrl%>" data-ums-confirm="Are you sure you want to delete section <%=html(sectionRs.getString("SECTION_TXT"))%> of <%=html(sectionRs.getString("COURSE_CDE"))%>?">Delete</a></td>
                    </tr>
<%
                }
            }
        }
        if(!foundSection) {
%>
                    <tr><td colspan="9" class="ums-empty-state">No sections are defined for this Faculty in <%=html(adminSession.workingTerm)%>.</td></tr>
<%
        }
%>
                </tbody>
            </table>
        </div>
        <div class="ums-table-footer">
            <div class="ums-page-size"><label for="sectionPageSize">Rows per page</label><select id="sectionPageSize" data-ums-page-size="sectionTable"><option value="5">5</option><option value="10" selected>10</option><option value="20">20</option><option value="50">50</option></select></div>
            <div class="ums-pagination-info" data-ums-page-info="sectionTable"></div>
            <div class="ums-pagination"><button type="button" data-ums-page-prev="sectionTable">Previous</button><div class="ums-page-numbers" data-ums-page-numbers="sectionTable"></div><button type="button" data-ums-page-next="sectionTable">Next</button></div>
        </div>
    </section>
</main>
<script src="../extra/js/ums-module.js?v=20260830"></script>
<script src="../extra/js/section.js?v=20260830"></script>
</body>
</html>
<%
    } finally {
        if(con != null) pool.close(con);
    }
%>
