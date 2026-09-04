<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<%
com.ums.packages.LocalSession adminSession=(com.ums.packages.LocalSession)session.getAttribute("adminSession");
if(adminSession == null)
{
%><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><%
return;
}
if(!adminSession.hasRightsOn("Course Equivalance"))
{
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Course Equivalence."/><%
return;
}
String newCourse=request.getParameter("newCourse");
String oldCourse=request.getParameter("old");
com.ums.db.Pool pool=(com.ums.db.Pool)application.getAttribute("pool");
if(pool == null) throw new ServletException("Database pool is not initialized.");
Connection con=null;
boolean oldAutoCommit=true;
try
{
oldCourse=oldCourse==null ? "" : oldCourse.trim().toUpperCase();
newCourse=newCourse==null ? "" : newCourse.trim().toUpperCase();
if(oldCourse.length()==0) throw new SQLException("Old Course Code is required.");
if(newCourse.length()==0) throw new SQLException("New Course Code is required.");
if(oldCourse.length()>10 || newCourse.length()>10) throw new SQLException("Course Code cannot exceed 10 characters.");
if(!oldCourse.matches("[A-Z][A-Z0-9._/-]*")) throw new SQLException("Old Course Code must start with an alphabet.");
if(!newCourse.matches("[A-Z][A-Z0-9._/-]*")) throw new SQLException("New Course Code must start with an alphabet.");
if(oldCourse.equals(newCourse)) throw new SQLException("Old Course Code and New Course Code cannot be the same.");
con=pool.getConnection();
oldAutoCommit=con.getAutoCommit();
con.setAutoCommit(false);
int num=0;
try(PreparedStatement ps=con.prepareStatement("UPDATE UMS.COR_GRADES SET NCOURSEID = ? WHERE COURSEID = ?")) { ps.setString(1,newCourse); ps.setString(2,oldCourse); num=ps.executeUpdate(); }
adminSession.addLog("UPDATE UMS.COR_GRADES SET NCOURSEID=" + newCourse + " WHERE COURSEID=" + oldCourse + ", ROWS=" + num, con);
con.commit();
if(num > 0) { session.setAttribute("flashType","success"); session.setAttribute("flashMessage",num + " grade record(s) updated successfully from " + oldCourse + " to " + newCourse + "."); } else { session.setAttribute("flashType","error"); session.setAttribute("flashMessage","Old Course '" + oldCourse + "' was not found in grade records."); }
response.sendRedirect("AdminCourseEq.jsp");
}
catch(Exception e)
{
if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
session.setAttribute("flashType","error");
session.setAttribute("flashMessage",e.getMessage()==null ? "Unable to change Course Equivalence." : e.getMessage());
response.sendRedirect("AdminCourseEq.jsp");
}
finally
{
if(con != null) try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
pool.close(con);
}
%>