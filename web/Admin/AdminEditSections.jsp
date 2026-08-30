<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*,java.util.*" session="true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<%!
    private void log(String message, String user) {
        System.out.println(new java.util.Date() + "::AdminEditSections.jsp::" + user + "::" + message);
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
    String sectionIdValue = request.getParameter("sectionId");
    if(sectionIdValue == null || !sectionIdValue.matches("\\d+")) {
        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", "Invalid Section ID.");
        response.sendRedirect("AdminSections.jsp");
        return;
    }
    int sectionId = Integer.parseInt(sectionIdValue);
    String flashType = (String) session.getAttribute("flashType");
    String flashMessage = (String) session.getAttribute("flashMessage");
    session.removeAttribute("flashType");
    session.removeAttribute("flashMessage");
    Connection con = null;
    try {
        con = pool.getConnection();
        int courseId = 0;
        int teacherId = 0;
        int strength = 0;
        int facultyId = 0;
        String courseCode = "";
        String courseAbbr = "";
        String sectionText = "";
        String facultyAbbrev = "";
        String sectionSql = "SELECT S.COURSE_ID, S.TCHR_ID, S.SECTION_TXT, S.STRENGTH_NBR, C.COURSE_CDE, C.COURSE_ABBR, SF.FACULTY_ID, F.FACULTY_ABBREV FROM UMS.SECTION S JOIN UMS.COURSE C ON C.COURSE_ID = S.COURSE_ID LEFT JOIN UMS.SECTION_FACULTY SF ON SF.SECTION_ID = S.SECTION_ID LEFT JOIN UMS.FACULTY F ON F.FACULTY_ID = SF.FACULTY_ID WHERE S.SECTION_ID = ? AND C.TERM_CDE = ?";
        try(PreparedStatement sectionStmt = con.prepareStatement(sectionSql)) {
            sectionStmt.setInt(1, sectionId);
            sectionStmt.setString(2, adminSession.workingTerm);
            try(ResultSet sectionRs = sectionStmt.executeQuery()) {
                if(!sectionRs.next()) {
                    session.setAttribute("flashType", "error");
                    session.setAttribute("flashMessage", "Section was not found in the current working term.");
                    response.sendRedirect("AdminSections.jsp");
                    return;
                }
                courseId = sectionRs.getInt("COURSE_ID");
                teacherId = sectionRs.getInt("TCHR_ID");
                sectionText = sectionRs.getString("SECTION_TXT");
                strength = sectionRs.getInt("STRENGTH_NBR");
                courseCode = sectionRs.getString("COURSE_CDE");
                courseAbbr = sectionRs.getString("COURSE_ABBR");
                facultyId = sectionRs.getInt("FACULTY_ID");
                facultyAbbrev = sectionRs.getString("FACULTY_ABBREV");
            }
        }
        if(facultyId == 0) facultyId = Integer.parseInt(adminSession.getWorkingFacultyId());
        int campusId = 0;
        try(PreparedStatement campusStmt = con.prepareStatement("SELECT CMP_ID FROM UMS.FACULTY WHERE FACULTY_ID = ?")) {
            campusStmt.setInt(1, facultyId);
            try(ResultSet campusRs = campusStmt.executeQuery()) {
                if(campusRs.next()) campusId = campusRs.getInt("CMP_ID");
            }
        }
        List<String[]> facultyRows = new ArrayList<String[]>();
        String facultySql = "SELECT F.FACULTY_ID, F.FACULTY_ABBREV, C.CMP_ABBERV FROM UMS.WEB_USERS_FACULTY WUF JOIN UMS.FACULTY F ON F.FACULTY_ID = WUF.FACULTY_ID JOIN UMS.CAMPUS C ON C.CMP_ID = F.CMP_ID WHERE WUF.USER_NME = ? AND F.CMP_ID = ? ORDER BY C.CMP_ABBERV, F.FACULTY_ID";
        try(PreparedStatement facultyStmt = con.prepareStatement(facultySql)) {
            facultyStmt.setString(1, adminSession.user);
            facultyStmt.setInt(2, campusId);
            try(ResultSet facultyRs = facultyStmt.executeQuery()) {
                while(facultyRs.next()) facultyRows.add(new String[]{String.valueOf(facultyRs.getInt("FACULTY_ID")), facultyRs.getString("CMP_ABBERV"), facultyRs.getString("FACULTY_ABBREV")});
            }
        }
        List<String[]> teacherRows = new ArrayList<String[]>();
        String teacherSql = "SELECT T.TCHR_ID, T.TCHR_ABBR, T.TCHR_NME FROM UMS.TEACHER T JOIN UMS.WEB_USERS WU ON WU.TCHR_ID = T.TCHR_ID JOIN UMS.WEB_USERS_FACULTY WUF ON WUF.USER_NME = WU.USER_NME WHERE T.STATUS_IND = 'A' AND WUF.FACULTY_ID = ? ORDER BY T.TCHR_NME";
        try(PreparedStatement teacherStmt = con.prepareStatement(teacherSql)) {
            teacherStmt.setInt(1, Integer.parseInt(adminSession.getWorkingFacultyId()));
            try(ResultSet teacherRs = teacherStmt.executeQuery()) {
                while(teacherRs.next()) teacherRows.add(new String[]{String.valueOf(teacherRs.getInt("TCHR_ID")), teacherRs.getString("TCHR_NME"), teacherRs.getString("TCHR_ABBR")});
            }
        }
        Set<Integer> selectedPrograms = new HashSet<Integer>();
        try(PreparedStatement selectedProgramStmt = con.prepareStatement("SELECT PROG_ID FROM UMS.SECTION_PROGRAM WHERE SECTION_ID = ?")) {
            selectedProgramStmt.setInt(1, sectionId);
            try(ResultSet selectedProgramRs = selectedProgramStmt.executeQuery()) {
                while(selectedProgramRs.next()) selectedPrograms.add(selectedProgramRs.getInt("PROG_ID"));
            }
        }
        List<String[]> programRows = new ArrayList<String[]>();
        String programSql = "SELECT P.PROG_CDE, P.PROG_ID FROM UMS.PREREQ PRE JOIN UMS.PROGRAM P ON P.PROG_ID = PRE.PROG_ID WHERE PRE.COURSE_ID = ? AND P.FACULTY_ID IN (SELECT WUF.FACULTY_ID FROM UMS.WEB_USERS_FACULTY WUF JOIN UMS.FACULTY F ON F.FACULTY_ID = WUF.FACULTY_ID WHERE WUF.USER_NME = ? AND F.CMP_ID = ?) ORDER BY P.PROG_CDE";
        try(PreparedStatement programStmt = con.prepareStatement(programSql)) {
            programStmt.setInt(1, courseId);
            programStmt.setString(2, adminSession.user);
            programStmt.setInt(3, campusId);
            try(ResultSet programRs = programStmt.executeQuery()) {
                while(programRs.next()) programRows.add(new String[]{programRs.getString("PROG_CDE"), String.valueOf(programRs.getInt("PROG_ID"))});
            }
        }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Section</title>
    <link href="../extra/css/style.css?v=20260830" rel="stylesheet" type="text/css">
    <link href="../extra/css/ums-module.css?v=20260830-section" rel="stylesheet" type="text/css">
</head>
<body class="ums-admin-main-body">
<main class="ums-module-page">
    <section class="ums-module-header">
        <div>
            <p class="ums-module-eyebrow">Academic Setup</p>
            <h1>Edit Section</h1>
            <p>Update teacher, faculty, strength and eligible Programs for this Section.</p>
        </div>
    </section>

<% if(flashMessage != null && flashMessage.trim().length() > 0) { %>
    <div id="umsFlashMessage" class="ums-flash-message <%= "error".equals(flashType) ? "ums-flash-error" : "ums-flash-success" %>" role="alert"><%=html(flashMessage)%></div>
<% } %>

    <section class="ums-module-card">
        <div class="ums-module-card-header">
            <h2><%=html(courseCode)%> - Section <%=html(sectionText)%></h2>
            <span>* Required fields</span>
        </div>
        <form action="AdminProcessEditSections.jsp" method="post" name="editSectionForm" id="editSectionForm" class="ums-module-form" data-ums-section-form="edit">
            <input type="hidden" name="sectionId" value="<%=sectionId%>">
            <input type="hidden" name="oldTeacherId" value="<%=teacherId%>">
            <div class="ums-info-strip">
                <div><strong>Working Term:</strong> <%=html(adminSession.workingTerm)%></div>
                <div><strong>Course:</strong> <%=html(courseCode)%> (<%=html(courseAbbr)%>)</div>
                <div><strong>Section:</strong> <%=html(sectionText)%></div>
            </div>
            <div class="ums-form-grid">
                <div class="ums-field">
                    <label for="faculty">Faculty *</label>
                    <select name="faculty" id="faculty" required>
<% for(String[] row : facultyRows) { %>
                        <option value="<%=row[0]%>" <%=Integer.parseInt(row[0]) == facultyId ? "selected" : ""%>><%=html(row[1])%> - <%=html(row[2])%></option>
<% } %>
                    </select>
                </div>
                <div class="ums-field">
                    <label for="Teacher">Teacher *</label>
                    <select name="Teacher" id="Teacher" required>
<% for(String[] row : teacherRows) { %>
                        <option value="<%=row[0]%>" <%=Integer.parseInt(row[0]) == teacherId ? "selected" : ""%>><%=html(row[1])%> (<%=html(row[2])%>)</option>
<% } %>
                    </select>
                </div>
                <div class="ums-field">
                    <label>Section</label>
                    <input type="text" value="<%=html(sectionText)%>" readonly>
                </div>
                <div class="ums-field">
                    <label for="strength">Strength *</label>
                    <input name="strength" type="number" id="strength" min="0" max="999" step="1" value="<%=strength%>" required>
                </div>
                <div class="ums-field ums-field-wide">
                    <label>Programs</label>
<% if(programRows.isEmpty()) { %>
                    <div class="ums-inline-notice ums-inline-notice-warning">This course has not been defined in any roadmap available to your campus faculties.</div>
<% } else { %>
                    <div class="ums-checkbox-grid" data-ums-program-list>
<% for(String[] row : programRows) { int programId = Integer.parseInt(row[1]); %>
                        <label class="ums-check-label"><input name="programs" type="checkbox" value="<%=programId%>" <%=selectedPrograms.contains(programId) ? "checked" : ""%>><span><%=html(row[0])%></span></label>
<% } %>
                    </div>
<% } %>
                </div>
            </div>
            <div class="ums-form-actions">
                <button type="submit">Update Section</button>
                <a href="AdminSections.jsp" class="ums-button-secondary">Cancel</a>
            </div>
        </form>
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
