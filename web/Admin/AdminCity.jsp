<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*,java.net.URLEncoder" session="true" errorPage="../error.jsp" %>
<%!
    private void log(String message, String user)
    { 
        System.out.println(new java.util.Date() + "::AdminCity.jsp::" + user + "::" + message);
    }
    private String html(String value)
    {
        if(value == null) return "";
        return value.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
    }
    private String url(String value) throws Exception
    {
        return URLEncoder.encode(value == null ? "" : value, "UTF-8");
    }
%>
<%
    com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession)session.getAttribute("adminSession");
    if(adminSession == null)
    {
        log("Session Not Found", "Invalid");
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
    com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
    if(pool == null) throw new ServletException("Database pool is not initialized.");
    response.setHeader("Pragma", "no-cache");
    response.setHeader("Expires", "0");
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    String flashType = (String)session.getAttribute("flashType");
    String flashMessage = (String)session.getAttribute("flashMessage");
    session.removeAttribute("flashType");
    session.removeAttribute("flashMessage");
    Connection con = null;
    PreparedStatement cityStmt = null;
    ResultSet cityRs = null;
    try
    {
        con = pool.getConnection();
        cityStmt = con.prepareStatement("SELECT CITY_ID, CITY_NME FROM UMS.CITY ORDER BY CITY_NME");
        cityRs = cityStmt.executeQuery();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>City Management</title>
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
            <h2>Define City</h2>
            <span>* Required fields</span>
        </div>
        <form action="AdminProcessCity.jsp" method="post" name="cityForm" id="cityForm" class="ums-module-form">
            <div class="ums-form-grid">
                <div class="ums-field">
                    <label for="cityId">City ID *</label>
                    <input name="cityId" type="number" id="cityId" min="1" step="1" autocomplete="off" required>
                    <small>Enter the numeric primary key for the city.</small>
                </div>
                <div class="ums-field">
                    <label for="cityName">City Name *</label>
                    <input name="cityName" type="text" id="cityName" maxlength="50" autocomplete="off" required>
                </div>
            </div>
            <div class="ums-form-actions">
                <button type="submit">Add City</button>
            </div>
        </form>
    </section>

<% if(flashMessage != null && flashMessage.trim().length() > 0) { %>
    <div id="umsFlashMessage" class="ums-flash-message <%= "error".equals(flashType) ? "ums-flash-error" : "ums-flash-success" %>" role="alert"><%=html(flashMessage)%></div>
<% } %>

    <section class="ums-module-card">
        <div class="ums-module-card-header ums-module-card-header-tools">
            <div>
                <h2>Cities</h2>
                <span>All defined cities</span>
            </div>
            <div class="ums-table-tools">
                <div class="ums-table-search">
                    <label for="citySearch">Search</label>
                    <input type="search" id="citySearch" data-ums-table-search="cityTable" placeholder="Search city ID or name" autocomplete="off">
                </div>
                <button type="button" class="ums-export-button" data-ums-table-export="cityTable" title="Export City list to Excel"><span class="ums-export-icon">⇩</span> Export to Excel</button>
            </div>
        </div>
        <div class="ums-table-wrap">
            <table class="ums-data-table" id="cityTable" data-ums-table data-export-file="Cities">
                <thead>
                    <tr>
                        <th class="ums-sortable" data-column="0" data-type="number" data-export-header="City ID"><button type="button" class="ums-sort-button">City ID <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-sortable" data-column="1" data-type="text" data-export-header="City Name"><button type="button" class="ums-sort-button">City Name <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-actions-col">Options</th>
                    </tr>
                </thead>
                <tbody>
<%
        boolean found = false;
        while(cityRs.next())
        {
            found = true;
            String cityId = cityRs.getString("CITY_ID");
            String cityName = cityRs.getString("CITY_NME");
            String editUrl = "AdminEditCity.jsp?cityId=" + url(cityId);
            String deleteUrl = "AdminProcessDeleteCity.jsp?cityId=" + url(cityId);
%>
                    <tr>
                        <td data-sort-value="<%=html(cityId)%>"><%=html(cityId)%></td>
                        <td><%=html(cityName)%></td>
                        <td class="ums-row-actions" data-export-ignore="true"><a class="ums-action-link ums-action-edit" href="<%=editUrl%>">Edit</a><a class="ums-action-link ums-action-delete" href="<%=deleteUrl%>" data-ums-confirm="Delete city '<%=html(cityName)%>'?">Delete</a></td>
                    </tr>
<%      }
        if(!found)
        {
%>
                    <tr data-ums-empty-row><td colspan="3" class="ums-table-empty">No cities are defined.</td></tr>
<%      } %>
                </tbody>
            </table>
        </div>
        <div class="ums-table-footer" data-ums-table-footer="cityTable"></div>
    </section>
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
