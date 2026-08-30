<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<%!
    private void log(String message, String user) {
        System.out.println(new java.util.Date() + "::AdminProcessSections.jsp::" + user + "::" + message);
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
    String section = request.getParameter("section");
    String courseIdValue = request.getParameter("Course");
    String teacherIdValue = request.getParameter("Teacher");
    String strengthValue = request.getParameter("strength");
    String[] programs = request.getParameterValues("programs");
    Connection con = null;
    try {
        if(section == null || courseIdValue == null || teacherIdValue == null || strengthValue == null) throw new SQLException("Required Section information is missing.");
        section = section.trim().toUpperCase();
        if(!section.matches("[A-Z0-9]{1,5}")) throw new SQLException("Section must contain letters and numbers only and cannot exceed 5 characters.");
        if(!courseIdValue.matches("\\d+") || !teacherIdValue.matches("\\d+") || !strengthValue.matches("\\d+")) throw new SQLException("Course, Teacher or Strength contains an invalid value.");
        int courseId = Integer.parseInt(courseIdValue);
        int teacherId = Integer.parseInt(teacherIdValue);
        int strength = Integer.parseInt(strengthValue);
        int facultyId = Integer.parseInt(adminSession.getWorkingFacultyId());
        if(strength < 0 || strength > 999) throw new SQLException("Strength must be between 0 and 999.");
        if(adminSession.getWorkingFaculty() == null || adminSession.getWorkingFaculty().trim().length() == 0) throw new SQLException("Faculty cannot be null.");
        if(programs == null || programs.length == 0) throw new SQLException("Program is not defined/selected for this Course.");
        con = pool.getConnection();
        con.setAutoCommit(false);
        try(PreparedStatement courseCheckStmt = con.prepareStatement("SELECT 1 FROM UMS.COURSE WHERE COURSE_ID = ? AND TERM_CDE = ?")) {
            courseCheckStmt.setInt(1, courseId);
            courseCheckStmt.setString(2, adminSession.workingTerm);
            try(ResultSet courseCheckRs = courseCheckStmt.executeQuery()) {
                if(!courseCheckRs.next()) throw new SQLException("Course was not found in the current working term.");
            }
        }
        int sectionId = 0;
        try(PreparedStatement idStmt = con.prepareStatement("SELECT UMS.SEQ_SECTION_ID.NEXTVAL FROM DUAL"); ResultSet idRs = idStmt.executeQuery()) {
            if(!idRs.next()) throw new SQLException("Unable to generate Section ID.");
            sectionId = idRs.getInt(1);
        }
        try(Statement logStmt = con.createStatement()) {
            try(PreparedStatement sectionStmt = con.prepareStatement("INSERT INTO UMS.SECTION(SECTION_ID, COURSE_ID, TCHR_ID, SECTION_TXT, STATUS_IND, STRENGTH_NBR) VALUES(?, ?, ?, ?, 'O', ?)")) {
                sectionStmt.setInt(1, sectionId);
                sectionStmt.setInt(2, courseId);
                sectionStmt.setInt(3, teacherId);
                sectionStmt.setString(4, section);
                sectionStmt.setInt(5, strength);
                sectionStmt.executeUpdate();
            }
            adminSession.addLog("INSERT UMS.SECTION SECTION_ID=" + sectionId + ", COURSE_ID=" + courseId + ", TCHR_ID=" + teacherId + ", SECTION_TXT=" + section + ", STRENGTH_NBR=" + strength, logStmt);
            try(PreparedStatement statusStmt = con.prepareStatement("INSERT INTO UMS.SECTION_STATUS(SECTION_ID, STRENGTH) VALUES(?, 0)")) {
                statusStmt.setInt(1, sectionId);
                statusStmt.executeUpdate();
            }
            adminSession.addLog("INSERT UMS.SECTION_STATUS SECTION_ID=" + sectionId + ", STRENGTH=0", logStmt);
            try(PreparedStatement facultyStmt = con.prepareStatement("INSERT INTO UMS.SECTION_FACULTY(SECTION_ID, FACULTY_ID) VALUES(?, ?)")) {
                facultyStmt.setInt(1, sectionId);
                facultyStmt.setInt(2, facultyId);
                facultyStmt.executeUpdate();
            }
            adminSession.addLog("INSERT UMS.SECTION_FACULTY SECTION_ID=" + sectionId + ", FACULTY_ID=" + facultyId, logStmt);
            try(PreparedStatement programStmt = con.prepareStatement("INSERT INTO UMS.SECTION_PROGRAM(SECTION_PROG_ID, SECTION_ID, PROG_ID) VALUES(UMS.SEQ_SECTION_PROG_ID.NEXTVAL, ?, ?)")) {
                for(String programValue : programs) {
                    if(programValue == null || !programValue.matches("\\d+")) throw new SQLException("Invalid Program selected.");
                    programStmt.setInt(1, sectionId);
                    programStmt.setInt(2, Integer.parseInt(programValue));
                    programStmt.addBatch();
                }
                programStmt.executeBatch();
            }
            adminSession.addLog("INSERT UMS.SECTION_PROGRAM SECTION_ID=" + sectionId + ", PROGRAM_COUNT=" + programs.length, logStmt);
        }
        con.commit();
        session.setAttribute("flashType", "success");
        session.setAttribute("flashMessage", "Section " + section + " has been added successfully.");
        response.sendRedirect("AdminSections.jsp?Course=" + courseId + "&Teacher=" + teacherId);
    } catch(Exception e) {
        if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
        String errorMessage = e.getMessage();
        if(errorMessage == null || errorMessage.trim().length() == 0) errorMessage = "Unable to add Section.";
        if(errorMessage.indexOf("ORA-00001") >= 0) errorMessage = "This Section is already defined.";
        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", errorMessage);
        String redirectCourse = courseIdValue != null && courseIdValue.matches("\\d+") ? courseIdValue : "";
        String redirectTeacher = teacherIdValue != null && teacherIdValue.matches("\\d+") ? teacherIdValue : "";
        response.sendRedirect("AdminSections.jsp?Course=" + redirectCourse + "&Teacher=" + redirectTeacher);
    } finally {
        if(con != null) pool.close(con);
    }
%>
