<%-- 
    Document   : AdminProcessEditFaculty
    Created on : Aug 24, 2012, 1:12:21 PM
    Author     : Aysha
--%>

<%@ page contentType="text/html;" language="java" import="java.sql.*, java.util.*" session = "true" errorPage="../error.jsp" %>
        <%@ include file="../shared/findReplace.jsp"%>
<html>
    <head>
        <%@ include file="../shared/nocache.inc"%>
        <%!
            public void log(String message, String user) {
                System.out.println(new java.util.Date() + "::AdminProcessEditFaculty.jsp::" + user + "::" + message);
            }
        %>

        <%
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
        <%    }
        %>
        <title>Define CAMPUS</title>
        <script language="JavaScript" type="text/JavaScript">
            <!--
            function redirect(mainPage)
            {
                document.editFacultyForm.action = mainPage;
            }



            function MM_openBrWindow(theURL,winName,features) { //v2.0
                window.open(theURL,winName,features);
            }
            //-->
        </script>
        <link href="../Images/style.css" rel="stylesheet" type="text/css">
        <script language="JavaScript" type="text/JavaScript">
            <!--


            function MM_reloadPage(init) {  //reloads the window if Nav4 resized
                if (init==true) with (navigator) {if ((appName=="Netscape")&&(parseInt(appVersion)==4)) {
                        document.MM_pgW=innerWidth; document.MM_pgH=innerHeight; onresize=MM_reloadPage; }}
                else if (innerWidth!=document.MM_pgW || innerHeight!=document.MM_pgH) location.reload();
            }
            MM_reloadPage(true);
            //-->
        </script>
    </head>
    <body>
        <%
            String cmpName = request.getParameter("cmpName");
            String facultyName = request.getParameter("facultyName");
            String facultyAbb = request.getParameter("facultyAbb");
            String facultyDsc = request.getParameter("facultyDsc");
            String facultyId= request.getParameter("facultyId");
            String query = "";
            String msg = "";
            Statement editFacultyStmt = null;
            String[] selectedValues = request.getParameterValues("selectedValues");
            String[] selectedValuesClass = request.getParameterValues("selectedValuesClass");
            String[] selectedDisc = request.getParameterValues("selectedDisc");
            String status=request.getParameter("status");
            if(status!=null && status.equals("on"))
                status = "Y";
            else
              status ="N";              
            if(selectedValues==null){
                %>
                <jsp:forward page="AdminEditFaculty.jsp">
                        <jsp:param name="msg" value="Please select atleast one value from the absent limit list"/>
                        </jsp:forward>
                %<%
            }
            String [] limitValues =null;
            String limitQuery= "";
            String[] classValues = null;
            String classQuery="";
            Connection con = adminSession.con;
            String sql = "";

            try {
                    con.setAutoCommit(false);
                 
                editFacultyStmt = con.createStatement();
                sql = "UPDATE FACULTY SET FACULTY_NME='"+facultyName+"',FACULTY_ABBREV='"+facultyAbb+"',FACULTY_DSC='"+facultyDsc+"',CMP_ID="+cmpName+",ACTIVE_STATUS='"+status+"' WHERE FACULTY_ID="+facultyId+"";
                int num = editFacultyStmt.executeUpdate(sql);
                adminSession.addLog(sql,editFacultyStmt);
                if (num > 0) 
                {
                        sql = "DELETE FROM ABSENT_LIMIT WHERE FACULTY_ID = "+facultyId;
                        editFacultyStmt.executeUpdate(sql);
                        adminSession.addLog(sql,editFacultyStmt);

                        sql = "DELETE FROM CREDIT_LOAD_DEFINITION WHERE FACULTY_ID ="+facultyId;
                        editFacultyStmt.executeUpdate(sql);
                        adminSession.addLog(sql,editFacultyStmt);

                        //sql = "DELETE FROM DISCOUNT_POLICY WHERE FACULTY_ID = "+facultyId;
                        //editFacultyStmt.executeUpdate(sql);
                        //adminSession.addLog(sql,editFacultyStmt);

                        for (int i = 0; i < selectedValues.length; i++) 
                        {
                            limitValues = selectedValues[i].split("-");
                            
                            limitQuery = "INSERT INTO ABSENT_LIMIT(ABSENT_LIMIT_ID,CREDIT_HRS,ABSENT_LIMIT,FACULTY_ID,FACULTY_ABBREV, ABSENT_LIMIT_SPORTS) VALUES(SEQ_ABSENT_LIMIT_ID.NEXTVAL,'" + limitValues[0] + "','" + limitValues[1] + "'," + facultyId + ",'" + facultyAbb + "','" + limitValues[2] + "')";
                            editFacultyStmt.executeUpdate(limitQuery);
                            adminSession.addLog(limitQuery,editFacultyStmt);
                        }
                        if (selectedValuesClass != null) {
                            for (int i = 0; i < selectedValuesClass.length; i++) {
                                classValues = selectedValuesClass[i].split("-");
                                classQuery = "INSERT INTO CREDIT_LOAD_DEFINITION(CREDIT_LOAD_DEFINITION_ID,CREDIT_HRS,CLASS_LIMIT,FACULTY_ID,FACULTY_ABBREV) VALUES (SEQ_CREDIT_LOAD_DEFINITION_ID.NEXTVAL,'" + classValues[0] + "','" + classValues[1] + "','" + facultyId + "','" + facultyAbb + "')";
                                editFacultyStmt.executeUpdate(classQuery);
                                adminSession.addLog(classQuery,editFacultyStmt);
                            }
                        }String envQuery="";
                        if(false){//(selectedDisc!=null){
                        for(int i=0;i<selectedDisc.length;i++){
                            limitValues= selectedDisc[i].split("-");
                            if(limitValues.length==5){
                        envQuery = "INSERT INTO DISCOUNT_POLICY VALUES"
                         +" ((select max(DISCOUNT_POLICY_ID)+1 from discount_policy), '"+facultyId+"','"+limitValues[0]+"', '"+nvl(limitValues[1])+"', '"+limitValues[2]+"', '"+limitValues[3]+"', '"+limitValues[4]+"', 23843 )";
                            }else{
                            envQuery = "INSERT INTO DISCOUNT_POLICY VALUES"
                         +" ((select max(DISCOUNT_POLICY_ID)+1 from discount_policy), '"+facultyId+"','"+limitValues[0]+"', '', '"+limitValues[1]+"', '"+limitValues[2]+"', '"+limitValues[3]+"', 23843 )";
                            }
                        editFacultyStmt.executeUpdate(envQuery);
                        adminSession.addLog(envQuery,editFacultyStmt);
                            }
                        }
                   adminSession.con.commit(); 
                }
                if (num != 0) {
                    msg = "Edited Successfully";
                }
                String myURL="AdminFaculty.jsp?msg="+msg;
                response.sendRedirect(myURL);
            } catch (SQLException e) {
                adminSession.con.rollback();
                throw new SQLException("Operation Failure~" + e.toString());
            }finally{
                if(editFacultyStmt!=null){
                    editFacultyStmt.close();
                }
            }
        %>
    </body>
    </html>
