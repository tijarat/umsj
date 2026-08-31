<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<%
    com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession)session.getAttribute("adminSession");
    if(adminSession == null)
    {
%>
        <jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/>
<%
        return;
    }
    if(!adminSession.hasRightsOn("Sub City"))
    {
%>
        <jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Sub City service."/>
<%
        return;
    }
    String subCityId = request.getParameter("subCityId");
    Connection con = null;
    com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
    if(pool == null) throw new ServletException("Database pool is not initialized.");
    try
    {
        if(subCityId == null || !subCityId.trim().matches("\\d+")) throw new SQLException("A valid numeric Sub City ID is required.");
        subCityId = subCityId.trim();
        con = pool.getConnection();
        con.setAutoCommit(false);
        String subCityName = null;
        try(PreparedStatement ps = con.prepareStatement("SELECT SUB_CITY_NAME FROM UMS.SUB_CITY WHERE SUB_CITY_ID = ?"))
        {
            ps.setLong(1, Long.parseLong(subCityId));
            try(ResultSet rs = ps.executeQuery())
            {
                if(rs.next()) subCityName = rs.getString("SUB_CITY_NAME");
            }
        }
        if(subCityName == null) throw new SQLException("Sub City record was not found.");
        try(PreparedStatement ps = con.prepareStatement("DELETE FROM UMS.SUB_CITY WHERE SUB_CITY_ID = ?"))
        {
            ps.setLong(1, Long.parseLong(subCityId));
            ps.executeUpdate();
        }
        try(Statement logStmt = con.createStatement())
        {
            adminSession.addLog("DELETE FROM UMS.SUB_CITY WHERE SUB_CITY_ID=" + subCityId, logStmt);
        }
        con.commit();
        session.setAttribute("flashType", "success");
        session.setAttribute("flashMessage", "Sub City " + subCityName + " has been deleted successfully.");
        response.sendRedirect("AdminSubCity.jsp");
    }
    catch(SQLException e)
    {
        if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
        String errorMessage = e.getMessage();
        if(errorMessage == null || errorMessage.trim().length() == 0) errorMessage = "Unable to delete Sub City.";
        if(errorMessage.indexOf("ORA-02292") >= 0) errorMessage = "This Sub City is being used by another record and cannot be deleted.";
        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", errorMessage);
        response.sendRedirect("AdminSubCity.jsp");
    }
    finally
    {
        pool.close(con);
    }
%>
