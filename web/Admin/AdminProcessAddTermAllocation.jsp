<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<%
com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession)session.getAttribute("adminSession");
if(adminSession == null)
{
%><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><%
return;
}
if(!adminSession.hasRightsOn("Term Allocation"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Term Allocation service."/><%
return;
}
String termCode = request.getParameter("termCode");
String userName = request.getParameter("userName");
String frmDate = request.getParameter("frmDate");
String toDate = request.getParameter("toDate");
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
Connection con = null;
boolean oldAutoCommit = true;
try
{
if(adminSession.getWorkingFacultyId() == null || adminSession.getWorkingFacultyId().trim().length() == 0) throw new SQLException("Working Faculty is not selected.");
if(termCode == null || termCode.trim().length() == 0) throw new SQLException("Term Code is required.");
if(userName == null || userName.trim().length() == 0) throw new SQLException("User is required.");
if(frmDate == null || !frmDate.matches("\\d{2}-\\d{2}-\\d{4}")) throw new SQLException("Invalid From Date.");
if(toDate == null || !toDate.matches("\\d{2}-\\d{2}-\\d{4}")) throw new SQLException("Invalid To Date.");
termCode = termCode.trim();
userName = userName.trim();
frmDate = frmDate.trim();
toDate = toDate.trim();
con = pool.getConnection();
oldAutoCommit = con.getAutoCommit();
con.setAutoCommit(false);
int dateValid = 0;
try(PreparedStatement ps = con.prepareStatement("SELECT CASE WHEN TO_DATE(?,'DD-MM-YYYY') <= TO_DATE(?,'DD-MM-YYYY') THEN 1 ELSE 0 END FROM DUAL"))
{
ps.setString(1, frmDate);
ps.setString(2, toDate);
try(ResultSet rs = ps.executeQuery()) { if(rs.next()) dateValid = rs.getInt(1); }
}
if(dateValid != 1) throw new SQLException("From Date cannot be greater than To Date.");
int managedUser = 0;
try(PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM UMS.WEB_USERS_MANAGEMENT WUM WHERE WUM.USER_RIGHTS_MANAGER = ? AND WUM.RIGHTS_FOR_USER = ?"))
{
ps.setString(1, adminSession.user);
ps.setString(2, userName);
try(ResultSet rs = ps.executeQuery()) { if(rs.next()) managedUser = rs.getInt(1); }
}
if(managedUser == 0) throw new SQLException("Selected User is not managed by the logged-in user.");
boolean canAllowAnyTerm = com.ums.functions.Functions.isUserAllowedProcess(con, "CanAllowAnyTerm", adminSession.user);
int allowedTerm = 0;
if(canAllowAnyTerm)
{
try(PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM UMS.TERM T WHERE T.TERM_CDE = ? AND T.TERM_CDE <> (SELECT CT.TERM_CDE FROM UMS.CURRENT_TERM CT WHERE CT.FACULTY_ID = ?)"))
{
ps.setString(1, termCode);
ps.setString(2, adminSession.getWorkingFacultyId());
try(ResultSet rs = ps.executeQuery()) { if(rs.next()) allowedTerm = rs.getInt(1); }
}
}
else
{
String allowedSql = "SELECT COUNT(*) FROM UMS.TERM T WHERE T.TERM_CDE = ? AND (T.START_DTE = (SELECT MAX(T1.START_DTE) FROM UMS.TERM T1 WHERE T1.START_DTE < (SELECT T2.START_DTE FROM UMS.TERM T2 JOIN UMS.CURRENT_TERM C2 ON C2.TERM_CDE = T2.TERM_CDE WHERE C2.FACULTY_ID = ?)) OR T.START_DTE BETWEEN (SELECT T3.START_DTE FROM UMS.TERM T3 JOIN UMS.CURRENT_TERM C3 ON C3.TERM_CDE = T3.TERM_CDE WHERE T3.STATUS_TYP = 'C' AND C3.FACULTY_ID = ?) AND (SELECT MAX(T4.START_DTE) FROM UMS.TERM T4 WHERE T4.START_DTE > (SELECT T5.START_DTE FROM UMS.TERM T5 JOIN UMS.CURRENT_TERM C5 ON C5.TERM_CDE = T5.TERM_CDE WHERE C5.FACULTY_ID = ?)))";
try(PreparedStatement ps = con.prepareStatement(allowedSql))
{
ps.setString(1, termCode);
ps.setString(2, adminSession.getWorkingFacultyId());
ps.setString(3, adminSession.getWorkingFacultyId());
ps.setString(4, adminSession.getWorkingFacultyId());
try(ResultSet rs = ps.executeQuery()) { if(rs.next()) allowedTerm = rs.getInt(1); }
}
}
if(allowedTerm == 0) throw new SQLException("Selected Term is not allowed for allocation.");
String insertSql = "INSERT INTO UMS.USER_TERM_ALLOCATION (USER_NME, TERM_CDE, FRM_DTE, TO_DTE, DISALLOW_IND, FACULTY_ID) VALUES (?, ?, TO_DATE(?,'DD-MM-YYYY'), TO_DATE(?,'DD-MM-YYYY'), 'F', ?)";
try(PreparedStatement ps = con.prepareStatement(insertSql))
{
ps.setString(1, userName);
ps.setString(2, termCode);
ps.setString(3, frmDate);
ps.setString(4, toDate);
ps.setString(5, adminSession.getWorkingFacultyId());
ps.executeUpdate();
}
adminSession.addLog("INSERT UMS.USER_TERM_ALLOCATION USER_NME=" + userName + ", TERM_CDE=" + termCode + ", FRM_DTE=" + frmDate + ", TO_DTE=" + toDate + ", FACULTY_ID=" + adminSession.getWorkingFacultyId(), con);
con.commit();
session.setAttribute("flashType", "success");
session.setAttribute("flashMessage", "Term allocation has been added successfully.");
response.sendRedirect("AdminAddTermAllocation.jsp");
}
catch(Exception e)
{
if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
String message = e.getMessage();
if(message == null || message.trim().length() == 0) message = "Unable to add Term Allocation.";
if(message.indexOf("ORA-00001") >= 0) message = "This Term Allocation is already defined.";
if(message.indexOf("ORA-018") >= 0) message = "Invalid date value.";
session.setAttribute("flashType", "error");
session.setAttribute("flashMessage", message);
response.sendRedirect("AdminAddTermAllocation.jsp");
}
finally
{
if(con != null) try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
pool.close(con);
}
%>