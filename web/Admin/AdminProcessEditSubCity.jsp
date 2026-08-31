<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*,java.net.URLEncoder" session="true" errorPage="../error.jsp" %>
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
    String subCityCode = request.getParameter("subCityCode");
    String subCityName = request.getParameter("subCityName");
    String cityId = request.getParameter("cityId");
    String activeInd = request.getParameter("activeInd");
    Connection con = null;
    com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
    if(pool == null) throw new ServletException("Database pool is not initialized.");
    try
    {
        if(subCityId == null || !subCityId.trim().matches("\\d+")) throw new SQLException("A valid numeric Sub City ID is required.");
        if(subCityCode == null || subCityCode.trim().length() == 0) throw new SQLException("Sub City Code is required.");
        if(subCityName == null || subCityName.trim().length() == 0) throw new SQLException("Sub City Name is required.");
        if(cityId == null || !cityId.trim().matches("\\d+")) throw new SQLException("Please select a valid City.");
        subCityId = subCityId.trim();
        subCityCode = subCityCode.trim().toUpperCase();
        subCityName = subCityName.trim();
        cityId = cityId.trim();
        activeInd = activeInd == null ? "Y" : activeInd.trim().toUpperCase();
        if(subCityCode.length() > 3) throw new SQLException("Sub City Code cannot exceed 3 characters.");
        if(subCityName.length() > 50) throw new SQLException("Sub City Name cannot exceed 50 characters.");
        if(!"Y".equals(activeInd) && !"N".equals(activeInd)) throw new SQLException("Invalid Active status.");
        con = pool.getConnection();
        con.setAutoCommit(false);
        try(PreparedStatement cityCheck = con.prepareStatement("SELECT 1 FROM UMS.CITY WHERE CITY_ID = ?"))
        {
            cityCheck.setLong(1, Long.parseLong(cityId));
            try(ResultSet rs = cityCheck.executeQuery())
            {
                if(!rs.next()) throw new SQLException("Selected City does not exist.");
            }
        }
        int updated = 0;
        try(PreparedStatement ps = con.prepareStatement("UPDATE UMS.SUB_CITY SET SUB_CITY_CODE = ?, SUB_CITY_NAME = ?, CITY_ID = ?, ACTIVE_IND = ? WHERE SUB_CITY_ID = ?"))
        {
            ps.setString(1, subCityCode);
            ps.setString(2, subCityName);
            ps.setLong(3, Long.parseLong(cityId));
            ps.setString(4, activeInd);
            ps.setLong(5, Long.parseLong(subCityId));
            updated = ps.executeUpdate();
        }
        if(updated == 0) throw new SQLException("Sub City record was not found.");
        try(Statement logStmt = con.createStatement())
        {
            adminSession.addLog("UPDATE UMS.SUB_CITY SET SUB_CITY_CODE=" + subCityCode + ",SUB_CITY_NAME=" + subCityName + ",CITY_ID=" + cityId + ",ACTIVE_IND=" + activeInd + " WHERE SUB_CITY_ID=" + subCityId, logStmt);
        }
        con.commit();
        session.setAttribute("flashType", "success");
        session.setAttribute("flashMessage", "Sub City " + subCityName + " has been updated successfully.");
        response.sendRedirect("AdminSubCity.jsp");
    }
    catch(SQLException e)
    {
        if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
        String errorMessage = e.getMessage();
        if(errorMessage == null || errorMessage.trim().length() == 0) errorMessage = "Unable to update Sub City.";
        if(errorMessage.indexOf("ORA-02291") >= 0) errorMessage = "Selected City does not exist.";
        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", errorMessage);
        String redirectSubCityId = subCityId == null ? "" : subCityId;
        response.sendRedirect("AdminEditSubCity.jsp?subCityId=" + URLEncoder.encode(redirectSubCityId, "UTF-8"));
    }
    finally
    {
        pool.close(con);
    }
%>
