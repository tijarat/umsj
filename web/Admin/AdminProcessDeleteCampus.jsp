<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<%
com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession)session.getAttribute("adminSession");
if(adminSession == null)
{
%><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><%
return;
}
if(!adminSession.hasRightsOn("Campus"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Campus service."/><%
return;
}
String cmpId = request.getParameter("cmpId");
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
Connection con = null;
boolean oldAutoCommit = true;
try
{
if(cmpId == null || !cmpId.trim().matches("\\d+")) throw new SQLException("A valid Campus ID is required.");
cmpId = cmpId.trim();
con = pool.getConnection();
oldAutoCommit = con.getAutoCommit();
con.setAutoCommit(false);
int deleted = 0;
try(PreparedStatement ps = con.prepareStatement("DELETE FROM UMS.CAMPUS WHERE CMP_ID = ?"))
{
ps.setLong(1, Long.parseLong(cmpId));
deleted = ps.executeUpdate();
}
if(deleted == 0) throw new SQLException("Campus record was not found.");
try(Statement logStmt = con.createStatement()) { adminSession.addLog("DELETE FROM UMS.CAMPUS WHERE CMP_ID=" + cmpId, logStmt); }
con.commit();
session.setAttribute("flashType", "success");
session.setAttribute("flashMessage", "Campus has been deleted successfully.");
response.sendRedirect("AdminCampus.jsp");
}
catch(Exception e)
{
if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
String errorMessage = e.getMessage();
if(errorMessage == null || errorMessage.trim().length() == 0) errorMessage = "Unable to delete Campus.";
if(errorMessage.indexOf("ORA-02292") >= 0) errorMessage = "This Campus is referenced by Faculty or other records and cannot be deleted.";
session.setAttribute("flashType", "error");
session.setAttribute("flashMessage", errorMessage);
response.sendRedirect("AdminCampus.jsp");
}
finally
{
if(con != null) try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
pool.close(con);
}
%>