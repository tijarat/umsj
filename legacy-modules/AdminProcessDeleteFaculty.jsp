<%-- 
    Document   : AdminProcessDeleteFaculty
    Created on : Aug 24, 2012, 1:12:57 PM
    Author     : Aysha
--%>
<%@ page contentType="text/html;" language="java" import="java.sql.*, java.util.*" session = "true" errorPage="../error.jsp" %>
<html>
    <head>
        <%@ include file="../shared/nocache.inc"%>
        <%!
            public void log(String message, String user) {
                System.out.println(new java.util.Date() + "::AdminProcessDeleteFaculty.jsp::" + user + "::" + message);
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
        <title>Define University</title>
        <script language="JavaScript" type="text/JavaScript">
            <!--
            function redirect(mainPage)
            {
            document.editCampusForm.action = mainPage;
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
            //String term=pool.getCurrentTerm(adminSession.getWorkingFacultyId(), adminSession.con);
            String facultyId = request.getParameter("facultyId");
            Statement deleteFacultyStmt = null;
            String msg = "";

            try {
                deleteFacultyStmt = adminSession.con.createStatement();
                adminSession.con.setAutoCommit(false);
                int n = deleteFacultyStmt.executeUpdate("DELETE FROM UCP.CURRENT_TERM WHERE FACULTY_ID = " + facultyId + "");
                adminSession.addLog("DELETE FROM UCP.CURRENT_TERM WHERE FACULTY_ID = " + facultyId.replace('\'', '`'));
                    n =deleteFacultyStmt.executeUpdate("DELETE FROM ABSENT_LIMIT WHERE FACULTY_ID = " + facultyId);
                    adminSession.addLog("DELETE FROM ABSENT_LIMIT WHERE FACULTY_ID = " + facultyId.replace('\'', '`'));
                    n =deleteFacultyStmt.executeUpdate("DELETE FROM CREDIT_LOAD_DEFINITION WHERE FACULTY_ID =" + facultyId);
                    adminSession.addLog("DELETE FROM CREDIT_LOAD_DEFINITION WHERE FACULTY_ID =" + facultyId.replace('\'', '`'));
                    n =deleteFacultyStmt.executeUpdate("DELETE FROM DISCOUNT_POLICY WHERE FACULTY_ID = " + facultyId);
                    adminSession.addLog("DELETE FROM DISCOUNT_POLICY WHERE FACULTY_ID = " + facultyId.replace('\'', '`'));
                    n =deleteFacultyStmt.executeUpdate("DELETE FROM ENV_VARIABLE WHERE FACULTY_ID = " + facultyId);
                    adminSession.addLog("DELETE FROM ENV_VARIABLE WHERE FACULTY_ID = " + facultyId.replace('\'', '`'));
              //  if (n > 0) {
                    int num = deleteFacultyStmt.executeUpdate("DELETE FROM UCP.FACULTY WHERE FACULTY_ID = " + facultyId + "");
                    adminSession.addLog("DELETE FROM UCP.FACULTY WHERE FACULTY_ID = " + facultyId.replace('\'', '`'));
                    if (num > 0) {
                        msg = "Record Deleted Successfully.";
                        adminSession.con.commit();
                    }
                //}
                if (deleteFacultyStmt != null) {
                    deleteFacultyStmt.close();
                }
                String myURL = "AdminFaculty.jsp?msg=" + msg;
                response.sendRedirect(myURL);
            } catch (SQLException e) {
                adminSession.con.rollback();
                throw new SQLException("This Faculty Contains Child Records~" + e.toString());

            }
        %>
    </body>
</html>


