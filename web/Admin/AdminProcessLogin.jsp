<%@page import="com.ums.functions.Functions"%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*,java.net.*,java.io.*,java.util.*,jakarta.servlet.http.HttpSession"  session="true" errorPage="../error.jsp"   trimDirectiveWhitespaces="true" %>
<%!
    private void log(String message, String user)
    {
        System.out.println( new java.util.Date() + "::AdminProcessLogin.jsp::" + nvl(user) +"::" + nvl(message));
    }

    private String nvl(String value)
    {
        return value == null ? "" : value.trim();
    }

    private boolean isBlank(String value)
    {
        return value == null || value.trim().length() == 0;
    }

    private String limit(String value, int maxLength)
    {
        String text = nvl(value);
        if(text.length() <= maxLength)return text;
        return text.substring(0, maxLength);
    }

    private String firstForwardedIp(String value)
    {
        String text = nvl(value);
        if(text.length() == 0)  return "";
        int comma = text.indexOf(',');
        if(comma >= 0) text = text.substring(0, comma);
        return text.trim();
    }

    private String getAccessIp(jakarta.servlet.http.HttpServletRequest request)
    {
        String ip = firstForwardedIp(request.getHeader("X-Forwarded-For"));
        if(isBlank(ip)) ip = nvl(request.getHeader("X-Real-IP"));
        if(isBlank(ip)) ip = nvl(request.getRemoteAddr());
        return ip;
    }

    private boolean hasIllegalUserName(String user)
    {
        if(isBlank(user)) return true;
        String lower = user.toLowerCase(Locale.ENGLISH);
        String[] invalid ={ ";", "'", "\"", "\\", "=", "--", "#", "&", "*", " ","0x", "02216", "8726", "0027"};
        for(int i = 0; i < invalid.length; i++)
        {
            if(lower.indexOf(invalid[i].toLowerCase(Locale.ENGLISH)) >= 0) return true;
        }
        return false;
    }

    private int intValue(String value, int defaultValue)
    {
        try
        {
            return Integer.parseInt(nvl(value));
        }catch(Exception e)
        {
            return defaultValue;
        }
    }

    private String getBrowserName(String userAgent)
    {
        String ua = nvl(userAgent);
        if(ua.indexOf("Edg/") >= 0 || ua.indexOf("EdgiOS/") >= 0) return "Microsoft Edge";
        if(ua.indexOf("OPR/") >= 0 || ua.indexOf("OPiOS/") >= 0) return "Opera";
        if(ua.indexOf("Firefox/") >= 0 || ua.indexOf("FxiOS/") >= 0) return "Mozilla Firefox";
        if(ua.indexOf("Chrome/") >= 0 || ua.indexOf("CriOS/") >= 0) return "Google Chrome";
        if(ua.indexOf("Safari/") >= 0) return "Safari";
        return "Unknown";
    }

    private String getBrowserVersion(String userAgent)
    {
        String ua = nvl(userAgent);
        String token = null;
        if(ua.indexOf("Edg/") >= 0) token = "Edg/";
        else if(ua.indexOf("EdgiOS/") >= 0) token = "EdgiOS/";
        else if(ua.indexOf("OPR/") >= 0) token = "OPR/";
        else if(ua.indexOf("OPiOS/") >= 0) token = "OPiOS/";
        else if(ua.indexOf("Firefox/") >= 0) token = "Firefox/";
        else if(ua.indexOf("FxiOS/") >= 0) token = "FxiOS/";
        else if(ua.indexOf("Chrome/") >= 0) token = "Chrome/";
        else if(ua.indexOf("CriOS/") >= 0) token = "CriOS/";
        else if(ua.indexOf("Version/") >= 0 && ua.indexOf("Safari/") >= 0) token = "Version/";

        if(token == null) return "";
        int start = ua.indexOf(token);
        if(start < 0) return "";
        start += token.length();

        int end = ua.indexOf(' ', start);
        if(end < 0) end = ua.length();
        return ua.substring(start, end);
    }

    private String getOperatingSystem(String userAgent)
    {
        String ua = nvl(userAgent);
        if(ua.indexOf("Windows NT 10.0") >= 0) return "Windows 10/11";
        if(ua.indexOf("Windows NT 6.3") >= 0) return "Windows 8.1";
        if(ua.indexOf("Windows NT 6.2") >= 0) return "Windows 8";
        if(ua.indexOf("Windows NT 6.1") >= 0) return "Windows 7";
        if(ua.indexOf("Android") >= 0) return "Android";
        if(ua.indexOf("iPhone") >= 0) return "iOS";
        if(ua.indexOf("iPad") >= 0) return "iPadOS";
        if(ua.indexOf("Mac OS") >= 0 || ua.indexOf("Macintosh") >= 0) return "macOS";
        if(ua.indexOf("Linux") >= 0) return "Linux";
        return "Unknown";
    }

    private String getDeviceType(String userAgent)
    {
        String ua = nvl(userAgent).toLowerCase(Locale.ENGLISH);

        if(ua.indexOf("ipad") >= 0 || ua.indexOf("tablet") >= 0) return "Tablet";
        if(ua.indexOf("android") >= 0 && ua.indexOf("mobile") < 0) return "Tablet";
        if(ua.indexOf("mobile") >= 0 || ua.indexOf("iphone") >= 0 || ua.indexOf("android") >= 0) return "Mobile";
        return "Desktop";
    }

    private String jsonValue(String json, String key)
    {
        if(json == null) return "";
        String token = "\"" + key + "\"";
        int pos = json.indexOf(token);
        if(pos < 0) return "";
        pos = json.indexOf(':', pos + token.length());
        if(pos < 0) return "";
        pos++;
        while(pos < json.length() && Character.isWhitespace(json.charAt(pos))) pos++;
        if(pos >= json.length()) return "";

        if(json.charAt(pos) == '"')
        {
            pos++;
            StringBuilder value = new StringBuilder();
            boolean escaped = false;
            while(pos < json.length())
            {
                char c = json.charAt(pos++);
                if(escaped)
                {
                    value.append(c);
                    escaped = false;
                }
                else if(c == '\\')
                {
                    escaped = true;
                }
                else if(c == '"')
                {
                    break;
                }
                else
                {
                    value.append(c);
                }
            }
            return value.toString();
        }

        int end = json.indexOf(',', pos);
        if(end < 0) end = json.indexOf('}', pos);
        if(end < 0) end = json.length();
        return json.substring(pos, end).trim();
    }

    private java.util.Map<String,String> getIpInfo(String ip)
    {
        java.util.Map<String,String> result = new java.util.HashMap<String,String>();
        HttpURLConnection conn = null;
        BufferedReader reader = null;

        try
        {
            String token = "326c0bde1b1352";
            String apiUrl = "https://api.ipinfo.io/lite/" + URLEncoder.encode(ip, "UTF-8") + "?token=" + URLEncoder.encode(token, "UTF-8");
            URL url = new URL(apiUrl);
            conn = (HttpURLConnection)url.openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(5000);
            conn.setRequestProperty("Accept", "application/json");

            int status = conn.getResponseCode();
            InputStream stream = status >= 200 && status < 300 ? conn.getInputStream() : conn.getErrorStream();
            reader = new BufferedReader(new InputStreamReader(stream, "UTF-8"));

            StringBuilder json = new StringBuilder();
            String line;
            while((line = reader.readLine()) != null) json.append(line);

            result.put("status", status >= 200 && status < 300 ? "SUCCESS" : "FAILED");
            result.put("error", status >= 200 && status < 300 ? "" : "HTTP " + status);
            result.put("ip", jsonValue(json.toString(), "ip"));
            result.put("country", jsonValue(json.toString(), "country"));
            result.put("asn", jsonValue(json.toString(), "asn"));
            result.put("org", jsonValue(json.toString(), "as_name"));
        }
        catch(Exception e)
        {
            result.put("status", "FAILED");
            result.put("error", e.toString());
        }
        finally
        {
            try { if(reader != null) reader.close(); } catch(Exception e) {}
            if(conn != null) conn.disconnect();
        }

        return result;
    }

    private void updateLog(jakarta.servlet.http.HttpServletRequest request, String user,String message, boolean success,Connection con) throws SQLException
    {
        String sql =
            "INSERT INTO UMS.USER_LOG " +
            "(USER_LOG_ID, TMS, USER_NME, PWD, " +
            " PUBLIC_IP, REMOTE_IP, X_FORWARD_IP, " +
            " BROWSER, WINDOWS, DEVICE, TIMEZONE, SCREEN, " +
            " CPU_CORE, RAM, GPU, NETWORK_TYPE, " +
            " COUNTRY, REGION, ISP, LOOKUP_ERROR) " +
            "VALUES " +
            "(UMS.SEQ_USER_LOG_ID.NEXTVAL, SYSTIMESTAMP, ?, ?, " +
            " ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        String remoteIp = nvl(request.getRemoteAddr());
        String forwardedIp = nvl(request.getHeader("X-Forwarded-For"));
        String publicIp = firstForwardedIp(forwardedIp);
        if(publicIp.length() == 0) publicIp = nvl(request.getHeader("X-Real-IP"));
        if(publicIp.length() == 0) publicIp = remoteIp;

        java.util.Map<String,String> ipInfo = getIpInfo(publicIp);
        String ipCountry = nvl(ipInfo.get("country"));
        String ipAsn = nvl(ipInfo.get("asn"));
        String ipOrg = nvl(ipInfo.get("org"));
        String ipLookupStatus = nvl(ipInfo.get("status"));
        String ipLookupError = nvl(ipInfo.get("error"));
        String userAgent = nvl(request.getParameter("browserUserAgent"));
        if(userAgent.length() == 0) userAgent = nvl(request.getHeader("User-Agent"));
        String browser = getBrowserName(userAgent);
        String browserVersion = getBrowserVersion(userAgent);
        if(browserVersion.length() > 0) browser += " " + browserVersion;
        String screenWidth = nvl(request.getParameter("screenWidth"));
        String screenHeight = nvl(request.getParameter("screenHeight"));
        String screen = "";
        if(screenWidth.length() > 0 || screenHeight.length() > 0) screen = screenWidth + "x" + screenHeight;
        String networkType = nvl(request.getParameter("networkType"));
        String downlink = nvl(request.getParameter("networkDownlink"));
        String rtt = nvl(request.getParameter("networkRtt"));
        if(downlink.length() > 0)  networkType += (networkType.length() == 0 ? "" : " ") + "DL:" + downlink;
        if(rtt.length() > 0) networkType += (networkType.length() == 0 ? "" : " ") + "RTT:" + rtt;
        String browserId = nvl(request.getParameter("browserId"));
        String device = getDeviceType(userAgent);
        if(browserId.length() > 0) device += " ID:" + browserId;
        String isp = ipOrg;
        if(ipAsn.length() > 0) isp += (isp.length() == 0 ? "" : " ") + ipAsn;
        String auditMessage = (success ? "SUCCESS::" : "FAIL::") + nvl(message);
        if(ipLookupStatus.length() > 0 || ipLookupError.length() > 0)
        {
            auditMessage += " | IP_LOOKUP:" + ipLookupStatus + (ipLookupError.length() > 0 ? ":" + ipLookupError : "");
        }

        try(PreparedStatement pstmt = con.prepareStatement(sql))
        {
            int i = 1;
            pstmt.setString(i++, limit(user, 100));
            pstmt.setNull(i++, Types.VARCHAR);
            pstmt.setString(i++, limit(publicIp, 100));
            pstmt.setString(i++, limit(remoteIp, 100));
            pstmt.setString(i++, limit(forwardedIp, 100));
            pstmt.setString(i++, limit(browser, 200));
            pstmt.setString(i++, limit(getOperatingSystem(userAgent), 200));
            pstmt.setString(i++, limit(device, 200));
            pstmt.setString(i++, limit(request.getParameter("timezone"), 50));
            pstmt.setString(i++, limit(screen, 10));
            pstmt.setString(i++, limit(request.getParameter("cpuCores"), 10));
            pstmt.setString(i++, limit(request.getParameter("deviceMemory"), 10));
            pstmt.setString(i++, limit(request.getParameter("gpuInfo"), 100));
            pstmt.setString(i++, limit(networkType, 100));
            pstmt.setString(i++, limit(ipCountry, 100));
            pstmt.setString(i++, "");
            pstmt.setString(i++, limit(isp, 100));
            pstmt.setString(i++, limit(auditMessage, 500));
            pstmt.executeUpdate();
        }
    }

    private void auditLogin(jakarta.servlet.http.HttpServletRequest request, com.ums.db.Pool pool, String user, String message, boolean success) throws Exception 
    {
        Connection auditCon = null;


        try
        {
            auditCon = pool.getConnection();
            if(auditCon == null)
            {
                log("Audit connection is null", user);
                return;
            }

            updateLog(request, user, message, success, auditCon);
            if(!auditCon.getAutoCommit()) auditCon.commit();
        }catch(Exception e)
        {
            if(!auditCon.getAutoCommit()) auditCon.rollback();
            log("Unable to save USER_LOG: " + e.getMessage(), user);
        }finally
        {
            pool.close(auditCon);
        }
    }

    private void redirectLogin(jakarta.servlet.http.HttpServletResponse response,String message) throws java.io.IOException
    {
        response.sendRedirect( "AdminLogin.jsp?des=" + URLEncoder.encode(nvl(message), "UTF-8"));
    }

    private void invalidateExistingUserSession( com.ums.packages.Container userContainer, String user, HttpSession currentSession)  throws Exception   
    {
        try
        {
            if(!userContainer.isUserExisit(user)) return;
            HttpSession oldSession = userContainer.getUserSession(user);
            userContainer.removeUser(user);
            if(oldSession != null && oldSession != currentSession)
            {
                try
                {
                    oldSession.invalidate();
                }catch(Exception e)
                {
                    log( "Unable to invalidate previous session: " + e.getMessage(), user);
                }
            }
        }catch(Exception e)
        {
            log("Unable to clear previous session: " + e.getMessage(), user);
        }
    }
%>

<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<jsp:useBean id="userContainer" scope="application" class="com.ums.packages.Container"/>
<jsp:useBean id="verification" scope="application" class="com.ums.packages.Security"/>

<%
    request.setCharacterEncoding("UTF-8");
    response.setHeader("Pragma", "no-cache");
    response.setHeader("Expires", "0");
    response.setHeader( "Cache-Control",  "private, no-store, no-cache, must-revalidate");
    response.setHeader("X-Content-Type-Options", "nosniff");
    String rawUser = request.getParameter("adminUser");
    String password = request.getParameter("adminPassword");

    if(isBlank(rawUser) || isBlank(password))
    {
        auditLogin( request, pool, nvl(rawUser).toUpperCase(Locale.ENGLISH), "Invalid User or Password", false);
        redirectLogin(response, "Invalid User or Password");
        return;
    }

    String user = rawUser.trim().toUpperCase(Locale.ENGLISH);

    if(user.length() > 100 || password.length() > 2000)
    {
        auditLogin( request, pool, user, "Username or password exceeds the allowed length", false );
        redirectLogin(response, "Invalid User or Password");
        return;
    }

    if(hasIllegalUserName(user))
    {
        auditLogin( request, pool,  user, "Illegal characters are not allowed in username",false);
        redirectLogin(response,"Illegal characters are not allowed in username");
        return;
    }

    Connection con = null;
    boolean authenticationSucceeded = false;

    try
    {
        con = pool.getConnection();

        if(con == null) throw new SQLException("Database connection is not available.");
        if(con.getAutoCommit()) con.setAutoCommit(false);
        boolean blockedUser = false;
        String blockMessage = "";

        String blockSql ="SELECT MESSAGE FROM UMS.USER_BLOCK_LIST WHERE UPPER(USER_NME) = ?";
        try(PreparedStatement ps = con.prepareStatement(blockSql))
        {
            ps.setString(1, user);
            try(ResultSet rs = ps.executeQuery())
            {
                if(rs.next())
                {
                    blockedUser = true;
                    blockMessage = nvl(rs.getString("MESSAGE"));
                    if(blockMessage.length() == 0) blockMessage = "This user account is blocked.";
                }
            }
        }

        if(blockedUser)
        {
            auditLogin(request, pool, user, blockMessage, false);
            pool.close(con);
            redirectLogin(response, blockMessage);
            return;
        }

        String accessIp = getAccessIp(request);
        boolean restrictedUser = false;
        boolean validIp = false;

        String ipSql ="SELECT IP FROM UMS.WEB_USERS_IP WHERE UPPER(USER_NME) = ?";
        try(PreparedStatement ps = con.prepareStatement(ipSql))
        {
            ps.setString(1, user);
            try(ResultSet rs = ps.executeQuery())
            {
                while(rs.next())
                {
                    restrictedUser = true;
                    String allowedIp = nvl(rs.getString("IP"));
                    if(allowedIp.equals(accessIp))
                    {
                        validIp = true;
                        break;
                    }
                }
            }
        }

        if(restrictedUser && !validIp)
        {
            auditLogin(request, pool, user, "Not a valid access location", false );
            pool.close(con);
            redirectLogin(response, "Not a valid access location!");
            return;
        }

        boolean validUser = verification.verify(con, user, password, "Admin", request);
        String errorMessage = nvl(verification.getErrorMsg());
        if(!validUser)
        {
            if(errorMessage.length() == 0) errorMessage = "Invalid User or Password";
            auditLogin(request, pool, user, errorMessage, false);
            pool.close(con);
            redirectLogin(response, errorMessage);
            return;
        }

        authenticationSucceeded = true;
        invalidateExistingUserSession(userContainer, user, session);

        boolean isFaculty = false;
        boolean profileFound = false;

        String cellNbr = "",email = "",nic = "";

        String facultySql =
            "SELECT T.TCHR_ID, " +
            "       REPLACE(T.CELL_NBR, '-', '') CELL_NBR, " +
            "       REPLACE(T.NIC, '-', '') NIC, " +
            "       T.EMAIL_TXT " +
            "FROM UMS.WEB_USERS W " +
            "JOIN UMS.TEACHER T ON T.TCHR_ID = W.TCHR_ID " +
            "WHERE UPPER(W.USER_NME) = ?";

        try(PreparedStatement ps = con.prepareStatement(facultySql))
        {
            ps.setString(1, user);
            try(ResultSet rs = ps.executeQuery())
            {
                if(rs.next())
                {
                    isFaculty = rs.getObject("TCHR_ID") != null;
                    profileFound = true;
                    cellNbr = nvl(rs.getString("CELL_NBR"));
                    email = nvl(rs.getString("EMAIL_TXT"));
                    nic = nvl(rs.getString("NIC"));
                }
            }
        }

        if(!isFaculty)
        {
            String adminInfoSql =
                "SELECT REPLACE(I.CELL_NBR, '-', '') CELL_NBR, " +
                "       REPLACE(I.CNIC, '-', '') CNIC, " +
                "       I.EMAIL_TXT " +
                "FROM UMS.WEB_USERS W " +
                "JOIN UMS.WEB_USERS_INFO I ON I.USER_NME = W.USER_NME " +
                "WHERE UPPER(W.USER_NME) = ?";

            try(PreparedStatement ps = con.prepareStatement(adminInfoSql))
            {
                ps.setString(1, user);
                try(ResultSet rs = ps.executeQuery())
                {
                    if(rs.next())
                    {
                        profileFound = true;
                        cellNbr = nvl(rs.getString("CELL_NBR"));
                        email = nvl(rs.getString("EMAIL_TXT"));
                        nic = nvl(rs.getString("CNIC"));
                    }
                }
            }
        }

        String cellWarning = "false",emailWarning = "false",nicWarning = "false";
        if(profileFound)
        {
            if(cellNbr.length() != 11 || !cellNbr.startsWith("0")) cellWarning = "true";
            if(email.length() == 0 ||!email.toLowerCase(Locale.ENGLISH).endsWith("@UMS.edu.pk")) emailWarning = "true";
            if(nic.length() != 13) nicWarning = "true";
        }
%>
        <jsp:useBean id="adminSession" scope="session" class="com.ums.packages.LocalSession"/>
<%
        adminSession.start(con, user,accessIp, userContainer);
        adminSession.addUserSession(accessIp,con);
        adminSession.setIpAddress(accessIp);
        if(isBlank(adminSession.getWorkingFaculty()))
        {
            auditLogin(request,pool,user,"User does not have right on any faculty.",false );
            pool.close(con);
            try
            {
                session.invalidate();
            }catch(Exception ignore)
            {
            }

            redirectLogin( response,"User does not have right on any faculty." );
            return;
        }

        userContainer.addUser(user, session);
        session.setAttribute("isFaculty", Boolean.FALSE);
        if(isFaculty)
        {
            session.setMaxInactiveInterval(60 * 10);
            session.setAttribute("isFaculty", Boolean.TRUE);
        }else
            session.setMaxInactiveInterval(60 * 10);

        try
        {
            String sendSms = com.ums.functions.Functions.getEnviornmentValue( "Send SMS on Login",con);
            if("True".equalsIgnoreCase(sendSms) && !isFaculty && cellNbr.length() > 0)
            {
                String smsMsg ="User " + user + " logged in to Online MCOM Portal from IP." + accessIp + " at " + new java.util.Date();
                com.ums.functions.Functions.sendSMS(con, cellNbr, smsMsg, "Login",adminSession);
            }
        }catch(Exception e)
        {
            log("SMS notification failed: " + e.getMessage(), user);
        }

        String expStatus = "", remainDay = "";

        int warningDays = intValue( com.ums.functions.Functions.getEnviornmentValue("Passwords Expiry Warning Period",con),7);
        String expirySql =
            "SELECT CASE " +
            "         WHEN TO_DATE(EXP_DTE, 'DD-MM-RRRR') <= TRUNC(SYSDATE) " +
            "           THEN 'EXPIRED' " +
            "         WHEN TO_DATE(EXP_DTE, 'DD-MM-RRRR') - TRUNC(SYSDATE) " +
            "              BETWEEN 1 AND ? " +
            "           THEN 'WARNING' " +
            "         ELSE 'NOT EXPIRED' " +
            "       END RESULT, " +
            "       TO_DATE(EXP_DTE, 'DD-MM-YYYY') - TRUNC(SYSDATE) DAYS " +
            "FROM UMS.WEB_USERS " +
            "WHERE UPPER(USER_NME) = ?";

        try(PreparedStatement ps = con.prepareStatement(expirySql))
        {
            ps.setInt(1, warningDays);
            ps.setString(2, user);

            try(ResultSet rs = ps.executeQuery())
            {
                if(rs.next())
                {
                    expStatus = nvl(rs.getString("RESULT"));
                    remainDay = nvl(rs.getString("DAYS"));
                }
            }
        }catch(SQLException e)
        {
            log("Unable to determine password expiry: " + e.getMessage(), user);
        }

        auditLogin(request, pool, user, "Login completed", true);

        String homeUrl = "AdminHome.jsp"
                + "?emailWarning=" + URLEncoder.encode(emailWarning, "UTF-8")
                + "&cellWarning=" + URLEncoder.encode(cellWarning, "UTF-8")
                + "&nicWarning=" + URLEncoder.encode(nicWarning, "UTF-8");

        if("EXPIRED".equalsIgnoreCase(expStatus))
            homeUrl += "&notification=" + URLEncoder.encode("Change Password", "UTF-8");
        else if("WARNING".equalsIgnoreCase(expStatus))
            homeUrl += "&notification=" + URLEncoder.encode(remainDay, "UTF-8");

        pool.close(con);
        response.sendRedirect(homeUrl);
        return;
    }catch(Exception e)
    {
        log("Login processing error: " + e.getMessage(), user);
        if(authenticationSucceeded)
        {
            userContainer.removeUser(user);
            session.removeAttribute("adminSession");
        }

        if(con != null)
        {
            if(!con.getAutoCommit()) con.rollback();
            pool.close(con);
        }
        throw e;
    }
%>
