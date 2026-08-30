<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*,java.net.URLEncoder" session="true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<%!
    private void log(String message, String user) {
        System.out.println(new java.util.Date() + "::AdminCourses.jsp::" + user + "::" + message);
    }

    private String html(String value) {
        if(value == null) return "";
        return value.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
    }

    private String url(String value) throws Exception {
        return URLEncoder.encode(value == null ? "" : value, "UTF-8");
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
    if(!adminSession.hasRightsOn("Course")) {
%>
        <jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Course service."/>
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
    Connection con = null;
    try {
        con = pool.getConnection();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Course Management</title>
    <link href="../extra/css/style.css?v=20260830" rel="stylesheet" type="text/css">
    <link href="../extra/css/ums-module.css?v=20260830-course" rel="stylesheet" type="text/css">
</head>
<body class="ums-admin-main-body">
<main class="ums-module-page">
    <section class="ums-module-header">
        <div>
            <p class="ums-module-eyebrow">Academic Setup</p>
            <h1>Course Management</h1>
            <p>Create and maintain Regular and Special courses for the working term.</p>
        </div>
    </section>

    <section class="ums-module-card">
        <div class="ums-module-card-header">
            <h2>Working Term</h2>
            <span>Copy courses from an earlier term when required</span>
        </div>
        <div class="ums-module-form">
            <div class="ums-info-strip">
                <div><strong>Current Term:</strong> <%=html(adminSession.workingTerm)%></div>
                <form action="AdminProcessAddFromCourses.jsp" method="post" data-ums-course-copy class="ums-inline-fields">
                    <div class="ums-field">
                        <label for="termList">Previous Term</label>
                        <select name="termList" id="termList">
<%
        String previousTermSql = "SELECT TERM_CDE FROM UMS.TERM WHERE START_DTE < (SELECT START_DTE FROM UMS.TERM WHERE TERM_CDE = ?) ORDER BY START_DTE DESC";
        try(PreparedStatement previousTermStmt = con.prepareStatement(previousTermSql)) {
            previousTermStmt.setString(1, adminSession.workingTerm);
            try(ResultSet previousTermRs = previousTermStmt.executeQuery()) {
                while(previousTermRs.next()) {
%>
                            <option value="<%=html(previousTermRs.getString("TERM_CDE"))%>"><%=html(previousTermRs.getString("TERM_CDE"))%></option>
<%
                }
            }
        }
%>
                        </select>
                    </div>
                    <button type="submit">Add from Term</button>
                </form>
            </div>
        </div>
    </section>

    <section class="ums-module-card">
        <div class="ums-module-card-header">
            <h2>Define Course</h2>
            <span>* Required fields</span>
        </div>
        <form action="AdminProcessCourse.jsp" method="post" name="courseForm" id="courseForm" class="ums-module-form" data-ums-course-form="add">
            <div class="ums-form-grid">
                <div class="ums-field">
                    <label for="courseCode">Course Code *</label>
                    <input name="courseCode" type="text" id="courseCode" maxlength="10" autocomplete="off" required>
                    <small>Letters and numbers only. If the last character is a digit it is used as the default credit hours.</small>
                </div>
                <div class="ums-field">
                    <label for="courseName">Course Name *</label>
                    <input name="courseName" type="text" id="courseName" maxlength="50" required>
                </div>
                <div class="ums-field">
                    <label for="courseAbbr">Course Abbreviation *</label>
                    <input name="courseAbbr" type="text" id="courseAbbr" maxlength="10" required>
                </div>
                <div class="ums-field">
                    <label for="creditHours">Credit Hours *</label>
                    <input name="creditHours" type="number" id="creditHours" min="0" max="6" step="1" required>
                </div>
                <div class="ums-field ums-field-wide">
                    <label for="description">Course Description</label>
                    <textarea name="description" id="description" maxlength="1500" rows="4"></textarea>
                    <small>Maximum 1500 characters.</small>
                </div>
                <div class="ums-field">
                    <label for="courseFor">Course For *</label>
                    <select name="courseFor" id="courseFor" required>
                        <option value="C" selected>ALL</option>
                    </select>
                </div>
                <div class="ums-field">
                    <label>Course Type *</label>
                    <div class="ums-radio-panel">
                        <div class="ums-radio-row">
                            <label class="ums-radio-label"><input name="courseType" type="radio" value="R" checked> Regular</label>
                            <label class="ums-radio-label"><input name="courseType" type="radio" value="S"> Special Course</label>
                        </div>
                        <div class="ums-subsection">
                            <p class="ums-subsection-title">Special Course Details</p>
                            <div class="ums-inline-fields">
                                <div class="ums-field">
                                    <label for="spCourseFee">Course Fee</label>
                                    <input name="spCourseFee" type="text" id="spCourseFee" maxlength="7" inputmode="decimal">
                                </div>
                                <div class="ums-field ums-field-check">
                                    <label class="ums-check-label"><input name="spCoursediscount" type="checkbox" id="spCoursediscount" value="Y"><span>Discount Allowed</span></label>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="ums-form-actions">
                <button type="submit">Add Course</button>
            </div>
        </form>
    </section>

<% if(flashMessage != null && flashMessage.trim().length() > 0) { %>
    <div id="umsFlashMessage" class="ums-flash-message <%= "error".equals(flashType) ? "ums-flash-error" : "ums-flash-success" %>" role="alert"><%=html(flashMessage)%></div>
<% } %>

    <section class="ums-module-card">
        <div class="ums-module-card-header ums-module-card-header-tools">
            <div>
                <h2>Courses</h2>
                <span>Special courses are highlighted</span>
            </div>
            <div class="ums-table-tools">
                <div class="ums-table-search">
                    <label for="courseSearch">Search</label>
                    <input type="search" id="courseSearch" data-ums-table-search="courseTable" placeholder="Search code, name, type or fee" autocomplete="off">
                </div>
                <button type="button" class="ums-export-button" data-ums-table-export="courseTable" title="Export current Course list to Excel"><span class="ums-export-icon">⇩</span>Export to Excel</button>
            </div>
        </div>
        <div class="ums-table-wrap">
            <table class="ums-data-table" id="courseTable" data-ums-table data-export-file="Courses">
                <thead>
                    <tr>
                        <th class="ums-sortable" data-column="0" data-type="text" data-export-header="Course Code"><button type="button" class="ums-sort-button">Course Code <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-sortable" data-column="1" data-type="text" data-export-header="Course Name"><button type="button" class="ums-sort-button">Course Name <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-sortable" data-column="2" data-type="text" data-export-header="Abbreviation"><button type="button" class="ums-sort-button">Abbreviation <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-sortable" data-column="3" data-type="number" data-export-header="Credit Hours"><button type="button" class="ums-sort-button">Cr. Hrs <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-sortable" data-column="4" data-type="text" data-export-header="Course Type"><button type="button" class="ums-sort-button">Type <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-sortable" data-column="5" data-type="number" data-export-header="Fee"><button type="button" class="ums-sort-button">Fee <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-sortable" data-column="6" data-type="text" data-export-header="Discount Allowed"><button type="button" class="ums-sort-button">Discount <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-actions-col">Options</th>
                    </tr>
                </thead>
                <tbody>
<%
        boolean found = false;
        String courseSql = "SELECT C.COURSE_CDE, C.COURSE_NME, C.COURSE_ABBR, C.CREDIT_HRS, C.TYP_IND, SP.FEE_AMT, SP.DISCOUNT_IND, C.COURSE_ID, C.COURSE_TYP, C.COURSE_DSC FROM UMS.COURSE C LEFT JOIN UMS.SPECIAL_COURSE SP ON SP.COURSE_ID = C.COURSE_ID WHERE C.TERM_CDE = ? ORDER BY C.COURSE_CDE";
        try(PreparedStatement courseStmt = con.prepareStatement(courseSql)) {
            courseStmt.setString(1, adminSession.workingTerm);
            try(ResultSet courseRs = courseStmt.executeQuery()) {
                while(courseRs.next()) {
                    found = true;
                    int courseId = courseRs.getInt("COURSE_ID");
                    String courseCode = courseRs.getString("COURSE_CDE");
                    String courseName = courseRs.getString("COURSE_NME");
                    String courseAbbr = courseRs.getString("COURSE_ABBR");
                    int creditHours = courseRs.getInt("CREDIT_HRS");
                    String courseType = courseRs.getString("TYP_IND");
                    String fee = courseRs.getString("FEE_AMT");
                    String discount = courseRs.getString("DISCOUNT_IND");
                    boolean special = "S".equalsIgnoreCase(courseType);
                    String editUrl = "AdminEditCourses.jsp?courseId=" + courseId;
                    String deleteUrl = "AdminProcessDeleteCourse.jsp?courseId=" + courseId;
%>
                    <tr class="<%=special ? "ums-special-row" : ""%>">
                        <td><strong><%=html(courseCode)%></strong></td>
                        <td><%=html(courseName)%></td>
                        <td><%=html(courseAbbr)%></td>
                        <td data-sort-value="<%=creditHours%>"><%=creditHours%></td>
                        <td data-export-value="<%=special ? "Special" : "Regular"%>"><span class="ums-type-badge <%=special ? "ums-type-special" : ""%>"><%=special ? "Special" : "Regular"%></span></td>
                        <td data-sort-value="<%=special && fee != null ? html(fee) : "0"%>"><%=special && fee != null ? html(fee) : "—"%></td>
                        <td><%=special ? ("Y".equalsIgnoreCase(discount) ? "Yes" : "No") : "—"%></td>
                        <td class="ums-row-actions"><a class="ums-action-link" href="<%=editUrl%>">Edit</a><a class="ums-action-link ums-action-danger" href="<%=deleteUrl%>" data-ums-confirm="Are you sure you want to delete <%=html(courseName)%> course?">Delete</a></td>
                    </tr>
<%
                }
            }
        }
        if(!found) {
%>
                    <tr><td colspan="8" class="ums-empty-state">No courses are defined for <%=html(adminSession.workingTerm)%>.</td></tr>
<%
        }
%>
                </tbody>
            </table>
        </div>
        <div class="ums-table-footer">
            <div class="ums-page-size"><label for="coursePageSize">Rows per page</label><select id="coursePageSize" data-ums-page-size="courseTable"><option value="5">5</option><option value="10" selected>10</option><option value="20">20</option><option value="50">50</option></select></div>
            <div class="ums-pagination-info" data-ums-page-info="courseTable"></div>
            <div class="ums-pagination"><button type="button" data-ums-page-prev="courseTable">Previous</button><div class="ums-page-numbers" data-ums-page-numbers="courseTable"></div><button type="button" data-ums-page-next="courseTable">Next</button></div>
        </div>
    </section>
</main>
<script src="../extra/js/ums-module.js?v=20260830"></script>
<script src="../extra/js/course.js?v=20260830"></script>
</body>
</html>
<%
    } finally {
        if(con != null) pool.close(con);
    }
%>
