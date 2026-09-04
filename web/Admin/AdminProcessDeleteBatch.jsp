<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<%
com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession)session.getAttribute("adminSession");
if(adminSession == null)
{
%><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><%
return;
}
if(!adminSession.hasRightsOn("Batch"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Batch service."/><%
return;
}
String batchId = request.getParameter("batchId");
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
Connection con = null;
boolean oldAutoCommit = true;
try
{
if(batchId == null || !batchId.matches("\\d+")) throw new SQLException("Invalid Batch ID.");
con = pool.getConnection();
oldAutoCommit = con.getAutoCommit();
con.setAutoCommit(false);
int deleted = 0;
try(PreparedStatement ps = con.prepareStatement("DELETE FROM UMS.BATCH WHERE BATCH_ID = ? AND PROG_ID IN (SELECT PROG_ID FROM UMS.PROGRAM WHERE FACULTY_ID = ?)"))
{
ps.setLong(1, Long.parseLong(batchId));
ps.setInt(2, adminSession.getWorkingFacultyId());
deleted = ps.executeUpdate();
}
if(deleted == 0) throw new SQLException("Batch record was not found for this faculty.");
adminSession.addLog("DELETE FROM UMS.BATCH WHERE BATCH_ID=" + batchId, con);
con.commit();
session.setAttribute("flashType","success");
session.setAttribute("flashMessage","Batch has been deleted successfully.");
response.sendRedirect("AdminBatch.jsp");
}
catch(Exception e)
{
if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
String msg = e.getMessage() == null ? "Unable to delete Batch." : e.getMessage();
if(msg.indexOf("ORA-02292") >= 0) msg = "This Batch contains child records and cannot be deleted.";
session.setAttribute("flashType","error");
session.setAttribute("flashMessage",msg);
response.sendRedirect("AdminBatch.jsp");
}
finally
{
if(con != null) try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
pool.close(con);
}
%>