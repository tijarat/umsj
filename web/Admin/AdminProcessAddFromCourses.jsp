<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<%!
    private void log(String message, String user) {
        System.out.println(new java.util.Date() + "::AdminProcessAddFromCourses.jsp::" + user + "::" + message);
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
    String sourceTerm = request.getParameter("termList");
    Connection con = null;
    try {
        if(sourceTerm == null || sourceTerm.trim().length() == 0) throw new SQLException("Please select a previous Term.");
        sourceTerm = sourceTerm.trim().toUpperCase();
        if(sourceTerm.equalsIgnoreCase(adminSession.workingTerm)) throw new SQLException("Source Term and working Term cannot be the same.");
        con = pool.getConnection();
        con.setAutoCommit(false);
        int copied = 0;
        String sourceSql = "SELECT C.COURSE_CDE, C.COURSE_NME, C.COURSE_ABBR, C.CREDIT_HRS, C.TYP_IND, C.COURSE_TYP, C.COURSE_DSC, SP.FEE_AMT, SP.DISCOUNT_IND FROM UMS.COURSE C LEFT JOIN UMS.SPECIAL_COURSE SP ON SP.COURSE_ID = C.COURSE_ID WHERE C.TERM_CDE = ? ORDER BY C.COURSE_CDE";
        try(Statement logStmt = con.createStatement(); PreparedStatement sourceStmt = con.prepareStatement(sourceSql); PreparedStatement duplicateStmt = con.prepareStatement("SELECT 1 FROM UMS.COURSE WHERE TERM_CDE = ? AND COURSE_CDE = ?"); PreparedStatement idStmt = con.prepareStatement("SELECT UMS.SEQ_COURSE_ID.NEXTVAL FROM DUAL"); PreparedStatement insertCourseStmt = con.prepareStatement("INSERT INTO UMS.COURSE(COURSE_ID, TERM_CDE, COURSE_CDE, COURSE_NME, COURSE_ABBR, CREDIT_HRS, TYP_IND, COURSE_TYP, COURSE_DSC) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)"); PreparedStatement insertSpecialStmt = con.prepareStatement("INSERT INTO UMS.SPECIAL_COURSE(SPEC_COURSE_ID, COURSE_ID, FEE_AMT, DISCOUNT_IND) VALUES(UMS.SEQ_SPEC_COURSE_ID.NEXTVAL, ?, ?, ?)")) {
            sourceStmt.setString(1, sourceTerm);
            try(ResultSet sourceRs = sourceStmt.executeQuery()) {
                while(sourceRs.next()) {
                    String courseCode = sourceRs.getString("COURSE_CDE");
                    duplicateStmt.setString(1, adminSession.workingTerm);
                    duplicateStmt.setString(2, courseCode);
                    try(ResultSet duplicateRs = duplicateStmt.executeQuery()) {
                        if(duplicateRs.next()) throw new SQLException("Course " + courseCode + " is already defined in " + adminSession.workingTerm + ". No courses were copied.");
                    }
                    int newCourseId = 0;
                    try(ResultSet idRs = idStmt.executeQuery()) {
                        if(!idRs.next()) throw new SQLException("Unable to generate Course ID.");
                        newCourseId = idRs.getInt(1);
                    }
                    insertCourseStmt.setInt(1, newCourseId);
                    insertCourseStmt.setString(2, adminSession.workingTerm);
                    insertCourseStmt.setString(3, courseCode);
                    insertCourseStmt.setString(4, sourceRs.getString("COURSE_NME"));
                    insertCourseStmt.setString(5, sourceRs.getString("COURSE_ABBR"));
                    insertCourseStmt.setInt(6, sourceRs.getInt("CREDIT_HRS"));
                    insertCourseStmt.setString(7, sourceRs.getString("TYP_IND"));
                    insertCourseStmt.setString(8, sourceRs.getString("COURSE_TYP"));
                    insertCourseStmt.setString(9, sourceRs.getString("COURSE_DSC"));
                    insertCourseStmt.executeUpdate();
                    if("S".equalsIgnoreCase(sourceRs.getString("TYP_IND"))) {
                        insertSpecialStmt.setInt(1, newCourseId);
                        insertSpecialStmt.setBigDecimal(2, sourceRs.getBigDecimal("FEE_AMT"));
                        insertSpecialStmt.setString(3, "Y".equalsIgnoreCase(sourceRs.getString("DISCOUNT_IND")) ? "Y" : "N");
                        insertSpecialStmt.executeUpdate();
                    }
                    copied++;
                }
            }
            adminSession.addLog("COPY UMS.COURSE FROM TERM " + sourceTerm + " TO TERM " + adminSession.workingTerm + ", RECORDS=" + copied, logStmt);
        }
        if(copied == 0) throw new SQLException("No courses were found in Term " + sourceTerm + ".");
        con.commit();
        session.setAttribute("flashType", "success");
        session.setAttribute("flashMessage", copied + " course" + (copied == 1 ? "" : "s") + " copied from " + sourceTerm + " to " + adminSession.workingTerm + " successfully.");
        response.sendRedirect("AdminCourses.jsp");
    } catch(Exception e) {
        if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
        String errorMessage = e.getMessage();
        if(errorMessage == null || errorMessage.trim().length() == 0) errorMessage = "Unable to copy Courses from the selected Term.";
        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", errorMessage);
        response.sendRedirect("AdminCourses.jsp");
    } finally {
        if(con != null) pool.close(con);
    }
%>
