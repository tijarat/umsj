<%@ page contentType="text/html; charset=UTF-8" language="java" import="java.net.URLEncoder" pageEncoding="UTF-8" %>
<%!
    public void log(String message, String user)
    {
        System.out.println(new java.util.Date() + "::AdminHome.jsp::" + user + "::" + message);
    }
%>
<%
    com.towertech.UMS.util.AdminSession adminSession = (com.towertech.UMS.util.AdminSession) session.getAttribute("adminSession");
    if(adminSession == null || adminSession.con == null)
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

    String notification = "";
    String expStatus = com.towertech.UMS.util.GlobalFunctions.passwordExpireStatus( adminSession.con, adminSession.user );

    if("EXPIRED".equalsIgnoreCase(expStatus))
        notification = "Change Password";
    else if("WARNING".equalsIgnoreCase(expStatus))
        notification = com.towertech.UMS.util.GlobalFunctions.passwordExpireRemaningDays( adminSession.con, adminSession.user );
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
        <link href="../extra/css/style.css" rel="stylesheet" type="text/css">

        <script src="../js/jquery-3.6.0.min.js" type="text/javascript"></script>
        <script src="../js/select2.min.js" type="text/javascript"></script>
    </head>
    <body class="ums-admin-home-body">
        <div class="ums-admin-shell">
            <div class="ums-admin-top-section">
                <jsp:include page="AdminHomeTop.jsp">
                    <jsp:param name="notification" value="<%=notification%>"/>
                </jsp:include>
            </div>
            <div class="ums-admin-workspace<%=passwordExpired ? " ums-admin-workspace-single" : ""%>">
<%
            if(!passwordExpired)
            {
%>
                    <iframe
                        name="leftFrame"
                        class="ums-admin-nav-frame"
                        src="AdminHomeLeft.jsp"
                        title="UMS Navigation">
                    </iframe>
<%
            }
%>
                <iframe
                    name="mainFrame"
                    id="mainFrame"
                    class="ums-admin-main-frame"
                    src="<%=mainFrameUrl%>"
                    title="UMS Workspace">
                </iframe>
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
