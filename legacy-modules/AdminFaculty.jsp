<%-- 
    Document   : AdminFaculty
    Created on : Aug 24, 2012, 11:07:46 AM
    Author     : Aysha
--%>
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
                option.text = "CrHr: "+f.creditHrs.value+" ,ClassLimit: "+f.classLimit.value;
                option.value = f.creditHrs.value+"-"+f.classLimit.value;
                var select = document.facultyForm.selectedValuesClass;
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
                var select = document.facultyForm.selectedDisc;
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
        </script>

        <link href="../Images/style.css" rel="stylesheet" type="text/css">

        <script language="JavaScript" type="text/JavaScript">
            <!--
            function chkUsr(){ 
            if (document.facultyForm.facultyName==null || document.facultyForm.facultyName.value=="" )
            {
            alert('Please fill in the Faculty Name');
            document.facultyForm.facultyName.focus();
            return false;
            }
            else if (document.facultyForm.facultyAbb==null || document.facultyForm.facultyAbb.value=="" )
            {
            alert('Please fill in the Faculty Abbreviation');
            document.facultyForm.facultyAbb.focus();
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
            var uId = document.getElementById("uniName").value;
            document.facultyForm.action='AdminFaculty.jsp?uId='+param.value;
            document.facultyForm.submit();
            }
        </script>
    </head>
    <body onLoad="changeIt('AdminFaculty.jsp');">
        <table width="100%" class="table_common" align="center" cellpadding="0" cellspacing="0">
            <tr>
                <th class="table_title" scope="col">
                    Define Faculty
                </th>
            </tr>
        </table>
        <hr>
        <table><tr><td class="normaltextboldRed" colspan="2">
                    <%= nvl(request.getParameter("msg"))%>
                    <% String uId = ""; %>
                </td></tr></table>
        <form action="AdminProcessFaculty.jsp" method="post" name="facultyForm" id="facultyForm" onsubmit="return chkUsr();">
            <table width="100%" class="table_common" align="center">
                <tr>
                    <td class="table_sub_title_bold">&nbsp; University *</td>
                    <td class="record_cell_light" colspan=""> <select id="uniName" name="uniName" style="width:160px;" onchange="refreshPage(this)" >

                            <%
                                uId = nvl(request.getParameter("uId"));
                                String prevTermQuery = "SELECT UNI_ID,UNI_NAME FROM UNIVERSITY ORDER BY UNI_ID ASC";
                                Statement uStmt = adminSession.con.createStatement();
                                ResultSet uRs = uStmt.executeQuery(prevTermQuery);
                            try{
                                while (uRs.next()) {
                            %>
                            <option value="<%=uRs.getString(1)%>" 
                                    <% if (uId != null && uId.equals(uRs.getString(1))) {

                                    %> selected="selected"<% }%>
                                    ><%=uRs.getString(2)%></option>
                            <%
                                }
                                if (uRs != null) {uRs.close();}
                                if (uStmt != null) {uStmt.close();}
                                }catch(Exception e){
                                    if (uRs != null) {uRs.close();}
                                    if (uStmt != null) {uStmt.close();}
                                }
                            %>

                        </select>
                    </td>
                    <td class="table_sub_title_bold">&nbsp; Campus *</td>
                    <%
                        Statement addTermStmt =  null;
                        ResultSet rs=null;
                        addTermStmt = adminSession.con.createStatement();
                        adminSession.con.setAutoCommit(false);
                        try{
                    %>
                    <td class="record_cell_light" > <select id="cmpName" name="cmpName" style="width:300px;" >
                            <%
                                if (!uId.equals("")) {
                                    prevTermQuery = "SELECT CMP_ID,CMP_NAME FROM CAMPUS WHERE UNI_ID=" + uId + " ORDER BY CMP_NAME";
                                } else {
                                    prevTermQuery = "SELECT CMP_ID,CMP_NAME FROM CAMPUS WHERE UNI_ID=1 ORDER BY CMP_NAME";
                                }
                                rs = addTermStmt.executeQuery(prevTermQuery);
                                while (rs.next()) {
                            %>
                            <option value="<%=rs.getString(1)%>"><%=rs.getString(2)%></option>
                            <%
                                }
//                                if (rs != null) {
//                                    rs.close();
//                                }
                            %>

                        </select>
                    </td>
                    <td class="table_sub_title_bold">&nbsp; Faculty Name*</td>
                    <td class="record_cell_light"><input name="facultyName" type="text" id="facultyName" maxlength="80" style="width:160px;" /></td>
                </tr>
                <tr>
                    <td class="table_sub_title_bold">&nbsp; Faculty Abbreviation*</td>
                    <td class="record_cell_light"><input name="facultyAbb" type="text" id="facultyAbb" maxlength="10"/></td>
                    <td class="table_sub_title_bold">&nbsp; Faculty Description </td>
                    <td class="record_cell_light" ><textarea name="facultyDsc" type="text" style="width:300px;" id="facultyDsc" maxlength="500"></textarea></td>
                    <td class="table_sub_title_bold">Active</td>
                    <td class="record_cell_light"><input id=status" name="status" type="checkbox" checked></td>               
                </tr>
              
                
            </table>
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
                    <td class="record_cell_light"><input type = "button" id="checkLimit" name="checkLimit" onclick="fillSelectedValues(this.form)" value="Add">
                    <input type = "button" id="checkLimit" name="checkLimit" onclick="removeOption()" value="Remove">
                    </td>
                    
                </tr>
               
                <tr>
                    <td class="table_sub_title_bold">&nbsp; Credit Hour : Absent Limit : Absent Limit Sports </td>
                    <td class="record_cell_light"><select id="selectedValues" multiple ="true" name ="selectedValues" ></select></td>
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
                            <option value="5">5</option>
                            <option value="6">6</option>
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
                    <td class="record_cell_light"><select id="selectedValuesClass" multiple ="true" name ="selectedValuesClass" ></select></td>
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
                                String termQry = "select  term_cde, t.START_DTE from term t order by t.START_DTE  desc";
                                if (rs!=null) {rs.close();}
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
                    <td class="table_sub_title_bold"> &nbsp; To Batch </td>
                    <td class="record_cell_light"><select id="toBatch" name="toBatch">
                            <option value="">&nbsp;</option>
                            <%
                                if (rs!=null) {rs.close();}
                                termQry = "select  term_cde, t.START_DTE from term t order by t.START_DTE  desc";
                                rs = addTermStmt.executeQuery(termQry);
                                while (rs.next()) {
                            %>
                            <option value="<%=rs.getString("term_cde")%>"><%=rs.getString("term_cde")%></option>
                            <%
                                }
                        }catch(Exception e){
                            if (rs!=null) {rs.close();}
                            if (addTermStmt!=null) {addTermStmt.close();}
                        }finally{
                            if (rs!=null) {rs.close();}
                            if (addTermStmt!=null) {addTermStmt.close();}
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
                    <td class="record_cell_light"><select id="selectedDisc" multiple ="true" name ="selectedDisc" ></select></td>
                </tr>
                    </table>
               </fieldset>
               
                            
                            <table>
                                <tr>
                    <td colspan="5"  align="center">
                        <input type="submit" name="Submit" value="Save">
                    </td>
                </tr>
                            </table>
        </form>

        <fieldset><legend class="table_title_small">Faculty</legend>
            <div id="navbtns1" align="center"></div>
            <table width="100%" border="0" align="center">


                <tr class="table_sub_title_bold">

                    <td width="5%">Sr.No</td>
                    <td width="20%">University</td>
                    <td width="10%">Campus</td>
                    <td width="15%">Faculty Name</td>
                    <td width="10%">Faculty Abbreviation</td>
                    <td width="33%">Faculty Description</td>
                    <td width="5%">Status</td>
                    <td colspan="2">Options</td>
                </tr>
                <%
                    Statement faultyIdStmt = adminSession.con.createStatement();
                    Statement campStmt =null, uniStmt =null;
                    ResultSet getFacultyRs = null,rsCamp=null, rsUni=null ;
                    try{
                     getFacultyRs = faultyIdStmt.executeQuery("SELECT F.FACULTY_NME,F.FACULTY_ABBREV,F.FACULTY_DSC,C.CMP_ID,F.FACULTY_ID, U.UNI_ID, DECODE(ACTIVE_STATUS,'Y','Active','N','Disabled',NULL,'-',ACTIVE_STATUS) ACTIVE_STATUS "
                            + " FROM FACULTY F, CAMPUS C, UNIVERSITY U WHERE C.CMP_ID=F.CMP_ID AND C.UNI_ID=U.UNI_ID");
                    int count = 1;
                    while (getFacultyRs.next()) {
                        
                            if("Disabled".equalsIgnoreCase(getFacultyRs.getString("ACTIVE_STATUS")))
                            {
                                out.println("<tr class=\"record_cell_light_red\">");
%>                                
                                <tr class="record_cell_light" style="color:red;font-family: Arial; font-size:10px; font-weight:bold">  
<%                            
                            }else
                            {
%>                                
                                <tr class="record_cell_light"> 
<%
                           }
%>
                    <td  ><%= count++%></td>

                    <%
                        uniStmt = adminSession.con.createStatement();
                        String uni = "select u.uni_name from university u, campus c where u.uni_id = c.uni_id and c.CMP_ID=" + getFacultyRs.getString(4) + "";
                        rsUni = uniStmt.executeQuery(uni);
                        while (rsUni.next()) {
                    %>
                    <td><%= rsUni.getString(1)%> </td>
                    <%
                        }
                        if (uniStmt != null) {uniStmt.close();}
                        if (rsUni != null) {rsUni.close();}
                        campStmt = adminSession.con.createStatement();
                        String camp = "SELECT CMP_NAME FROM CAMPUS WHERE CMP_ID=" + getFacultyRs.getString(4) + "";
                        rsCamp = campStmt.executeQuery(camp);
                        while (rsCamp.next()) {
                    %>
                    <td><%= rsCamp.getString(1)%> </div></td>
                    <%
                        }
                        if (campStmt != null) {campStmt.close();}
                        if (rsCamp != null) {rsCamp.close();}
                    %>
                    <td><%= getFacultyRs.getString(1)%></td>
                    <td><%= getFacultyRs.getString(2)%></td>
                    <td><%= nvl(getFacultyRs.getString(3))%> </div></td>
                    <td><%= nvl(getFacultyRs.getString("ACTIVE_STATUS"))%></td>
                    <td width="9%" class="current_term" ><a href="AdminEditFaculty.jsp?facultyId=<%=getFacultyRs.getString(5)%>&uId=<%=getFacultyRs.getString(6)%>" class="body_links2">Edit</a></td>
                    <td width="9%"><a href="AdminProcessDeleteFaculty.jsp?facultyId=<%=getFacultyRs.getString(5)%>" onClick="return confirm('Are you sure you want to delete?')" class="body_links2">Delete</a></td>
                    <%
                        }
                    %>

                </tr>
                <%
                    if (getFacultyRs != null){getFacultyRs.close();} 
                    if(faultyIdStmt != null) {faultyIdStmt.close();}
                    }catch(Exception e){
                            if (getFacultyRs != null){getFacultyRs.close();} 
                            if (rsCamp != null){rsCamp.close();} 
                            if (rsUni != null){rsUni.close();} 
                            if(faultyIdStmt != null) {faultyIdStmt.close();}
                            if(campStmt != null) {campStmt.close();}
                            if(uniStmt != null) {uniStmt.close();}
                        }finally{
                            if (getFacultyRs != null){getFacultyRs.close();} 
                            if (rsCamp != null){rsCamp.close();} 
                            if (rsUni != null){rsUni.close();} 
                            if(faultyIdStmt != null) {faultyIdStmt.close();}
                            if(campStmt != null) {campStmt.close();}
                            if(uniStmt != null) {uniStmt.close();}
                        }
                %>
            </table>
        </fieldset>
    </body>
</html>

