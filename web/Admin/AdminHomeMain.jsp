<%@page import="com.ums.functions.Functions"%>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<%@ page contentType="text/html; charset=UTF-8" language="java" import="java.sql.*" pageEncoding="UTF-8" errorPage="../error.jsp"%>
<%!
    public void log(String message, String user)
    {
        System.out.println(new java.util.Date() + "::AdminHomeMain.jsp::" + user + "::" + message);
    }

    public String html(String value)
    {
        if(value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
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

    boolean isFaculty = Boolean.TRUE.equals(session.getAttribute("isFaculty"));
    boolean emailWarning = "true".equalsIgnoreCase(request.getParameter("emailWarning"));
    boolean cellWarning = "true".equalsIgnoreCase(request.getParameter("cellWarning"));
    boolean nicWarning = "true".equalsIgnoreCase(request.getParameter("nicWarning"));
    String notification = request.getParameter("notification");

    Connection con = pool.getConnection();

    String currentTerm = Functions.getCurrentTerm(adminSession.getWorkingFacultyId(),con);

    String lastLoginDate = null;
    String lastLoginTime = null;
    String lastLoginIp = null;

    String sessionSql =
        "SELECT TO_CHAR(US.LOGIN_DTE, 'DD-MM-RRRR') LOGIN_DTE, " +
        "TO_CHAR(US.LOGIN_DTE, 'HH:MI:SS PM') LOGIN_TIM, US.IP_ADDRESS " +
        "FROM USER_SESSION US " +
        "WHERE US.USER_SESSION_ID = (" +
        "SELECT MAX(USER_SESSION_ID) " +
        "FROM USER_SESSION " +
        "WHERE LOGOUT_DTE IS NOT NULL " +
        "AND USER_NME = ?)";

    try(PreparedStatement sessionStmt = con.prepareStatement(sessionSql))
    {
        sessionStmt.setString(1, adminSession.user);
        try(ResultSet sessionRs = sessionStmt.executeQuery())
        {
            if(sessionRs.next())
            {
                lastLoginDate = sessionRs.getString("LOGIN_DTE");
                lastLoginTime = sessionRs.getString("LOGIN_TIM");
                lastLoginIp = sessionRs.getString("IP_ADDRESS");
            }
        }
    }catch(SQLException e)
    {
        log("Unable to load previous session: " + e.getMessage(), adminSession.user);
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>UMS Home</title>
    <link href="../extra/css/style.css?v=20260829-2" rel="stylesheet" type="text/css">
</head>
<body class="ums-admin-main-body">
    <main class="ums-dashboard">
        <section class="ums-dashboard-status-grid">
            <div class="ums-dashboard-status">
                <span>Working Faculty</span>
                <strong><%=html(adminSession.getWorkingFaculty())%>0</strong>
            </div>
            <div class="ums-dashboard-status">
                <span>Current Term</span>
                <strong><%=html(currentTerm)%>0</strong>
            </div>
            <div class="ums-dashboard-status">
                <span>Working Term</span>
                <strong><%=html(adminSession.workingTerm)%>0</strong>
            </div>
        </section>
<%
        if(notification != null && !notification.trim().equals("") &&  !"null".equalsIgnoreCase(notification) && !"Change Password".equalsIgnoreCase(notification))
        {
%>
            <div class="ums-dashboard-alert ums-dashboard-alert-warning">
                Your password will expire in <strong><%=html(notification)%> day(s)</strong>.
                Please change it from the link in the top bar.
            </div>
<%
        }
        if(emailWarning || cellWarning || nicWarning)
        {
%>
            <div class="ums-dashboard-alert ums-dashboard-alert-danger">
                <strong>Your profile requires attention:</strong>
                <span>
<%
                    boolean separatorRequired = false;
                    if(emailWarning)
                    {
%>
                        Email
<%
                        separatorRequired = true;
                    }

                    if(cellWarning)
                    {
                        if(separatorRequired)
                        {
%>
                            ,
<%
                        }
%>
                        Cell Number
<%
                        separatorRequired = true;
                    }

                    if(nicWarning)
                    {
                        if(separatorRequired)
                        {
%>
                            ,
<%
                        }
%>
                        NIC
<%
                    }
%>
                </span>
            </div>
<%
        }
%>
        <section class="ums-dashboard-welcome">
            <div class="ums-dashboard-welcome-icon"><%=isFaculty ? "T" : "A"%></div>
            <div>
                <p class="ums-dashboard-eyebrow">Welcome</p>
                <h1><%=isFaculty ? "Teacher Services" : "Administrator Services"%></h1>
                <p>Use the navigation panel on the left to access the services available to your account. </p>
            </div>
        </section>
        <section class="ums-dashboard-info-grid">
            <div class="ums-dashboard-info-card">
                <div class="ums-dashboard-info-icon">S</div>
                <div>
                    <h2>Previous Session</h2>
<%
                    if(lastLoginDate != null)
                    {
%>
                        <p>Your last completed session was on<strong><%=html(lastLoginDate)%></strong> at<strong><%=html(lastLoginTime)%></strong>from <strong><%=html(lastLoginIp)%></strong>.</p>
<%
                    }else
                    {
%>
                        <p>Welcome to UMS Online. This is your first recorded completed session on this portal.</p>
<%
                    }
%>
                </div>
            </div>
<%
            if(isFaculty)
            {
%>
                <div class="ums-dashboard-info-card">
                    <div class="ums-dashboard-info-icon">T</div>
                    <div>
                        <h2>Session Timeout</h2>
                        <p>Your session will expire after<strong><%=session.getMaxInactiveInterval() / 60%> minutes</strong>of inactivity.</p>
                    </div>
                </div>
<%
            }
    pool.close(con);
%>
        </section>
    </main>
</body>
</html>
