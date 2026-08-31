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
    if(!adminSession.hasRightsOn("City"))
    {
%>
        <jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over City service."/>
<%
        return;
    }
    String cityId = request.getParameter("cityId");
    Connection con = null;
    com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
    if(pool == null) throw new ServletException("Database pool is not initialized.");
    try
    {
        if(cityId == null || !cityId.trim().matches("\\d+")) throw new SQLException("A valid numeric City ID is required.");
        cityId = cityId.trim();
        con = pool.getConnection();
        con.setAutoCommit(false);
        String cityName = null;
        try(PreparedStatement ps = con.prepareStatement("SELECT CITY_NME FROM UMS.CITY WHERE CITY_ID = ?"))
        {
            ps.setLong(1, Long.parseLong(cityId));
            try(ResultSet rs = ps.executeQuery())
            {
                if(rs.next()) cityName = rs.getString("CITY_NME");
            }
        }
        if(cityName == null) throw new SQLException("City record was not found.");
        try(PreparedStatement ps = con.prepareStatement("DELETE FROM UMS.CITY WHERE CITY_ID = ?"))
        {
            ps.setLong(1, Long.parseLong(cityId));
            ps.executeUpdate();
        }
        try(Statement logStmt = con.createStatement())
        {
            adminSession.addLog("DELETE FROM UMS.CITY WHERE CITY_ID=" + cityId, logStmt);
        }
        con.commit();
        session.setAttribute("flashType", "success");
        session.setAttribute("flashMessage", "City " + cityName + " has been deleted successfully.");
        response.sendRedirect("AdminCity.jsp");
    }
    catch(SQLException e)
    {
        if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
        String errorMessage = e.getMessage();
        if(errorMessage == null || errorMessage.trim().length() == 0) errorMessage = "Unable to delete City.";
        if(errorMessage.indexOf("ORA-02292") >= 0) errorMessage = "This City is being used by another record and cannot be deleted.";
        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", errorMessage);
        response.sendRedirect("AdminCity.jsp");
    }
    finally
    {
        pool.close(con);
    }
%>
