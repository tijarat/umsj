<%@ page contentType="text/html; charset=iso-8859-1" language="java" import="java.sql.*, java.util.*,com.towertech.ucp.util.*" session = "true" errorPage="../error.jsp" %>
<%@ include file="../shared/nocache.inc"%>
<%@ include file="../shared/findReplace.jsp"%>
<jsp:useBean id="pool" scope="application" class="com.towertech.ucp.DB.ConnectionPool"/>
<%!
    public void log(String message,String user)
    {
      System.out.println(new java.util.Date() + "::AdminCity.jsp::" + user + "::" + message);
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
%>
<html>
    <head>        
        <title>Define City</title>
        <script language="JavaScript" type="text/JavaScript"></script>
        <link href="../Images/style.css" rel="stylesheet" type="text/css">
        <script language="JavaScript" type="text/JavaScript">
            <!--
            function changeIt(elm)
            {
                if(parent.frames.length==0) return;
                var obj = parent.frames.leftFrame.document.links;
                for(ctr=0;ctr<obj.length;ctr++) 
                    if(obj[ctr].href.indexOf(elm) > 0)
                        obj[ctr].style.cssText = "color:#000000; text-decoration:underline; font-weight:bold";
                    else
                        obj[ctr].style.cssText = "color:#006699";
             }
             -->
        </script>
    </head>
    <body onLoad="changeIt('AdminCity.jsp');">
        <table width="100%" class="table_common" align="center" cellpadding="0" cellspacing="0">
            <tr><th class="table_title" scope="col">Define City</th></tr>
        </table>
        <hr>
        <table>
            <tr><td class="normaltextboldRed" colspan="2"><%= nvl(request.getParameter("msg"))%></td></tr>
        </table>
        <form action="AdminProcessAddCity.jsp" method="post" name="cityForm" id="universityForm">
<%
    String msg= "",sql = "";
    java.sql.Statement stmt = null;
    Connection con = null;
    java.sql.ResultSet rs = null;
      
    try
    {
        con = adminSession.con;
        msg= request.getParameter("msg");
        stmt = con.createStatement();
        con.setAutoCommit(false);
%>
            <table width="60%" class="table_common" align="center">
                
                <tr>
                    <td class="table_sub_title_bold">&nbsp; City Name*</td>
                    <td class="record_cell_light"><input name="cityNme" onInvalid="this.setCustomValidity('Please enter Valid City Name. only character and . allowed');" oninput="setCustomValidity('')" pattern="[A-Za-z., ]{3,30}" required="required" type="text" id="cityNme" maxlength="30"/></td>                    
                </tr>
                <tr><td colspan="5"  align="center"><input type="submit" name="Submit" value="Add"></td></tr>
            </table>
        </form>
        <fieldset><legend class="table_title_small">Building</legend>
            <div id="navbtns1" align="center"></div>
            <table width="100%" border="0" align="center">
                <tr class="table_sub_title_bold">
                    <td>Sr.No</td>
                    <td>City Name</td>
                    <td colspan="2">Options</td>
                </tr>
<%
        sql =  "SELECT * FROM UCP.CITY_MASTER ORDER BY CITY_NAME ";
        rs = stmt.executeQuery(sql);
        int count = 1;
        while (rs.next()) 
        {
%>
                <tr class="record_cell_light">
                    <td  accept-charset="utf-8"><%= count++%></td>
                    <td><%= rs.getString("CITY_NAME")%></td>
                    <td width="5%"><a href="AdminEditCity.jsp?cityMasId=<%=rs.getString(1)%>&cityNme=<%=rs.getString(2)%>" class="body_links2">Edit</a></td>
                    <td width="5%"><a href="AdminProcessDeleteCity.jsp?cityMasId=<%=rs.getString(1)%>" onClick="return confirm('Are you sure you want to delete?')" class="body_links2">Delete</a></td>
<%        }
%>                </tr>
<%
    }catch(Exception exp)
    {
        throw new Exception(exp.getMessage());
    }finally
    {
        if(rs != null) rs.close();
        if(stmt != null) stmt.close();
    }
%>
            </table>
        </fieldset>
    </body>
</html>