<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<%!
    private void log(String message, String user) { System.out.println(new java.util.Date() + "::AdminProcessWorkingTerm.jsp::" + user + "::" + message); }
%>
<%
com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession)session.getAttribute("adminSession");
if(adminSession == null) { log("Session Not Found", "Invalid"); %><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><% return; }
boolean hasWorkingTermRight = adminSession.hasRightsOn("Change Working Term") || adminSession.hasRightsOn("Working Term");
if(!hasWorkingTermRight) { %><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Change Working Term service."/><% return; }
if(!"POST".equalsIgnoreCase(request.getMethod())) { response.sendRedirect("AdminWorkingTerm.jsp"); return; }
com.ums.db.Pool pool = (com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
String workingFacultyId = adminSession.getWorkingFacultyId();
String selectedTerm = request.getParameter("termCode");
Connection con = null;
boolean oldAutoCommit = true;
try {
if(workingFacultyId == null || workingFacultyId.trim().length() == 0) throw new SQLException("Working Faculty is not selected.");
if(selectedTerm == null || selectedTerm.trim().length() == 0) throw new SQLException("Please select a Working Term.");
selectedTerm = selectedTerm.trim().toUpperCase();
con = pool.getConnection();
try(PreparedStatement validateStmt = con.prepareStatement("SELECT TERM_CDE FROM UMS.TERM WHERE TERM_CDE = ?")) { validateStmt.setString(1, selectedTerm); try(ResultSet validateRs = validateStmt.executeQuery()) { if(!validateRs.next()) throw new SQLException("Selected Term does not exist."); } }
oldAutoCommit = con.getAutoCommit();
con.setAutoCommit(false);
try(PreparedStatement updateStmt = con.prepareStatement("UPDATE UMS.CURRENT_TERM SET TERM_CDE = ? WHERE FACULTY_ID = ?")) { updateStmt.setString(1, selectedTerm); updateStmt.setString(2, workingFacultyId); int updated = updateStmt.executeUpdate(); if(updated == 0) { try(PreparedStatement insertStmt = con.prepareStatement("INSERT INTO UMS.CURRENT_TERM(FACULTY_ID, TERM_CDE) VALUES(?, ?)")) { insertStmt.setString(1, workingFacultyId); insertStmt.setString(2, selectedTerm); insertStmt.executeUpdate(); } } }
try(Statement logStmt = con.createStatement()) { adminSession.addLog("CHANGE WORKING TERM FACULTY_ID=" + workingFacultyId + " TERM_CDE=" + selectedTerm, logStmt); }
con.commit();
adminSession.setWorkingTerm(con);
session.setAttribute("flashType", "success");
session.setAttribute("flashMessage", "Working Term has been changed to " + adminSession.workingTerm + " successfully.");
response.sendRedirect("AdminWorkingTerm.jsp");
} catch(Exception e) { if(con != null) try { con.rollback(); } catch(SQLException ignored) {} log("Error: " + e.getMessage(), adminSession.user); session.setAttribute("flashType", "error"); session.setAttribute("flashMessage", e.getMessage() == null || e.getMessage().trim().length() == 0 ? "Unable to change Working Term." : e.getMessage()); response.sendRedirect("AdminWorkingTerm.jsp"); } finally { if(con != null) { try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {} pool.close(con); } }
%>
