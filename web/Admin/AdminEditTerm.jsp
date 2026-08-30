<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java"
    import="java.net.URLEncoder" session="true" errorPage="../error.jsp" %>
<%!
    private void log(String message, String user) {
        System.out.println(new java.util.Date() + "::AdminEditTerm.jsp::" + user + "::" + message);
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
    com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession) session.getAttribute("adminSession");

    if(adminSession == null) 
    {
        log("Session Not Found", "Invalid");
%>
        <jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/>
<%
        return;
    }

    if(!adminSession.hasRightsOn("Term")) 
    {
%>
        <jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Term service."/>
<%
        return;
    }

    String flashType = (String) session.getAttribute("flashType");
    String flashMessage = (String) session.getAttribute("flashMessage");
    session.removeAttribute("flashType");
    session.removeAttribute("flashMessage");

    String termCode = request.getParameter("termCode");
    String termName = request.getParameter("termName");
    String startDate = request.getParameter("startDate");
    String endDate = request.getParameter("endDate");
    String status = request.getParameter("status");

    if(termCode == null || termCode.trim().isEmpty()) 
    {
        response.sendRedirect("AdminTerm.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Term</title>
    <link href="../extra/css/style.css?v=20260830" rel="stylesheet" type="text/css">
    <link href="../extra/css/ums-module.css?v=20260830" rel="stylesheet" type="text/css">
</head>
<body class="ums-admin-main-body">
<main class="ums-module-page">
    <section class="ums-module-header">
        <div>
            <p class="ums-module-eyebrow">Academic Setup</p>
            <h1>Term Management</h1>
            <p>Create and maintain Spring, Summer and Fall terms.</p>
        </div>
    </section>

    <section class="ums-module-card">
        <div class="ums-module-card-header">
            <h2>Edit Term</h2>
            <span>* Required fields</span>
        </div>

        <form action="AdminProcessEditTerm.jsp?oldTermCode=<%=url(termCode)%>"
              method="post" name="editTermForm" id="editTermForm"
              class="ums-module-form" data-ums-term-form="edit">

            <div class="ums-form-grid">
                <div class="ums-field">
                    <label>Term Code</label>
                    <div class="ums-readonly-value"><%=html(termCode)%></div>
                    <input name="termCode" type="hidden" value="<%=html(termCode)%>">
                </div>

                <div class="ums-field">
                    <label for="termName">Term Name *</label>
                    <input name="termName" type="text" id="termName" maxlength="30"
                           value="<%=html(termName)%>" required>
                </div>

                <div class="ums-field">
                    <label for="startDateDisplay">Start Date *</label>
                    <div class="ums-date-picker">
                        <input type="text" id="startDateDisplay" class="ums-date-display"
                               placeholder="DD-MM-YYYY" value="<%=html(startDate)%>" readonly>
                        <button type="button" class="ums-date-button"
                                aria-label="Select start date">&#128197;</button>
                        <input type="date" id="startDatePicker" class="ums-native-date"
                               aria-label="Start Date">
                        <input type="hidden" name="startDate" id="startDate"
                               value="<%=html(startDate)%>">
                    </div>
                </div>

                <div class="ums-field">
                    <label for="endDateDisplay">End Date *</label>
                    <div class="ums-date-picker">
                        <input type="text" id="endDateDisplay" class="ums-date-display"
                               placeholder="DD-MM-YYYY" value="<%=html(endDate)%>" readonly>
                        <button type="button" class="ums-date-button"
                                aria-label="Select end date">&#128197;</button>
                        <input type="date" id="endDatePicker" class="ums-native-date"
                               aria-label="End Date">
                        <input type="hidden" name="endDate" id="endDate"
                               value="<%=html(endDate)%>">
                    </div>
                </div>

                <div class="ums-field ums-field-check">
                    <label class="ums-check-label">
                        <input name="status" type="checkbox" id="status" value="C"
                               <%="C".equalsIgnoreCase(status) ? "checked" : ""%>>
                        <span>Set as current term</span>
                    </label>
                </div>
            </div>

            <div class="ums-form-actions">
                <button type="submit">Update Term</button>
                <a class="ums-button-secondary" href="AdminTerm.jsp">Cancel</a>
            </div>
        </form>
    </section>

<% 
    if(flashMessage != null && flashMessage.trim().length() > 0) 
    { 
%>
    <div id="umsFlashMessage" class="ums-flash-message <%= "error".equals(flashType) ? "ums-flash-error" : "ums-flash-success" %>" role="alert">
        <%=html(flashMessage)%>
    </div>
<% 
    } 
%>
</main>
<script src="../extra/js/ums-module.js?v=20260830"></script>
<script src="../extra/js/term.js?v=20260830"></script>
</body>
</html>
