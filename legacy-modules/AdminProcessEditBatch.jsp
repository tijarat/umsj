<%@ page contentType="text/html; charset=windows-1252" language="java" import="java.sql.*, java.util.*,com.towertech.ucp.util.*" session = "true" errorPage="../error.jsp" %>
<%!
public void log(String message,String user)
{
  System.out.println(new java.util.Date() + "::AdminProcessEditBatch.jsp::" + user + "::" + message);
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
	int batchNbr = Integer.parseInt(request.getParameter("batch"));
  
	java.sql.Statement editBatchStmt = null;
	
	try
	{
		editBatchStmt = adminSession.con.createStatement();
		adminSession.con.setAutoCommit(false);

		editBatchStmt.executeUpdate("UPDATE UCP.BATCH SET BATCH_NBR="+ batchNbr +" WHERE BATCH_ID="+ Integer.parseInt(request.getParameter("batchId")));      
		adminSession.addLog("UPDATE UCP.BATCH SET BATCH_NBR="+ batchNbr +" WHERE BATCH_ID="+ Integer.parseInt(request.getParameter("batchId")),editBatchStmt);
		adminSession.con.commit();
		editBatchStmt.close();
%>
			<jsp:forward page="AdminBatch.jsp"/>
<%
	}
	catch(SQLException e)
	{
		adminSession.con.rollback();
		editBatchStmt.close();
		throw new SQLException("This Batch Number is Already Defined~" + e.toString());
	}

%>
