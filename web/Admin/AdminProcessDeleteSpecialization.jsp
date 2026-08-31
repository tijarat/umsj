<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<%
    com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession)session.getAttribute("adminSession");
    if(adminSession == null)
    {
%><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><%
        return;
    }
    if(!adminSession.hasRightsOn("Specialization"))
    {
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Specialization service."/><%
        return;
    }
    String spId = request.getParameter("spId");
    com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
    if(pool == null) throw new ServletException("Database pool is not initialized.");
    Connection con = null;
    try
    {
        if(spId == null || !spId.trim().matches("\\d+")) throw new SQLException("A valid Specialization ID is required.");
        spId = spId.trim();
        con = pool.getConnection();
        con.setAutoCommit(false);
        int deleted = 0;
        try(PreparedStatement ps = con.prepareStatement("DELETE FROM UMS.SPECIALIZATION SP WHERE SP.SP_ID = ? AND EXISTS (SELECT 1 FROM UMS.PROGRAM P WHERE P.PROG_ID = SP.PROG_ID AND P.FACULTY_ID = ?)")) { ps.setLong(1, Long.parseLong(spId)); ps.setInt(2, adminSession.getWorkingFacultyId()); deleted = ps.executeUpdate(); }
        if(deleted == 0) throw new SQLException("Specialization record was not found for the current working faculty.");
        try(Statement logStmt = con.createStatement()) { adminSession.addLog("DELETE FROM UMS.SPECIALIZATION WHERE SP_ID=" + spId, logStmt); }
        con.commit();
        session.setAttribute("flashType", "success");
        session.setAttribute("flashMessage", "Specialization has been deleted successfully.");
        response.sendRedirect("AdminViewSpecialization.jsp");
    }
    catch(Exception e)
    {
        if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
        String errorMessage = e.getMessage();
        if(errorMessage == null || errorMessage.trim().length() == 0) errorMessage = "Unable to delete Specialization.";
        if(errorMessage.indexOf("ORA-02292") >= 0) errorMessage = "This Specialization contains child records and cannot be deleted.";
        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", errorMessage);
        response.sendRedirect("AdminViewSpecialization.jsp");
    }
    finally
    {
        pool.close(con);
    }
%>