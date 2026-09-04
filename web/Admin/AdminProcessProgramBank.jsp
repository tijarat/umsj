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
String bankCde = request.getParameter("bankCde");
String progId = request.getParameter("progId");
String acctNbr = request.getParameter("acctNbr");
String branchTxt = request.getParameter("branchTxt");
String challanTitle = request.getParameter("challanTitle");
String challanPrefix = request.getParameter("challanPrefix");
String onlineInd = "Y".equals(request.getParameter("onlineInd")) ? "Y" : "N";
String activeInd = "Y".equals(request.getParameter("activeInd")) ? "Y" : "N";
String bankRemarks = request.getParameter("bankRemarks");
String showInd = "Y";
String showAccount = "Y";
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
Connection con = null;
boolean oldAutoCommit = true;
try
{
if(bankCde == null || bankCde.trim().length() == 0) throw new SQLException("Bank is required.");
if(progId == null || !progId.matches("\\d+")) throw new SQLException("Program is required.");
acctNbr = acctNbr == null ? "" : acctNbr.trim();
branchTxt = branchTxt == null ? "" : branchTxt.trim();
challanTitle = challanTitle == null ? "" : challanTitle.trim();
challanPrefix = challanPrefix == null ? "" : challanPrefix.trim();
bankRemarks = bankRemarks == null ? "" : bankRemarks.trim();
bankCde = bankCde.trim();
if("OL".equalsIgnoreCase(bankCde) || "CDN".equalsIgnoreCase(bankCde)) { acctNbr = "000"; showInd = "N"; branchTxt = "Online"; }
if(branchTxt.length() == 0) throw new SQLException("Branch is required.");
if(challanTitle.length() == 0) throw new SQLException("Challan Title is required.");
if(!challanPrefix.matches("\\d{3}")) throw new SQLException("Challan Prefix must contain 3 digits.");
con = pool.getConnection();
oldAutoCommit = con.getAutoCommit();
con.setAutoCommit(false);
int allowed = 0;
try(PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM UMS.PROGRAM WHERE PROG_ID = ? AND FACULTY_ID = ?")) { ps.setLong(1, Long.parseLong(progId)); ps.setInt(2, adminSession.getWorkingFacultyId()); try(ResultSet rs = ps.executeQuery()) { if(rs.next()) allowed = rs.getInt(1); } }
if(allowed == 0) throw new SQLException("Selected Program does not belong to the working faculty.");
String sql = "INSERT INTO UMS.BANK (BANK_ID, PROG_ID, BANK_TXT, ACCOUNT_NBR, BRANCH_TXT, BANK_CHALLAN_PREFIX, CHALLAN_TITLE, BANK_CDE, ACTIVE_IND, ONLINE_IND, SHOW_IND, SHOW_ACCOUNT, BANK_REMARKS) VALUES (UMS.SEQ_BANK_ID.NEXTVAL, ?, (SELECT BANK_NAME FROM UMS.BANK_MASTER WHERE BANK_CDE = ?), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
try(PreparedStatement ps = con.prepareStatement(sql))
{
ps.setLong(1, Long.parseLong(progId)); ps.setString(2, bankCde); ps.setString(3, acctNbr); ps.setString(4, branchTxt); ps.setString(5, challanPrefix); ps.setString(6, challanTitle); ps.setString(7, bankCde); ps.setString(8, activeInd); ps.setString(9, onlineInd); ps.setString(10, showInd); ps.setString(11, showAccount); ps.setString(12, bankRemarks); ps.executeUpdate();
}
adminSession.addLog("INSERT UMS.BANK PROG_ID=" + progId + ", BANK_CDE=" + bankCde, con);
con.commit();
session.setAttribute("flashType","success");
session.setAttribute("flashMessage","Program Bank has been added successfully.");
response.sendRedirect("AdminProgramBank.jsp");
}
catch(Exception e)
{
if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
session.setAttribute("flashType","error");
session.setAttribute("flashMessage",e.getMessage() == null ? "Unable to add Program Bank." : e.getMessage());
response.sendRedirect("AdminProgramBank.jsp");
}
finally
{
if(con != null) try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
pool.close(con);
}
%>