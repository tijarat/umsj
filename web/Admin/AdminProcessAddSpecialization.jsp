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
    String progId = request.getParameter("progId");
    String spAbbrev = request.getParameter("spAbbrev");
    String spDesc = request.getParameter("spDesc");
    com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
    if(pool == null) throw new ServletException("Database pool is not initialized.");
    Connection con = null;
    try
    {
        if(progId == null || !progId.trim().matches("\\d+")) throw new SQLException("A valid Program is required.");
        if(spAbbrev == null || spAbbrev.trim().length() == 0) throw new SQLException("Specialization Abbreviation is required.");
        progId = progId.trim();
        spAbbrev = spAbbrev.trim();
        spDesc = spDesc == null ? "" : spDesc.trim();
        con = pool.getConnection();
        con.setAutoCommit(false);
        try(PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM UMS.PROGRAM WHERE PROG_ID = ? AND FACULTY_ID = ?"))
        {
            ps.setLong(1, Long.parseLong(progId));
            ps.setString(2, adminSession.getWorkingFacultyId());
            try(ResultSet rs = ps.executeQuery()) { if(!rs.next() || rs.getInt(1) == 0) throw new SQLException("Selected Program does not belong to the current working faculty."); }
        }
        long spId = 1;
        try(PreparedStatement ps = con.prepareStatement("SELECT NVL(MAX(SP_ID),0)+1 FROM UMS.SPECIALIZATION"); ResultSet rs = ps.executeQuery()) { if(rs.next()) spId = rs.getLong(1); }
        try(PreparedStatement ps = con.prepareStatement("INSERT INTO UMS.SPECIALIZATION (SP_ID, PROG_ID, SPECIALIZATION_ABBREV, SPECIALIZATION_DESC) VALUES (?, ?, ?, ?)"))
        {
            ps.setLong(1, spId);
            ps.setLong(2, Long.parseLong(progId));
            ps.setString(3, spAbbrev);
            ps.setString(4, spDesc);
            ps.executeUpdate();
        }
        try(Statement logStmt = con.createStatement()) { adminSession.addLog("INSERT INTO UMS.SPECIALIZATION (SP_ID,PROG_ID,SPECIALIZATION_ABBREV,SPECIALIZATION_DESC) VALUES(" + spId + "," + progId + "," + spAbbrev + "," + spDesc + ")", logStmt); }
        con.commit();
        session.setAttribute("flashType", "success");
        session.setAttribute("flashMessage", "Specialization " + spAbbrev + " has been added successfully.");
        response.sendRedirect("AdminViewSpecialization.jsp");
    }
    catch(Exception e)
    {
        if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
        String errorMessage = e.getMessage();
        if(errorMessage == null || errorMessage.trim().length() == 0) errorMessage = "Unable to add Specialization.";
        if(errorMessage.indexOf("ORA-00001") >= 0) errorMessage = "This Specialization is already defined.";
        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", errorMessage);
        response.sendRedirect("AdminViewSpecialization.jsp");
    }
    finally
    {
        pool.close(con);
    }
%>