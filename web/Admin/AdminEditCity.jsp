<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<%!
    private String html(String value) 
    {
        if(value == null) return "";
        return value.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
    }
%>
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
    if(cityId == null || !cityId.trim().matches("\\d+"))
    {
        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", "A valid City ID is required.");
        response.sendRedirect("AdminCity.jsp");
        return;
    }
    cityId = cityId.trim();
    com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
    if(pool == null) throw new ServletException("Database pool is not initialized.");
    String flashType = (String)session.getAttribute("flashType");
    String flashMessage = (String)session.getAttribute("flashMessage");
    session.removeAttribute("flashType");
    session.removeAttribute("flashMessage");
    String cityName = null;
    Connection con = null;
    try
    {
        con = pool.getConnection();
        try(PreparedStatement ps = con.prepareStatement("SELECT CITY_NME FROM UMS.CITY WHERE CITY_ID = ?"))
        {
            ps.setLong(1, Long.parseLong(cityId));
            try(ResultSet rs = ps.executeQuery())
            {
                if(rs.next()) cityName = rs.getString("CITY_NME");
            }
        }
        if(cityName == null)
        {
            session.setAttribute("flashType", "error");
            session.setAttribute("flashMessage", "City record was not found.");
            response.sendRedirect("AdminCity.jsp");
            return;
        }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit City</title>
    <link href="../extra/css/style.css?v=20260831" rel="stylesheet" type="text/css">
    <link href="../extra/css/ums-module.css?v=20260831" rel="stylesheet" type="text/css">
</head>
<body class="ums-admin-main-body">
<main class="ums-module-page">
    <section class="ums-module-header">
        <div>
            <p class="ums-module-eyebrow">General Setup</p>
            <h1>City Management</h1>
            <p>Create and maintain cities used throughout UMS.</p>
        </div>
    </section>
    <section class="ums-module-card">
        <div class="ums-module-card-header">
            <h2>Edit City</h2>
            <span>* Required fields</span>
        </div>
        <form action="AdminProcessEditCity.jsp" method="post" name="editCityForm" id="editCityForm" class="ums-module-form">
            <div class="ums-form-grid">
                <div class="ums-field">
                    <label>City ID</label>
                    <div class="ums-readonly-value"><%=html(cityId)%></div>
                    <input name="cityId" type="hidden" value="<%=html(cityId)%>">
                </div>
                <div class="ums-field">
                    <label for="cityName">City Name *</label>
                    <input name="cityName" type="text" id="cityName" maxlength="50" value="<%=html(cityName)%>" autocomplete="off" required>
                </div>
            </div>
            <div class="ums-form-actions">
                <button type="submit">Update City</button>
                <a class="ums-button-secondary" href="AdminCity.jsp">Cancel</a>
            </div>
        </form>
    </section>
<% if(flashMessage != null && flashMessage.trim().length() > 0) { %>
    <div id="umsFlashMessage" class="ums-flash-message <%= "error".equals(flashType) ? "ums-flash-error" : "ums-flash-success" %>" role="alert"><%=html(flashMessage)%></div>
<% } %>
</main>
<script src="../extra/js/ums-module.js?v=20260831"></script>
</body>
</html>
<%
    }
    finally
    {
        pool.close(con);
    }
%>
