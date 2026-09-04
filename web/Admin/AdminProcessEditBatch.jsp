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
String batchNbr = request.getParameter("batch");
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
Connection con = null;
boolean oldAutoCommit = true;
try
{
if(batchId == null || !batchId.matches("\\d+")) throw new SQLException("Invalid Batch ID.");
if(batchNbr == null || !batchNbr.matches("\\d{1,3}")) throw new SQLException("Batch must be numeric and at most 3 digits.");
con = pool.getConnection();
oldAutoCommit = con.getAutoCommit();
con.setAutoCommit(false);
int updated = 0;
try(PreparedStatement ps = con.prepareStatement("UPDATE UMS.BATCH SET BATCH_NBR = ? WHERE BATCH_ID = ? AND PROG_ID IN (SELECT PROG_ID FROM UMS.PROGRAM WHERE FACULTY_ID = ?)"))
{
ps.setInt(1, Integer.parseInt(batchNbr));
ps.setLong(2, Long.parseLong(batchId));
ps.setInt(3, adminSession.getWorkingFacultyId());
updated = ps.executeUpdate();
}
if(updated == 0) throw new SQLException("Batch record was not found for this faculty.");
adminSession.addLog("UPDATE UMS.BATCH SET BATCH_NBR=" + batchNbr + " WHERE BATCH_ID=" + batchId, con);
con.commit();
session.setAttribute("flashType","success");
session.setAttribute("flashMessage","Batch has been updated successfully.");
response.sendRedirect("AdminBatch.jsp");
}
catch(Exception e)
{
if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
String msg = e.getMessage() == null ? "Unable to update Batch." : e.getMessage();
if(msg.indexOf("ORA-00001") >= 0) msg = "This Batch Number is already defined.";
session.setAttribute("flashType","error");
session.setAttribute("flashMessage",msg);
response.sendRedirect("AdminEditBatch.jsp?batchId=" + (batchId == null ? "" : batchId));
}
finally
{
if(con != null) try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
pool.close(con);
}
%>