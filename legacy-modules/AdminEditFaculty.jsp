<%@ page contentType="text/html; charset=iso-8859-1" language="java" import="java.sql.*, java.util.*,com.towertech.ucp.util.*" session = "true" errorPage="../error.jsp" %>
<html>
    <head>
        <%@ include file="../shared/nocache.inc"%>
        <%@ include file="../shared/findReplace.jsp"%>
        <jsp:useBean id="pool" scope="application" class="com.towertech.ucp.DB.ConnectionPool"/>
        <%!    public void log(String message, String user) {
                System.out.println(new java.util.Date() + "::AdminFaculty.jsp::" + user + "::" + message);
            }
        %>
        <%
            int prmSectionId = -1;
            String prmSectionTxt = "";

            com.towertech.ucp.util.AdminSession adminSession = (com.towertech.ucp.util.AdminSession) session.getAttribute("adminSession");
            if (adminSession == null || adminSession.con == null) {
                log("Session Not Found", "Invalid");
        %>
        <jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/>		
        <%
            }

            if (!adminSession.hasRightsOn("Faculty")) {
        %>
        <jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Faculty service." />
        <%
            }
        %>
        <title>Define Campus</title>
        <script language="JavaScript" type="text/JavaScript">


        </script>

        <link href="../Images/style.css" rel="stylesheet" type="text/css">

        <script language="JavaScript" type="text/JavaScript">

            function fillSelectedValues(f) {

            if( (f.CrHr.value!=null && f.CrHr.value!='' )&& (eval(f.CrHr.value)>0)&& (f.absentLimit.value!=null && f.absentLimit.value!='' ) && (eval(f.absentLimit.value)>0)&&(f.absentLimitSports.value!=null && f.absentLimitSports.value!='' ) && (eval(f.absentLimitSports.value)>0)){
            var option = document.createElement("option");
            option.text = "CrHr: "+f.CrHr.value+" ,AbsentLimit: "+f.absentLimit.value+" ,Absent Sports limit "+f.absentLimitSports.value;
            option.value = f.CrHr.value+"-"+f.absentLimit.value+"-"+f.absentLimitSports.value;
            var select = document.getElementById("selectedValues");
            select.appendChild(option);
            }
            else{
            alert('Please fill the credit hour, absent limit and sports limit values');
            }
            }

            function fillSelectedValuesClass(f) {

            if( (f.creditHrs.value!=null && f.creditHrs.value!='' )&& (eval(f.creditHrs.value)>0)&& (f.classLimit.value!=null && f.classLimit.value!='' ) && (eval(f.classLimit.value)>0)){
            var option = document.createElement("option");
            option.text = "CrHr: "+f.creditHrs.value+" ,AbsentLimit: "+f.classLimit.value;
            option.value = f.creditHrs.value+"-"+f.classLimit.value;
            var select = document.getElementById("selectedValuesClass");
            select.appendChild(option);
            }
            else{
            alert('Please fill the credit hour,class limit  values');
            }
            }
            function removeOption(){
            var selectedOptn = document.getElementById("selectedValues");
            selectedOptn.remove(selectedOptn.selectedIndex);
            }

            function removeOptionClassLimit(){
            var selectedOptn = document.getElementById("selectedValuesClass");
            selectedOptn.remove(selectedOptn.selectedIndex);
            }
            function fillDisc(f) {
                
            if( (f.frmBatch.value!=null )&& f.toCgpa.value!='' && f.frmCgpa.value!=null && f.disc.value!=null){
                var option = document.createElement("option");
                option.text = "From batch: "+f.frmBatch.value+" ,Discount: "+f.disc.value;
                if(f.toBatch.value!=null && f.toBatch.value!=""){
                option.value = f.frmBatch.value+"-"+f.toBatch.value+"-"+f.frmCgpa.value+"-"+f.toCgpa.value+"-"+f.disc.value ;
                }
                else{
                    option.value = f.frmBatch.value+"-"+f.frmCgpa.value+"-"+f.toCgpa.value+"-"+f.disc.value ;
                }
                alert(option.value);
                var select = document.editFacultyForm.selectedDisc;
                select.appendChild(option);
                
            }
             else{
                 alert('Please fill the Discount  values');
             }
            }
            function removeDisc(){
            var selectedOptn = document.getElementById("selectedDisc");
            selectedOptn.remove(selectedOptn.selectedIndex);
            }   

            <!--
            function chkUsr(){ 
            if (document.editFacultyForm.facultyName==null || document.editFacultyForm.facultyName.value=="" )
            {
            alert('Please fill in the Faculty Name');
            document.editFacultyForm.facultyName.focus();
            return false;
            }
            else if (document.editFacultyForm.facultyAbb==null || document.editFacultyForm.facultyAbb.value=="" )
            {
            alert('Please fill in the Faculty Abbreviation');
            document.editFacultyForm.facultyAbb.focus();
            return false;
            }
            else{
            return true;
            }
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
            function refreshPage(param){
            var fId = document.getElementById("facultyId").value;
            document.editFacultyForm.action='AdminEditFaculty.jsp?uId='+param.value+'&facultyId='+fId;
            document.editFacultyForm.submit();
            }
            function redirectOnCancel(mainPage)
            {
            document.editFacultyForm.action = mainPage;
            document.editFacultyForm.submit();
            }
        </script>
    </head>
    <body>
        <table width="100%" class="table_common" align="center" cellpadding="0" cellspacing="0">
            <tr>
                <th class="table_title" scope="col">
                    Edit Faculty
                </th>
            </tr>
        </table>
        <hr>
        <table>
            <tr>
                <td class="normaltextboldRed" colspan="2"><%= nvl(request.getParameter("msg"))%></td>
            </tr>
        </table>
        <form action="AdminProcessEditFaculty.jsp?facultyId=<%= request.getParameter("facultyId")%>" method="post" name="editFacultyForm" id="editFacultyForm"  onsubmit="return chkUsr()">

            <table width="100%" class="table_common" align="center">
                <input type="hidden" name="facultyId" id="facultyId" value="<%= request.getParameter("facultyId")%>">
                <%
                    String uId = "";
                    Statement stmtEditFaculty = adminSession.con.createStatement();
                    adminSession.con.setAutoCommit(false);
                    String qryEditFaculty = "SELECT * FROM FACULTY WHERE FACULTY_ID=" + request.getParameter("facultyId") + "";
                    ResultSet rsEditFaculty = stmtEditFaculty.executeQuery(qryEditFaculty);
                    while (rsEditFaculty.next()) {
                %>
                <tr>
                    <td class="table_sub_title_bold">&nbsp; University *</td>
                    <td class="record_cell_light" colspan=""> <select id="uniName" name="uniName" style="width:160px;" onchange="refreshPage(this)" >

                            <%
                                String status = nvl(rsEditFaculty.getString("ACTIVE_STATUS")); 
                                uId = nvl(request.getParameter("uId"));
                                String prevTermQuery = "SELECT UNI_ID,UNI_NAME FROM UNIVERSITY";
                                Statement uStmt = adminSession.con.createStatement();
                                ResultSet uRs = uStmt.executeQuery(prevTermQuery);
                                while (uRs.next()) {
                            %>
                            <option value="<%=uRs.getString(1)%>" 
                                    <% if (uId != null && uId.equals(uRs.getString(1))) {

                                    %> selected="selected"<% }%>
                                    ><%=uRs.getString(2)%></option>
                            <%
                                }
                                if (uRs != null) {
                                    uRs.close();
                                }
                                if (uStmt != null) {
                                    uStmt.close();
                                }
                            %>

                        </select>
                    </td>
                    <td class="table_sub_title_bold">&nbsp; Campus *</td>
                    <td class="record_cell_light" colspan=""> <select id="cmpName" name="cmpName" style="width:160px;" >

                            <%
                                Statement stmtCamp = adminSession.con.createStatement();
                                if (!uId.equals("")) {
                                    prevTermQuery = "SELECT CMP_ID,CMP_NAME FROM CAMPUS WHERE UNI_ID=" + uId + " ORDER BY CMP_NAME";
                                } else {
                                    prevTermQuery = "SELECT CMP_ID,CMP_NAME FROM CAMPUS ORDER BY CMP_NAME";
                                }
                                ResultSet rs = stmtCamp.executeQuery(prevTermQuery);
                                while (rs.next()) {
                                    if (rsEditFaculty.getString("CMP_ID").equals(rs.getString(1))) {
                            %>
                            <option value="<%=rs.getString(1)%>" selected="selected"><%=rs.getString(2)%></option>
                            <%
                            } else {
                            %>

                            <option value="<%=rs.getString(1)%>"><%=rs.getString(2)%></option>
                            <%}
                                }
                                if (rs != null) {
                                    rs.close();
                                }
                                if (stmtCamp != null) {
                                    stmtCamp.close();
                                }
                            %>

                        </select>
                    </td>
                    <td class="table_sub_title_bold">&nbsp; Faculty Name*</td>
                    <td class="record_cell_light"><input name="facultyName" type="text" id="facultyName" maxlength="250" style="width:160px;" value="<%=rsEditFaculty.getString("FACULTY_NME")%>" /></td>
                </tr>
                <tr>
                    <td class="table_sub_title_bold">&nbsp; Faculty Abbreviation*</td>
                    <td class="record_cell_light"><input name="facultyAbb" type="text" id="facultyAbb" maxlength="10" style="width:90px;" value="<%=rsEditFaculty.getString("FACULTY_ABBREV")%>" /></td>
                    <td class="table_sub_title_bold">&nbsp; Faculty Description </td>
                    <td class="record_cell_light"><textarea name="facultyDsc" type="text" id="facultyDsc" maxlength="250" style="width:300px;"><%=nvl(rsEditFaculty.getString("FACULTY_Dsc"))%></textarea></td>
                    <td class="table_sub_title_bold">Active</td>
<%
            if("Y".equalsIgnoreCase(status))
            {
%>                    
                    <td class="record_cell_light"><input id=status" name="status" type="checkbox" checked="checked"></td>  
<%
            }else
            {
%>                    
                    <td class="record_cell_light"><input id=status" name="status" type="checkbox"></td>  
<%
            }
%>                    
                </tr>
            </table>
            <%}%>
            <fieldset>
                <legend class="table_title_small">Absent Limit</legend>
                <table width="100%" class="table_common" align="center">
                    <tr>
                        <td class="table_sub_title_bold"> &nbsp; Credit Hours *</td>
                        <td class="record_cell_light"><select id="CrHr" name="crHr">
                                <option value="1">1</option>
                                <option value="2">2</option>
                                <option value="3">3</option>
                                <option value="4">4</option>
                                <option value="5">5</option>
                                <option value="6">6</option>                                
                            </select>
                        </td>
                    </tr>
                    <tr>
                        <td class="table_sub_title_bold">&nbsp; Absent Limit *</td>
                        <td class="record_cell_light"><input type = "number" id="absentLimit" name="absentLimit" min="0"></td>
                    </tr>
                    <tr>
                        <td class="table_sub_title_bold">&nbsp; Absent Limit Sports *</td>
                        <td class="record_cell_light"><input type = "number" id="absentLimitSports" name="absentLimitSports" min="0"></td>
                    </tr>
                    <tr>
                        <td class="table_sub_title_bold">&nbsp; Options *</td>
                        <td class="record_cell_light">
                            <input type = "button" id="checkLimit" name="checkLimit" onclick="fillSelectedValues(this.form)" value="Add">
                            <input type = "button" id="checkLimit" name="checkLimit" onclick="removeOption()" value="Remove">
                        </td>

                    </tr>
                    <tr>
                        <td class="table_sub_title_bold">&nbsp; Credit Hour : Absent Limit : Absent Limit Sports </td>
                        <td class="record_cell_light"><select id="selectedValues" multiple ="true" name ="selectedValues" >
                                <%
                                    String query = "SELECT * FROM ABSENT_LIMIT WHERE FACULTY_ID = '" + request.getParameter("facultyId") + "'";
                                    Statement absentLimitStmt = null;
                                    ResultSet absentLimitResult = null;
                                    try {
                                        absentLimitStmt = adminSession.con.createStatement();
                                        absentLimitResult = absentLimitStmt.executeQuery(query);
                                        while (absentLimitResult.next()) {
                                %>

                                <option value ="<%=absentLimitResult.getString("CREDIT_HRS")%>-<%=absentLimitResult.getString("ABSENT_LIMIT")%>-<%=absentLimitResult.getString("ABSENT_LIMIT_SPORTS")%>">
                                    <%="CrHr " + absentLimitResult.getString("CREDIT_HRS")%>:<%="AbsentLimit " + absentLimitResult.getString("ABSENT_LIMIT")%>:<%="AbsentLimitSports " + absentLimitResult.getString("ABSENT_LIMIT_SPORTS")%>
                                </option>
                                <% }
                                    } catch (Exception ex) {
                                        ex.getMessage();
                                        absentLimitStmt.close();
                                        absentLimitResult.close();
                                    } finally {
                                        if (absentLimitStmt != null) {
                                            absentLimitStmt.close();
                                        }
                                        if (absentLimitResult != null) {
                                            absentLimitResult.close();
                                        }

                                    }

                                %>
                            </select></td>
                    </tr>
                </table>
            </fieldset>
            <fieldset>
                <legend class="table_title_small">Credit Load Definition</legend>
                <table width="100%" class="table_common" align="center">
                    <tr>
                        <td class="table_sub_title_bold"> &nbsp; Credit Hours *</td>
                        <td class="record_cell_light"><select id="creditHrs" name="creditHrs">
                                <option value="1">1</option>
                                <option value="2">2</option>
                                <option value="3">3</option>
                                <option value="4">4</option>
                            </select>
                        </td>
                    </tr>
                    <tr>
                        <td class="table_sub_title_bold">&nbsp; Class Limit *</td>
                        <td class="record_cell_light"><input type = "number" id="classLimit" name="classLimit"></td>
                    </tr>

                    <tr>
                        <td class="table_sub_title_bold">&nbsp; Options *</td>
                        <td class="record_cell_light"><input type = "button" id="checkLimit" name="checkLimit" onclick="fillSelectedValuesClass(this.form)" value="Add">
                            <input type = "button" id="checkLimit" name="checkLimit" onclick="removeOptionClassLimit()" value="Remove">
                        </td>

                    </tr>

                    <tr>
                        <td class="table_sub_title_bold">&nbsp; Credit Hour : Class Limit </td>
                        <td class="record_cell_light"><select id="selectedValuesClass" multiple ="true" name ="selectedValuesClass" >
                                <%                            String classLimitQuery = "SELECT * FROM CREDIT_LOAD_DEFINITION WHERE FACULTY_ID = '" + request.getParameter("facultyId") + "'";
                                    Statement classLimitStmt = null;
                                    ResultSet classLimitRs = null;
                                    try {
                                        classLimitStmt = adminSession.con.createStatement();
                                        classLimitRs = classLimitStmt.executeQuery(classLimitQuery);

                                        while (classLimitRs.next()) {
                                %>
                                <option value ="<%=classLimitRs.getString("CREDIT_HRS")%>-<%=classLimitRs.getString("CLASS_LIMIT")%>" >
                                    <%="CrHr " + classLimitRs.getString("CREDIT_HRS")%>:<%="Class Limit " + classLimitRs.getString("CLASS_LIMIT")%>
                                </option>

                                <% }
                                    } catch (Exception ex) {
                                        ex.getMessage();
                                        classLimitStmt.close();
                                        classLimitRs.close();
                                    } finally {
                                        if (classLimitStmt != null) {
                                            classLimitStmt.close();
                                        }
                                        if (classLimitRs != null) {
                                            classLimitRs.close();
                                        }
                                    }

                                %>
                            </select></td>
                    </tr>
                </table>
            </fieldset>
               <fieldset>
                    <legend class="table_title_small">Discount Policy</legend>
                    <table width="100%" class="table_common" align="center">
                        <tr>
                        <td class="table_sub_title_bold">&nbsp; From CGPA *</td>
                        <td class="record_cell_light"><input type = "text" id="frmCgpa" name="frmCgpa"></td>
                        </tr>

                        <tr>
                        <td class="table_sub_title_bold">&nbsp; To CGPA*</td>
                        <td class="record_cell_light">
                            <input type= "text" id="toCgpa" name="toCgpa">
                        </td>
                        </tr>
                <tr>
                    <td class="table_sub_title_bold"> &nbsp; From Batch *</td>
                    <td class="record_cell_light"><select id="frmBatch" name="frmBatch">
                            <%
                                Statement addTermStmt= adminSession.con.createStatement();
                                String termQry = "select  term_cde, t.START_DTE from term t order by t.START_DTE  desc";
                                ResultSet rs = addTermStmt.executeQuery(termQry);
                                while (rs.next()) {
                            %>
                            <option value="<%=rs.getString("term_cde")%>"><%=rs.getString("term_cde")%></option>
                            <%
                                }
                            %>
                        </select>
                    </td>
                </tr>
                
                <tr>
                    <td class="table_sub_title_bold"> &nbsp; To Batch </td>
                    <td class="record_cell_light"><select id="toBatch" name="toBatch">
                            <option value="">&nbsp;</option>
                            <%
                                termQry = "select  term_cde, t.START_DTE from term t order by t.START_DTE  desc";
                                rs = addTermStmt.executeQuery(termQry);
                                while (rs.next()) {
                            %>
                            <option value="<%=rs.getString("term_cde")%>"><%=rs.getString("term_cde")%></option>
                            <%
                                }
                            %>
                        </select>
                    </td>
                </tr>
                <tr>
                        <td class="table_sub_title_bold">&nbsp; Discount Percentage *</td>
                        <td class="record_cell_light"><input type = "text" id="disc" name="disc"></td>
                        </tr>
                        
                <tr>
                  <td class="table_sub_title_bold">&nbsp; Options *</td>
                    <td class="record_cell_light"><input type = "button" id="discPolicy" name="discPolicy" onclick="fillDisc(this.form)" value="Add">
                    <input type = "button" id="checkDisc" name="checkDisc" onclick="removeDisc()" value="Remove">
                    </td>
                    
                </tr>
                <tr>
                    <td class="table_sub_title_bold">&nbsp; Discount Policy</td>
                    <td class="record_cell_light"><select id="selectedDisc" multiple ="true" name ="selectedDisc" >
                        
                             <%                            
                                String discPolQuery = "SELECT D.DISCID, D.DISCOUNT_POLICY_ID, D.FACULTY_ID, D.FROM_BATCH, D.FROM_CGPA, D.PCT, D.TO_BATCH, D.TO_CGPA  FROM DISCOUNT_POLICY D WHERE FACULTY_ID = '" + request.getParameter("facultyId") + "'";
                                Statement discPolStmt = null;
                                ResultSet discPolRs = null;
                                    try {
                                        discPolStmt = adminSession.con.createStatement();
                                        discPolRs = discPolStmt.executeQuery(discPolQuery);

                                        while (discPolRs.next()) {
//"From batch: "+f.frmBatch.value+" ,Discount: "+f.disc.value
                                            if(discPolRs.getString("to_batch")!=null){
                                %>
                                <option value ="<%=discPolRs.getString("FROM_BATCH")%>-<%=discPolRs.getString("TO_BATCH")%>-<%=discPolRs.getString("FROM_CGPA")%>-<%=discPolRs.getString("TO_CGPA")%>-<%=discPolRs.getString("PCT")%>" >
                                    <%="From batch: " + discPolRs.getString("FROM_BATCH")%>:<%="Discount:" + discPolRs.getString("PCT")%>
                                </option>

                                <% }else{
                                                %>
                                <option value ="<%=discPolRs.getString("FROM_BATCH")%>-<%=discPolRs.getString("FROM_CGPA")%>-<%=discPolRs.getString("TO_CGPA")%>-<%=discPolRs.getString("PCT")%>" >
                                    <%="From batch: " + discPolRs.getString("FROM_BATCH")%>:<%="Discount:" + discPolRs.getString("PCT")%>
                                </option>

                                <%
                                            }
                                            }
                                    } catch (Exception ex) {
                                        ex.getMessage();
                                        classLimitStmt.close();
                                        classLimitRs.close();
                                    } finally {
                                        if (classLimitStmt != null) {
                                            classLimitStmt.close();
                                        }
                                        if (classLimitRs != null) {
                                            classLimitRs.close();
                                        }
                                    }

                                %>
                        </select></td>
                </tr>
                    </table>
               </fieldset>
            <table>
                <tr>
                    <td></td>
                    <td>
                        <input type="submit" value="Update" />
                        <input type="button" value="Cancel" onclick="redirectOnCancel('AdminFaculty.jsp')" /></td>
                </tr>
            </table>
        
    </body>
</html>
