<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<%!
    private void log(String message, String user) {
        System.out.println(new java.util.Date() + "::AdminProcessEditCourse.jsp::" + user + "::" + message);
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
    String courseCode = request.getParameter("courseCode");
    String courseName = request.getParameter("courseName");
    String courseAbbr = request.getParameter("courseAbbr");
    String courseDsc = request.getParameter("description");
    String courseType = request.getParameter("courseType");
    String spCourseFee = request.getParameter("spCourseFee");
    String spCourseDiscountAllowed = request.getParameter("spCoursediscount");
    String courseFor = request.getParameter("courseFor");
    Connection con = null;
    try {
        if(courseIdValue == null || !courseIdValue.matches("\\d+") || courseCode == null || courseName == null || courseAbbr == null || courseType == null || courseFor == null) throw new SQLException("Required Course information is missing.");
        int courseId = Integer.parseInt(courseIdValue);
        courseCode = courseCode.trim().toUpperCase();
        courseName = courseName.trim();
        courseAbbr = courseAbbr.trim();
        courseDsc = courseDsc == null ? "" : courseDsc.trim();
        courseType = "S".equalsIgnoreCase(courseType) ? "S" : "R";
        courseFor = courseFor.trim();
        spCourseDiscountAllowed = "Y".equalsIgnoreCase(spCourseDiscountAllowed) ? "Y" : "N";
        if(courseName.length() == 0 || courseName.length() > 50) throw new SQLException("Course Name is required and cannot exceed 50 characters.");
        if(courseAbbr.length() == 0 || courseAbbr.length() > 10) throw new SQLException("Course Abbreviation is required and cannot exceed 10 characters.");
        if(courseDsc.length() > 1500) throw new SQLException("Course Description cannot exceed 1500 characters.");
        if(courseFor.length() == 0) throw new SQLException("Course For is required.");
        if("S".equals(courseType) && (spCourseFee == null || spCourseFee.trim().length() == 0)) throw new SQLException("Course Fee is required for a Special Course.");
        con = pool.getConnection();
        con.setAutoCommit(false);
        try(Statement logStmt = con.createStatement()) {
            String ownershipSql = "SELECT 1 FROM UMS.COURSE WHERE COURSE_ID = ? AND TERM_CDE = ?";
            try(PreparedStatement ownershipStmt = con.prepareStatement(ownershipSql)) {
                ownershipStmt.setInt(1, courseId);
                ownershipStmt.setString(2, adminSession.workingTerm);
                try(ResultSet ownershipRs = ownershipStmt.executeQuery()) {
                    if(!ownershipRs.next()) throw new SQLException("Course was not found in the current working term.");
                }
            }
            String deleteSpecialSql = "DELETE FROM UMS.SPECIAL_COURSE WHERE COURSE_ID = ?";
            try(PreparedStatement deleteSpecialStmt = con.prepareStatement(deleteSpecialSql)) {
                deleteSpecialStmt.setInt(1, courseId);
                deleteSpecialStmt.executeUpdate();
            }
            adminSession.addLog("DELETE UMS.SPECIAL_COURSE WHERE COURSE_ID=" + courseId, logStmt);
            String updateCourseSql = "UPDATE UMS.COURSE SET COURSE_CDE = ?, COURSE_NME = ?, COURSE_ABBR = ?, TYP_IND = ?, COURSE_TYP = ?, COURSE_DSC = ? WHERE COURSE_ID = ? AND TERM_CDE = ?";
            try(PreparedStatement updateCourseStmt = con.prepareStatement(updateCourseSql)) {
                updateCourseStmt.setString(1, courseCode);
                updateCourseStmt.setString(2, courseName);
                updateCourseStmt.setString(3, courseAbbr);
                updateCourseStmt.setString(4, courseType);
                updateCourseStmt.setString(5, courseFor);
                updateCourseStmt.setString(6, courseDsc);
                updateCourseStmt.setInt(7, courseId);
                updateCourseStmt.setString(8, adminSession.workingTerm);
                updateCourseStmt.executeUpdate();
            }
            adminSession.addLog("UPDATE UMS.COURSE COURSE_ID=" + courseId + ", COURSE_CDE=" + courseCode + ", COURSE_NME=" + courseName + ", COURSE_ABBR=" + courseAbbr + ", TYP_IND=" + courseType + ", COURSE_TYP=" + courseFor, logStmt);
            if("S".equals(courseType)) {
                String insertSpecialSql = "INSERT INTO UMS.SPECIAL_COURSE(SPEC_COURSE_ID, COURSE_ID, FEE_AMT, DISCOUNT_IND) VALUES(UMS.SEQ_SPEC_COURSE_ID.NEXTVAL, ?, ?, ?)";
                try(PreparedStatement insertSpecialStmt = con.prepareStatement(insertSpecialSql)) {
                    insertSpecialStmt.setInt(1, courseId);
                    insertSpecialStmt.setBigDecimal(2, new java.math.BigDecimal(spCourseFee.trim()));
                    insertSpecialStmt.setString(3, spCourseDiscountAllowed);
                    insertSpecialStmt.executeUpdate();
                }
                adminSession.addLog("INSERT UMS.SPECIAL_COURSE COURSE_ID=" + courseId + ", FEE_AMT=" + spCourseFee + ", DISCOUNT_IND=" + spCourseDiscountAllowed, logStmt);
            }
        }
        con.commit();
        session.setAttribute("flashType", "success");
        session.setAttribute("flashMessage", "Course " + courseCode + " has been updated successfully.");
        response.sendRedirect("AdminCourses.jsp");
    } catch(Exception e) {
        if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
        String errorMessage = e.getMessage();
        if(errorMessage == null || errorMessage.trim().length() == 0) errorMessage = "Unable to update Course.";
        if(errorMessage.indexOf("ORA-02292") >= 0) errorMessage = "This Course contains child records and cannot be changed in this way.";
        if(e instanceof NumberFormatException) errorMessage = "Course Fee contains an invalid number.";
        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", errorMessage);
        response.sendRedirect("AdminEditCourses.jsp?courseId=" + (courseIdValue == null ? "" : courseIdValue));
    } finally {
        if(con != null) pool.close(con);
    }
%>
