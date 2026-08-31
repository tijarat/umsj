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
    String cityName = request.getParameter("cityName");
    Connection con = null;
    com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
    if(pool == null) throw new ServletException("Database pool is not initialized.");
    try
    {
        if(cityId == null || !cityId.trim().matches("\\d+")) throw new SQLException("A valid numeric City ID is required.");
        if(cityName == null || cityName.trim().length() == 0) throw new SQLException("City Name is required.");
        cityId = cityId.trim();
        cityName = cityName.trim();
        if(cityName.length() > 50) throw new SQLException("City Name cannot exceed 50 characters.");
        con = pool.getConnection();
        con.setAutoCommit(false);
        try(PreparedStatement ps = con.prepareStatement("INSERT INTO UMS.CITY (CITY_ID, CITY_NME) VALUES (?, ?)"))
        {
            ps.setLong(1, Long.parseLong(cityId));
            ps.setString(2, cityName);
            ps.executeUpdate();
        }
        try(Statement logStmt = con.createStatement())
        {
            adminSession.addLog("INSERT INTO UMS.CITY (CITY_ID,CITY_NME) VALUES(" + cityId + "," + cityName + ")", logStmt);
        }
        con.commit();
        session.setAttribute("flashType", "success");
        session.setAttribute("flashMessage", "City " + cityName + " has been added successfully.");
        response.sendRedirect("AdminCity.jsp");
    }
    catch(SQLException e)
    {
        if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
        String errorMessage = e.getMessage();
        if(errorMessage == null || errorMessage.trim().length() == 0) errorMessage = "Unable to add City.";
        if(errorMessage.indexOf("ORA-00001") >= 0 && errorMessage.toUpperCase().indexOf("UK_CITYMAST_CITYNME") >= 0) errorMessage = "This City Name is already defined.";
        else if(errorMessage.indexOf("ORA-00001") >= 0) errorMessage = "This City ID or City Name is already defined.";
        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", errorMessage);
        response.sendRedirect("AdminCity.jsp");
    }
    finally
    {
        pool.close(con);
    }
%>
