<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<%!
    private void log(String message, String user) { System.out.println(new java.util.Date() + "::AdminWorkingTerm.jsp::" + user + "::" + message); }
    private String html(String value) { if(value == null) return ""; return value.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;"); }
%>
<%
com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession)session.getAttribute("adminSession");
if(adminSession == null) { log("Session Not Found", "Invalid"); %><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><% return; }
boolean hasWorkingTermRight = adminSession.hasRightsOn("Change Working Term") || adminSession.hasRightsOn("Working Term");
if(!hasWorkingTermRight) { %><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Change Working Term service."/><% return; }
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
response.setHeader("Pragma", "no-cache");
response.setHeader("Expires", "0");
response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
String flashType = (String)session.getAttribute("flashType");
String flashMessage = (String)session.getAttribute("flashMessage");
session.removeAttribute("flashType");
session.removeAttribute("flashMessage");
String workingFacultyId = adminSession.getWorkingFacultyId();
String workingFaculty = adminSession.getWorkingFaculty();
String currentWorkingTerm = adminSession.workingTerm;
Connection con = null;
PreparedStatement termStmt = null;
ResultSet termRs = null;
try {
if(workingFacultyId == null || workingFacultyId.trim().length() == 0) throw new SQLException("Working Faculty is not selected.");
con = pool.getConnection();
termStmt = con.prepareStatement("SELECT TERM_CDE, TERM_NME, TO_CHAR(START_DTE,'DD-MM-YYYY') START_DTE, TO_CHAR(END_DTE,'DD-MM-YYYY') END_DTE FROM UMS.TERM ORDER BY START_DTE DESC");
termRs = termStmt.executeQuery();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Change Working Term</title>
    <link href="../extra/css/style.css?v=20260831" rel="stylesheet" type="text/css">
    <link href="../extra/css/ums-module.css?v=20260831b" rel="stylesheet" type="text/css">
</head>
<body class="ums-admin-main-body">
<main class="ums-module-page">
    <section class="ums-module-header">
        <div>
            <p class="ums-module-eyebrow">Academic Setup</p>
            <h1>Change Working Term</h1>
            <p>Choose the working term for your current faculty. Start typing a term code or name to filter the options.</p>
        </div>
    </section>

<% if(flashMessage != null && flashMessage.trim().length() > 0) { %>
    <div id="umsFlashMessage" class="ums-flash-message <%= "error".equals(flashType) ? "ums-flash-error" : "ums-flash-success" %>" role="alert"><%=html(flashMessage)%></div>
<% } %>

    <section class="ums-module-card">
        <div class="ums-module-card-header">
            <h2>Working Term Setup</h2>
            <span>Faculty-specific setting</span>
        </div>
        <form action="AdminProcessWorkingTerm.jsp" method="post" name="workingTermForm" id="workingTermForm" class="ums-module-form">
            <div class="ums-form-grid">
                <div class="ums-field">
                    <label>Working Faculty</label>
                    <div class="ums-readonly-value"><%=html(workingFaculty)%> <span class="ums-field-muted">(<%=html(workingFacultyId)%>)</span></div>
                </div>
                <div class="ums-field">
                    <label>Current Working Term</label>
                    <div class="ums-readonly-value"><%=html(currentWorkingTerm)%></div>
                </div>
                <div class="ums-field ums-field-wide">
                    <label for="termCode">New Working Term *</label>
                    <select name="termCode" id="termCode" required data-ums-search-select data-search-placeholder="Type term code or name..." data-search-label="Search Working Term">
                        <option value="">Select Working Term</option>
<% while(termRs.next()) { String termCode = termRs.getString("TERM_CDE"); String termName = termRs.getString("TERM_NME"); String startDate = termRs.getString("START_DTE"); String endDate = termRs.getString("END_DTE"); boolean selected = termCode != null && termCode.equalsIgnoreCase(currentWorkingTerm); %>
                        <option value="<%=html(termCode)%>" <%=selected ? "selected" : ""%>><%=html(termCode)%> - <%=html(termName)%> (<%=html(startDate)%> to <%=html(endDate)%>)</option>
<% } %>
                    </select>
                    <small>Type any part of the term code, term name, or displayed date to filter. This changes UMS.CURRENT_TERM only for faculty <%=html(workingFaculty)%>.</small>
                </div>
            </div>
            <div class="ums-form-actions">
                <button type="submit" data-ums-confirm="Change the working term for <%=html(workingFaculty)%>?">Change Working Term</button>
            </div>
        </form>
    </section>

    <section class="ums-module-card">
        <div class="ums-module-card-header">
            <h2>Working Term Context</h2>
            <span>Current faculty</span>
        </div>
        <div class="ums-module-form">
            <div class="ums-inline-notice">Working Term controls screens that use <strong>adminSession.workingTerm</strong> for the selected faculty. It does not change the Term module's global Current/Open status.</div>
        </div>
    </section>
</main>
<script src="../extra/js/ums-module.js?v=20260831b"></script>
<% if("success".equals(flashType)) { %>
<script>
try { if(parent && parent !== window && parent.document) { var termNode = parent.document.querySelector('.ums-top-current-term strong'); if(termNode) termNode.textContent = '<%=html(adminSession.workingTerm)%>'; } } catch(ignore) {}
</script>
<% } %>
</body>
</html>
<% } catch(Exception e) { log("Error: " + e.getMessage(), adminSession.user); throw new ServletException(e); } finally { if(termRs != null) try { termRs.close(); } catch(SQLException ignored) {} if(termStmt != null) try { termStmt.close(); } catch(SQLException ignored) {} if(con != null) pool.close(con); } %>
