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
String buildingCode = request.getParameter("buildingCode");
String buildingName = request.getParameter("buildingName");
String subCityId = request.getParameter("subCityId");
String addressText = request.getParameter("addressText");
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
Connection con = null;
boolean oldAutoCommit = true;
try
{
if(buildingId == null || !buildingId.trim().matches("\\d+")) throw new SQLException("A valid Building ID is required.");
if(buildingCode == null || buildingCode.trim().length() == 0) throw new SQLException("Building Code is required.");
if(buildingName == null || buildingName.trim().length() == 0) throw new SQLException("Building Name is required.");
if(subCityId == null || !subCityId.trim().matches("\\d+")) throw new SQLException("A valid Sub City is required.");
buildingId = buildingId.trim();
buildingCode = buildingCode.trim().toUpperCase();
buildingName = buildingName.trim();
subCityId = subCityId.trim();
addressText = addressText == null ? "" : addressText.trim();
if(buildingCode.length() > 5) throw new SQLException("Building Code cannot exceed 5 characters.");
if(buildingName.length() > 50) throw new SQLException("Building Name cannot exceed 50 characters.");
if(addressText.length() > 50) throw new SQLException("Address cannot exceed 50 characters.");
con = pool.getConnection();
oldAutoCommit = con.getAutoCommit();
con.setAutoCommit(false);
int updated = 0;
try(PreparedStatement ps = con.prepareStatement("UPDATE UMS.BUILDING SET BUILDING_CDE = ?, BUILDING_NME = ?, SUB_CITY_ID = ?, ADDRESS_TXT = ? WHERE BUILDING_ID = ?"))
{
ps.setString(1, buildingCode);
ps.setString(2, buildingName);
ps.setLong(3, Long.parseLong(subCityId));
ps.setString(4, addressText);
ps.setLong(5, Long.parseLong(buildingId));
updated = ps.executeUpdate();
}
if(updated == 0) throw new SQLException("Building record was not found.");
try(Statement logStmt = con.createStatement()) { adminSession.addLog("UPDATE UMS.BUILDING SET BUILDING_CDE=" + buildingCode + ", BUILDING_NME=" + buildingName + ", SUB_CITY_ID=" + subCityId + " WHERE BUILDING_ID=" + buildingId, logStmt); }
con.commit();
session.setAttribute("flashType", "success");
session.setAttribute("flashMessage", "Building " + buildingName + " has been updated successfully.");
response.sendRedirect("AdminBuilding.jsp");
}
catch(Exception e)
{
if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
String errorMessage = e.getMessage();
if(errorMessage == null || errorMessage.trim().length() == 0) errorMessage = "Unable to update Building.";
if(errorMessage.indexOf("ORA-02291") >= 0) errorMessage = "Selected Sub City does not exist.";
session.setAttribute("flashType", "error");
session.setAttribute("flashMessage", errorMessage);
response.sendRedirect("AdminEditBuilding.jsp?buildingId=" + (buildingId == null ? "" : buildingId));
}
finally
{
if(con != null) try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
pool.close(con);
}
%>