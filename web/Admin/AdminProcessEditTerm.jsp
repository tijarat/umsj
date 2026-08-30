<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*, java.net.URLEncoder" session="true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<%!
    private void log(String message, String user) {
        System.out.println(new java.util.Date() + "::AdminProcessEditTerm.jsp::" + user + "::" + message);
    }
%>
<%
    com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession) session.getAttribute("adminSession");

    if(adminSession == null) 
    {
        log("Session Not Found", "Invalid");
%>
        <jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/>
<%
        return;
    }

    if(!adminSession.hasRightsOn("Term"))
    {
%>
        <jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Term service."/>
<%
        return;
    }

    String oldTermCode = request.getParameter("oldTermCode");
    String termCode = request.getParameter("termCode");
    String termName = request.getParameter("termName");
    String startDate = request.getParameter("startDate");
    String endDate = request.getParameter("endDate");
    String status = request.getParameter("status");
    String sql = "";

    Connection con = null;

    try 
    {
        if(oldTermCode == null || termCode == null || termName == null || startDate == null || endDate == null) throw new SQLException("Required term information is missing.");

        oldTermCode = oldTermCode.trim().toUpperCase();
        termCode = termCode.trim().toUpperCase();
        termName = termName.trim();
        status = "C".equalsIgnoreCase(status) ? "C" : "O";

        con = pool.getConnection();
        con.setAutoCommit(false);

        try(Statement logStmt = con.createStatement())
        {
            if("C".equals(status))
            {
                sql = "UPDATE UMS.TERM SET STATUS_TYP = 'O' WHERE STATUS_TYP = 'C'";
                try(PreparedStatement ps = con.prepareStatement(sql)) 
                {
                    ps.executeUpdate();
                }
                adminSession.addLog("UPDATE UMS.TERM SET STATUS_TYP = O WHERE STATUS_TYP = C", logStmt);
            }

            sql = "UPDATE UMS.TERM SET TERM_CDE = ?, TERM_NME = ?, START_DTE = TO_DATE(?,'DD-MM-YYYY'), END_DTE = TO_DATE(?,'DD-MM-YYYY'), STATUS_TYP = ? WHERE TERM_CDE = ?";
            try(PreparedStatement ps = con.prepareStatement(sql)) 
            {
                ps.setString(1, termCode);
                ps.setString(2, termName);
                ps.setString(3, startDate);
                ps.setString(4, endDate);
                ps.setString(5, status);
                ps.setString(6, oldTermCode);
                ps.executeUpdate();
            }
            adminSession.addLog("UPDATE UMS.TERM SET TERM_CDE=" + termCode + ", TERM_NME=" + termName + ", START_DTE=" + startDate + ", END_DTE=" + endDate + ", STATUS_TYP=" + status + " WHERE TERM_CDE=" + oldTermCode, logStmt);
        }

        con.commit();
        adminSession.setWorkingTerm(con);

        session.setAttribute("flashType", "success");
        session.setAttribute("flashMessage", "Term " + termCode + " has been updated successfully.");
        response.sendRedirect("AdminTerm.jsp");

    } catch(SQLException e) 
    {
        if(con != null) try { con.rollback(); } catch(SQLException ignored) {}

        String errorMessage = e.getMessage();
        if(errorMessage == null || errorMessage.trim().length() == 0) errorMessage = "Unable to update Term.";
        if(errorMessage.indexOf("ORA-00001") >= 0) errorMessage = "This Term Code is already defined.";

        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", errorMessage);

        String redirectTermCode = termCode == null ? "" : termCode;
        String redirectTermName = termName == null ? "" : termName;
        String redirectStartDate = startDate == null ? "" : startDate;
        String redirectEndDate = endDate == null ? "" : endDate;
        String redirectStatus = status == null ? "O" : status;

        response.sendRedirect("AdminEditTerm.jsp?termCode=" + URLEncoder.encode(redirectTermCode, "UTF-8") + "&termName=" + URLEncoder.encode(redirectTermName, "UTF-8") + "&startDate=" + URLEncoder.encode(redirectStartDate, "UTF-8") + "&endDate=" + URLEncoder.encode(redirectEndDate, "UTF-8") + "&status=" + URLEncoder.encode(redirectStatus, "UTF-8"));

    } finally 
    {
        pool.close(con);
    }
%>
