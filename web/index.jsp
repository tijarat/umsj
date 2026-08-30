<%@ page contentType="text/html; charset=UTF-8" import="com.ums.functions.Functions" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>UMS Online</title>
    <link href="extra/css/style.css" rel="stylesheet" type="text/css">
</head>
<%
    String servletPath = request.getServletPath();
    String servletPathReal = application.getRealPath(servletPath);
    String sep = servletPathReal.indexOf("\\") > 0 ? "\\" : "/";
    
    String reportPath = servletPathReal.substring(0, servletPathReal.lastIndexOf(sep))+sep+"WEB-INF";
    String rootPath = reportPath.substring(0, reportPath.lastIndexOf(sep));    
    Functions.setpath(rootPath, sep);
%>
<body>
    <div class="ums-page">
        <header class="ums-header">
            <div class="ums-header-inner">
                <div class="ums-brand">
                    <div class="ums-brand-mark"><%=Functions.getParameters("uniLogo")%></div>
                    <div>
                        <h1 class="ums-brand-title"><%=Functions.getParameters("uniPortalName")%></h1>
                        <p class="ums-brand-subtitle"><%=Functions.getParameters("uniPortalSubName")%></p>
                    </div>
                </div>
                <a href="http://www.plover.edu" target="_blank" rel="noopener noreferrer" class="ums-site-link">Visit UMS Website</a>
            </div>
        </header>
        <main class="ums-main">
            <section class="ums-intro">
                <h2><%=Functions.getParameters("uniTitle")%></h2>
                <p><%=Functions.getParameters("uniSubTitle")%></p>
            </section>
            <section class="ums-portal-grid">
                <a href="Student/StdLogin.jsp" class="ums-portal-card">
                    <div class="ums-portal-icon-student">S</div>
                    <h3><%=Functions.getParameters("uniStudentPortalTitle")%></h3>
                    <p><%=Functions.getParameters("uniStudentPortalText")%></p>
                    <span class="ums-login-button-student"><%=Functions.getParameters("uniStudentPortalButtonName")%></span>
                </a>
                <a href="Admin/AdminLogin.jsp?usr=Teacher" class="ums-portal-card">
                    <div class="ums-portal-icon">T</div>
                    <h3><%=Functions.getParameters("uniTeacherPortalTitle")%></h3>
                    <p><%=Functions.getParameters("uniTeacherPortalText")%></p>
                    <span class="ums-login-button"><%=Functions.getParameters("uniTeacherPortalButtonName")%></span>
                </a>
                <a href="Admin/AdminLogin.jsp" class="ums-portal-card">
                    <div class="ums-portal-icon">A</div>
                    <h3><%=Functions.getParameters("uniAdminPortalTitle")%></h3>
                    <p><%=Functions.getParameters("uniAdminPortalText")%></p>
                    <span class="ums-login-button"><%=Functions.getParameters("uniAdminPortalButtonName")%></span>
                </a>
            </section>
        </main>
        <footer class="ums-footer">
            &copy; <%= java.time.Year.now().getValue() %> <strong><%=Functions.getParameters("uniName")%></strong>. <%=Functions.getParameters("uniRights")%>
        </footer>
    </div>
    </body>
</html>
