<%@page import="java.io.*"%>
<%@page import="java.net.HttpURLConnection"%>
<%@page import="java.net.URL"%>
<%@page import="java.text.DateFormat"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.util.Date"%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" isErrorPage="true" %>

<%!
    private String html(String value) 
    {
        if(value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>

<%
    String mainMessage = "";
    String desc = "";
    String message = "";
if(exception != null) {
        exception.printStackTrace();   // print to Tomcat/NetBeans Output
        mainMessage = exception.toString();
    }
    StringWriter sw = new StringWriter();
    PrintWriter pw = new PrintWriter(sw, true);

    try 
    {
        System.out.println("CP:" + request.getContextPath());
        System.out.println("URI:" + request.getRequestURI());
        System.out.println("URL:" + request.getRequestURL());

        if(exception != null) 
        {
            exception.printStackTrace(pw);
            mainMessage = exception.toString();
        } else 
            mainMessage = "Exception value is Null";
        String ip = request.getHeader("X-FORWARDED-FOR");
        if(ip == null || ip.trim().length() == 0) ip = request.getRemoteAddr();
    } catch(Exception ex) 
    {
        mainMessage = "Invalid Parameter found Activity has been logged::" + ex.getMessage();
    }
    if(mainMessage.indexOf("~") > 0)
    {
        int separatorIndex = mainMessage.indexOf("~");
        desc = mainMessage.substring(0, separatorIndex);
        message = mainMessage.substring(separatorIndex + 1);
    } else 
    {
        desc = mainMessage;
        message = mainMessage;
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>UMS - Error</title>
    <link href="<%=request.getContextPath()%>/extra/css/style.css?v=20260829-error" rel="stylesheet" type="text/css">
</head>

<body>

<main class="ums-error-page">

    <section class="ums-error-card">

        <div class="ums-error-header">
            <div class="ums-error-icon">!</div>

            <div>
                <p class="ums-error-eyebrow">System Error</p>
                <h1>Unable to Process Request</h1>
                <p>The server could not complete your requested operation.</p>
            </div>
        </div>

        <div class="ums-error-body">

            <div class="ums-error-instructions">
                <h2>What you can do</h2>

                <ol>
                    <li>Press your browser's Back button.</li>
                    <li>Try the operation again.</li>
                    <li>If the problem continues, log out and sign in again.</li>
                    <li>If the issue still persists, contact the system administrator.</li>
                </ol>
            </div>

            <div class="ums-error-message">
                <div class="ums-error-message-title">Message</div>
                <div class="ums-error-message-text"><%=html(desc)%></div>
            </div>

            <% if(message != null && message.trim().length() > 0 && !message.equals(desc)) { %>

            <details class="ums-error-details">
                <summary>Technical Details</summary>

                <div class="ums-error-details-content">
                    <%=html(message)%>
                </div>
            </details>

            <% } %>

            <div class="ums-error-actions">
                <button type="button" onclick="history.back();">Go Back</button>

                <a href="<%=request.getContextPath()%>/Admin/AdminHome.jsp" class="ums-button-secondary">
                    Admin Home
                </a>
            </div>

        </div>

    </section>

</main>

</body>
</html>
```
