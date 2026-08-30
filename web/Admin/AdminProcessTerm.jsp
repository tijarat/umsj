<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>

<%!
    private void log(String message, String user) {
        System.out.println(new java.util.Date() + "::AdminProcessTerm.jsp::" + user + "::" + message);
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

    String termCode = request.getParameter("termCode");
    String termName = request.getParameter("termName");
    String startDate = request.getParameter("startDate");
    String endDate = request.getParameter("endDate");
    String status = request.getParameter("status");
    String sql = "";

    Connection con = null;
    try
    {
        if(termCode == null || termName == null || startDate == null || endDate == null) throw new SQLException("Required term information is missing.");

        termCode = termCode.trim().toUpperCase();
        termName = termName.trim();
        status = "C".equalsIgnoreCase(status) ? "C" : "O";

        con = pool.getConnection();
        con.setAutoCommit(false);
        String previousTermCode = null;

        sql = "SELECT TERM_CDE FROM UMS.TERM WHERE END_DTE = (SELECT MAX(END_DTE) FROM UMS.TERM)";
        try(PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) 
        {
            if(rs.next()) previousTermCode = rs.getString(1);
        }

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

            sql = "INSERT INTO UMS.TERM (TERM_CDE, TERM_NME, START_DTE, END_DTE, STATUS_TYP) VALUES(?, ?, TO_DATE(?,'DD-MM-YYYY'), TO_DATE(?,'DD-MM-YYYY'), ?)";
            try(PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, termCode);
                ps.setString(2, termName);
                ps.setString(3, startDate);
                ps.setString(4, endDate);
                ps.setString(5, status);
                ps.executeUpdate();
            }

            adminSession.addLog("INSERT INTO UMS.TERM VALUES(" + termCode + "," + termName + "," + startDate + "," + endDate + "," + status + ")", logStmt);

            if(previousTermCode != null) 
            {
                sql = "INSERT INTO UMS.GRADE_KEY (LOWER_LIMIT, UPPER_LIMIT, LETTER_GRADE, GP, TERM_CDE, GP_L2, GP_L3) SELECT LOWER_LIMIT, UPPER_LIMIT, LETTER_GRADE, GP, ?, GP_L2, GP_L3 FROM UMS.GRADE_KEY WHERE TERM_CDE = ?";
                try(PreparedStatement ps = con.prepareStatement(sql)) 
                {
                    ps.setString(1, termCode);
                    ps.setString(2, previousTermCode);
                    ps.executeUpdate();
                }
                adminSession.addLog("COPY UMS.GRADE_KEY FROM TERM " + previousTermCode + " TO TERM " + termCode, logStmt);
            }

            String sourceCurrentTerm = null;

            sql = "SELECT TERM_CDE FROM UMS.TERM WHERE STATUS_TYP = 'C' AND ROWNUM = 1";
            try(PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery())
            {
                if(rs.next()) sourceCurrentTerm = rs.getString(1);
            }

            if(sourceCurrentTerm != null) 
            {
                sql = "INSERT INTO UMS.ACADEMIC_CALENDAR (ACTIVITY_ID, ACTIVITY_NAME, FACULTY_ID, TERM_CDE, START_DATE, END_DATE) SELECT SEQ_ACTIVITY_ID.NEXTVAL, ACTIVITY_NAME, FACULTY_ID, ?, TO_DATE('01-01-1900','DD-MM-YYYY'), TO_DATE('01-01-1900','DD-MM-YYYY') FROM UMS.ACADEMIC_CALENDAR WHERE TERM_CDE = ?";
                try(PreparedStatement ps = con.prepareStatement(sql)) 
                {
                    ps.setString(1, termCode);
                    ps.setString(2, sourceCurrentTerm);
                    ps.executeUpdate();
                }
            }
        }

        con.commit();
        adminSession.setWorkingTerm(con);
        session.setAttribute("flashType", "success");
        session.setAttribute("flashMessage", "Term " + termCode + " has been added successfully.");
        response.sendRedirect("AdminTerm.jsp");
    } catch(SQLException e) 
    {
        if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
        String errorMessage = e.getMessage();
        if(errorMessage == null || errorMessage.trim().length() == 0) errorMessage = "Unable to add Term.";
        if(errorMessage.indexOf("ORA-00001") >= 0) errorMessage = "This Term Code is already defined.";

        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", errorMessage);
        response.sendRedirect("AdminTerm.jsp");

    } finally 
    {
            pool.close(con);
    }
%>