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
String uniId = request.getParameter("uniId");
String cmpAbbrev = request.getParameter("cmpAbbrev");
String cmpName = request.getParameter("cmpName");
String cmpPrefix = request.getParameter("cmpPrefix");
String franchise = request.getParameter("franchise");
String cmpCode = request.getParameter("cmpCode");
String challanApproval = request.getParameter("challanApproval");
String subCityId = request.getParameter("subCityId");
String buildingId = request.getParameter("buildingId");
String businessUnitId = request.getParameter("businessUnitId");
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
Connection con = null;
boolean oldAutoCommit = true;
try
{
if(cmpId == null || !cmpId.trim().matches("\\d+")) throw new SQLException("A valid Campus ID is required.");
if(uniId == null || !uniId.trim().matches("\\d+")) throw new SQLException("A valid University is required.");
if(cmpAbbrev == null || cmpAbbrev.trim().length() == 0) throw new SQLException("Campus Abbreviation is required.");
if(cmpName == null || cmpName.trim().length() == 0) throw new SQLException("Campus Name is required.");
cmpId = cmpId.trim();
uniId = uniId.trim();
cmpAbbrev = cmpAbbrev.trim().toUpperCase();
cmpName = cmpName.trim();
cmpPrefix = cmpPrefix == null ? "" : cmpPrefix.trim().toUpperCase();
franchise = "Y".equalsIgnoreCase(franchise) ? "Y" : "N";
cmpCode = cmpCode == null ? "" : cmpCode.trim().toUpperCase();
challanApproval = "Y".equalsIgnoreCase(challanApproval) ? "Y" : "N";
subCityId = subCityId == null ? "" : subCityId.trim();
buildingId = buildingId == null ? "" : buildingId.trim();
businessUnitId = businessUnitId == null ? "" : businessUnitId.trim();
if(cmpAbbrev.length() > 10) throw new SQLException("Campus Abbreviation cannot exceed 10 characters.");
if(cmpName.length() > 250) throw new SQLException("Campus Name cannot exceed 250 characters.");
if(cmpPrefix.length() > 3) throw new SQLException("Campus Prefix cannot exceed 3 characters.");
if(cmpCode.length() > 15) throw new SQLException("Campus Code cannot exceed 15 characters.");
if(subCityId.length() > 0 && !subCityId.matches("\\d+")) throw new SQLException("Invalid Sub City.");
if(buildingId.length() > 0 && !buildingId.matches("\\d+")) throw new SQLException("Invalid Building.");
if(businessUnitId.length() > 0 && !businessUnitId.matches("\\d+")) throw new SQLException("Invalid Business Unit.");
con = pool.getConnection();
oldAutoCommit = con.getAutoCommit();
con.setAutoCommit(false);
try(PreparedStatement ps = con.prepareStatement("INSERT INTO UMS.CAMPUS (CMP_ID, UNI_ID, CMP_ABBERV, CMP_NAME, CMP_PREFIX, FRANCHISE, CMP_CDE, CHALLAN_APPROVAL_IND, SUB_CITY_ID, BUILDING_ID, BUSINESS_UNIT_ID) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"))
{
ps.setLong(1, Long.parseLong(cmpId));
ps.setLong(2, Long.parseLong(uniId));
ps.setString(3, cmpAbbrev);
ps.setString(4, cmpName);
if(cmpPrefix.length() == 0) ps.setNull(5, Types.VARCHAR); else ps.setString(5, cmpPrefix);
ps.setString(6, franchise);
if(cmpCode.length() == 0) ps.setNull(7, Types.VARCHAR); else ps.setString(7, cmpCode);
ps.setString(8, challanApproval);
if(subCityId.length() == 0) ps.setNull(9, Types.NUMERIC); else ps.setLong(9, Long.parseLong(subCityId));
if(buildingId.length() == 0) ps.setNull(10, Types.NUMERIC); else ps.setLong(10, Long.parseLong(buildingId));
if(businessUnitId.length() == 0) ps.setNull(11, Types.NUMERIC); else ps.setLong(11, Long.parseLong(businessUnitId));
ps.executeUpdate();
}
try(Statement logStmt = con.createStatement()) { adminSession.addLog("INSERT INTO UMS.CAMPUS CMP_ID=" + cmpId + ", CMP_ABBERV=" + cmpAbbrev + ", CMP_NAME=" + cmpName, logStmt); }
con.commit();
session.setAttribute("flashType", "success");
session.setAttribute("flashMessage", "Campus " + cmpName + " has been added successfully.");
response.sendRedirect("AdminCampus.jsp");
}
catch(Exception e)
{
if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
String errorMessage = e.getMessage();
if(errorMessage == null || errorMessage.trim().length() == 0) errorMessage = "Unable to add Campus.";
if(errorMessage.indexOf("ORA-00001") >= 0) errorMessage = "Campus ID, Abbreviation, Name or Prefix is already defined.";
if(errorMessage.indexOf("ORA-02291") >= 0) errorMessage = "Selected University, Building or location reference does not exist.";
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