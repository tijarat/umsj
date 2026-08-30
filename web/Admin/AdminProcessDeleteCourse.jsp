<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<%!
    private void log(String message, String user) {
        System.out.println(new java.util.Date() + "::AdminProcessDeleteCourse.jsp::" + user + "::" + message);
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
    Connection con = null;
    try {
        if(courseIdValue == null || !courseIdValue.matches("\\d+")) throw new SQLException("Invalid Course ID.");
        int courseId = Integer.parseInt(courseIdValue);
        con = pool.getConnection();
        con.setAutoCommit(false);
        String courseCode = "";
        try(PreparedStatement lookupStmt = con.prepareStatement("SELECT COURSE_CDE FROM UMS.COURSE WHERE COURSE_ID = ? AND TERM_CDE = ?")) {
            lookupStmt.setInt(1, courseId);
            lookupStmt.setString(2, adminSession.workingTerm);
            try(ResultSet lookupRs = lookupStmt.executeQuery()) {
                if(!lookupRs.next()) throw new SQLException("Course was not found in the current working term.");
                courseCode = lookupRs.getString(1);
            }
        }
        try(Statement logStmt = con.createStatement()) {
            try(PreparedStatement deleteSpecialStmt = con.prepareStatement("DELETE FROM UMS.SPECIAL_COURSE WHERE COURSE_ID = ?")) {
                deleteSpecialStmt.setInt(1, courseId);
                deleteSpecialStmt.executeUpdate();
            }
            adminSession.addLog("DELETE UMS.SPECIAL_COURSE WHERE COURSE_ID=" + courseId, logStmt);
            try(PreparedStatement deleteCourseStmt = con.prepareStatement("DELETE FROM UMS.COURSE WHERE COURSE_ID = ? AND TERM_CDE = ?")) {
                deleteCourseStmt.setInt(1, courseId);
                deleteCourseStmt.setString(2, adminSession.workingTerm);
                deleteCourseStmt.executeUpdate();
            }
            adminSession.addLog("DELETE UMS.COURSE WHERE COURSE_ID=" + courseId + ", TERM_CDE=" + adminSession.workingTerm, logStmt);
        }
        con.commit();
        session.setAttribute("flashType", "success");
        session.setAttribute("flashMessage", "Course " + courseCode + " has been deleted successfully.");
        response.sendRedirect("AdminCourses.jsp");
    } catch(Exception e) {
        if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
        String errorMessage = e.getMessage();
        if(errorMessage == null || errorMessage.trim().length() == 0) errorMessage = "Unable to delete Course.";
        if(errorMessage.indexOf("ORA-02292") >= 0) errorMessage = "This Course contains child records and cannot be deleted.";
        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", errorMessage);
        response.sendRedirect("AdminCourses.jsp");
    } finally {
        if(con != null) pool.close(con);
    }
%>
