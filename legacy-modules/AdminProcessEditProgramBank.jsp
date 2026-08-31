<%@ page contentType="text/html; charset=windows-1252" language="java" import="java.sql.PreparedStatement,java.sql.Connection" session="true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.towertech.ucp.DB.ConnectionPool"/>
<%@page import="com.towertech.ucp.util.AdminSession"%>
<%@ include file="../shared/findReplace.jsp"%>
<%@ include file="../shared/nocache.inc"%>

<%!
    public void log(String message, String user) 
    {
        System.out.println(new java.util.Date() + "::AdminProcessEditProgramBank.jsp::" + user + "::" + message);
    }
%>
<%
    AdminSession adminSession = (AdminSession) session.getAttribute("adminSession");
    if (adminSession == null || adminSession.con == null) 
    {
        log("Session Not Found", "Invalid");
%>
<jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/>
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

    // Extract Request Parameters
    String bankCde      = nvl(request.getParameter("bankCde"));
    String bankId       = nvl(request.getParameter("bankId"));
    String acctNbr      = nvl(request.getParameter("acctNbr"));
    String branchTxt    = nvl(request.getParameter("branchTxt"));
    String onlineInd    = nvl(request.getParameter("onlineInd"), "N");
    String activeInd    = nvl(request.getParameter("activeInd"), "N"); 
    String showInd      = nvl(request.getParameter("showInd"), "N"); 
    String showAccount  = nvl(request.getParameter("showAccount"), "N");
    String bankRemarks  = nvl(request.getParameter("bankRemarks"));

    if ("OL".equalsIgnoreCase(bankCde) || "CDN".equalsIgnoreCase(bankCde)) 
    {
        acctNbr = "000";
        showInd = "N";
        branchTxt = "Online";
    }

    String sql = "UPDATE UCP.BANK SET ACCOUNT_NBR = ?, SHOW_ACCOUNT = ?, ONLINE_IND = ?, ACTIVE_IND = ?, SHOW_IND = ?, BANK_REMARKS = ? WHERE BANK_ID = ?";
    Connection con = adminSession.con;
    PreparedStatement pstmt = null;
    
    try 
    {
        con.setAutoCommit(false);
        
        pstmt = con.prepareStatement(sql);
        pstmt.setString(1, acctNbr);
        pstmt.setString(2, showAccount);
        pstmt.setString(3, onlineInd);
        pstmt.setString(4, activeInd);
        pstmt.setString(5, showInd);
        pstmt.setString(6, bankRemarks);
        pstmt.setLong(7, Long.parseLong(bankId));

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
        throw new Exception("Error updating Program Bank: " + exp.getMessage(), exp);
    }
    finally
    {
        if (pstmt != null)
        {
            try { pstmt.close(); } catch (Exception ignored) {}
        }
    }
%>