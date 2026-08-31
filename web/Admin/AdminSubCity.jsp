<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*,java.net.URLEncoder" session="true" errorPage="../error.jsp" %>
<%!
    private void log(String message, String user)
    {
        System.out.println(new java.util.Date() + "::AdminSubCity.jsp::" + user + "::" + message);
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
    if(!adminSession.hasRightsOn("Sub City"))
    {
%>
        <jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Sub City service."/>
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
    PreparedStatement subCityStmt = null;
    ResultSet subCityRs = null;
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
    <title>Sub City Management</title>
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
            <h2>Define Sub City</h2>
            <span>* Required fields</span>
        </div>
        <form action="AdminProcessSubCity.jsp" method="post" name="subCityForm" id="subCityForm" class="ums-module-form">
            <div class="ums-form-grid">
                <div class="ums-field">
                    <label for="subCityId">Sub City ID *</label>
                    <input name="subCityId" type="number" id="subCityId" min="1" step="1" autocomplete="off" required>
                </div>
                <div class="ums-field">
                    <label for="subCityCode">Sub City Code *</label>
                    <input name="subCityCode" type="text" id="subCityCode" maxlength="3" autocomplete="off" required>
                    <small>Maximum 3 characters.</small>
                </div>
                <div class="ums-field">
                    <label for="subCityName">Sub City Name *</label>
                    <input name="subCityName" type="text" id="subCityName" maxlength="50" autocomplete="off" required>
                </div>
                <div class="ums-field">
                    <label for="cityId">City *</label>
                    <select name="cityId" id="cityId" required>
                        <option value="">Select City</option>
<%      while(cityRs.next()) { %>
                        <option value="<%=html(cityRs.getString("CITY_ID"))%>"><%=html(cityRs.getString("CITY_NME"))%></option>
<%      } %>
                    </select>
                </div>
                <div class="ums-field">
                    <label for="activeInd">Status *</label>
                    <select name="activeInd" id="activeInd" required>
                        <option value="Y" selected>Active</option>
                        <option value="N">Inactive</option>
                    </select>
                </div>
            </div>
            <div class="ums-form-actions">
                <button type="submit">Add Sub City</button>
            </div>
        </form>
    </section>

<% if(flashMessage != null && flashMessage.trim().length() > 0) { %>
    <div id="umsFlashMessage" class="ums-flash-message <%= "error".equals(flashType) ? "ums-flash-error" : "ums-flash-success" %>" role="alert"><%=html(flashMessage)%></div>
<% } %>

<%
        if(cityRs != null) { cityRs.close(); cityRs = null; }
        if(cityStmt != null) { cityStmt.close(); cityStmt = null; }
        subCityStmt = con.prepareStatement("SELECT S.SUB_CITY_ID, S.SUB_CITY_CODE, S.SUB_CITY_NAME, S.CITY_ID, C.CITY_NME, S.ACTIVE_IND FROM UMS.SUB_CITY S LEFT JOIN UMS.CITY C ON C.CITY_ID = S.CITY_ID ORDER BY C.CITY_NME, S.SUB_CITY_NAME");
        subCityRs = subCityStmt.executeQuery();
%>
    <section class="ums-module-card">
        <div class="ums-module-card-header ums-module-card-header-tools">
            <div>
                <h2>Sub Cities</h2>
                <span>All defined sub cities</span>
            </div>
            <div class="ums-table-tools">
                <div class="ums-table-search">
                    <label for="subCitySearch">Search</label>
                    <input type="search" id="subCitySearch" data-ums-table-search="subCityTable" placeholder="Search code, name, city or status" autocomplete="off">
                </div>
                <button type="button" class="ums-export-button" data-ums-table-export="subCityTable" title="Export Sub City list to Excel"><span class="ums-export-icon">⇩</span> Export to Excel</button>
            </div>
        </div>
        <div class="ums-table-wrap">
            <table class="ums-data-table" id="subCityTable" data-ums-table data-export-file="Sub_Cities">
                <thead>
                    <tr>
                        <th class="ums-sortable" data-column="0" data-type="number" data-export-header="Sub City ID"><button type="button" class="ums-sort-button">ID <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-sortable" data-column="1" data-type="text" data-export-header="Sub City Code"><button type="button" class="ums-sort-button">Code <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-sortable" data-column="2" data-type="text" data-export-header="Sub City Name"><button type="button" class="ums-sort-button">Sub City Name <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-sortable" data-column="3" data-type="text" data-export-header="City"><button type="button" class="ums-sort-button">City <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-sortable" data-column="4" data-type="text" data-export-header="Status"><button type="button" class="ums-sort-button">Status <span class="ums-sort-indicator">↕</span></button></th>
                        <th class="ums-actions-col">Options</th>
                    </tr>
                </thead>
                <tbody>
<%
        boolean found = false;
        while(subCityRs.next())
        {
            found = true;
            String subCityId = subCityRs.getString("SUB_CITY_ID");
            String subCityCode = subCityRs.getString("SUB_CITY_CODE");
            String subCityName = subCityRs.getString("SUB_CITY_NAME");
            String cityName = subCityRs.getString("CITY_NME");
            String activeInd = subCityRs.getString("ACTIVE_IND");
            String statusText = "Y".equalsIgnoreCase(activeInd) ? "Active" : "Inactive";
            String statusClass = "Y".equalsIgnoreCase(activeInd) ? "ums-status-active" : "ums-status-inactive";
            String editUrl = "AdminEditSubCity.jsp?subCityId=" + url(subCityId);
            String deleteUrl = "AdminProcessDeleteSubCity.jsp?subCityId=" + url(subCityId);
%>
                    <tr>
                        <td data-sort-value="<%=html(subCityId)%>"><%=html(subCityId)%></td>
                        <td><%=html(subCityCode)%></td>
                        <td><%=html(subCityName)%></td>
                        <td><%=html(cityName == null ? "" : cityName)%></td>
                        <td data-sort-value="<%=html(statusText)%>"><span class="ums-status-badge <%=statusClass%>"><%=html(statusText)%></span></td>
                        <td class="ums-row-actions" data-export-ignore="true"><a class="ums-action-link ums-action-edit" href="<%=editUrl%>">Edit</a><a class="ums-action-link ums-action-delete" href="<%=deleteUrl%>" data-ums-confirm="Delete sub city '<%=html(subCityName)%>'?">Delete</a></td>
                    </tr>
<%      }
        if(!found)
        {
%>
                    <tr data-ums-empty-row><td colspan="6" class="ums-table-empty">No sub cities are defined.</td></tr>
<%      } %>
                </tbody>
            </table>
        </div>
        <div class="ums-table-footer" data-ums-table-footer="subCityTable"></div>
    </section>
</main>
<script src="../extra/js/ums-module.js?v=20260831"></script>
</body>
</html>
<%
    }
    finally
    {
        if(subCityRs != null) try { subCityRs.close(); } catch(SQLException ignored) {}
        if(subCityStmt != null) try { subCityStmt.close(); } catch(SQLException ignored) {}
        if(cityRs != null) try { cityRs.close(); } catch(SQLException ignored) {}
        if(cityStmt != null) try { cityStmt.close(); } catch(SQLException ignored) {}
        pool.close(con);
    }
%>
