<%@ page contentType="text/html; charset=windows-1252" language="java" import="java.sql.*, java.util.*,com.towertech.ucp.util.*" session = "true" errorPage="../error.jsp" %>
<html>
<head>
<%@ include file="../shared/nocache.inc"%>
<%!
public void log(String message,String user)
{
  System.out.println(new java.util.Date() + "::AdminEditBatch.jsp::" + user + "::" + message);
}
%>
<jsp:useBean id="pool" scope="application" class="com.towertech.ucp.DB.ConnectionPool"/>

<%
	AdminSession adminSession = (AdminSession)session.getAttribute("adminSession");
	if(adminSession == null || adminSession.con == null)
  {
    log("Session Not Found","Invalid");
%>
		<jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/>		
<%
  }

	if(!adminSession.hasRightsOn("Batch"))
	{
%>
		<jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Batch service." />
<%
	}
%>
<title>Registration</title>
<script language="JavaScript" type="text/JavaScript">
<!--
function redirect(mainPage)
{
	document.editBatchForm.action = mainPage;
}

function fieldCheck()
{
	for(i=0;i<editBatchForm.length;i++)
	{
		if(editBatchForm.elements[i] == '[object]')
		{
			if(editBatchForm.elements[i].type == 'text' && editBatchForm.elements[i].value == '')
			{
				if(editBatchForm.elements[i].name == 'batch' && editBatchForm.elements[i].value == '')
				{
					alert('Please fill out ['+editBatchForm.elements[i].name.toUpperCase()+'] field.');
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
		var num = "0123456789";
		
		if(num.indexOf(document.editBatchForm.batch.value.substring(0,1)) >= 0 && num.indexOf(document.editBatchForm.batch.value.substring(1,2)) >= 0)
		{
			return true;
		}
		else
		{
			alert('invalid batch number');
			document.editBatchForm.batch.value='';
			return false;
		}
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


<body>
<table width="100%" class="table_common" align="center" cellpadding="0" cellspacing="0">
  <tr>
    <th class="table_title" scope="col">
    Edit Batch
    </th>
  </tr>
</table>
<hr>
<form action="AdminProcessEditBatch.jsp?batchId=<%= request.getParameter("batchId") %>" method="post" name="editBatchForm" id="editBatchForm">


<table width="50%" class="table_common" align="center">
  <tr>
    <td class="table_sub_title_bold">&nbsp;Term</td>
    <td class="record_cell_light"><%= request.getParameter("termCode") %></td>
    <td class="table_sub_title_bold">&nbsp;Program</td>
    <td class="record_cell_light"><%= request.getParameter("progCode") %></td>
  </tr>
  <tr>
    <td class="table_sub_title_bold">&nbsp;Batch *</td>
    <td colspan="3" class="record_cell_light"><input name="batch" type="text" id="batch" size="5" maxlength="3" value="<%= request.getParameter("batch") %>" onKeypress="var uniCode=event.keyCode || event.charCode; if(uniCode>=48 && uniCode<=57 || uniCode==8 || uniCode==46){return true} else alert('Only numeric values can be entered here');  return false;"></td>
    </tr>
</table>
<table width="50%" class="table_common" align="center">
  <tr class="record_cell_light">
    <td>
      <input type="submit" name="Submit" value="Update" onClick="return validateControls()">
    </td>
    <td>
      <input type="submit" name="Submit2" value="Cancel" onClick="redirect('AdminBatch.jsp')">
    </td>
  </tr>
</table>
</form>

</body>
</html>