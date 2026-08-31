<%@ page contentType="text/html; charset=windows-1252" language="java" import="java.sql.*, java.util.*,com.towertech.ucp.util.*" session = "true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.towertech.ucp.DB.ConnectionPool"/>
<%@ include file="../shared/nocache.inc"%>
<%@ include file="../shared/findReplace.jsp"%>
<%!
    public void log(String message, String user) 
    {
        System.out.println(new java.util.Date() + "::AdminProgramBank.jsp::" + user + "::" + message);
    }
%>
<%
    AdminSession adminSession = (AdminSession) session.getAttribute("adminSession");
    if (adminSession == null || adminSession.con == null) 
    {
        log("Session Not Found", "Invalid");
%>
<jsp:forward page= "../SessionExpire.jsp?des=Your Session/Connection closed please login again."/>
<%
        return;
    }

    if (!adminSession.hasRightsOn("Program Bank")) 
    {
%>
<jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Program Bank service." />
<%  
        return;
    }

    String bankCde      = nvl(request.getParameter("bankCde"));
    String progId       = nvl(request.getParameter("progId"));
    String acctNbr      = nvl(request.getParameter("acctNbr"));
    String branchTxt    = nvl(request.getParameter("branchTxt"));
    String challanTitle = nvl(request.getParameter("challanTitle"));
    String challanPrefix= nvl(request.getParameter("challanPrefix"));
    String onlineInd    = nvl(request.getParameter("onlineInd"), "N");
    String activeInd    = nvl(request.getParameter("activeInd"), "N"); 
    String bankRemarks  = nvl(request.getParameter("bankRemarks"));
    String showInd      = "Y";
    String showAccount  = "Y";

    if (bankCde.equalsIgnoreCase("OL") || bankCde.equalsIgnoreCase("CDN"))
    {
        acctNbr = "000";
        showInd = "N";
        branchTxt = "Online";
    }

    PreparedStatement pstmt = null;
    Connection con = null;
    
    String sql = "INSERT INTO UCP.BANK (BANK_ID, PROG_ID, BANK_TXT, ACCOUNT_NBR, BRANCH_TXT, " +
                 "BANK_CHALLAN_PREFIX, CHALLAN_TITLE, BANK_CDE, ACTIVE_IND, ONLINE_IND, SHOW_IND, SHOW_ACCOUNT, BANK_REMARKS) " +
                 "VALUES (SEQ_BANK_ID.NEXTVAL, ?, (SELECT BANK_NAME FROM UCP.BANK_MASTER WHERE BANK_CDE = ?), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

    try
    {
        con = adminSession.con;
        con.setAutoCommit(false);

        pstmt = con.prepareStatement(sql);
        pstmt.setLong(1, Long.parseLong(progId));
        pstmt.setString(2, bankCde);
        pstmt.setString(3, acctNbr);
        pstmt.setString(4, branchTxt);
        pstmt.setString(5, challanPrefix);
        pstmt.setString(6, challanTitle);
        pstmt.setString(7, bankCde);
        pstmt.setString(8, activeInd);
        pstmt.setString(9, onlineInd);
        pstmt.setString(10, showInd);
        pstmt.setString(11, showAccount);
        pstmt.setString(12, bankRemarks);

        pstmt.executeUpdate();
        adminSession.addLog(sql, pstmt);
        con.commit();
%>
    <jsp:forward page="AdminProgramBank.jsp"/>
<%
    }
    catch (Exception exp)
    {
        if (con != null)
        {
            try { con.rollback(); } catch (Exception ignored) {}
        }
        throw new Exception("Error inserting Program Bank: " + exp.getMessage(), exp);
    }
    finally
    {
        if (pstmt != null) 
        {
            try { pstmt.close(); } catch (Exception ignored) {}
        }
    }
%>