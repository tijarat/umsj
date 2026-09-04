<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<%!
private String html(String value)
{
    if(value == null) return "";
    return value.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
}
private String url(String value) throws Exception
{
    return java.net.URLEncoder.encode(value == null ? "" : value, "UTF-8");
}
%>
<%
com.ums.packages.LocalSession adminSession=(com.ums.packages.LocalSession)session.getAttribute("adminSession");
if(adminSession == null)
{
%><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><%
return;
}
if(!adminSession.hasRightsOn("Course Equivalance"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Course Equivalance."/><%
return;
}
com.ums.db.Pool pool=(com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
String flashType=(String)session.getAttribute("flashType");
String flashMessage=(String)session.getAttribute("flashMessage");
session.removeAttribute("flashType");
session.removeAttribute("flashMessage");
Connection con=null;
try
{
con=pool.getConnection();
%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Course Equivalence</title><link href="../extra/css/style.css?v=20260904" rel="stylesheet"><link href="../extra/css/ums-module.css?v=20260904" rel="stylesheet"></head>
<body class="ums-admin-main-body"><main class="ums-module-page">
<section class="ums-module-header"><div><p class="ums-module-eyebrow">Academic Maintenance</p><h1>Course Equivalence</h1><p>Replace an old course code with a new equivalent course code in existing grade records.</p></div></section>
<section class="ums-module-card"><div class="ums-module-card-header"><h2>Change Course Equivalence</h2><span>* Required fields</span></div>
<form action="AdminProcessCourseEq.jsp" method="post" class="ums-module-form" id="courseEqForm">
<div class="ums-form-grid">
<div class="ums-field"><label for="old">Old Course Code *</label><input name="old" type="text" id="old" maxlength="10" autocomplete="off" required></div>
<div class="ums-field"><label for="newCourse">New Course Code *</label><input name="newCourse" type="text" id="newCourse" maxlength="10" autocomplete="off" required></div>
</div>
<div class="ums-inline-notice">This operation preserves the legacy behavior: it updates <strong>COR_GRADES.NCOURSEID</strong> for rows whose <strong>COURSEID</strong> matches the old course code. It does not modify the COURSE master table.</div>
<div class="ums-form-actions"><button type="submit">Change Equivalence</button></div>
</form></section>
<% if(flashMessage != null && flashMessage.trim().length() > 0) { %><div id="umsFlashMessage" class="ums-flash-message <%="error".equals(flashType) ? "ums-flash-error" : "ums-flash-success"%>" role="alert"><%=html(flashMessage)%></div><% } %>
</main><script src="../extra/js/ums-module.js?v=20260904"></script><script src="../extra/js/course-equivalence.js?v=20260904"></script></body></html>
<%
}
finally
{
pool.close(con);
}
%>