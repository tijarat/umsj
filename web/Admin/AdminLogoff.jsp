from pathlib import Path

output = Path("/mnt/data/AdminLogoff_new.jsp")

content = r'''<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="com.ums.packages.LocalSession" %>
<%
response.setHeader("Pragma", "no-cache");
response.setHeader("Expires", "0");
response.setHeader("Cache-Control", "private, no-store, no-cache, must-revalidate");
String closeOption = request.getParameter("closeOption");
if(closeOption == null || (!"Y".equalsIgnoreCase(closeOption) && !"N".equalsIgnoreCase(closeOption))) closeOption = "N";
LocalSession adminSession = (LocalSession)session.getAttribute("adminSession");
String user = adminSession != null ? adminSession.user : "";
boolean loggedOff = true;
String message = "You are logged off successfully.";
try
{
    if(session != null) session.invalidate();
}
catch(Exception e)
{
    loggedOff = false;
    message = "An error occurred while trying to log off.";
    System.out.println("Error in AdminLogoff.jsp while invalidating user [" + user + "]: " + e.getMessage());
    e.printStackTrace();
}
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Logoff - UMS Online</title>
        <link href="../extra/css/style.css" rel="stylesheet" type="text/css">
    </head>
    <body<%= "Y".equalsIgnoreCase(closeOption) ? " onload=\"window.close();\"" : "" %>>
        <div class="ums-page ums-auth-page">
            <header class="ums-header">
                <div class="ums-header-inner">
                    <div class="ums-brand">
                        <div class="ums-brand-mark">PLOVER</div>
                        <div>
                            <h1 class="ums-brand-title">UMS Online</h1>
                            <p class="ums-brand-subtitle">University Online Services Portal</p>
                        </div>
                    </div>
                    <a href="AdminLogin.jsp" class="ums-site-link">Login</a>
                </div>
            </header>

            <main class="ums-auth-main">
                <section class="ums-auth-shell">
                    <div class="ums-auth-info">
                        <div class="ums-auth-icon"><%= loggedOff ? "✓" : "!" %></div>
                        <h2><%= loggedOff ? "Session Closed" : "Logoff Error" %></h2>
                        <p>Your UMS session has been ended and this browser is no longer authenticated for that session.</p>
                        <div class="ums-auth-note">
                            <strong>Security note:</strong><br>
                            On a shared computer, close the browser after signing out.
                        </div>
                    </div>

                    <div class="ums-auth-form-panel">
                        <p class="ums-auth-eyebrow">Secure Access</p>
                        <h2 class="ums-auth-title"><%= loggedOff ? "Logged Off" : "Unable to Log Off" %></h2>
                        <p class="ums-auth-subtitle"><%= message %></p>

<% if(loggedOff) { %>
                        <div class="ums-auth-alert">Your session has been safely closed.</div>
<% } else { %>
                        <div class="ums-auth-alert"><%= message %></div>
<% } %>

<% if(!"Y".equalsIgnoreCase(closeOption)) { %>
                        <a href="AdminLogin.jsp" class="ums-auth-submit" style="display:block;text-align:center;text-decoration:none;">Return to Login</a>
<% } else { %>
                        <p class="ums-auth-subtitle">You may close this window if it does not close automatically.</p>
<% } %>
                    </div>
                </section>
            </main>
        </div>
    </body>
</html>
'''

output.write_text(content, encoding="utf-8")
print(f"Created: {output}")
print(f"Java statement line check: {'PASS' if all(not line.rstrip().endswith(('+', '=', ',', '&&', '||')) for line in content.splitlines() if line.strip()) else 'REVIEW'}")
