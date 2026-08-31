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
%>
<html>
    <head>        
        <title>Registration</title>
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

            function MM_openBrWindow(theURL,winName,features) 
            { //v2.0
                window.open(theURL,winName,features);
            }

            //-->
        </script>
        <link href="../Images/style.css" rel="stylesheet" type="text/css">
    </head>
    <body onLoad="changeIt('AdminProgramBank.jsp');">
        <table width="100%" class="table_common" align="center" cellpadding="0" cellspacing="0">
            <tr>
                <th class="table_title" scope="col">
                    Define Program Bank
                </th>
            </tr>
        </table>
        <hr>
        <form action="AdminProcessEditProgramBank.jsp" method="post" name="programBankForm" id="programBankForm">
            <table width="100%" class="table_common" align="center">
                <tr>
                    <td class="table_sub_title_bold">&nbsp;Program</td>
                    <td class="record_cell_light">
                        
<%
    Statement stmt = null;
    ResultSet rs = null;
    String sql = "";
    Connection con = null;
    String bankId = "";
    String bankCde = "", progId = "", acctNbr = "", branchTxt = "", challanTitle = "", challanPrefix = "", onlineInd = "", activeInd = "",showInd="";
    String progCde = "",showAccount="";
    String bankRemarks = "";
    try
    {
        con = adminSession.con;
        stmt = con.createStatement();
        bankId = nvl(request.getParameter("bankId"));
        sql = "SELECT * FROM UCP.BANK B, UCP.PROGRAM P WHERE B.PROG_ID = P.PROG_ID AND BANK_ID = "+bankId;
        rs = stmt.executeQuery(sql);
        if(rs.next())
        {
            bankRemarks = rs.getString("BANK_REMARKS") != null ? rs.getString("BANK_REMARKS") : "";
            bankCde = rs.getString("BANK_CDE");
            acctNbr = rs.getString("ACCOUNT_NBR");
            branchTxt = rs.getString("BRANCH_TXT");
            challanTitle = rs.getString("CHALLAN_TITLE");
            challanPrefix = rs.getString("BANK_CHALLAN_PREFIX");
            onlineInd = rs.getString("ONLINE_IND");
            activeInd = rs.getString("ACTIVE_IND");
            showInd = rs.getString("SHOW_IND");
            progCde = rs.getString("PROG_CDE");
            showAccount = rs.getString("SHOW_ACCOUNT");
        }
%>
                    <input type="text" readonly="readonly"  name="progCde" value="<%=progCde%>" />     
                    </td>
                    <td class="table_sub_title_bold">Bank Code</td>
                    <td class="record_cell_light">
                        <input type="text" readonly="readonly"  name="bankCde" value="<%=bankCde%>" /> 
                        <input type="hidden" readonly="readonly"  name="bankId" value="<%=bankId%>" /> 
                    </td> 
                    <td class="table_sub_title_bold">Acct #</td>
                    <td class="record_cell_light">
                        <input type="text" name="acctNbr" value="<%=acctNbr%>" />
                    </td>  
                    <td class="table_sub_title_bold">Branch</td>
                    <td class="record_cell_light">
                        <input type="text" readonly="readonly"  name="branchTxt" value="<%=branchTxt%>" required="required" />
                    </td>      
                    <td class="table_sub_title_bold">Show Bank on Challan</td>
                    <td class="record_cell_light">
<%
        if(showInd.equals("Y"))
        {
            if(bankCde.equalsIgnoreCase("OL") || bankCde.equalsIgnoreCase("CDN"))
            {
%>                        
                    <input disabled="disabled" type="checkbox" value="Y" name="showInd"/>
<%
            }else
            {
%>                        
                    <input checked="checked" type="checkbox" value="Y" name="showInd"/>
<%
            }
        }else
        {
            if(bankCde.equalsIgnoreCase("OL") || bankCde.equalsIgnoreCase("CDN"))
            {
%>                        
                <input disabled="disabled" type="checkbox" value="Y" name="showInd"/>
<%
            }else
            {
%>                        
                        <input type="checkbox" value="Y" name="showInd"/>
<%
            }    
        }
%>                        
                    </td>                
                </tr>
                <tr>

                    <td class="table_sub_title_bold">Challan Title</td>
                    <td class="record_cell_light">
                        <input type="text" readonly="readonly" name="challanTitle" maxlength="43" value="<%=challanTitle%>" required="required" />
                    </td>    
                    <td class="table_sub_title_bold">Challan Prefix</td>
                    <td class="record_cell_light">
                        <input type="number" readonly="readonly" maxlength="3" name="challanPrefix" value="<%=challanPrefix%>" required="required" />
                    </td>    
                    <td class="table_sub_title_bold">Online Ind</td>
                    <td class="record_cell_light">
<%
        if(onlineInd.equals("Y"))
        {
%>                        
                        <input checked="checked" type="checkbox" value="Y" name="onlineInd"/>
<%
        }else
        {
%>                        
                        <input type="checkbox" value="Y" name="onlineInd"/>
<%
        }
%>                        
                    </td>    
                    <td class="table_sub_title_bold">Active Ind</td>
                    <td class="record_cell_light">
<%
        if(activeInd.equals("Y"))
        {
%>                        
                        <input checked="checked" type="checkbox" value="Y" name="activeInd"/>
<%
        }else
        {
%>                        
                        <input type="checkbox" value="Y" name="activeInd"/>
<%
        }
%> 
                    </td>   
                    <td class="table_sub_title_bold">Show Account on Challan</td>
                    <td class="record_cell_light">
<%
        if(showAccount != null && showAccount.equals("Y"))
        {
            if(bankCde.equalsIgnoreCase("OL") || bankCde.equalsIgnoreCase("CDN"))
            {
%>                        
                    <input disabled="disabled" type="checkbox" value="Y" name="showAccount"/>
<%
            }else
            {
%>                        
                    <input checked="checked" type="checkbox" value="Y" name="showAccount"/>
<%
            }
        }else
        {
            if(bankCde.equalsIgnoreCase("OL") || bankCde.equalsIgnoreCase("CDN"))
            {
%>                        
                <input disabled="disabled" type="checkbox" value="Y" name="showAccount"/>
<%
            }else
            {
%>                        
                        <input type="checkbox" value="Y" name="showAccount"/>
<%
            }    
        }
%>                        
                    </td>                      
                </tr>  
                <tr>
                    <td class="table_sub_title_bold">Bank Remarks</td>
                    <td class="record_cell_light" colspan="9">
                        <input type="text" 
                        name="bankRemarks" 
                        id="bankRemarks" 
                        maxlength="100" 
                        value="<%=bankRemarks%>" 
                        size="80" 
                        pattern="[a-zA-Z0-9\s.()-]*" 
                        oninput="this.value = this.value.replace(/[^a-zA-Z0-9\s.()-]/g, '')" 
                        title="Only letters, numbers, spaces, periods, parentheses, and hyphens are allowed" />
                    </td>
                </tr>                
                <tr>
                    <td colspan="8" align="center">
                        <input type="submit" name="Submit" value="Update">
                        <input type="button" name="Cancel" value="Cancel" onclick="window.location.href='AdminProgramBank.jsp';">                    
                    </td>
                </tr>
            </table>
<%
    }catch(Exception exp)
    {}finally
    {
        if(rs != null) rs.close();
        if(stmt != null) stmt.close();
    }
%>    
        </form>
    </body>
</html>