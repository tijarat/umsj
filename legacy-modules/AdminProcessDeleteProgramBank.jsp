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
    }

    if (!adminSession.hasRightsOn("Program Bank")) 
    {
%>
<jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Program Bank service." />
<%  
    }

    String bankCde = "", progId = "", acctNbr = "", branchTxt = "", challanTitle = "", challanPrefix = "", onlineInd = "", activeInd = "";
    Statement stmt = null;
    ResultSet rs = null;
    String sql = "", msg = "record deleted successfully", showInd = "Y", bankId="";
    Connection con = null;
    try
    {
        con = adminSession.con;
        bankCde = nvl(request.getParameter("bankCde"));
        bankId = nvl(request.getParameter("bankId"));
        progId = nvl(request.getParameter("progId"));
        acctNbr = nvl(request.getParameter("acctNbr"));
        branchTxt = nvl(request.getParameter("branchTxt"));
        challanTitle = nvl(request.getParameter("challanTitle"));
        challanPrefix = nvl(request.getParameter("challanPrefix"));
        onlineInd = nvl(request.getParameter("onlineInd"),"N");
        activeInd = nvl(request.getParameter("activeInd"),"N"); 
        if(bankCde.equalsIgnoreCase("OL") || bankCde.equalsIgnoreCase("CDN"))
        {
            acctNbr = "000";
            showInd = "N";
            branchTxt = "Online";
        }
        stmt = con.createStatement();
        con.setAutoCommit(false);
        sql =   "DELETE FROM UCP.BANK WHERE BANK_ID = "+bankId;
        stmt.execute(sql);
        adminSession.addLog(sql, stmt);
        con.commit();

    }catch(Exception exp)
    {
        con.rollback();
        msg = "cannot delete recrod";
        throw new Exception(exp.getMessage());
    }finally
    {
        if(rs != null) rs.close();
        if(stmt != null) stmt.close();
    }

    response.sendRedirect("AdminProgramBank.jsp?msg="+msg);
%>
