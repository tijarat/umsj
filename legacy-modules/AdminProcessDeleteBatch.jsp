<%@ page contentType="text/html; charset=windows-1252" language="java" import="java.sql.*, java.util.*,com.towertech.ucp.util.*" session = "true" errorPage="../error.jsp" %>
<%!
public void log(String message,String user)
{
  System.out.println(new java.util.Date() + "::AdminProcessDeleteBatch.jsp::" + user + "::" + message);
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
	int batchId = Integer.parseInt(request.getParameter("batchId"));
  
	java.sql.Statement deleteBatchStmt = null;
		
	try
	{
		deleteBatchStmt = adminSession.con.createStatement();
		adminSession.con.setAutoCommit(false);

		deleteBatchStmt.executeUpdate("DELETE FROM UCP.BATCH where BATCH_ID = "+ batchId );      
		adminSession.addLog("DELETE FROM UCP.BATCH where BATCH_ID = "+ batchId,deleteBatchStmt);
		adminSession.con.commit();
		deleteBatchStmt.close();
%>
			<jsp:forward page="AdminBatch.jsp"/>
<%
	}
	catch(SQLException e)
	{
		adminSession.con.rollback();
		deleteBatchStmt.close();
		throw new SQLException("This Batch Contains Child Records~" + e.toString());
	}
%>
