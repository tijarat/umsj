<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<%!
    private void log(String message, String user) {
        System.out.println(new java.util.Date() + "::AdminProcessEditSections.jsp::" + user + "::" + message);
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
    String teacherIdValue = request.getParameter("Teacher");
    String oldTeacherIdValue = request.getParameter("oldTeacherId");
    String strengthValue = request.getParameter("strength");
    String facultyValue = request.getParameter("faculty");
    String[] programs = request.getParameterValues("programs");
    Connection con = null;
    try {
        if(sectionIdValue == null || teacherIdValue == null || oldTeacherIdValue == null || strengthValue == null || facultyValue == null) throw new SQLException("Required Section information is missing.");
        if(!sectionIdValue.matches("\\d+") || !teacherIdValue.matches("\\d+") || !oldTeacherIdValue.matches("\\d+") || !strengthValue.matches("\\d+") || !facultyValue.matches("\\d+")) throw new SQLException("Section, Teacher, Faculty or Strength contains an invalid value.");
        int sectionId = Integer.parseInt(sectionIdValue);
        int teacherId = Integer.parseInt(teacherIdValue);
        int oldTeacherId = Integer.parseInt(oldTeacherIdValue);
        int strength = Integer.parseInt(strengthValue);
        int facultyId = Integer.parseInt(facultyValue);
        if(strength < 0 || strength > 999) throw new SQLException("Strength must be between 0 and 999.");
        con = pool.getConnection();
        con.setAutoCommit(false);
        try(PreparedStatement ownershipStmt = con.prepareStatement("SELECT 1 FROM UMS.SECTION S JOIN UMS.COURSE C ON C.COURSE_ID = S.COURSE_ID WHERE S.SECTION_ID = ? AND C.TERM_CDE = ?")) {
            ownershipStmt.setInt(1, sectionId);
            ownershipStmt.setString(2, adminSession.workingTerm);
            try(ResultSet ownershipRs = ownershipStmt.executeQuery()) {
                if(!ownershipRs.next()) throw new SQLException("Section was not found in the current working term.");
            }
        }
        if(teacherId != oldTeacherId) {
            String teacherAbbr = "";
            try(PreparedStatement teacherStmt = con.prepareStatement("SELECT TCHR_ABBR FROM UMS.TEACHER WHERE TCHR_ID = ?")) {
                teacherStmt.setInt(1, teacherId);
                try(ResultSet teacherRs = teacherStmt.executeQuery()) {
                    if(!teacherRs.next()) throw new SQLException("Selected Teacher was not found.");
                    teacherAbbr = teacherRs.getString("TCHR_ABBR");
                }
            }
            if(!"PROF.".equalsIgnoreCase(teacherAbbr)) {
                StringBuilder clashMessage = new StringBuilder();
                String clashSql = "SELECT DISTINCT C.COURSE_ABBR, S.SECTION_TXT, T.TCHR_ABBR FROM UMS.TIME_TABLE CURRENT_TT JOIN UMS.TIME_TABLE CONFLICT_TT ON CONFLICT_TT.DAY_ID = CURRENT_TT.DAY_ID AND CONFLICT_TT.SLOT_ID = CURRENT_TT.SLOT_ID JOIN UMS.SECTION S ON S.SECTION_ID = CONFLICT_TT.SECTION_ID JOIN UMS.COURSE C ON C.COURSE_ID = S.COURSE_ID JOIN UMS.TEACHER T ON T.TCHR_ID = S.TCHR_ID WHERE CURRENT_TT.SECTION_ID = ? AND S.TCHR_ID = ? AND C.TERM_CDE = ? AND S.SECTION_ID <> ? ORDER BY C.COURSE_ABBR, S.SECTION_TXT";
                try(PreparedStatement clashStmt = con.prepareStatement(clashSql)) {
                    clashStmt.setInt(1, sectionId);
                    clashStmt.setInt(2, teacherId);
                    clashStmt.setString(3, adminSession.workingTerm);
                    clashStmt.setInt(4, sectionId);
                    try(ResultSet clashRs = clashStmt.executeQuery()) {
                        while(clashRs.next()) {
                            if(clashMessage.length() > 0) clashMessage.append(" ");
                            clashMessage.append(clashRs.getString("COURSE_ABBR")).append("(").append(clashRs.getString("SECTION_TXT")).append(")");
                        }
                    }
                }
                if(clashMessage.length() > 0) throw new SQLException("Teacher '" + teacherAbbr + "' has clash with these courses [" + clashMessage.toString() + "]");
            }
        }
        try(Statement logStmt = con.createStatement()) {
            try(PreparedStatement updateSectionStmt = con.prepareStatement("UPDATE UMS.SECTION SET TCHR_ID = ?, STRENGTH_NBR = ? WHERE SECTION_ID = ?")) {
                updateSectionStmt.setInt(1, teacherId);
                updateSectionStmt.setInt(2, strength);
                updateSectionStmt.setInt(3, sectionId);
                updateSectionStmt.executeUpdate();
            }
            adminSession.addLog("UPDATE UMS.SECTION SECTION_ID=" + sectionId + ", TCHR_ID=" + teacherId + ", STRENGTH_NBR=" + strength, logStmt);
            int facultyUpdated = 0;
            try(PreparedStatement updateFacultyStmt = con.prepareStatement("UPDATE UMS.SECTION_FACULTY SET FACULTY_ID = ? WHERE SECTION_ID = ?")) {
                updateFacultyStmt.setInt(1, facultyId);
                updateFacultyStmt.setInt(2, sectionId);
                facultyUpdated = updateFacultyStmt.executeUpdate();
            }
            if(facultyUpdated == 0) {
                try(PreparedStatement insertFacultyStmt = con.prepareStatement("INSERT INTO UMS.SECTION_FACULTY(SECTION_ID, FACULTY_ID) VALUES(?, ?)")) {
                    insertFacultyStmt.setInt(1, sectionId);
                    insertFacultyStmt.setInt(2, facultyId);
                    insertFacultyStmt.executeUpdate();
                }
            }
            adminSession.addLog((facultyUpdated == 0 ? "INSERT" : "UPDATE") + " UMS.SECTION_FACULTY SECTION_ID=" + sectionId + ", FACULTY_ID=" + facultyId, logStmt);
            try(PreparedStatement deleteProgramsStmt = con.prepareStatement("DELETE FROM UMS.SECTION_PROGRAM WHERE SECTION_ID = ?")) {
                deleteProgramsStmt.setInt(1, sectionId);
                deleteProgramsStmt.executeUpdate();
            }
            adminSession.addLog("DELETE UMS.SECTION_PROGRAM SECTION_ID=" + sectionId, logStmt);
            if(programs != null && programs.length > 0) {
                try(PreparedStatement insertProgramStmt = con.prepareStatement("INSERT INTO UMS.SECTION_PROGRAM(SECTION_PROG_ID, SECTION_ID, PROG_ID) VALUES(UMS.SEQ_SECTION_PROG_ID.NEXTVAL, ?, ?)")) {
                    for(String programValue : programs) {
                        if(programValue == null || !programValue.matches("\\d+")) throw new SQLException("Invalid Program selected.");
                        insertProgramStmt.setInt(1, sectionId);
                        insertProgramStmt.setInt(2, Integer.parseInt(programValue));
                        insertProgramStmt.addBatch();
                    }
                    insertProgramStmt.executeBatch();
                }
                adminSession.addLog("INSERT UMS.SECTION_PROGRAM SECTION_ID=" + sectionId + ", PROGRAM_COUNT=" + programs.length, logStmt);
            }
        }
        con.commit();
        session.setAttribute("flashType", "success");
        session.setAttribute("flashMessage", "Section has been updated successfully.");
        response.sendRedirect("AdminSections.jsp");
    } catch(Exception e) {
        if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
        String errorMessage = e.getMessage();
        if(errorMessage == null || errorMessage.trim().length() == 0) errorMessage = "Unable to update Section.";
        if(errorMessage.indexOf("ORA-00001") >= 0) errorMessage = "The selected Section information creates a duplicate record.";
        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", errorMessage);
        response.sendRedirect("AdminEditSections.jsp?sectionId=" + (sectionIdValue == null ? "" : sectionIdValue));
    } finally {
        if(con != null) pool.close(con);
    }
%>
