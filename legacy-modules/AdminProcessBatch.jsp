<%@ page contentType="text/html; charset=windows-1252" language="java" import="java.sql.*, java.util.*,com.towertech.ucp.util.*" session = "true" errorPage="../error.jsp" %>
<%@ include file="../shared/nocache.inc"%>
<%@ include file="../shared/findReplace.jsp"%>
<%!
public void log(String message,String user)
{
  System.out.println(new java.util.Date() + "::AdminProcessBatch.jsp::" + user + "::" + message);
}
%>
<jsp:useBean id="pool" scope="application" class="com.towertech.ucp.DB.ConnectionPool"/>

<%
	com.towertech.ucp.util.AdminSession adminSession = (com.towertech.ucp.util.AdminSession)session.getAttribute("adminSession");
	if(adminSession == null || adminSession.con == null)
  {
    log("Session Not Found","Invalid");
%>
		<jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/>		
<%
  }
	if(!adminSession.hasRightsOn("Batch"))
	{
%>
		<jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Batch service." />
<%
	}

	//String term=pool.getCurrentTerm();
	//String termCode = pool.getCurrentTerm();
        String termCode = adminSession.workingTerm;
	String progCode = request.getParameter("progList");
	String batchNbr = request.getParameter("batch");
        String btchId = "";
        String btchSeqQuery = "SELECT SEQ_BATCH_ID.NEXTVAL FROM DUAL ";
        java.sql.Statement addBatchStmt = null;
        java.sql.Statement degBatchStmt = null;
        java.sql.Statement seqStmt = null;
        java.sql.ResultSet rs = null;
	
	try
	{
		addBatchStmt = adminSession.con.createStatement();
		adminSession.con.setAutoCommit(false);
                degBatchStmt= adminSession.con.createStatement();
                seqStmt = adminSession.con.createStatement();
                rs = seqStmt.executeQuery(btchSeqQuery);
                if(rs.next()){
                btchId = rs.getString(1);
                }
                String sql  = "INSERT INTO DEGREE_COMP_REQ SELECT SEQ_DEGREE_COMP_REQ_ID.NEXTVAL, '"+btchId+"',D.CR_HR_MIN, D.YEAR_MIN, D.YEAR_MAX, D.CGPA_MIN "+
                      "FROM PROGRAM P, BATCH B ,DEGREE_COMP_REQ D "+
                      "WHERE B.PROG_ID = P.PROG_ID "+
                      "AND D.BATCH_ID = B.BATCH_ID AND P.PROG_CDE = '"+progCode+"' "+
                      "AND D.DEGREE_COMP_REQ_ID = (SELECT MAX(D.DEGREE_COMP_REQ_ID) FROM DEGREE_COMP_REQ D,BATCH B, PROGRAM P "+
                      "WHERE D.BATCH_ID = B.BATCH_ID  "+
                      "AND B.PROG_ID = P.PROG_ID "+
                      "AND P.PROG_CDE ='"+progCode+"') ";
	
		addBatchStmt.executeUpdate("INSERT INTO UCP.BATCH(BATCH_ID,TERM_CDE,BATCH_NBR,PROG_ID) VALUES('"+btchId+"','" + termCode + "'," + batchNbr + ",(SELECT PROG_ID FROM PROGRAM WHERE PROG_CDE = '"+ progCode+ "' AND  FACULTY_ID=" + adminSession.getWorkingFacultyId() + " ) )");      
		adminSession.addLog("INSERT INTO UCP.BATCH(BATCH_ID,TERM_CDE,BATCH_NBR,PROG_ID) VALUES(SEQ_BATCH_ID.NEXTVAL," + termCode + "," + batchNbr + ",(SELECT PROG_ID FROM PROGRAM WHERE PROG_CDE = " + progCode + ") )",addBatchStmt);
		
                degBatchStmt.executeUpdate(sql);
                 adminSession.addLog(sql.replace('\'','`'),degBatchStmt);
		adminSession.con.commit();
		addBatchStmt.close();
                degBatchStmt.close();
                seqStmt.close();
%>
			<jsp:forward page="AdminBatch.jsp"/>
<%
	}
	catch(SQLException e)
	{
		adminSession.con.rollback();
		addBatchStmt.close();
                degBatchStmt.close();
                seqStmt.close();
		throw new SQLException("This Batch Number is Already Defined~" + e.toString());
	}

%>
