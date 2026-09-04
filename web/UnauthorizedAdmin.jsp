<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%!
private String html(String value)
{
    if(value == null) return "";
    return value.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
}
%>
<%
String description = request.getParameter("des");
if(description == null || description.trim().length() == 0) description = "You do not have permission to access this service.";
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Unauthorized Access</title>
<link href="extra/css/style.css?v=20260904" rel="stylesheet" type="text/css">
<link href="extra/css/ums-module.css?v=20260904" rel="stylesheet" type="text/css">
</head>
<body class="ums-admin-main-body">
<main class="ums-module-page">
<section class="ums-module-header">
<div>
<p class="ums-module-eyebrow">Access Control</p>
<h1>Unauthorized Access</h1>
<p>Your account does not have permission to open the requested service.</p>
</div>
</section>

<section class="ums-module-card">
<div class="ums-module-card-header">
<h2>Access Denied</h2>
<span>Permission required</span>
</div>

<div class="ums-flash-message ums-flash-error" role="alert">
<%=html(description)%>
</div>

<div class="ums-inline-notice">
If you believe you should have access to this service, contact the system administrator to review your assigned rights.
</div>

<div class="ums-form-actions">
<button type="button" class="ums-button-secondary" onclick="history.back()">Go Back</button>
<a class="ums-button-secondary" href="Admin/AdminHome.jsp">Admin Home</a>
</div>
</section>
</main>
</body>
</html>
