<%@ page contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"
         language="java"
         import="java.sql.*"
         errorPage="error.jsp"
         session="true" %>

<%!
    private String html(String value) {
        if(value == null) return "";

        return value.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }
%>

<%
    String description = request.getParameter("des");

    if(description == null)
        description = " ";
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>UMS - Session Expired</title>

<link href="<%=request.getContextPath()%>/extra/css/style.css?v=20260829-session2"
      rel="stylesheet"
      type="text/css">
</head>

<body>

<main class="ums-session-expire-page">

    <section class="ums-session-expire-card">

        <div class="ums-session-expire-icon">
            !
        </div>

        <p class="ums-session-expire-eyebrow">
            Session Expired
        </p>

        <h1>Your session has expired</h1>

        <div class="ums-session-expire-description">
            <%=html(description)%>
        </div>

        <p class="ums-session-expire-help">
            Please close the current application window and start the process again.
        </p>

    </section>

</main>

<%
    // Session will be invalidated here so that all resources can be released.
    try
    {
        session.invalidate();
    }
    catch(Exception e)
    {
        e.printStackTrace();
    }
%>
<script>
    setTimeout(function () {
        window.top.location.href = "<%=request.getContextPath()%>/Admin/AdminLogin.jsp";
    }, 5000);
</script>

</body>
</html>
```
