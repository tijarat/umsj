<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<%!
    private void log(String message, String user) {
        System.out.println(new java.util.Date() + "::AdminEditCourses.jsp::" + user + "::" + message);
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
    if(!adminSession.hasRightsOn("Course")) {
%>
        <jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Course service."/>
<%
        return;
    }
    String courseIdValue = request.getParameter("courseId");
    if(courseIdValue == null || !courseIdValue.matches("\\d+")) {
        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", "Invalid Course ID.");
        response.sendRedirect("AdminCourses.jsp");
        return;
    }
    int courseId = Integer.parseInt(courseIdValue);
    Connection con = null;
    try {
        con = pool.getConnection();
        String sql = "SELECT C.COURSE_CDE, C.COURSE_NME, C.COURSE_ABBR, C.CREDIT_HRS, C.TYP_IND, SP.FEE_AMT, SP.DISCOUNT_IND, C.COURSE_ID, C.COURSE_TYP, C.COURSE_DSC FROM UMS.COURSE C LEFT JOIN UMS.SPECIAL_COURSE SP ON SP.COURSE_ID = C.COURSE_ID WHERE C.TERM_CDE = ? AND C.COURSE_ID = ?";
        try(PreparedStatement stmt = con.prepareStatement(sql)) {
            stmt.setString(1, adminSession.workingTerm);
            stmt.setInt(2, courseId);
            try(ResultSet rs = stmt.executeQuery()) {
                if(!rs.next()) {
                    session.setAttribute("flashType", "error");
                    session.setAttribute("flashMessage", "Course was not found in the current working term.");
                    response.sendRedirect("AdminCourses.jsp");
                    return;
                }
                String courseCode = rs.getString("COURSE_CDE");
                String courseName = rs.getString("COURSE_NME");
                String courseAbbr = rs.getString("COURSE_ABBR");
                int creditHours = rs.getInt("CREDIT_HRS");
                String courseType = rs.getString("TYP_IND");
                String courseFor = rs.getString("COURSE_TYP");
                String description = rs.getString("COURSE_DSC");
                String fee = rs.getString("FEE_AMT");
                String discount = rs.getString("DISCOUNT_IND");
                boolean special = "S".equalsIgnoreCase(courseType);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Course</title>
    <link href="../extra/css/style.css?v=20260830" rel="stylesheet" type="text/css">
    <link href="../extra/css/ums-module.css?v=20260830-course" rel="stylesheet" type="text/css">
</head>
<body class="ums-admin-main-body">
<main class="ums-module-page ums-module-page-narrow">
    <section class="ums-module-header">
        <div>
            <p class="ums-module-eyebrow">Academic Setup</p>
            <h1>Edit Course</h1>
            <p>Update the selected course for working term <strong><%=html(adminSession.workingTerm)%></strong>.</p>
        </div>
    </section>
    <section class="ums-module-card">
        <div class="ums-module-card-header">
            <h2>Course Details</h2>
            <span>* Required fields</span>
        </div>
        <form action="AdminProcessEditCourse.jsp" method="post" name="editCourseForm" id="editCourseForm" class="ums-module-form" data-ums-course-form="edit">
            <input type="hidden" name="courseId" value="<%=courseId%>">
            <input type="hidden" name="courseCode" value="<%=html(courseCode)%>">
            <div class="ums-form-grid">
                <div class="ums-field">
                    <label>Course Code</label>
                    <div class="ums-readonly-value"><%=html(courseCode)%></div>
                </div>
                <div class="ums-field">
                    <label>Credit Hours</label>
                    <div class="ums-readonly-value"><%=creditHours%></div>
                </div>
                <div class="ums-field">
                    <label for="courseName">Course Name *</label>
                    <input name="courseName" type="text" id="courseName" value="<%=html(courseName)%>" maxlength="50" required>
                </div>
                <div class="ums-field">
                    <label for="courseAbbr">Course Abbreviation *</label>
                    <input name="courseAbbr" type="text" id="courseAbbr" value="<%=html(courseAbbr)%>" maxlength="10" required>
                </div>
                <div class="ums-field ums-field-wide">
                    <label for="description">Course Description</label>
                    <textarea name="description" id="description" maxlength="1500" rows="4"><%=html(description)%></textarea>
                    <small>Maximum 1500 characters.</small>
                </div>
                <div class="ums-field">
                    <label for="courseFor">Course For *</label>
                    <select name="courseFor" id="courseFor" required>
                        <option value="C" <%=courseFor == null || "C".equalsIgnoreCase(courseFor) ? "selected" : ""%>>ALL</option>
                    </select>
                </div>
                <div class="ums-field">
                    <label>Course Type *</label>
                    <div class="ums-radio-panel">
                        <div class="ums-radio-row">
                            <label class="ums-radio-label"><input name="courseType" type="radio" value="R" <%=!special ? "checked" : ""%>> Regular</label>
                            <label class="ums-radio-label"><input name="courseType" type="radio" value="S" <%=special ? "checked" : ""%>> Special Course</label>
                        </div>
                        <div class="ums-subsection">
                            <p class="ums-subsection-title">Special Course Details</p>
                            <div class="ums-inline-fields">
                                <div class="ums-field">
                                    <label for="spCourseFee">Course Fee</label>
                                    <input name="spCourseFee" type="text" id="spCourseFee" value="<%=special && fee != null ? html(fee) : ""%>" maxlength="7" inputmode="decimal">
                                </div>
                                <div class="ums-field ums-field-check">
                                    <label class="ums-check-label"><input name="spCoursediscount" type="checkbox" id="spCoursediscount" value="Y" <%=special && "Y".equalsIgnoreCase(discount) ? "checked" : ""%>><span>Discount Allowed</span></label>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="ums-form-actions">
                <button type="submit">Update Course</button>
                <a class="ums-button-secondary" href="AdminCourses.jsp">Cancel</a>
            </div>
        </form>
    </section>
</main>
<script src="../extra/js/ums-module.js?v=20260830"></script>
<script src="../extra/js/course.js?v=20260830"></script>
</body>
</html>
<%
            }
        }
    } finally {
        if(con != null) pool.close(con);
    }
%>
