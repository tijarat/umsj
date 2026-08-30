<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<%!
    private void log(String message, String user) {
        System.out.println(new java.util.Date() + "::AdminProcessDeleteSections.jsp::" + user + "::" + message);
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
    Connection con = null;
    try {
        if(sectionIdValue == null || !sectionIdValue.matches("\\d+")) throw new SQLException("Invalid Section ID.");
        int sectionId = Integer.parseInt(sectionIdValue);
        con = pool.getConnection();
        con.setAutoCommit(false);
        String sectionName = "";
        String courseCode = "";
        try(PreparedStatement lookupStmt = con.prepareStatement("SELECT S.SECTION_TXT, C.COURSE_CDE FROM UMS.SECTION S JOIN UMS.COURSE C ON C.COURSE_ID = S.COURSE_ID WHERE S.SECTION_ID = ? AND C.TERM_CDE = ?")) {
            lookupStmt.setInt(1, sectionId);
            lookupStmt.setString(2, adminSession.workingTerm);
            try(ResultSet lookupRs = lookupStmt.executeQuery()) {
                if(!lookupRs.next()) throw new SQLException("Section was not found in the current working term.");
                sectionName = lookupRs.getString("SECTION_TXT");
                courseCode = lookupRs.getString("COURSE_CDE");
            }
        }
        try(Statement logStmt = con.createStatement()) {
            try(PreparedStatement deleteFacultyStmt = con.prepareStatement("DELETE FROM UMS.SECTION_FACULTY WHERE SECTION_ID = ?")) {
                deleteFacultyStmt.setInt(1, sectionId);
                deleteFacultyStmt.executeUpdate();
            }
            adminSession.addLog("DELETE UMS.SECTION_FACULTY SECTION_ID=" + sectionId, logStmt);
            try(PreparedStatement deleteProgramStmt = con.prepareStatement("DELETE FROM UMS.SECTION_PROGRAM WHERE SECTION_ID = ?")) {
                deleteProgramStmt.setInt(1, sectionId);
                deleteProgramStmt.executeUpdate();
            }
            adminSession.addLog("DELETE UMS.SECTION_PROGRAM SECTION_ID=" + sectionId, logStmt);
            try(PreparedStatement deleteStatusStmt = con.prepareStatement("DELETE FROM UMS.SECTION_STATUS WHERE SECTION_ID = ?")) {
                deleteStatusStmt.setInt(1, sectionId);
                deleteStatusStmt.executeUpdate();
            }
            adminSession.addLog("DELETE UMS.SECTION_STATUS SECTION_ID=" + sectionId, logStmt);
            try(PreparedStatement deleteSectionStmt = con.prepareStatement("DELETE FROM UMS.SECTION WHERE SECTION_ID = ?")) {
                deleteSectionStmt.setInt(1, sectionId);
                deleteSectionStmt.executeUpdate();
            }
            adminSession.addLog("DELETE UMS.SECTION SECTION_ID=" + sectionId, logStmt);
        }
        con.commit();
        session.setAttribute("flashType", "success");
        session.setAttribute("flashMessage", "Section " + courseCode + " (" + sectionName + ") has been deleted successfully.");
        response.sendRedirect("AdminSections.jsp");
    } catch(Exception e) {
        if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
        String errorMessage = e.getMessage();
        if(errorMessage == null || errorMessage.trim().length() == 0) errorMessage = "Unable to delete Section.";
        if(errorMessage.indexOf("ORA-02292") >= 0) errorMessage = "This Section contains child records and cannot be deleted.";
        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", errorMessage);
        response.sendRedirect("AdminSections.jsp");
    } finally {
        if(con != null) pool.close(con);
    }
%>
