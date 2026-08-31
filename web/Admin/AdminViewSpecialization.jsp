<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*,java.net.URLEncoder" session="true" errorPage="../error.jsp" %>
<%!
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
%>
        <jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/>
<%
        return;
    }
    if(!adminSession.hasRightsOn("Specialization"))
    {
%>
        <jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Specialization service."/>
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
    PreparedStatement programStmt = null;
    PreparedStatement specializationStmt = null;
    ResultSet programRs = null;
    ResultSet specializationRs = null;
    try
    {
        con = pool.getConnection();
        programStmt = con.prepareStatement("SELECT PROG_ID, PROG_CDE, PROG_NME FROM UMS.PROGRAM WHERE FACULTY_ID = ? ORDER BY PROG_CDE");
        programStmt.setString(1, adminSession.getWorkingFacultyId());
        programRs = programStmt.executeQuery();
        specializationStmt = con.prepareStatement("SELECT SP.SP_ID, P.PROG_ID, P.PROG_CDE, P.PROG_NME, SP.SPECIALIZATION_ABBREV, SP.SPECIALIZATION_DESC FROM UMS.SPECIALIZATION SP JOIN UMS.PROGRAM P ON SP.PROG_ID = P.PROG_ID WHERE P.FACULTY_ID = ? ORDER BY P.PROG_CDE, SP.SPECIALIZATION_ABBREV, SP.SP_ID");
        specializationStmt.setString(1, adminSession.getWorkingFacultyId());
        specializationRs = specializationStmt.executeQuery();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Specialization Management</title>
    <link href="../extra/css/style.css?v=20260831" rel="stylesheet" type="text/css">
    <link href="../extra/css/ums-module.css?v=20260831" rel="stylesheet" type="text/css">
</head>
<body class="ums-admin-main-body">
<main class="ums-module-page">
    <section class="ums-module-header"><div><p class="ums-module-eyebrow">Academic Setup</p><h1>Specialization Management</h1><p>Create and maintain program specializations for the current working faculty.</p></div></section>
    <section class="ums-module-card">
        <div class="ums-module-card-header"><h2>Define Specialization</h2><span>* Required fields</span></div>
        <form action="AdminProcessAddSpecialization.jsp" method="post" id="specializationForm" class="ums-module-form">
            <div class="ums-form-grid">
                <div class="ums-field"><label for="progId">Program *</label><select name="progId" id="progId" required data-ums-search-select data-search-placeholder="Type program code or name..." data-search-label="Search Program"><option value="">Select Program</option><% while(programRs.next()) { %><option value="<%=html(programRs.getString("PROG_ID"))%>"><%=html(programRs.getString("PROG_CDE"))%> - <%=html(programRs.getString("PROG_NME"))%></option><% } %></select></div>
                <div class="ums-field"><label for="spAbbrev">Specialization Abbreviation *</label><input name="spAbbrev" type="text" id="spAbbrev" maxlength="50" autocomplete="off" required></div>
                <div class="ums-field ums-field-full"><label for="spDesc">Specialization Description</label><textarea name="spDesc" id="spDesc" rows="3"></textarea></div>
            </div>
            <div class="ums-form-actions"><button type="submit">Add Specialization</button></div>
        </form>
    </section>
<% if(flashMessage != null && flashMessage.trim().length() > 0) { %><div id="umsFlashMessage" class="ums-flash-message <%= "error".equals(flashType) ? "ums-flash-error" : "ums-flash-success" %>" role="alert"><%=html(flashMessage)%></div><% } %>
    <section class="ums-module-card">
        <div class="ums-module-card-header ums-module-card-header-tools"><div><h2>Specializations</h2><span>Specializations for the current working faculty</span></div><div class="ums-table-tools"><div class="ums-table-search"><label for="specializationSearch">Search</label><input type="search" id="specializationSearch" data-ums-table-search="specializationTable" placeholder="Search program or specialization" autocomplete="off"></div><button type="button" class="ums-export-button" data-ums-table-export="specializationTable" title="Export Specialization list to Excel"><span class="ums-export-icon">⇩</span> Export to Excel</button></div></div>
        <div class="ums-table-wrap"><table class="ums-data-table" id="specializationTable" data-ums-table data-export-file="Specializations"><thead><tr><th class="ums-sortable" data-column="0" data-type="text" data-export-header="Program"><button type="button" class="ums-sort-button">Program <span class="ums-sort-indicator">↕</span></button></th><th class="ums-sortable" data-column="1" data-type="text" data-export-header="Abbreviation"><button type="button" class="ums-sort-button">Abbreviation <span class="ums-sort-indicator">↕</span></button></th><th class="ums-sortable" data-column="2" data-type="text" data-export-header="Description"><button type="button" class="ums-sort-button">Description <span class="ums-sort-indicator">↕</span></button></th><th class="ums-actions-col">Options</th></tr></thead><tbody>
<%
        boolean found = false;
        while(specializationRs.next())
        {
            found = true;
            String spId = specializationRs.getString("SP_ID");
            String abbreviation = specializationRs.getString("SPECIALIZATION_ABBREV");
            String editUrl = "AdminEditSpecialization.jsp?spId=" + url(spId);
            String deleteUrl = "AdminProcessDeleteSpecialization.jsp?spId=" + url(spId);
%>
<tr><td><%=html(specializationRs.getString("PROG_CDE"))%></td><td><%=html(abbreviation)%></td><td><%=html(specializationRs.getString("SPECIALIZATION_DESC"))%></td><td class="ums-row-actions" data-export-ignore="true"><a class="ums-action-link ums-action-edit" href="<%=editUrl%>">Edit</a><a class="ums-action-link ums-action-delete" href="<%=deleteUrl%>" data-ums-confirm="Delete specialization '<%=html(abbreviation)%>'?">Delete</a></td></tr>
<%      }
        if(!found)
        {
%><tr data-ums-empty-row><td colspan="4" class="ums-table-empty">No specializations are defined for this faculty.</td></tr><% } %>
        </tbody></table></div><div class="ums-table-footer" data-ums-table-footer="specializationTable"></div>
    </section>
</main>
<script src="../extra/js/ums-module.js?v=20260831"></script>
</body>
</html>
<%
    }
    finally
    {
        if(specializationRs != null) try { specializationRs.close(); } catch(SQLException ignored) {}
        if(specializationStmt != null) try { specializationStmt.close(); } catch(SQLException ignored) {}
        if(programRs != null) try { programRs.close(); } catch(SQLException ignored) {}
        if(programStmt != null) try { programStmt.close(); } catch(SQLException ignored) {}
        pool.close(con);
    }
%>