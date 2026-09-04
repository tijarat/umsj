<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<%
com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession)session.getAttribute("adminSession");
if(adminSession == null)
{
%><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><%
return;
}
if(!adminSession.hasRightsOn("Program Bank"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Program Bank service."/><%
return;
}
String bankId = request.getParameter("bankId");
String bankCde = request.getParameter("bankCde");
String acctNbr = request.getParameter("acctNbr");
String onlineInd = "Y".equals(request.getParameter("onlineInd")) ? "Y" : "N";
String activeInd = "Y".equals(request.getParameter("activeInd")) ? "Y" : "N";
String showInd = "Y".equals(request.getParameter("showInd")) ? "Y" : "N";
String showAccount = "Y".equals(request.getParameter("showAccount")) ? "Y" : "N";
String bankRemarks = request.getParameter("bankRemarks");
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
Connection con = null;
boolean oldAutoCommit = true;
try
{
if(bankId == null || !bankId.matches("\\d+")) throw new SQLException("Invalid Bank ID.");
bankCde = bankCde == null ? "" : bankCde.trim();
acctNbr = acctNbr == null ? "" : acctNbr.trim();
bankRemarks = bankRemarks == null ? "" : bankRemarks.trim();
if("OL".equalsIgnoreCase(bankCde) || "CDN".equalsIgnoreCase(bankCde)) { acctNbr = "000"; showInd = "N"; }
con = pool.getConnection();
oldAutoCommit = con.getAutoCommit();
con.setAutoCommit(false);
String sql = "UPDATE UMS.BANK SET ACCOUNT_NBR = ?, SHOW_ACCOUNT = ?, ONLINE_IND = ?, ACTIVE_IND = ?, SHOW_IND = ?, BANK_REMARKS = ? WHERE BANK_ID = ? AND PROG_ID IN (SELECT PROG_ID FROM UMS.PROGRAM WHERE FACULTY_ID = ?)";
int updated = 0;
try(PreparedStatement ps = con.prepareStatement(sql))
{
ps.setString(1, acctNbr); ps.setString(2, showAccount); ps.setString(3, onlineInd); ps.setString(4, activeInd); ps.setString(5, showInd); ps.setString(6, bankRemarks); ps.setLong(7, Long.parseLong(bankId)); ps.setInt(8, adminSession.getWorkingFacultyId()); updated = ps.executeUpdate();
}
if(updated == 0) throw new SQLException("Program Bank record was not found for this faculty.");
adminSession.addLog("UPDATE UMS.BANK BANK_ID=" + bankId, con);
con.commit();
session.setAttribute("flashType","success");
session.setAttribute("flashMessage","Program Bank has been updated successfully.");
response.sendRedirect("AdminProgramBank.jsp");
}
catch(Exception e)
{
if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
session.setAttribute("flashType","error");
session.setAttribute("flashMessage",e.getMessage() == null ? "Unable to update Program Bank." : e.getMessage());
response.sendRedirect("AdminEditProgramBank.jsp?bankId=" + (bankId == null ? "" : bankId));
}
finally
{
if(con != null) try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
pool.close(con);
}
%>