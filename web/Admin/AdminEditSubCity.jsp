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
    if(!adminSession.hasRightsOn("Sub City"))
    {
%>
        <jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Sub City service."/>
<%
        return;
    }
    String subCityId = request.getParameter("subCityId");
    if(subCityId == null || !subCityId.trim().matches("\\d+"))
    {
        session.setAttribute("flashType", "error");
        session.setAttribute("flashMessage", "A valid Sub City ID is required.");
        response.sendRedirect("AdminSubCity.jsp");
        return;
    }
    subCityId = subCityId.trim();
    com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
    if(pool == null) throw new ServletException("Database pool is not initialized.");
    String flashType = (String)session.getAttribute("flashType");
    String flashMessage = (String)session.getAttribute("flashMessage");
    session.removeAttribute("flashType");
    session.removeAttribute("flashMessage");
    String subCityCode = null;
    String subCityName = null;
    String cityId = null;
    String activeInd = "Y";
    Connection con = null;
    PreparedStatement cityStmt = null;
    ResultSet cityRs = null;
    try
    {
        con = pool.getConnection();
        try(PreparedStatement ps = con.prepareStatement("SELECT SUB_CITY_CODE, SUB_CITY_NAME, CITY_ID, ACTIVE_IND FROM UMS.SUB_CITY WHERE SUB_CITY_ID = ?"))
        {
            ps.setLong(1, Long.parseLong(subCityId));
            try(ResultSet rs = ps.executeQuery())
            {
                if(rs.next())
                {
                    subCityCode = rs.getString("SUB_CITY_CODE");
                    subCityName = rs.getString("SUB_CITY_NAME");
                    cityId = rs.getString("CITY_ID");
                    activeInd = rs.getString("ACTIVE_IND");
                }
            }
        }
        if(subCityName == null)
        {
            session.setAttribute("flashType", "error");
            session.setAttribute("flashMessage", "Sub City record was not found.");
            response.sendRedirect("AdminSubCity.jsp");
            return;
        }
        cityStmt = con.prepareStatement("SELECT CITY_ID, CITY_NME FROM UMS.CITY ORDER BY CITY_NME");
        cityRs = cityStmt.executeQuery();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Sub City</title>
    <link href="../extra/css/style.css?v=20260831" rel="stylesheet" type="text/css">
    <link href="../extra/css/ums-module.css?v=20260831" rel="stylesheet" type="text/css">
</head>
<body class="ums-admin-main-body">
<main class="ums-module-page">
    <section class="ums-module-header">
        <div>
            <p class="ums-module-eyebrow">General Setup</p>
            <h1>Sub City Management</h1>
            <p>Create and maintain sub cities against their parent city.</p>
        </div>
    </section>

    <section class="ums-module-card">
        <div class="ums-module-card-header">
            <h2>Edit Sub City</h2>
            <span>* Required fields</span>
        </div>
        <form action="AdminProcessEditSubCity.jsp" method="post" name="editSubCityForm" id="editSubCityForm" class="ums-module-form">
            <div class="ums-form-grid">
                <div class="ums-field">
                    <label>Sub City ID</label>
                    <div class="ums-readonly-value"><%=html(subCityId)%></div>
                    <input name="subCityId" type="hidden" value="<%=html(subCityId)%>">
                </div>
                <div class="ums-field">
                    <label for="subCityCode">Sub City Code *</label>
                    <input name="subCityCode" type="text" id="subCityCode" maxlength="3" value="<%=html(subCityCode)%>" autocomplete="off" required>
                </div>
                <div class="ums-field">
                    <label for="subCityName">Sub City Name *</label>
                    <input name="subCityName" type="text" id="subCityName" maxlength="50" value="<%=html(subCityName)%>" autocomplete="off" required>
                </div>
                <div class="ums-field">
                    <label for="cityId">City *</label>
                    <select name="cityId" id="cityId" required>
                        <option value="">Select City</option>
<%      while(cityRs.next()) { String optionCityId = cityRs.getString("CITY_ID"); %>
                        <option value="<%=html(optionCityId)%>"<%= optionCityId != null && optionCityId.equals(cityId) ? " selected" : "" %>><%=html(cityRs.getString("CITY_NME"))%></option>
<%      } %>
                    </select>
                </div>
                <div class="ums-field">
                    <label for="activeInd">Status *</label>
                    <select name="activeInd" id="activeInd" required>
                        <option value="Y"<%= "Y".equalsIgnoreCase(activeInd) ? " selected" : "" %>>Active</option>
                        <option value="N"<%= "N".equalsIgnoreCase(activeInd) ? " selected" : "" %>>Inactive</option>
                    </select>
                </div>
            </div>
            <div class="ums-form-actions">
                <button type="submit">Update Sub City</button>
                <a class="ums-button-secondary" href="AdminSubCity.jsp">Cancel</a>
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
        if(cityRs != null) try { cityRs.close(); } catch(SQLException ignored) {}
        if(cityStmt != null) try { cityStmt.close(); } catch(SQLException ignored) {}
        pool.close(con);
    }
%>
