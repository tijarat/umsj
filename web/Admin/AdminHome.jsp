<%@ page contentType="text/html; charset=UTF-8" language="java" import="java.net.URLEncoder" pageEncoding="UTF-8" errorPage="../error.jsp"%>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<%!
    public void log(String message, String user)
    {
        System.out.println(new java.util.Date() + "::AdminHome.jsp::" + user + "::" + message);
    }
%>
<%
    com.ums.packages.LocalSession adminSession =  (com.ums.packages.LocalSession) session.getAttribute("adminSession");
    if(adminSession == null)
    {
        log("Session Not Found", "Invalid");
%>
        <jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/>
<%
        return;
    }

    if(!response.isCommitted())
    {
        response.setHeader("Pragma", "no-cache");
        response.setHeader("Expires", "0");
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    }
    java.sql.Connection con =  con = pool.getConnection();
    String notification = "";
    String expStatus = com.ums.functions.Functions.passwordExpireStatus(con, adminSession.user );

    if("EXPIRED".equalsIgnoreCase(expStatus))
        notification = "Change Password";
    else if("WARNING".equalsIgnoreCase(expStatus))
        notification = com.ums.functions.Functions.passwordExpireRemaningDays(con, adminSession.user );
    String emailWarning = "true".equalsIgnoreCase(request.getParameter("emailWarning")) ? "true" : "false";
    String cellWarning = "true".equalsIgnoreCase(request.getParameter("cellWarning")) ? "true" : "false";
    String nicWarning = "true".equalsIgnoreCase(request.getParameter("nicWarning")) ? "true" : "false";

    boolean passwordExpired = "Change Password".equalsIgnoreCase(notification);
    String encodedNotification = URLEncoder.encode(notification == null ? "" : notification, "UTF-8");

    String mainFrameUrl;
    if(passwordExpired)
        mainFrameUrl = "AdminChangePass.jsp?des=Your%20Password%20has%20been%20expired.";
    else
        mainFrameUrl = "AdminHomeMain.jsp?notification=" + encodedNotification + "&emailWarning=" + emailWarning + "&cellWarning=" + cellWarning + "&nicWarning=" + nicWarning;
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>UMS Administration</title>

        <link href="../css/select2.min.css" rel="stylesheet" type="text/css">
        <link href="../extra/css/style.css?v=20260829-2" rel="stylesheet" type="text/css">

        <script src="../js/jquery-3.6.0.min.js" type="text/javascript"></script>
        <script src="../js/select2.min.js" type="text/javascript"></script>
    </head>
    <body class="ums-admin-home-body">
        <div id="umsAdminPage">
            <header id="umsAdminHeader">
                <jsp:include page="AdminHomeTop.jsp">
                    <jsp:param name="notification" value="<%=notification%>"/>
                </jsp:include>
            </header>

            <div id="umsAdminBody" class="<%=passwordExpired ? "no-sidebar" : ""%>">
<%
            if(!passwordExpired)
            {
%>
                <aside id="umsAdminSidebar">
                    <iframe
                        name="leftFrame"
                        id="leftFrame"
                        src="AdminHomeLeft.jsp"
                        frameborder="0"
                        scrolling="no"
                        title="UMS Navigation"></iframe>
                </aside>
<%
            }
            pool.close(con);
%>
                <main id="umsAdminContent">
                    <iframe
                        name="mainFrame"
                        id="mainFrame"
                        src="<%=mainFrameUrl%>"
                        frameborder="0"
                        title="UMS Workspace"></iframe>
                </main>
            </div>
        </div>
        <script>
            function formatFaculty(state)
            {
                if(!state.id)
                {
                    return state.text;
                }

                var elementClass = $(state.element).attr("class") || "";
                return $("<span>").addClass(elementClass).text(state.text);
            }

            $(document).ready(function()
            {
                $(".ums-working-faculty").select2({
                    placeholder: "Search Faculty...",
                    allowClear: false,
                    templateResult: formatFaculty,
                    templateSelection: formatFaculty,
                    width: "100%"
                }).on("select2:open", function()
                {
                    var searchField = document.querySelector(".select2-search__field");
                    if(searchField)
                    {
                        searchField.focus();
                    }
                });
            });
        </script>
    </body>
</html>
