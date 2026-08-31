<%@ page contentType="text/html; charset=windows-1252" language="java" import="java.sql.*, java.util.*,com.towertech.ucp.util.*" session = "true" errorPage="../error.jsp" %>
<%@ include file="../shared/findReplace.jsp"%>
<%@ include file="../shared/nocache.inc"%>
<html>
<head>
<%!
public void log(String message,String user)
{
  System.out.println(new java.util.Date() + "::AdminCourses.jsp::" + user + "::" + message);
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

	if(!adminSession.hasRightsOn("Prereq"))
	{
%>
		<jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Prereq service." />
<%
	}
%>
<title>Registration</title>
<script language="JavaScript" type="text/JavaScript">
<!--
function redirect(mainPage)
{
	document.editPrereqForm.action = mainPage;
}

function fieldCheck()
{
	for(i=0;i<editPrereqForm.length;i++)
	{
		if(editPrereqForm.elements[i] == '[object]')
		{
			if(editPrereqForm.elements[i].value == '' && editPrereqForm.elements[i].name != 'Prereq')
			{
				alert('Please fill out ['+editPrereqForm.elements[i].name.toUpperCase()+'] field.');
				return false;
			}
		}
	}
	return true;
}

function validateControls()
{
	return fieldCheck();
}


function MM_openBrWindow(theURL,winName,features) { //v2.0
  window.open(theURL,winName,features);
}
//-->
</script>
<link href="../Images/style.css" rel="stylesheet" type="text/css">
</head>

<%
    java.sql.Statement qryPrereqStmt = null;
    java.sql.ResultSet getPrereqListRs = null;
	String Program = request.getParameter("Program");
    String ProgramCde="";
    try{
        String qry = "SELECT P.PROG_CDE,P.PROG_ID FROM UCP.PROGRAM P WHERE P.PROG_TYP = 'R' AND P.FACULTY_ID = " + adminSession.getWorkingFacultyId() + " AND P.PROG_ID="+Program;
        qryPrereqStmt = adminSession.con.createStatement();
        getPrereqListRs = qryPrereqStmt.executeQuery(qry);
        if(getPrereqListRs.next())
            ProgramCde = getPrereqListRs.getString("PROG_CDE");
    }catch(Exception e){
        throw new Exception(e);
    }finally{
        if(getPrereqListRs !=null )
            getPrereqListRs.close();
        if(qryPrereqStmt !=null )
            qryPrereqStmt.close();
    }
%>
<body onLoad="document.editPrereqForm.Prereq.value=<%= Integer.parseInt(request.getParameter("preqcid")) %>;document.editPrereqForm.status.value='<%= request.getParameter("status") %>'">
<table width="100%" class="table_common" align="center" cellpadding="0" cellspacing="0">
  <tr>
    <th class="table_title" scope="col">
      Edit Prereq
    </th>
  </tr>
</table>
<hr>
<form action="AdminProcessEditProgramCourseDetail.jsp?preqid=<%= request.getParameter("preqid") %>" method="post" name="editPrereqForm" id="editPrereqForm">
<input name="Program" type="hidden" value="<%= Program %>">
<input name="crsId" type="hidden" value="<%= nvl(request.getParameter("cid")) %>">
<input name="prgCde" type="hidden" value="<%= ProgramCde %>">
<table width="50%" class="table_common" align="center">
  <tr>
    <td width="14%" class="table_sub_title_bold"><div align="center">Term</div>
    </td>
    <td width="28%" class="record_cell_light"><%= adminSession.workingTerm %>
    </td>
    <td width="22%" class="table_sub_title_bold"><div align="center">Program</div></td>
    <td width="36%" class="record_cell_light"><%= ProgramCde%></td>
  </tr>
</table>
<table width="80%" class="table_common" align="center">
  <tr>
    <td class="table_sub_title_bold">Course Code</td>
    <td class="record_cell_light"><%= request.getParameter("courseCode") %></td>
  </tr>
  <tr>
    <td class="table_sub_title_bold">&nbsp;Course </td>
    <td class="record_cell_light"><%= request.getParameter("Course") %></td>
    </tr>
  <tr>
    <td class="table_sub_title_bold">&nbsp;PreReq</td>
    <td class="record_cell_light">
		<select name="Prereq" id="Prereq">
			<option value="blank">&nbsp;</option>
<%
	qryPrereqStmt = adminSession.con.createStatement();
	getPrereqListRs = qryPrereqStmt.executeQuery("select COURSE_ID, COURSE_ABBR, COURSE_NME, COURSE_CDE from UCP.COURSE where TERM_CDE='"+ adminSession.workingTerm +"' and COURSE_ID not in "+ Integer.parseInt(request.getParameter("cid")) +" order by COURSE_CDE, COURSE_NME");
	while(getPrereqListRs.next())
	{
%>
      <option value="<%= getPrereqListRs.getString("COURSE_ID") %>"><%= getPrereqListRs.getString("COURSE_CDE") %>&nbsp;&nbsp[<%= getPrereqListRs.getString("COURSE_NME") %>]&nbsp;(<%= getPrereqListRs.getString("COURSE_ABBR") %>)</option>
<%
	}
	
%>
      </select>
    </td>
    </tr>
     <tr>
    <td class="table_sub_title_bold">&nbsp;Status *</td>
    <td class="record_cell_light">
    <select name="status" id="status">
    <%
	java.sql.ResultSet getCoursestatusListRs = qryPrereqStmt.executeQuery("select status_nme from COURSE_STATUS");
    String status = nvl(request.getParameter("status") );
	while(getCoursestatusListRs.next())
	{
%>
<option value="<%=getCoursestatusListRs.getString("status_nme") %>" <%= ( status.equals(getCoursestatusListRs.getString("status_nme"))? "selected='selected'":"" ) %> ><%=getCoursestatusListRs.getString("status_nme") %></option>
<%
	}
	getCoursestatusListRs.close();
  qryPrereqStmt.close();
%>
      
     <!-- <option value="BUS. ELECT">BUS. ELECT</option>
      <option value="CORE">CORE</option>
			<option value="DEFICIENCY">DEFICIENCY</option>
      <option value="ELECT">ELECT</option>
      <option value="FIN (SPEC)">FIN (SPEC)</option>
      <option value="GEN. EDU">GEN. EDU</option>
      <option value="GEN. ELECT">GEN. ELECT</option>
      <option value="HRM (SPEC)">HRM (SPEC)</option>
      <option value="HUM">HUM</option>
      <option value="IT (SPEC)">IT (SPEC)</option>
      <option value="IT CORE">IT CORE</option>
      <option value="MATH">MATH</option>
      <option value="MKTG (SPEC)">MKTG (SPEC)</option>
      <option value="PROJECT">PROJECT</option>-->
      </select>
    </td>
  </tr>
 
  <tr>
    <td class="table_sub_title_bold">&nbsp;Course Sequence
      *</td>
    <td class="record_cell_light"><input name="seq" type="text" id="seq" value="<%= request.getParameter("seq") %>" size="5" maxlength="3" onKeypress="var uniCode=event.keyCode || event.charCode; if (uniCode < 45 || uniCode > 57) {alert('Only numeric values can be entered here'); return false;}">
    </td>
  </tr>
</table>
<table width="50%" class="table_common" align="center">
  <tr>
    <td><div align="center">
      <input type="submit" name="Submit" value="Update" onClick="return validateControls()">
    </div></td>
    <td><div align="center">
      <input type="submit" name="Submit2" value="Cancel" onClick="redirect('AdminProgramCourseDetail.jsp')">
    </div></td>
  </tr>
</table>
</form>

</body>
</html>