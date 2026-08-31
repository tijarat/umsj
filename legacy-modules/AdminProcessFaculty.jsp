<%-- 
    Document   : AdminProcessFaculty
    Created on : Aug 24, 2012, 11:22:16 AM
    Author     : Aysha
--%>
<%@ page contentType="text/html; charset=windows-1252" language="java" import="java.sql.*, java.util.*,com.towertech.ucp.util.*" session = "true" errorPage="../error.jsp" %>
        <%@ include file="../shared/findReplace.jsp"%>
<html>
    <%!
        public void log(String message, String user) {
            System.out.println(new java.util.Date() + "::AdminProcessFaculty.jsp::" + user + "::" + message);
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

        if (!adminSession.hasRightsOn("Faculty")) {
    %>
    <jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Faculty service." />
    <%    }
    %>

    <head>
    </head>
    <body>
        <%

            String cmpName = request.getParameter("cmpName");
            String facultyName = request.getParameter("facultyName");
            String facultyAbb = request.getParameter("facultyAbb");
            String facultyDsc = request.getParameter("facultyDsc");
            String query = "";
            String msg = "";
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
                <jsp:forward page="AdminFaculty.jsp">
                        <jsp:param name="msg" value="Please select atleast one value from the absent limit list"/>
                        </jsp:forward>
                %<%
            }
            String [] limitValues =null;
            String limitQuery= "";
            String[] classValues = null;
            String classQuery="";
            String envQuery ="";
            try {
                Statement addTermStmt = adminSession.con.createStatement();
                adminSession.con.setAutoCommit(false);
                String fId="SELECT SEQ_FACULTY_ID.NEXTVAL FROM DUAL";
                ResultSet rst = addTermStmt.executeQuery(fId);
                rst.next();
                int facultyId=rst.getInt(1);
                query = "INSERT INTO UCP.FACULTY (FACULTY_ABBREV,FACULTY_NME,FACULTY_DSC,FACULTY_ID,CMP_ID,ACTIVE_STATUS) VALUES('" + facultyAbb + "','" + facultyName + "','" + facultyDsc + "',"+facultyId+","+cmpName+",'" + status + "')"; 
                int num=addTermStmt.executeUpdate(query);
                adminSession.addLog(query.replace('\'', '`'));
                if(num > 0){
                    query="INSERT INTO CURRENT_TERM (TERM_CDE,FACULTY_ID) VALUES('"+adminSession.workingTerm+"',"+facultyId+")"; 
                    int n=addTermStmt.executeUpdate(query);
                    adminSession.addLog(query.replace('\'', '`'));
                    if(n > 0){
                        for(int i=0;i<selectedValues.length;i++){
                            limitValues= selectedValues[i].split("-");
                            limitQuery ="INSERT INTO ABSENT_LIMIT(ABSENT_LIMIT_ID,CREDIT_HRS,ABSENT_LIMIT,FACULTY_ID,FACULTY_ABBREV, ABSENT_LIMIT_SPORTS) VALUES(SEQ_ABSENT_LIMIT_ID.NEXTVAL,'"+limitValues[0]+"','"+limitValues[1]+"',"+facultyId+",'"+facultyAbb+"','"+limitValues[2]+"')";
                            addTermStmt.executeUpdate(limitQuery);
                            adminSession.addLog(query.replace('\'', '`'));
                        }
                        if(selectedValuesClass!=null){
                            for(int i=0;i<selectedValuesClass.length;i++){
                                classValues= selectedValuesClass[i].split("-");
                                classQuery ="INSERT INTO CREDIT_LOAD_DEFINITION(CREDIT_LOAD_DEFINITION_ID,CREDIT_HRS,CLASS_LIMIT,FACULTY_ID,FACULTY_ABBREV) VALUES (SEQ_CREDIT_LOAD_DEFINITION_ID.NEXTVAL,'"+classValues[0]+"','"+classValues[1]+"','"+facultyId+"','"+facultyAbb+"')";
                                addTermStmt.executeUpdate(classQuery);
                                adminSession.addLog(classQuery.replace('\'', '`'));
                            }
                        }
                        envQuery = "INSERT INTO ENV_VARIABLE(ENV_VAR_ID, VAR_NME, VAR_VAL, VAR_DSC, VAR_TYP, FACULTY_ID, FACULTY_ABBREV) "+
                                "SELECT SEQ_ENV_VAR_ID.NEXTVAL,VAR_NME_DFLT, VAR_VAL_DFLT, VAR_DSC_DFLT, VAR_TYP_DFLT,"+facultyId+",'" + facultyAbb + "' FROM ENV_VARIABLE_DEFAULT";
                        addTermStmt.executeUpdate(envQuery);
                        adminSession.addLog(envQuery.replace('\'', '`'));
                        if(selectedDisc!=null){
                        for(int i=0;i<selectedDisc.length;i++){
                            limitValues= selectedDisc[i].split("-");
                            if(limitValues.length==5){
                        envQuery = "INSERT INTO DISCOUNT_POLICY VALUES"
                         +" ((select max(DISCOUNT_POLICY_ID)+1 from discount_policy), '"+facultyId+"','"+limitValues[0]+"', '"+nvl(limitValues[1])+"', '"+limitValues[2]+"', '"+limitValues[3]+"', '"+limitValues[4]+"', 23843 )";
                            }else{
                            envQuery = "INSERT INTO DISCOUNT_POLICY VALUES"
                         +" ((select max(DISCOUNT_POLICY_ID)+1 from discount_policy), '"+facultyId+"','"+limitValues[0]+"', '', '"+limitValues[1]+"', '"+limitValues[2]+"', '"+limitValues[3]+"', 23843 )";
                            }
                        addTermStmt.executeUpdate(envQuery);
                        adminSession.addLog(envQuery.replace('\'', '`'));
                            }
                        }
                        adminSession.con.commit();
                    }
                }
                if(addTermStmt!=null){
                    addTermStmt.close();
                }
 		if(num!=0)
                {
                    msg="Added Successfully";
                }
                String myURL="AdminFaculty.jsp?msg="+msg;
                response.sendRedirect(myURL);
            } catch (SQLException e) {
                adminSession.con.rollback();
                throw new SQLException("This Faculty ID is Already Defined~" + e.toString());
            }
        %>
    </body>
    </html>
