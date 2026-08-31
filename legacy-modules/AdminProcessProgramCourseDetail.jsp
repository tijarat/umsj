<%@page import="com.towertech.ucp.Dao.Dao"%>
<%@ page contentType="text/html; charset=windows-1252" language="java" import="java.sql.*, java.util.*,com.towertech.ucp.util.*" session = "true" errorPage="../error.jsp" %>
<%@ include file="../shared/findReplace.jsp"%>
<%!    public void log(String message, String user) {
        System.out.println(new java.util.Date() + "::AdminProcessProgramCourseDetail.jsp::" + user + "::" + message);
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
    //adminSession.con.setAutoCommit(false);
    Dao dao = new Dao();
    String progCode = request.getParameter("Program");
    List paramsList = new ArrayList();
    List qryList = new ArrayList();
    Object[] param = null;
    boolean flag = false;
    if (nvl(request.getParameter("act")).equals("")) 
    {
        String courseId = null;
        try {
            courseId = nvl(request.getParameter("Course"));
        } catch (NumberFormatException nfe) {
            throw new NumberFormatException("Error in converting CourseId to integer~" + nfe.toString());
        }

        String pr = request.getParameter("Prereq");

        String seq = null;
        try {
            seq = request.getParameter("seq");
        } catch (Exception npe) {
            throw new Exception("Sequence cannot be NULL");
        }


        String status = request.getParameter("status").toUpperCase();
        paramsList.clear();
        String qry = "SELECT COUNT(*) CNT FROM PREREQ WHERE COURSE_ID = ? AND PROG_ID IN (SELECT PROG_ID FROM PROGRAM WHERE PROG_CDE=(SELECT PROG_CDE FROM PROGRAM WHERE PROG_ID=?)) ";
     /*   qry =   "SELECT COUNT(*) CNT FROM PREREQ WHERE COURSE_ID = ? AND PROG_ID IN (SELECT PROG_ID FROM PROGRAM P, FACULTY F, CAMPUS C WHERE PROG_CDE=(SELECT PROG_CDE FROM PROGRAM WHERE PROG_ID=?) " +
                "AND P.FACULTY_ID = F.FACULTY_ID AND F.CMP_ID = C.CMP_ID AND C.UNI_ID IN (SELECT UNI_ID FROM CAMPUS C2 WHERE C2.CMP_ID = "+adminSession.getCampusId()+")) ";
        paramsList.add(courseId);
        paramsList.add(progCode);
        List prereqData = dao.getData(qry, paramsList, adminSession.con);
        if(prereqData!=null && prereqData.size()>0)
        {
            Map map = (HashMap)prereqData.get(0);
            if(map.containsKey("CNT") && map.get("CNT")!=null && !map.get("CNT").toString().isEmpty() && Integer.parseInt(map.get("CNT").toString())>0 )
            {
                throw new Exception("This course is already defined in the Roadmap");
            }
        } */
        try 
        {
            qry = "INSERT INTO PREREQ SELECT SEQ_PREREQ_ID.NEXTVAL,?,?,?,?,NULL,PROG_ID,NULL FROM PROGRAM P, FACULTY F WHERE PROG_CDE=(SELECT PROG_CDE FROM PROGRAM WHERE PROG_ID=?) AND P.FACULTY_ID = F.FACULTY_ID AND F.CMP_ID = 133";

            qry =   "INSERT INTO PREREQ SELECT SEQ_PREREQ_ID.NEXTVAL,?,?,?,?,NULL,PROG_ID,NULL F FROM PROGRAM P, FACULTY F, CAMPUS C " +
                    "WHERE PROG_CDE=(SELECT PROG_CDE FROM PROGRAM WHERE PROG_ID=?) " +
                    "AND P.FACULTY_ID = F.FACULTY_ID AND F.CMP_ID = C.CMP_ID " +
                    "AND C.UNI_ID IN (SELECT UNI_ID FROM CAMPUS C2 WHERE C2.CMP_ID = "+adminSession.getCampusId()+") "+
                    "AND (P.PROG_ID, "+courseId+","+seq+") NOT IN  " +
                    "    ( " +
                    "        SELECT PR1.PROG_ID,PR1.COURSE_ID,PR1.COURSE_NBR " +
                    "        FROM UCP.PREREQ PR1, UCP.PROGRAM P1, FACULTY F1, CAMPUS C1  " +
                    "        WHERE P1.FACULTY_ID = F1.FACULTY_ID  " +
                    "        AND F1.CMP_ID = C1.CMP_ID AND PR1.PROG_ID = P1.PROG_ID " +
                    "        AND C1.UNI_ID =(SELECT UNI_ID FROM CAMPUS C2 WHERE C2.CMP_ID = "+adminSession.getCampusId()+") " +
                    "    ) " ;


            qryList.add(qry);
            param = new Object[]{courseId,pr,seq,status,progCode};
            paramsList.clear();
            paramsList.add(param);
            flag = dao.cudData(qryList, paramsList, adminSession.con, adminSession.sessionId);
            /*addPrereqStmt.executeUpdate("INSERT INTO UCP.PREREQ (PREREQ_ID,PROG_ID,COURSE_ID,PREREQ_COURSE_ID,COURSE_NBR,STATUS_TXT) values(SEQ_PREREQ_ID.NEXTVAL, "+progCode+", " + courseId + ", " + pr + ", " + seq + ",'" + status + "')");
            adminSession.addLog("INSERT INTO UCP.PREREQ (PREREQ_ID,PROG_ID,COURSE_ID,PREREQ_COURSE_ID,COURSE_NBR,STATUS_TXT) values(SEQ_PREREQ_ID.NEXTVAL, "+progCode+", " + courseId + ", " + pr + ", " + seq + "," + status + ")", addPrereqStmt);
            adminSession.con.commit();
            addPrereqStmt.close();
            //addCourseStmt.executeUpdate("INSERT INTO UCP.prog_course_limit (PROG_COURSE_LIMIT_ID,PROG_ID,COURSE_LIMIT,TERM_CDE) values(SEQ_PROG_COURSE_LIMIT_ID.NEXTVAL, (SELECT PROG_ID FROM PROGRAM WHERE PROG_CDE = '"+progCode+"'), "+courseLimit+", '"+adminSession.workingTerm+"')");
            //adminSession.addLog("INSERT INTO UCP.prog_course_limit (PROG_COURSE_LIMIT_ID,PROG_ID,COURSE_LIMIT,TERM_CDE) values(SEQ_PROG_COURSE_LIMIT_ID.NEXTVAL, (SELECT PROG_ID FROM PROGRAM WHERE PROG_CDE = "+progCode+"), "+courseLimit+", "+adminSession.workingTerm+")",addCourseStmt);
            adminSession.con.commit();
            addCourseStmt.close();*/
%>
<jsp:forward page="AdminProgramCourseDetail.jsp">

    <jsp:param name="prg" value="<%= progCode%>"/>
</jsp:forward>
<%
        } catch (SQLException e){
            throw new SQLException("This Prereq is Already Defined For The Selected Course~" + e.toString());
        }
    } else {
        java.sql.Statement lockStmt = null;
        try {
            String pr = request.getParameter("prog");
            String qry = "UPDATE PREREQ SET LOCKED_IND=? WHERE PREREQ_ID IN (SELECT PR.PREREQ_ID FROM PROGRAM P,PREREQ PR,COURSE C "+
                         " WHERE P.PROG_CDE = (SELECT PROG_CDE FROM PROGRAM WHERE PROG_ID=?) "+
                         " AND P.PROG_ID=PR.PROG_ID AND PR.COURSE_ID=C.COURSE_ID AND C.TERM_CDE=?)";

            qry =   "UPDATE PREREQ SET LOCKED_IND=? WHERE PREREQ_ID IN (SELECT PR.PREREQ_ID FROM PROGRAM P,PREREQ PR,COURSE C, FACULTY F, CAMPUS C  WHERE P.PROG_CDE = (SELECT PROG_CDE FROM PROGRAM WHERE PROG_ID=?)   " +
                    "AND P.PROG_ID=PR.PROG_ID AND PR.COURSE_ID=C.COURSE_ID AND C.TERM_CDE=? " +
                    "AND P.FACULTY_ID = F.FACULTY_ID AND F.CMP_ID = C.CMP_ID AND C.UNI_ID IN (SELECT UNI_ID FROM CAMPUS C2 WHERE C2.CMP_ID = "+adminSession.getCampusId()+")) " ;

            qryList.add(qry);
            param = new Object[]{nvl(request.getParameter("act")),progCode,adminSession.workingTerm};
            paramsList.add(param);
            dao.cudData(qryList, paramsList, adminSession.con, adminSession.sessionId) ;
            //adminSession.addLog("UPDATE PREREQ SET LOCKED_IND=" + nvl(request.getParameter("act")) + " WHERE PREREQ_ID IN (SELECT PR.PREREQ_ID FROM PREREQ PR,COURSE C WHERE PR.PROG_ID="+progCode+" AND PR.COURSE_ID = C.COURSE_ID AND C.TERM_CDE=" + adminSession.workingTerm + ")", lockStmt);
            response.sendRedirect("AdminProgramCourseDetail.jsp?Program=" + pr);
        } catch (Exception e){
            throw new SQLException("Un able to perform operatrion" + e.toString());
        }
    }
%>