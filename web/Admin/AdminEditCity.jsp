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
             
             function redirect(mainPage)
             {
                    document.cityForm.action = mainPage;
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
        <form action="AdminProcessEditCity.jsp" method="post" name="cityForm" id="universityForm">
<%
    String msg= "",sql = "", cityCde = "", cityNme = "",cityMasId = "";
     
    try
    {
        cityNme= request.getParameter("cityNme");
        cityMasId= request.getParameter("cityMasId");
%><input type="hidden" name="cityMasId" id="cityMasId" value="<%=cityMasId%>"/>
            <table width="60%" class="table_common" align="center">
                <tr>
                    <td class="table_sub_title_bold">&nbsp; City Name*</td>
                    <td class="record_cell_light"><input name="cityNme" value="<%=cityNme%>"  onInvalid="this.setCustomValidity('Please enter Valid City Name. only character and . allowed');" oninput="setCustomValidity('')" pattern="[A-Za-z., ]{3,30}" required="required" type="text" id="cityNme" maxlength="30"/></td>                    
                </tr>
                <tr>
                    <td></td>
                    <td align="center"><input type="submit" name="Submit" value="Update"></td>
                    
                    <td align="center"><input name="Submit" type="submit" value="Cancel" onClick="redirect('AdminCity.jsp')"></td>
                    <td></td>                    
                </tr>
            </table>
        </form>
<%
    }catch(Exception exp)
    {
        throw new Exception(exp.getMessage());
    }finally
    {
    }
%>
    </body>
</html>