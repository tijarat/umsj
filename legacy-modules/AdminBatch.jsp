<%@ page contentType="text/html; charset=windows-1252" language="java" import="java.sql.*, java.util.*,com.towertech.ucp.util.*" session = "true" errorPage="../error.jsp" %>
<html>
    <head>
        <%@ include file="../shared/nocache.inc"%>
        <%!
            public void log(String message, String user) {
                System.out.println(new java.util.Date() + "::AdminBatch.jsp::" + user + "::" + message);
            }
        %>
        <jsp:useBean id="pool" scope="application" class="com.towertech.ucp.DB.ConnectionPool"/>

        <%
            AdminSession adminSession = (AdminSession) session.getAttribute("adminSession");
            if (adminSession == null || adminSession.con == null) {
                log("Session Not Found", "Invalid");
        %>
        <jsp:forward page= "../SessionExpire.jsp?des=Your Session/Connection closed please login again."/>
        <%
            }

            if (!adminSession.hasRightsOn("Batch")) {
        %>
        <jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Batch service." />
        <%    }

        %>
        <title>Registration</title>
        <script language="JavaScript" type="text/JavaScript">
            <!--
            function changeIt(elm)
            {
                if(parent.frames.length==0) return;
                var obj = parent.frames.leftFrame.document.links
                for(ctr=0;ctr<obj.length;ctr++)
                {
                    if(obj[ctr].href.indexOf(elm) > 0)
                    {
                        obj[ctr].style.cssText = "color:#000000; text-decoration:underline; font-weight:bold"
                    }
                    else
                    {
                        obj[ctr].style.cssText = "color:#006699"
                    }
                }
            }

            function fieldCheck()
            {
                for(i=0;i<batchForm.length;i++)
                {
                    if(batchForm.elements[i] == '[object]')
                    {
                        if(batchForm.elements[i].type == 'text' && batchForm.elements[i].value == '')
                        {
                            if(batchForm.elements[i].name == 'batch' && batchForm.elements[i].value == '')
                            {
                                alert('Please fill out ['+batchForm.elements[i].name.toUpperCase()+'] field.');
                                document.batchForm.elements[i].focus();
                                return false;
                            }
                        }
                    }
                }
                return true;
            }

            function validateControls()
            {
                if(fieldCheck())
                {
                    return true;
                }
                else
                {
                    return false;
                }
            }


            function MM_openBrWindow(theURL,winName,features) { //v2.0
                window.open(theURL,winName,features);
            }

            //-->
        </script>
        <link href="../Images/style.css" rel="stylesheet" type="text/css">
    </head>


    <body onLoad="changeIt('AdminBatch.jsp');">
        <table width="100%" class="table_common" align="center" cellpadding="0" cellspacing="0">
            <tr>
                <th class="table_title" scope="col">
                    Define Batch
                </th>
            </tr>
        </table>
        <hr>
        <form action="AdminProcessBatch.jsp" method="post" name="batchForm" id="batchForm" onSubmit="return validateControls()">

            <table width="50%" class="table_common" align="center">
                <tr>
                    <td class="table_sub_title_bold">&nbsp;Term</td>
                    <td class="record_cell_light"><%= adminSession.workingTerm%></td>
                    <td class="table_sub_title_bold">&nbsp;Program</td>
                    <td class="record_cell_light">
                        <select name="progList" id="progList">
                            <%
                                java.sql.Statement qryTermProgStmt = adminSession.con.createStatement();
                            //		java.sql.ResultSet getProgramListRs = qryTermProgStmt.executeQuery("SELECT PROG_CDE FROM UCP.PROGRAM WHERE PROG_TYP = 'V' ORDER BY 1");
                                java.sql.ResultSet getProgramListRs = qryTermProgStmt.executeQuery("SELECT PROG_CDE FROM UCP.PROGRAM WHERE FACULTY_ID=" + adminSession.getWorkingFacultyId() + " ORDER BY 1");
                                while (getProgramListRs.next()) {
                            %>
                            <option><%= getProgramListRs.getString(1)%></option>
                            <%
                                }
                                getProgramListRs.close();
                            %>
                        </select></td>
                </tr>
                <tr>
                    <td class="table_sub_title_bold">&nbsp;Batch *</td>
                    <td colspan="3" class="record_cell_light"><input name="batch" type="text" id="batch" size="5" maxlength="3" onKeypress="var uniCode=event.keyCode || event.charCode; if(uniCode>=48 && uniCode<=57 || uniCode==8 || uniCode==46){return true} else alert('Only numeric values can be entered here');  return false;"></td>
                </tr>
                <tr>
                    <td colspan="4" align="center">
                        <input type="submit" name="Submit" value="Add">
                    </td>
                </tr>
            </table>
            <fieldset><legend class="table_title_small">Batches</legend>
                <table width="100%" class="table_common" align="center">
                    <tr class="table_sub_title_bold">
                        <td width="9%">Term
                        </td>
                        <td width="23%">Program
                        </td>
                        <td width="34%">Batch
                        </td>
                        <td colspan="2">Options
                        </td>
                    </tr>
                    <%
                        int total = 0;
                        java.sql.ResultSet getBatchRs = qryTermProgStmt.executeQuery("select B.TERM_CDE, P.PROG_CDE, B.BATCH_NBR, B.BATCH_ID from UCP.BATCH B,UCP.PROGRAM P WHERE B.PROG_ID=P.PROG_ID AND  P.FACULTY_ID=" + adminSession.getWorkingFacultyId() + "  order by BATCH_ID DESC");
                        while (getBatchRs.next()) {
                            total++;
                    %>
                    <tr class="record_cell_light">
                        <%
                            if (getBatchRs.getString(1).equals(adminSession.workingTerm)) {
                        %>
                        <td width="4%" class="current_term" title="Current Batches"><%= getBatchRs.getString(1)%>
                        </td>
                        <td width="7%" class="current_term" title="Current Batches"><%= getBatchRs.getString(2)%>
                        </td>
                        <td width="5%" class="current_term" title="Current Batches"><%= getBatchRs.getString(3)%>
                        </td>
                        <td width="9%" class="current_term" title="Current Batches"><a href="AdminEditBatch.jsp?termCode=<%= getBatchRs.getString(1)%>&progCode=<%= getBatchRs.getString(2)%>&batch=<%= getBatchRs.getInt(3)%>&batchId=<%= getBatchRs.getInt(4)%>" class="body_links2">Edit</a>
                        </td>
                        <td width="9%" class="current_term" title="Current Batches"><a href="AdminProcessDeleteBatch.jsp?batchId=<%= getBatchRs.getInt(4)%>" onClick="return confirm('Are you sure you want to delete <%= getBatchRs.getInt(3)%> batch of <%= getBatchRs.getString(2)%> program?')" class="body_links2">Delete</a>
                        </td>
                        <%
                        } else {
                        %>
                        <td width="4%"><%= getBatchRs.getString(1)%>
                        </td>
                        <td width="7%"><%= getBatchRs.getString(2)%>
                        </td>
                        <td width="5%"><%= getBatchRs.getString(3)%>
                        </td>
                        <td width="9%"><a href="AdminEditBatch.jsp?termCode=<%= getBatchRs.getString(1)%>&progCode=<%= getBatchRs.getString(2)%>&batch=<%= getBatchRs.getString(3)%>&batchId=<%= getBatchRs.getInt(4)%>" class="body_links2">Edit</a>
                        </td>
                        <td width="9%"><a href="AdminProcessDeleteBatch.jsp?batchId=<%= getBatchRs.getInt(4)%>" onClick="return confirm('Are you sure you want to delete <%= getBatchRs.getInt(3)%> batch of <%= getBatchRs.getString(2)%> program?')" class="body_links2">Delete</a>
                        </td>
                        <%
                            }
                        %>
                    </tr>
                    <%
                        }
                        getBatchRs.close();
                        qryTermProgStmt.close();
                    %>
                </table>
            </fieldset>
            <table>
                <tr>
                    <td class="total-text">
                        Total:&nbsp;<%= total%>		</td>
                </tr>
            </table>
        </form>

    </body>
</html>