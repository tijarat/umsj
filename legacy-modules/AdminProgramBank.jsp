<%@ page contentType="text/html; charset=windows-1252" language="java" import="java.sql.*, java.util.*,com.towertech.ucp.util.*" session = "true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.towertech.ucp.DB.ConnectionPool"/>
<%@ include file="../shared/nocache.inc"%>
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
        <form action="AdminProcessProgramBank.jsp" method="post" name="programBankForm" id="programBankForm">
            <table width="100%" class="table_common" align="center">
                <tr>
                    <td class="table_sub_title_bold">&nbsp;Program</td>
                    <td class="record_cell_light">
                        <select name="progId" id="progId">
<%
    Statement stmt = null;
    ResultSet rs = null;
    String sql = "";
    Connection con = null;
    try
    {
        con = adminSession.con;
        stmt = con.createStatement();
        sql = "SELECT PROG_CDE, PROG_ID FROM UCP.PROGRAM WHERE FACULTY_ID=" + adminSession.getWorkingFacultyId() + " ORDER BY 1";
        rs = stmt.executeQuery(sql);
        while (rs.next()) 
        {
%>
            <option value="<%= rs.getString(2)%>"><%= rs.getString(1)%></option>
<%
        }  
        sql = "SELECT BANK_CDE||'-'||BANK_NAME, BANK_CDE  FROM UCP.BANK_MASTER ORDER BY 1";
        rs = stmt.executeQuery(sql);
       
%>
                        </select>
                    </td>
                    <td class="table_sub_title_bold">Bank Code</td>
                    <td class="record_cell_light">
                        <select name="bankCde" id="bankCde">
<%
        while (rs.next())
        {
%>                            
                           <option value="<%= rs.getString(2)%>"><%= rs.getString(1)%></option>
<%
        }
%>                            
                        </select>
                    </td> 
                    <td class="table_sub_title_bold">Acct #</td>
                    <td class="record_cell_light">
                        <input type="text" minlength="8" pattern="\d*" name="acctNbr" required="required" />
                    </td>  
                    <td class="table_sub_title_bold">Branch</td>
                    <td class="record_cell_light">
                        <input type="text" name="branchTxt" value="Any Branch" required="required" />
                    </td>                       
                </tr>
                <tr>
                    <td class="table_sub_title_bold">Challan Title</td>
                    <td class="record_cell_light">
                        <input type="text" maxlength="43" name="challanTitle" required="required" />
                    </td>    
                    <td class="table_sub_title_bold">Challan Prefix</td>
                    <td class="record_cell_light">
                        <input type="number" min="700" minlength="3" max="999" maxlength="3" name="challanPrefix" required="required" />
                    </td>    
                    <td class="table_sub_title_bold">Online Ind</td>
                    <td class="record_cell_light">
                        <input type="checkbox" value="Y" name="onlineInd"/>
                    </td>    
                    <td class="table_sub_title_bold">Active Ind</td>
                    <td class="record_cell_light">
                        <input type="checkbox" value="Y" name="activeInd" />
                    </td>                      
                </tr>                
<!-- ADD THIS NEW ROW BELOW -->
                <tr>
                    <td class="table_sub_title_bold">Bank Remarks</td>
                    <td class="record_cell_light" colspan="7">
                        <input type="text" 
               name="bankRemarks" 
               id="bankRemarks" 
               maxlength="100" 
               size="80" 
               pattern="[a-zA-Z0-9\s.()-]*" 
               oninput="this.value = this.value.replace(/[^a-zA-Z0-9\s.()-]/g, '')" 
               title="Only letters, numbers, spaces, periods, parentheses, and hyphens are allowed" />
                    </td>
                </tr>             
                <tr>
                    <td colspan="8" align="center">
                        <input type="submit" name="Submit" value="Add">
                    </td>
                </tr>
            </table>
            <fieldset>
                <legend class="table_title_small">Program Banks</legend>
                <table width="100%" class="table_common" align="center">
                    <tr class="table_sub_title_bold">
                        <td>Program Code</td>
                        <td>Bank Code</td>
                        <td>Bank Name</td>
                        <td>Account#</td>
                        <td>Branch</td>
                        <td>Challan Title</td>
                        <td>Challan Prefix</td>
                        <td>Online</td>
                        <td>Active</td> 
                        <td>Show Bank on<br/> Challan</td>
                        <td>Show Account on<br/> Challan</td>
                        <td>Bank Remarks</td><!-- NEW COLUMN HEADER -->
                        <td colspan="2">Options</td>
                    </tr>
<%
                        int total = 0;
                        sql = "SELECT P.PROG_CDE, B.BANK_CDE, B.BANK_TXT, DECODE(B.ACCOUNT_NBR, '0','-','000','-', B.ACCOUNT_NBR) ACCOUNT_NBR, B.BRANCH_TXT, B.CHALLAN_TITLE, B.BANK_CHALLAN_PREFIX, B.ONLINE_IND, B.SHOW_IND, B.ACTIVE_IND, B.BANK_ID, NVL(B.SHOW_ACCOUNT,'N') SHOW_ACCOUNT, NVL(B.BANK_REMARKS,'-') BANK_REMARKS  " +
                                "FROM UCP.BANK_MASTER BM, UCP.BANK_USER BU, UCP.BANK B, UCP.PROGRAM P, UCP.FACULTY F " +
                                "WHERE BM.BANK_CDE = B.BANK_CDE AND BM.BANK_CDE = BU.BANK_CDE(+) " +
                                "AND F.FACULTY_ID = P.FACULTY_ID " +
                                "AND P.FACULTY_ID = F.FACULTY_ID AND B.PROG_ID = P.PROG_ID  " +
                                "AND F.FACULTY_ID = "+adminSession.getWorkingFacultyId()+" " +
                                "ORDER BY 1,3,10 " ;

                        rs = stmt.executeQuery(sql);
        while (rs.next()) 
        {
%>
                    <tr class="record_cell_light">
                        <td><%= rs.getString(1)%></td>
                        <td><%= rs.getString(2)%></td>
                        <td><%= rs.getString(3)%></td>
                        <td><%= rs.getString(4)%></td>
                        <td><%= rs.getString(5)%></td>
                        <td><%= rs.getString(6)%></td>
                        <td><%= rs.getString(7)%></td>
                        <td><%= rs.getString(8)%></td>
                        <td><%= rs.getString(10)%></td>
                        <td><%= rs.getString(9)%></td>
                        <td><%= rs.getString(12)%></td>
                        <td><%= rs.getString("BANK_REMARKS")%></td>
                        <td><a href="AdminEditProgramBank.jsp?bankId=<%= rs.getString("BANK_ID")%>" class="body_links2">Edit</a></td>
                        <td><a href="AdminProcessDeleteProgramBank.jsp?bankId=<%= rs.getString("BANK_ID")%>" onClick="return confirm('Are you sure you want to delete <%= rs.getString(2)%>')" class="body_links2">Delete</a></td>
                    </tr>

<%
        }
    }catch(Exception exp)
    {
       throw new Exception("Error while getting bank inforamtion.");
    }finally
    {
        if(rs != null) rs.close();
        if(stmt != null) stmt.close();
    }
%>    
                </table>
            </fieldset>
        </form>
    </body>
</html>