<%@page import="com.towertech.ucp.Dao.Dao"%>
<%@ page contentType="text/html; charset=windows-1252" language="java" import="java.sql.*, java.util.*,com.towertech.ucp.util.*" session = "true" errorPage="../error.jsp" %>
<%@ include file="../shared/findReplace.jsp"%>
<%!
    public void log(String message,String user){
        System.out.println(new java.util.Date() + "::AdminProcessEditProgramCourseDetail.jsp::" + user + "::" + message);
    }
%>
<jsp:useBean id="pool" scope="application" class="com.towertech.ucp.DB.ConnectionPool"/>

<%
    com.towertech.ucp.util.AdminSession adminSession = (com.towertech.ucp.util.AdminSession)session.getAttribute("adminSession");
    if(adminSession == null || adminSession.con == null){
        log("Session Not Found","Invalid");
%>
        <jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/>		
<%
    }
    if(!adminSession.hasRightsOn("Prereq")){
%>
        <jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Prereq service." />
<%
    }
    Dao dao = new Dao();
    List paramsList = new ArrayList();
    List qryList = new ArrayList();
    Object[] param = null;
    String pr = request.getParameter("Prereq");
    String crsId = nvl(request.getParameter("crsId"));
    int seq;
    try{
            seq = Integer.parseInt(request.getParameter("seq"));
    }catch(Exception npe){
            throw new Exception("Sequence cannot be NULL");		
    }
    int preqid = Integer.parseInt(request.getParameter("preqid"));
    String status = request.getParameter("status").toUpperCase();
    //java.sql.Statement editPrereqStmt = adminSession.con.createStatement();
    //adminSession.con.setAutoCommit(false);
    String Program = request.getParameter("Program"),qry = null,prgCde = request.getParameter("prgCde");
    boolean flag = false;
    try{
        if(request.getParameter("Prereq") == null || request.getParameter("Prereq").equals("blank")){
            qry = "UPDATE UCP.PREREQ SET PREREQ_COURSE_ID= null, COURSE_NBR= ?, STATUS_TXT=? WHERE PREREQ_ID IN (SELECT PREREQ_ID FROM PREREQ PR,PROGRAM P WHERE P.PROG_ID=PR.PROG_ID AND P.PROG_CDE=? AND PR.COURSE_ID=?)";
            qry =   "UPDATE UCP.PREREQ SET PREREQ_COURSE_ID= null, COURSE_NBR= ?, STATUS_TXT=?  " +
                    "WHERE PREREQ_ID IN (SELECT PREREQ_ID FROM PREREQ PR,PROGRAM P, FACULTY F, CAMPUS C " +
                    "WHERE P.PROG_ID=PR.PROG_ID AND P.PROG_CDE=? AND PR.COURSE_ID=? " +
                    "AND P.FACULTY_ID = F.FACULTY_ID AND F.CMP_ID = C.CMP_ID AND C.UNI_ID IN (SELECT UNI_ID FROM CAMPUS C2 WHERE C2.CMP_ID = "+adminSession.getCampusId()+") ) "; 

            qryList.add(qry);
            param = new Object[]{seq,status,prgCde,crsId};
            paramsList.add(param);
            flag = dao.cudData(qryList, paramsList, adminSession.con, adminSession.sessionId);
            //editPrereqStmt.executeUpdate("UPDATE UCP.PREREQ SET PREREQ_COURSE_ID= null, COURSE_NBR= "+seq+", STATUS_TXT='"+status+"' WHERE PREREQ_ID="+ preqid);
            //adminSession.addLog("UPDATE UCP.PREREQ SET PREREQ_COURSE_ID= null, COURSE_NBR= "+seq+", STATUS_TXT="+status+" WHERE PREREQ_ID="+ preqid,editPrereqStmt);	
        }
        else{
            qry = "UPDATE UCP.PREREQ SET PREREQ_COURSE_ID= ?, COURSE_NBR= ?, STATUS_TXT=? WHERE PREREQ_ID IN (SELECT PREREQ_ID FROM PREREQ PR,PROGRAM P, FACULTY F, CAMPUS C " +
                    "WHERE P.PROG_ID=PR.PROG_ID AND P.PROG_CDE=? AND PR.COURSE_ID=? " +
                    "AND P.FACULTY_ID = F.FACULTY_ID AND F.CMP_ID = C.CMP_ID AND C.UNI_ID IN (SELECT UNI_ID FROM CAMPUS C2 WHERE C2.CMP_ID = "+adminSession.getCampusId()+") ) "; 
     qryList.add(qry);
            param = new Object[]{pr,seq,status,prgCde,crsId};
            paramsList.add(param);
            flag = dao.cudData(qryList, paramsList, adminSession.con, adminSession.sessionId);
            //editPrereqStmt.executeUpdate("UPDATE UCP.PREREQ SET PREREQ_COURSE_ID= "+pr+", COURSE_NBR= "+seq+", STATUS_TXT='"+status+"' WHERE PREREQ_ID="+ preqid);
            //adminSession.addLog("UPDATE UCP.PREREQ SET PREREQ_COURSE_ID= "+pr+", COURSE_NBR= "+seq+", STATUS_TXT="+status+" WHERE PREREQ_ID="+ preqid,editPrereqStmt);	
        }
        //adminSession.con.commit();
        //editPrereqStmt.close();
%>
        <jsp:forward page="AdminProgramCourseDetail.jsp">
            <jsp:param name="prg" value="<%= Program %>"/>
        </jsp:forward>
<%
    }catch(SQLException e){
        //adminSession.con.rollback();
        //editPrereqStmt.close();
        throw new SQLException("Operation Failure~" + e.toString());
    }
%>