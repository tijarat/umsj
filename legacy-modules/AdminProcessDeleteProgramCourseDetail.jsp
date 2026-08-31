<%@page import="com.towertech.ucp.Dao.Dao"%>
<%@ page contentType="text/html; charset=windows-1252" language="java" import="java.sql.*, java.util.*,com.towertech.ucp.util.*" session = "true" errorPage="../error.jsp" %>
<%@ include file="../shared/findReplace.jsp"%>
<%!
public void log(String message,String user)
{
  System.out.println(new java.util.Date() + "::AdminProcessDeleteProgramCourseDetail.jsp::" + user + "::" + message);
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

    int preqid = Integer.parseInt(request.getParameter("preqid"));

    java.sql.Statement deletePrereqStmt = null;
    deletePrereqStmt = adminSession.con.createStatement();
    java.sql.Statement deleteCourseStmt = null;
    deleteCourseStmt = adminSession.con.createStatement();
    String Program = request.getParameter("Program"),crsId = nvl(request.getParameter("crsId")),prgCde = nvl(request.getParameter("prgCde"));
    Dao dao = new Dao();
    List paramsList = new ArrayList();
    List qryList = new ArrayList();
    Object[] param = null;
    boolean flag = false;
    try{
        String qry = "DELETE FROM UCP.PREREQ where PREREQ_ID IN (SELECT PREREQ_ID FROM PREREQ PR,PROGRAM P, FACULTY F, CAMPUS C WHERE P.FACULTY_ID = F.FACULTY_ID AND F.CMP_ID = C.CMP_ID AND C.UNI_ID IN (SELECT UNI_ID FROM CAMPUS C2 WHERE C2.CMP_ID = "+adminSession.getCampusId()+") AND P.PROG_ID=PR.PROG_ID AND P.PROG_CDE=? AND PR.COURSE_ID=?)";
        param = new Object[]{prgCde,crsId};
        qryList.add(qry);
        paramsList.add(param);
        flag = dao.cudData(qryList, paramsList, adminSession.con, adminSession.sessionId);
        //deletePrereqStmt.executeUpdate("DELETE FROM UCP.PREREQ WHERE PREREQ_ID = "+ preqid);
		//adminSession.addLog("DELETE FROM UCP.PREREQ where PREREQ_ID = "+ preqid,deletePrereqStmt);
		//adminSession.con.commit();
		//deletePrereqStmt.close();
                //deleteCourseStmt.close();
%>
        <jsp:forward page="AdminProgramCourseDetail.jsp">
            <jsp:param name="prg" value="<%= Program %>"/>
        </jsp:forward>
<%
    }catch(SQLException e){
        //adminSession.con.rollback();
        //deletePrereqStmt.close();
        throw new SQLException("This Prereq Contains Child Records~" + e.toString());
    }
%>
