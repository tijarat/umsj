<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<%!
    private void log(String message, String user) {
        System.out.println(new java.util.Date() + "::AdminProcessDeleteTerm.jsp::" + user + "::" + message);
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

    if(!adminSession.hasRightsOn("Term")) {
%>
        <jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Term service."/>
<%
        return;
    }

    String termCode = request.getParameter("termCode");
    String sql = "";
    Connection con = null;

    try 
    {
        if(termCode == null || termCode.trim().isEmpty()) throw new SQLException("Term Code is required.");
        termCode = termCode.trim().toUpperCase();
        con = pool.getConnection();
        con.setAutoCommit(false);

        try(Statement logStmt = con.createStatement()) {
            sql = "DELETE FROM UMS.ACADEMIC_CALENDAR WHERE TERM_CDE = ?";
            try(PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, termCode);
                ps.executeUpdate();
            }

            sql = "DELETE FROM UMS.GRADE_KEY WHERE TERM_CDE = ?";
            try(PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, termCode);
                ps.executeUpdate();
            }
            adminSession.addLog("DELETE FROM UMS.GRADE_KEY WHERE TERM_CDE=" + termCode, logStmt);

            sql = "DELETE FROM UMS.TERM WHERE TERM_CDE = ?";
            try(PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, termCode);
                ps.executeUpdate();
            }
            adminSession.addLog("DELETE FROM UMS.TERM WHERE TERM_CDE=" + termCode, logStmt);
        }

        con.commit();
        adminSession.setWorkingTerm(con);

        session.setAttribute("flashType", "success");
        session.setAttribute("flashMessage", "Term " + termCode + " has been deleted successfully.");
        response.sendRedirect("AdminTerm.jsp");

    } catch(SQLException e) 
    {
        if(con != null) try { con.rollback(); } catch(SQLException ignored) {}

        String errorMessage = e.getMessage();
        if(errorMessage == null || errorMessage.trim().length() == 0) errorMessage = "Unable to delete Term.";
        if(errorMessage.indexOf("ORA-02292") >= 0) errorMessage = "This Term contains child records and cannot be deleted.";
        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", errorMessage);
        response.sendRedirect("AdminTerm.jsp");

    } finally 
    {
            pool.close(con);
    }
%>
