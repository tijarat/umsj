<%@ page contentType="text/html; charset=windows-1252" language="java" import="java.sql.*, java.util.*" session = "true" errorPage="../error.jsp" %>
<html>
    <head>
        <%@ include file="../shared/findReplace.jsp"%>
        <%@ include file="../shared/nocache.inc"%>
        <%!    public void log(String message, String user) {
                System.out.println(new java.util.Date() + "::AdminProgramCourseDetail.jsp::" + user + "::" + message);
            }
        %>
        <jsp:useBean id="pool" scope="application" class="com.towertech.ucp.DB.ConnectionPool"/>

        <%
            com.towertech.ucp.util.AdminSession adminSession = (com.towertech.ucp.util.AdminSession) session.getAttribute("adminSession");
            if (adminSession == null || adminSession.con == null) {
                log("Session Not Found", "Invalid");
        %>
        <jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/>		
        <%
            }

            if (!adminSession.hasRightsOn("Prereq")) {
        %>
        <jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Prereq service." />
        <%    }

        %>
        <title>Registration</title>
<link rel="stylesheet" href="http://code.jquery.com/ui/1.10.3/themes/smoothness/jquery-ui.css">
<script language='javascript' src='../js/md5.js'></script>
<script type="text/javascript" src="../js/jquery-1.6.2.min.js"></script>
<script type="text/javascript" src="../js/jquery-ui-1.8.15.custom.min.js"></script>
<link rel="stylesheet" href="/resources/demos/style.css">
        <script language="JavaScript" type="text/JavaScript">
            <!--
            function setProgram()
            {
                var url = "AdminProgramCourseDetail.jsp";
                document.prereqForm.action = url;
                document.prereqForm.submit();
            }

            function checkIfEqual()
            {
                var a = document.prereqForm.Course.value;
                var b = document.prereqForm.Prereq.value;
                if( a == b )
                {
                    alert('Course and Prereq cannot be equal');
                    document.prereqForm.Course.value = '';
                    document.prereqForm.Prereq.value = '';
                    document.prereqForm.Course.focus();
                    return false;
                }
                return true;
            }

            function fieldCheck()
            {
                for(i=0;i<prereqForm.length;i++)
                {
                    if(prereqForm.elements[i] == '[object]')
                    {
                        if(prereqForm.elements[i].value == '' && prereqForm.elements[i].name != 'Prereq')
                        {
                            alert('Please fill out ['+prereqForm.elements[i].name.toUpperCase()+'] field.');
                            document.prereqForm.elements[i].focus();
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

            function LockUnlock(act,prog){
                if(confirm('Are you sure to lock this program ?')){
                    document.prereqForm.action="AdminProcessProgramCourseDetail.jsp?act="+act+"&prog="+prog;
                    document.prereqForm.submit();
                }
            }
             function Unlock(act,prog){
                if(confirm('Are you sure to Unlock this program?')){
                    document.prereqForm.action="AdminProcessProgramCourseDetail.jsp?act="+act+"&prog="+prog;
                    document.prereqForm.submit();
                }
            }
            //-->
            function getCampusFacultyRoadMap(rmCmpFacObj){
                var url = "../ajax/AdminGetCopyRMProgram.jsp?facId="+rmCmpFacObj.value;
                $("#prev_rm").load(url);
            }
            /*function showHideCopyRm(chkBoxObj){
                if($("#alreadyRMExist").val()=='N'){
                    if(chkBoxObj.checked==true){
                        document.getElementById("rmCF").style.display='';
                        document.getElementById("prev_rm").style.display='';
                    }else{
                        document.getElementById("rmCF").style.display='none';
                        document.getElementById("prev_rm").style.display='none';
                    }
                }else{
                    $('#rmCopy').attr('checked', false);
                    alert("Roadmap already defined.");
                }
            }
            function CopyRoadmap(){
                if($("#rmWorkingFaculty").val()!=null && $("#prevRm").val()!=null && $("#rmWorkingFaculty").val()!='' && $("#prevRm").val()!=''){
                    if(confirm('Are you sure to roadmap ?')){
                        var form = document.getElementById("prereqForm");
                        form.addEventListener('submit', validateControls, false);
                        var rmWFacId = $("#rmWorkingFaculty").val();
                        var CamFacIdRmId = $("#prevRm").val();
                        form.action = "AdminCopyRoadmap.jsp";
                        form.submit();
                    }else{
                        return false;
                    }
                }else{
                    alert("Select required parameters to copy roadmap.");
                    return false;
                }
            }*/
        </script>
        <link href="../Images/style.css" rel="stylesheet" type="text/css">
    </head>
    <%
        String query = "";
        java.sql.Statement qryPrereqStmt = adminSession.con.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY);
        java.sql.ResultSet getProgramListRs = null,getPrereqRs=null, getCoursestatusListRs=null;
        String prog = request.getParameter("Program");
        String lockUnlock = "",program="";
        if (prog == null) {
    %>
    <body onLoad="changeIt('AdminProgramCourseDetail.jsp'); document.prereqForm.Course.value=''; document.prereqForm.Prereq.value='';">
        <%} else {
        %>
    <body onLoad="document.prereqForm.Course.value=''; document.prereqForm.Prereq.value='';document.prereqForm.Program.value='<%= prog%>'; changeIt('AdminProgramCourseDetail.jsp');">
        <%
            }
        %>
        <table width="100%" class="table_common" align="center" cellpadding="0" cellspacing="0">
            <tr>
                <th class="table_title" scope="col">
                    Define Roadmap 
                </th>
            </tr>
        </table>
        <hr>
        <form action="AdminProcessProgramCourseDetail.jsp" method="post" name="prereqForm" id="prereqForm" onSubmit="return validateControls()">
            <%
                //if(!lockUnlock.equals("Y")){
            %>
            <table width="70%" class="table_common" align="center">
                <tr>
                    <td width="14%" class="table_sub_title_bold"><div align="center">Term</div>
                    </td>
                    <td width="10%" class="record_cell_light"><%= adminSession.workingTerm%>
                    </td>
                    <td width="12%" class="table_sub_title_bold"><div align="center">Program
                            *</div>
                    </td>
                    <td width="13%" class="record_cell_light">
                        <select name="Program" onChange="setProgram()">
                            <%
                                try{
                                query = "SELECT P.PROG_CDE,P.PROG_ID FROM UCP.PROGRAM P WHERE  "
                                        + "P.PROG_TYP = 'R' AND P.FACULTY_ID = " + adminSession.getWorkingFacultyId() + "";
                                getProgramListRs = qryPrereqStmt.executeQuery(query);
                                //	java.sql.ResultSet getProgramListRs = qryPrereqStmt.executeQuery("SELECT PROG_CDE FROM UCP.PROGRAM WHERE PROG_TYP = 'R' ORDER BY 1");

                                while (getProgramListRs.next()) {
                                    if (prog == null) {
                                        prog = getProgramListRs.getString("PROG_ID");
                                        program=getProgramListRs.getString("PROG_CDE");
                                    }
                                    if (prog.equals(getProgramListRs.getString("PROG_ID"))) {
                                        program=getProgramListRs.getString("PROG_CDE");
                            %>
                            <option selected="selected" value="<%= getProgramListRs.getString("PROG_ID")%>"><%= getProgramListRs.getString("PROG_CDE")%></option>
                            <%
                            } else {
                            %>
                            <option value="<%= getProgramListRs.getString("PROG_ID")%>"><%= getProgramListRs.getString("PROG_CDE")%></option>
                            <%
                                    }
                                }
                                if (getProgramListRs!=null) {getProgramListRs.close();}
                            %>
                        </select>
                        <%
                            String checkLock = "SELECT DISTINCT LOCKED_IND FROM PREREQ P,COURSE C,PROGRAM PROG WHERE P.PROG_ID=PROG.PROG_ID AND PROG.PROG_ID= " + prog + " AND P.COURSE_ID = C.COURSE_ID AND FACULTY_ID=" + adminSession.getWorkingFacultyId() + " AND C.TERM_CDE= '" + adminSession.workingTerm + "' ";
                            
                            getProgramListRs = qryPrereqStmt.executeQuery(checkLock);
                            if (getProgramListRs.next()) {
                                lockUnlock = nvl(getProgramListRs.getString("LOCKED_IND"));
                            }
                        %>
<%
    if (lockUnlock.equals("N") || lockUnlock.equals("")) 
    {
%>
        <a href="#" onclick="LockUnlock('Y','<%=prog%>')"><img border="0" title="Lock" src="../Images/lock.png"/></a>
<%
    }else if(lockUnlock.equals("Y")) 
    {
        if(pool.isUserAllowedProcess("CanUnlockPrereq", adminSession.user))
        {
%>
            <a href="#" onclick="Unlock('N','<%=prog%>')"><img border="0" title="UnLock" src="../Images/unlock.jpg"/></a>
<%
        }else
        {
%>
            Locked
<%
        }
    }
%>
                    </td>
                </tr>
            </table>
            <%
                if (!lockUnlock.equals("Y")) {
            %>
            <table width="80%" class="table_common" align="center">
                <tr>
                    <td class="table_sub_title_bold">&nbsp;Course *</td>
                    <td class="record_cell_light">
                        <select name="Course" id="Course" onChange="return checkIfEqual()">
                            <%  
                                if (getProgramListRs!=null) {getProgramListRs.close();}
                                getProgramListRs = qryPrereqStmt.executeQuery("select COURSE_ID, COURSE_ABBR,  COURSE_NME, COURSE_CDE from UCP.COURSE where TERM_CDE='" + adminSession.workingTerm + "' order by COURSE_CDE, COURSE_NME");

                                while (getProgramListRs.next()) {
                            %>
                            <option value="<%= getProgramListRs.getInt("COURSE_ID")%>"><%= getProgramListRs.getString("COURSE_CDE")%>&nbsp;&nbsp[<%= getProgramListRs.getString("COURSE_NME")%>]&nbsp;(<%= getProgramListRs.getString("COURSE_ABBR")%>)</option>
                            <%
                                }
                            %>
                        </select>
                    </td>
                </tr>
                <tr>
                    <td class="table_sub_title_bold">&nbsp;PreReq</td>
                    <td class="record_cell_light">
                        <select name="Prereq" id="Prereq" onChange="return checkIfEqual()">
                            <%
                                if (getProgramListRs!=null) {getProgramListRs.close();}
                                getProgramListRs = qryPrereqStmt.executeQuery("select COURSE_ID, COURSE_ABBR,  COURSE_NME, COURSE_CDE from UCP.COURSE where TERM_CDE='" + adminSession.workingTerm + "' order by COURSE_CDE, COURSE_NME");
                                while (getProgramListRs.next()) {
                            %>
                            <option value="<%= getProgramListRs.getInt("COURSE_ID")%>"><%= getProgramListRs.getString("COURSE_CDE")%>&nbsp;&nbsp[<%= getProgramListRs.getString("COURSE_NME")%>]&nbsp;(<%= getProgramListRs.getString("COURSE_ABBR")%>)</option>
                            <%
                                }
                                if (getProgramListRs!=null) {getProgramListRs.close();}
                            %>
                        </select>
                    </td>
                </tr>
                <tr>
                    <td class="table_sub_title_bold">&nbsp;Status *</td>
                    <td class="record_cell_light">
                        <select name="status" id="status">
                            <%
                                getCoursestatusListRs = qryPrereqStmt.executeQuery("select status_nme from COURSE_STATUS");
                                while (getCoursestatusListRs.next()) {
                            %>
                            <option value="<%=getCoursestatusListRs.getString("status_nme")%>"><%=getCoursestatusListRs.getString("status_nme")%></option>
                            <%
                                }
                                if(getCoursestatusListRs!=null){getCoursestatusListRs.close();}
                            %>
                        </select>
                    </td>
                </tr>
                <tr>
                    <td class="table_sub_title_bold">&nbsp;Course Sequence *</td>
                    <td class="record_cell_light"><input name="seq" type="text" id="seq" size="5" maxlength="3" onKeypress="var uniCode=event.keyCode || event.charCode; if (uniCode < 45 || uniCode > 57) {alert('Only numeric values can be entered here'); this.select(); return false;}">
                    </td>
                </tr>
                <tr>
                    <td colspan="2" align="center">
                        <input type="submit" name="Submit" value="Add">
                    </td>
                </tr>
            </table>
            <%
                }
            %>
            <fieldset>
                <legend class="table_title_small">Roadmap Of <%= program%> : <%=adminSession.getCampus()%> : <%=adminSession.getWorkingFaculty() %></legend>
                <%
                    query = "select p.course_id, p.prereq_course_id, p.course_nbr course_nbr, "
                            + "(select course_cde  || ' (CrHr '|| c.CREDIT_HRS || ')' course_cde from UCP.COURSE where course_id=p.course_id) course_cde, "
                            + "(select course_nme from UCP.COURSE where course_id=p.course_id) course_nme, "
                            + "nvl((select course_cde from UCP.COURSE where course_id=p.prereq_course_id),'-') prereq_cde, "
                            + "nvl((select course_nme from UCP.COURSE where course_id=p.prereq_course_id),'-') prereq_nme, "
                            + "prereq_id, nvl(p.status_txt,' ') status,P.LOCKED_IND,PR.PROG_CDE "
                            + "from UCP.PREREQ p, UCP.COURSE c, PROGRAM PR "
                            + "where c.course_id = p.course_id "
                            + "and c.term_cde = '" + adminSession.workingTerm + "' "
                            + "and p.prog_id="+prog+" "
                            + "AND PR.PROG_ID = P.PROG_ID "
                            + "AND PR.FACULTY_ID = " + adminSession.getWorkingFacultyId() + " "
                            + "order by course_nbr, course_cde";
                    //(select prog_id from program where prog_cde = '" + prog + "' AND FACULTY_ID=" + adminSession.getWorkingFacultyId() + ") "

                    getPrereqRs = qryPrereqStmt.executeQuery(query);

                    //	java.sql.ResultSet getPrereqRs = qryPrereqStmt.executeQuery("select p.course_id, p.prereq_course_id, p.course_nbr course_nbr, (select course_cde from UCP.COURSE where course_id=p.course_id) course_cde, (select course_nme from UCP.COURSE where course_id=p.course_id) course_nme, nvl((select course_cde from UCP.COURSE where course_id=p.prereq_course_id),'-') prereq_cde, nvl((select course_nme from UCP.COURSE where course_id=p.prereq_course_id),'-') prereq_nme, prereq_id, "+
                    //    "nvl(p.status_txt,' ') status from UCP.PREREQ p, UCP.COURSE c where c.course_id = p.course_id and c.term_cde = '"+ adminSession.workingTerm +"' and p.prog_cde='"+prog+" AND PF.PROG_CDE = P.PROG_CDE order by course_nbr, course_cde");
                    int total = 0;

                    if (getPrereqRs.next()) {
                %>
                <input type="hidden" name="alreadyRMExist" id="alreadyRMExist" value="Y"/>
                <table width="100%" border="1" bordercolordark="#FFFFFF" bordercolorlight="#666666" bordercolor="#ff0000" cellspacing="0" cellspacing="2">
                    <tr class="table_sub_title_bold">
                        <td width="10%">Course Code
                        </td>
                        <td width="22%">Title</td>
                        <td width="10%">Prereq Code
                        </td>
                        <td width="22%">Title</td>
                        <td width="9%">Sequence
                        </td>
                        <td width="10%">Status
                        </td>
                        <%
                            if (!nvl(getPrereqRs.getString("LOCKED_IND")).equals("Y")) {
                        %>
                        <td colspan="2">Options</td>
                        <%    }
                            getPrereqRs.beforeFirst();
                        %>
                    </tr>
                    <%
                        while (getPrereqRs.next()) {
                            total++;
                    %>
                    <tr class="record_cell_light">
                        <td><%= getPrereqRs.getString("course_cde")%></td>
                        <td><div align="left"><%= getPrereqRs.getString("course_nme")%></div></td>
                        <%
                            if (getPrereqRs.getString("prereq_cde").equals("-")) {
                        %>
                        <td>&nbsp;</td>
                        <td>&nbsp;</td>
                        <%} else {
                        %>
                        <td><%= getPrereqRs.getString("prereq_cde")%></td>
                        <td><%= getPrereqRs.getString("prereq_nme")%></td>
                        <%
                            }
                        %>
                        <td><%= getPrereqRs.getInt("course_nbr")%></td>
                        <td><%= getPrereqRs.getString("status")%></td>
                        <%
                            if (!nvl(getPrereqRs.getString("LOCKED_IND")).equals("Y")) {
                        %>
                        <td width="6%">
                            <a href="AdminEditProgramCourseDetail.jsp?Program=<%= prog%>&Course=<%= getPrereqRs.getString("course_nme")%>&Prereq=<%= getPrereqRs.getString("prereq_nme")%>&seq=<%= getPrereqRs.getInt("course_nbr")%>&preqcid=<%= getPrereqRs.getInt(2)%>&preqid=<%= getPrereqRs.getInt("prereq_id")%>&cid=<%= getPrereqRs.getInt(1)%>&status=<%= getPrereqRs.getString("status")%>&courseCode=<%= getPrereqRs.getString("course_cde")%>" class="body_links2">Edit</a>                    
                        </td>
                        <td width="6%"><a href="AdminProcessDeleteProgramCourseDetail.jsp?preqid=<%= getPrereqRs.getInt("prereq_id")%>&prgCde=<%= getPrereqRs.getString("PROG_CDE")%>&Program=<%= prog%>&crsId=<%= getPrereqRs.getInt(1)%>" onClick="return confirm('Are you sure you want to delete roadmap for <%= getPrereqRs.getString("course_nme")%> course?')" class="body_links2">Delete</a></td>
                        <%
                            }
                        %>
                    </tr>
                    <%
                        }

                    %>
                </table>
                <%
                }//if any record exists
                else {
                %>
                <input type="hidden" name="alreadyRMExist" id="alreadyRMExist" value="N"/>
                <table width="100%" class="table_common" align="center">
                    <tr class="normaltextboldRed">
                        <td>No Roadmap has been defined for <%= program%> program</td>
                    </tr>
                </table>
                <%
                    }
                    
                %>
            </fieldset>
            <table>
                <tr>
                    <td class="total-text">
                        Total:&nbsp;<%= total%>		</td>
                </tr>
            </table>
                <%
                            }catch(Exception e){

                            }finally{
                                if (getPrereqRs!=null) {getPrereqRs.close();}
                                if (getProgramListRs!=null) {getProgramListRs.close();}
                                if (getCoursestatusListRs!=null) {getCoursestatusListRs.close();}
                                if (qryPrereqStmt!=null) {qryPrereqStmt.close();}
                            }
                %>
        </form>

    </body>
</html>