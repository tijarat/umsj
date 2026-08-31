<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<%
com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession)session.getAttribute("adminSession");
if(adminSession == null)
{
%><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><%
return;
}
if(!adminSession.hasRightsOn("Building"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Building service."/><%
return;
}
String buildingId = request.getParameter("buildingId");
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
Connection con = null;
boolean oldAutoCommit = true;
try
{
if(buildingId == null || !buildingId.trim().matches("\\d+")) throw new SQLException("A valid Building ID is required.");
buildingId = buildingId.trim();
con = pool.getConnection();
oldAutoCommit = con.getAutoCommit();
con.setAutoCommit(false);
int deleted = 0;
try(PreparedStatement ps = con.prepareStatement("DELETE FROM UMS.BUILDING WHERE BUILDING_ID = ?"))
{
ps.setLong(1, Long.parseLong(buildingId));
deleted = ps.executeUpdate();
}
if(deleted == 0) throw new SQLException("Building record was not found.");
try(Statement logStmt = con.createStatement()) { adminSession.addLog("DELETE FROM UMS.BUILDING WHERE BUILDING_ID=" + buildingId, logStmt); }
con.commit();
session.setAttribute("flashType", "success");
session.setAttribute("flashMessage", "Building has been deleted successfully.");
response.sendRedirect("AdminBuilding.jsp");
}
catch(Exception e)
{
if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
String errorMessage = e.getMessage();
if(errorMessage == null || errorMessage.trim().length() == 0) errorMessage = "Unable to delete Building.";
if(errorMessage.indexOf("ORA-02292") >= 0) errorMessage = "This Building is referenced by Campus or other records and cannot be deleted.";
session.setAttribute("flashType", "error");
session.setAttribute("flashMessage", errorMessage);
response.sendRedirect("AdminBuilding.jsp");
}
finally
{
if(con != null) try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
pool.close(con);
}
%>