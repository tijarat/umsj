<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<%!
    private void log(String message, String user) {
        System.out.println(new java.util.Date() + "::AdminProcessCourse.jsp::" + user + "::" + message);
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
    String courseCode = request.getParameter("courseCode");
    String courseName = request.getParameter("courseName");
    String courseAbbr = request.getParameter("courseAbbr");
    String courseDsc = request.getParameter("description");
    String creditHoursValue = request.getParameter("creditHours");
    String courseType = request.getParameter("courseType");
    String spCourseFee = request.getParameter("spCourseFee");
    String spCourseDiscountAllowed = request.getParameter("spCoursediscount");
    String courseFor = request.getParameter("courseFor");
    Connection con = null;
    try {
        if(courseCode == null || courseName == null || courseAbbr == null || creditHoursValue == null || courseType == null || courseFor == null) throw new SQLException("Required Course information is missing.");
        courseCode = courseCode.trim().toUpperCase();
        courseName = courseName.trim();
        courseAbbr = courseAbbr.trim();
        courseDsc = courseDsc == null ? "" : courseDsc.trim();
        if(!courseCode.matches("[A-Z0-9]{1,10}") || !courseCode.matches(".*\\d$")) throw new SQLException("Course Code must contain letters and numbers only and end with a digit.");
        if(courseName.length() == 0 || courseName.length() > 50) throw new SQLException("Course Name is required and cannot exceed 50 characters.");
        if(courseAbbr.length() == 0 || courseAbbr.length() > 10) throw new SQLException("Course Abbreviation is required and cannot exceed 10 characters.");
        if(courseDsc.length() > 1500) throw new SQLException("Course Description cannot exceed 1500 characters.");
        int creditHours = Integer.parseInt(creditHoursValue);
        if(creditHours < 0 || creditHours > 6) throw new SQLException("Credit Hours must be between 0 and 6.");
        courseType = "S".equalsIgnoreCase(courseType) ? "S" : "R";
        courseFor = courseFor.trim();
        if(courseFor.length() == 0) throw new SQLException("Course For is required.");
        if("S".equals(courseType) && (spCourseFee == null || spCourseFee.trim().length() == 0)) throw new SQLException("Course Fee is required for a Special Course.");
        spCourseDiscountAllowed = "Y".equalsIgnoreCase(spCourseDiscountAllowed) ? "Y" : "N";
        con = pool.getConnection();
        con.setAutoCommit(false);
        int nextCourseId = 0;
        try(PreparedStatement idStmt = con.prepareStatement("SELECT UMS.SEQ_COURSE_ID.NEXTVAL FROM DUAL"); ResultSet idRs = idStmt.executeQuery()) {
            if(!idRs.next()) throw new SQLException("Unable to generate Course ID.");
            nextCourseId = idRs.getInt(1);
        }
        try(Statement logStmt = con.createStatement()) {
            String existsSql = "SELECT 1 FROM UMS.COURSES WHERE COURSEID = ?";
            boolean masterExists = false;
            try(PreparedStatement existsStmt = con.prepareStatement(existsSql)) {
                existsStmt.setString(1, courseCode);
                try(ResultSet existsRs = existsStmt.executeQuery()) {
                    masterExists = existsRs.next();
                }
            }
            if(!masterExists) {
                String masterInsertSql = "INSERT INTO UMS.COURSES(COURSEID, COURSETITLE, COURSECREDITS, ABBR) VALUES(?, ?, ?, ?)";
                try(PreparedStatement masterInsertStmt = con.prepareStatement(masterInsertSql)) {
                    masterInsertStmt.setString(1, courseCode);
                    masterInsertStmt.setString(2, courseName);
                    masterInsertStmt.setInt(3, creditHours);
                    masterInsertStmt.setString(4, courseAbbr);
                    masterInsertStmt.executeUpdate();
                }
                adminSession.addLog("INSERT UMS.COURSES COURSEID=" + courseCode + ", COURSETITLE=" + courseName + ", COURSECREDITS=" + creditHours + ", ABBR=" + courseAbbr, logStmt);
            }
            String courseInsertSql = "INSERT INTO UMS.COURSE(COURSE_ID, TERM_CDE, COURSE_CDE, COURSE_NME, COURSE_ABBR, CREDIT_HRS, TYP_IND, COURSE_TYP, COURSE_DSC) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)";
            try(PreparedStatement courseInsertStmt = con.prepareStatement(courseInsertSql)) {
                courseInsertStmt.setInt(1, nextCourseId);
                courseInsertStmt.setString(2, adminSession.workingTerm);
                courseInsertStmt.setString(3, courseCode);
                courseInsertStmt.setString(4, courseName);
                courseInsertStmt.setString(5, courseAbbr);
                courseInsertStmt.setInt(6, creditHours);
                courseInsertStmt.setString(7, courseType);
                courseInsertStmt.setString(8, courseFor);
                courseInsertStmt.setString(9, courseDsc);
                courseInsertStmt.executeUpdate();
            }
            adminSession.addLog("INSERT UMS.COURSE COURSE_ID=" + nextCourseId + ", TERM_CDE=" + adminSession.workingTerm + ", COURSE_CDE=" + courseCode, logStmt);
            if("S".equals(courseType)) {
                String specialInsertSql = "INSERT INTO UMS.SPECIAL_COURSE(SPEC_COURSE_ID, COURSE_ID, FEE_AMT, DISCOUNT_IND) VALUES(UMS.SEQ_SPEC_COURSE_ID.NEXTVAL, ?, ?, ?)";
                try(PreparedStatement specialInsertStmt = con.prepareStatement(specialInsertSql)) {
                    specialInsertStmt.setInt(1, nextCourseId);
                    specialInsertStmt.setBigDecimal(2, new java.math.BigDecimal(spCourseFee.trim()));
                    specialInsertStmt.setString(3, spCourseDiscountAllowed);
                    specialInsertStmt.executeUpdate();
                }
                adminSession.addLog("INSERT UMS.SPECIAL_COURSE COURSE_ID=" + nextCourseId + ", FEE_AMT=" + spCourseFee + ", DISCOUNT_IND=" + spCourseDiscountAllowed, logStmt);
            }
        }
        con.commit();
        session.setAttribute("flashType", "success");
        session.setAttribute("flashMessage", "Course " + courseCode + " has been added successfully.");
        response.sendRedirect("AdminCourses.jsp");
    } catch(Exception e) {
        if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
        String errorMessage = e.getMessage();
        if(errorMessage == null || errorMessage.trim().length() == 0) errorMessage = "Unable to add Course.";
        if(errorMessage.indexOf("ORA-00001") >= 0) errorMessage = "This Course Code is already defined for the working term.";
        if(e instanceof NumberFormatException) errorMessage = "Credit Hours or Course Fee contains an invalid number.";
        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", errorMessage);
        response.sendRedirect("AdminCourses.jsp");
    } finally {
        if(con != null) pool.close(con);
    }
%>
