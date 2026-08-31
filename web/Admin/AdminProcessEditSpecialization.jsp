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
    String progId = request.getParameter("progId");
    String spAbbrev = request.getParameter("spAbbrev");
    String spDesc = request.getParameter("spDesc");
    com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
    if(pool == null) throw new ServletException("Database pool is not initialized.");
    Connection con = null;
    try
    {
        if(spId == null || !spId.trim().matches("\\d+")) throw new SQLException("A valid Specialization ID is required.");
        if(progId == null || !progId.trim().matches("\\d+")) throw new SQLException("A valid Program is required.");
        if(spAbbrev == null || spAbbrev.trim().length() == 0) throw new SQLException("Specialization Abbreviation is required.");
        spId = spId.trim();
        progId = progId.trim();
        spAbbrev = spAbbrev.trim();
        spDesc = spDesc == null ? "" : spDesc.trim();
        con = pool.getConnection();
        con.setAutoCommit(false);
        try(PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM UMS.PROGRAM WHERE PROG_ID = ? AND FACULTY_ID = ?")) { ps.setLong(1, Long.parseLong(progId)); ps.setInt(2, adminSession.getWorkingFacultyId()); try(ResultSet rs = ps.executeQuery()) { if(!rs.next() || rs.getInt(1) == 0) throw new SQLException("Selected Program does not belong to the current working faculty."); } }
        int updated = 0;
        try(PreparedStatement ps = con.prepareStatement("UPDATE UMS.SPECIALIZATION SET PROG_ID = ?, SPECIALIZATION_ABBREV = ?, SPECIALIZATION_DESC = ? WHERE SP_ID = ? AND EXISTS (SELECT 1 FROM UMS.PROGRAM P WHERE P.PROG_ID = UMS.SPECIALIZATION.PROG_ID AND P.FACULTY_ID = ?)"))
        {
            ps.setLong(1, Long.parseLong(progId));
            ps.setString(2, spAbbrev);
            ps.setString(3, spDesc);
            ps.setLong(4, Long.parseLong(spId));
            ps.setInt(5, adminSession.getWorkingFacultyId());
            updated = ps.executeUpdate();
        }
        if(updated == 0) throw new SQLException("Specialization record was not found for the current working faculty.");
        try(Statement logStmt = con.createStatement()) { adminSession.addLog("UPDATE UMS.SPECIALIZATION SET PROG_ID=" + progId + ", SPECIALIZATION_ABBREV=" + spAbbrev + ", SPECIALIZATION_DESC=" + spDesc + " WHERE SP_ID=" + spId, logStmt); }
        con.commit();
        session.setAttribute("flashType", "success");
        session.setAttribute("flashMessage", "Specialization " + spAbbrev + " has been updated successfully.");
        response.sendRedirect("AdminViewSpecialization.jsp");
    }
    catch(Exception e)
    {
        if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
        String errorMessage = e.getMessage();
        if(errorMessage == null || errorMessage.trim().length() == 0) errorMessage = "Unable to update Specialization.";
        if(errorMessage.indexOf("ORA-00001") >= 0) errorMessage = "This Specialization is already defined.";
        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", errorMessage);
        response.sendRedirect("AdminEditSpecialization.jsp?spId=" + (spId == null ? "" : spId));
    }
    finally
    {
        pool.close(con);
    }
%>