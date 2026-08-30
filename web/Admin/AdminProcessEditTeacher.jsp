<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<%!
    private String p(jakarta.servlet.http.HttpServletRequest request, String name) {
        String value = request.getParameter(name);
        return value == null ? "" : value.trim();
    }
%>
<%
    com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession) session.getAttribute("adminSession");
    if(adminSession == null) { %><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><% return; }
    if(!adminSession.hasRightsOn("Teacher")) { %><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Teacher service."/><% return; }
    Connection con = null;
    String teacherIdValue = p(request,"tchrId");
    try {
        if(!teacherIdValue.matches("\\d+")) throw new SQLException("Invalid Teacher ID.");
        int teacherId = Integer.parseInt(teacherIdValue);
        String tchrName = p(request,"tchrName").toUpperCase();
        String tchrAbbr = p(request,"tchrAbbr").toUpperCase();
        String tchrAddr = p(request,"tchrAddr");
        String tchrPhone = p(request,"tchrPhone");
        String tchrCell = p(request,"tchrCell");
        String tchrOffAddr = p(request,"tchrOffAddr");
        String tchrOffPhone = p(request,"tchrOffPhone");
        String tchrOffPhoneExt = p(request,"tchrOffPhoneExt");
        String tchrEmail = p(request,"tchrEmail").toLowerCase();
        String tchrPersonalWebURL = p(request,"tchrPersonalWebURL");
        String joinDate = p(request,"joinDate");
        String typeInd = p(request,"typeInd").toUpperCase();
        String available = request.getParameter("available") == null ? "N" : "A";
        String tchrNic = p(request,"nic");
        String rateValue = p(request,"rte");
        String designationValue = p(request,"tchrDesigId");
        String facultyValue = p(request,"faculty");
        String cityId = p(request,"cityId");
        if(tchrName.length() == 0 || tchrAbbr.length() == 0) throw new SQLException("Teacher Name and Abbreviation are required.");
        if(!tchrEmail.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) throw new SQLException("Please enter a valid email address.");
        if(!tchrNic.matches("\\d{13}")) throw new SQLException("CNIC must contain exactly 13 digits without dashes.");
        if(!facultyValue.matches("\\d+")) throw new SQLException("Invalid Faculty.");
        if(!"P".equals(typeInd) && !"V".equals(typeInd)) throw new SQLException("Invalid Teacher Type.");
        if("V".equals(typeInd) && !rateValue.matches("\\d{1,5}")) throw new SQLException("Teacher Rate is required for visiting faculty.");
        if(tchrPersonalWebURL.length() > 0 && !tchrPersonalWebURL.matches("(?i)^https?://.*")) tchrPersonalWebURL = "http://" + tchrPersonalWebURL;
        Integer rate = "V".equals(typeInd) ? Integer.valueOf(rateValue) : null;
        Integer designationId = designationValue.matches("\\d+") ? Integer.valueOf(designationValue) : null;
        int facultyId = Integer.parseInt(facultyValue);
        int workingFacultyId = Integer.parseInt(adminSession.getWorkingFacultyId());
        con = pool.getConnection();
        con.setAutoCommit(false);
        String updateSql = "UPDATE UMS.TEACHER SET TCHR_NME=?,TCHR_ABBR=?,ADDRESS_TXT=?,PHONE_NBR=?,CELL_NBR=?,OFF_ADDRESS_TXT=?,OFF_PHONE_NBR=?,EMAIL_TXT=?,STATUS_IND=?,JOINING_DTE=TO_DATE(NULLIF(?,'') ,'DD-MM-YYYY'),TYPE_IND=?,TCHR_RTE=?,FACULTY_ID=?,DESIG_ID=?,OFFICE_PHONE_EXT=?,PERSONAL_WEB_URL=?,NIC=? WHERE TCHR_ID=?";
        try(PreparedStatement ps = con.prepareStatement(updateSql)) { ps.setString(1,tchrName); ps.setString(2,tchrAbbr); ps.setString(3,tchrAddr); ps.setString(4,tchrPhone); ps.setString(5,tchrCell); ps.setString(6,tchrOffAddr); ps.setString(7,tchrOffPhone); ps.setString(8,tchrEmail); ps.setString(9,available); ps.setString(10,joinDate); ps.setString(11,typeInd); if(rate == null) ps.setNull(12,Types.NUMERIC); else ps.setInt(12,rate.intValue()); ps.setInt(13,facultyId); if(designationId == null) ps.setNull(14,Types.NUMERIC); else ps.setInt(14,designationId.intValue()); ps.setString(15,tchrOffPhoneExt); ps.setString(16,tchrPersonalWebURL); ps.setString(17,tchrNic); ps.setInt(18,teacherId); if(ps.executeUpdate() == 0) throw new SQLException("Teacher was not found."); }
        String username = null;
        try(PreparedStatement ps = con.prepareStatement("SELECT USER_NME FROM UMS.WEB_USERS WHERE TCHR_ID=?")) { ps.setInt(1,teacherId); try(ResultSet rs = ps.executeQuery()) { if(rs.next()) username = rs.getString(1); } }
        if(username != null) {
            try(PreparedStatement ps = con.prepareStatement("DELETE FROM UMS.WEB_USERS_FACULTY WHERE USER_NME=? AND FACULTY_ID<>?")) { ps.setString(1,username); ps.setInt(2,workingFacultyId); ps.executeUpdate(); }
            try(PreparedStatement ps = con.prepareStatement("INSERT INTO UMS.WEB_USERS_FACULTY(USER_NME,FACULTY_ID) SELECT ?,? FROM DUAL WHERE NOT EXISTS(SELECT 1 FROM UMS.WEB_USERS_FACULTY WHERE USER_NME=? AND FACULTY_ID=?)")) { ps.setString(1,username); ps.setInt(2,workingFacultyId); ps.setString(3,username); ps.setInt(4,workingFacultyId); ps.executeUpdate(); }
            if(cityId.matches("\\d+")) { String citySql = "INSERT INTO UMS.WEB_USERS_FACULTY(USER_NME,FACULTY_ID) SELECT ?,F.FACULTY_ID FROM UMS.FACULTY F JOIN UMS.CAMPUS C ON C.CMP_ID=F.CMP_ID WHERE C.CITY_ID=? AND NOT EXISTS(SELECT 1 FROM UMS.WEB_USERS_FACULTY W WHERE W.USER_NME=? AND W.FACULTY_ID=F.FACULTY_ID)"; try(PreparedStatement ps = con.prepareStatement(citySql)) { ps.setString(1,username); ps.setInt(2,Integer.parseInt(cityId)); ps.setString(3,username); ps.executeUpdate(); } }
        }
        try(Statement logStmt = con.createStatement()) { adminSession.addLog("UPDATE UMS.TEACHER TCHR_ID=" + teacherId + ", TCHR_ABBR=" + tchrAbbr,logStmt); }
        con.commit();
        session.setAttribute("flashType","success");
        session.setAttribute("flashMessage","Teacher " + tchrName + " has been updated successfully.");
        response.sendRedirect("AdminTeacher.jsp");
    } catch(Exception e) {
        if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
        String message = e.getMessage() == null ? "Unable to update Teacher." : e.getMessage();
        if(message.indexOf("ORA-00001") >= 0) message = "Teacher abbreviation or CNIC already exists.";
        session.setAttribute("flashType","error");
        session.setAttribute("flashMessage",message);
        if(teacherIdValue.matches("\\d+")) response.sendRedirect("AdminEditTeacher.jsp?tchrId=" + teacherIdValue); else response.sendRedirect("AdminTeacher.jsp");
    } finally {
        if(con != null) pool.close(con);
    }
%>
