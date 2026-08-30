<%@ page contentType="text/html; charset=iso-8859-1" language="java" import="java.sql.*, java.util.*,com.towertech.ucp.util.*" session = "true" errorPage="../error.jsp" %>
<%@ include file="../shared/nocache.inc"%>
<%@ include file="../shared/findReplace.jsp"%>
<jsp:useBean id="pool" scope="application" class="com.towertech.ucp.DB.ConnectionPool"/>
<%!

public void log(String message,String user)
{
  System.out.println(new java.util.Date() + "::AdminCampus.jsp::" + user + "::" + message);
}
%>
<%
int prmSectionId = -1;
String prmSectionTxt="";

	com.towertech.ucp.util.AdminSession adminSession = (com.towertech.ucp.util.AdminSession)session.getAttribute("adminSession");
	if(adminSession == null || adminSession.con == null)
  {
    log("Session Not Found","Invalid");
%>
		<jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/>		
<%
  }

	if(!adminSession.hasRightsOn("City"))
	{
%>
		<jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over City service." />
<%
	}

    String msg= "",sql = "", cityNme = "", cityCde = "";
    java.sql.Statement stmt = null;
    Connection con = null;
    java.sql.ResultSet rs = null;
      
    try
    {
        cityNme = nvl(request.getParameter("cityNme"));
        con = adminSession.con;
        stmt = con.createStatement();
        con.setAutoCommit(false);
        sql =  "INSERT INTO UCP.CITY_MASTER VALUES(UCP.SEQ_CITY_MASTER_ID.NEXTVAL,'"+cityNme+"')";
        stmt.execute(sql);
        adminSession.addLog(sql, stmt);
        con.commit();
        msg = "City Added successfully";
    }catch(Exception exp)
    {
        con.rollback();
        msg = exp.getMessage();
    }finally
    {
        if(rs != null) rs.close();
        if(stmt != null) stmt.close();
    }
    response.sendRedirect("AdminCity.jsp?msg="+msg);
%>