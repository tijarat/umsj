<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*,com.ums.functions.Functions" errorPage="../error.jsp" %>

<%!
    private String escapeHtml(String value) 
    {
        if (value == null)  return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>

<%
    String url = "http://" + Functions.getParameters("onlneurl");
    if (!response.isCommitted()) 
    {
        response.setHeader("Pragma", "no-cache");
        response.setHeader("Expires", "0");
        response.setHeader("Cache-Control", "private, no-store, no-cache, must-revalidate");
    }

    if (session.getAttribute("adminSession") != null) {
%>
        <jsp:forward page="AdminHome.jsp" />
<%
    }

    String closeOption = request.getParameter("closeOption");
    if (closeOption == null)  closeOption = "N";
    String description = request.getParameter("des");
    if (description == null)   description = "";
    String requestedUsr = request.getParameter("usr");
    String usr = "Teacher".equalsIgnoreCase(requestedUsr) ? "Teacher" : "Admin";
    String portalInitial = "Teacher".equals(usr) ? "T" : "A";
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title><%= usr %> Login - UMS Online</title>
        <link href="../extra/css/style.css" rel="stylesheet" type="text/css">
        <script src="../Images/encode.js"></script>
        <script src="../js/md5.js"></script>
        <script>
            function preventBack() 
            {
                window.history.forward();
            }

            setTimeout(preventBack, 0);
            window.onunload = function () {};

            function chkUsrPass()
            {
                var form = document.adminLoginForm;
                if (form.adminUser.value.trim() === "" || form.adminPassword.value === "") 
                {
                    alert("Please fill in the username and password fields.");
                    return false;
                }
                form.adminPassword.value = Encrypt(form.adminPassword.value);
                return true;
            }

            function hasInvalidChar(val) 
            {
                return val.indexOf("=") >= 0 || val.indexOf("'") >= 0 || val.indexOf("-") >= 0 || val.indexOf("*") >= 0 || val.indexOf("\"") >= 0;
            }

            function MM_callJS(jsStr) 
            {
                return eval(jsStr);
            }
        </script>
    </head>
<% 
    if ("Y".equals(closeOption)) 
    { 
%>
    <body onload="window.close();">
<% 
    }else
    {
%>
    <body onload="document.adminLoginForm.adminUser.focus();">
<% 
    }
%>
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
                    <a href="<%= escapeHtml(url) %>" class="ums-site-link">UMS Home</a>
                </div>
            </header>
            <main class="ums-auth-main">
                <section class="ums-auth-shell">
                    <div class="ums-auth-info">
                        <div class="ums-auth-icon"><%= portalInitial %></div>
                        <h2><%= usr %> Portal</h2>
                        <p>Sign in to access UMS online services, academic resources and authorized university functions.</p>
                        <div class="ums-auth-note">
                            <strong>Security note:</strong><br>Always sign out after using UMS Online Services, especially on a shared computer.
                        </div>
                    </div>
                    <div class="ums-auth-form-panel">
                        <p class="ums-auth-eyebrow">Secure Access</p>
                        <h2 class="ums-auth-title"><%= usr %> Login</h2>
                        <p class="ums-auth-subtitle">Enter your UMS username and password to continue.</p>
<% 
    if (!description.trim().isEmpty()) 
    { 
%>
                    <div class="ums-auth-alert"><%= escapeHtml(description) %></div>
<% 
    } 
%>
                        <form name="adminLoginForm"  method="post"  action="AdminProcessLogin.jsp" onsubmit="return chkUsrPass();">
                            <div class="ums-form-group">
                                <label class="ums-form-label" for="adminUser">Username</label>
                                <input id="adminUser" name="adminUser" type="text" maxlength="20" tabindex="1"  autocomplete="username" required>
                            </div>
                            <div class="ums-form-group">
                                <label class="ums-form-label" for="adminPassword">Password</label>
                                <input type="hidden" name="loginTime">
                                <input id="adminPassword" name="adminPassword" type="password" tabindex="2" autocomplete="current-password" required>
                            </div>
                            <div class="ums-auth-row">
                                <a href="AdminForgetPass.jsp?usr=<%= usr %>" name="frgtpass" tabindex="4" class="ums-forgot-link">
                                    Forgot Password?
                                </a>
                            </div>
                            <button name="Submit" value="Submit" tabindex="3" type="submit"class="ums-auth-submit">Sign In</button>
                        </form>
                        <div class="ums-auth-back">
                            <a href="../index.jsp">&larr; Back to portal selection</a>
                        </div>
                    </div>
                </section>
            </main>
            <footer class="ums-footer">
                &copy; <%= java.time.Year.now().getValue() %> <strong><%=Functions.getParameters("uniName")%></strong>. <%=Functions.getParameters("uniRights")%>
            </footer>
        </div>
    </body>
</html>
