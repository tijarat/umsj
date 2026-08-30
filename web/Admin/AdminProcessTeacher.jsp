<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*" session="true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<%!
    private void log(String message, String user) {
        System.out.println(new java.util.Date() + "::AdminProcessTeacher.jsp::" + user + "::" + message);
    }
    private String p(jakarta.servlet.http.HttpServletRequest request, String name) {
        String value = request.getParameter(name);
        return value == null ? "" : value.trim();
    }
%>
<%
    com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession) session.getAttribute("adminSession");
    if(adminSession == null) {
        log("Session Not Found", "Invalid");
%><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><%
        return;
    }
    if(!adminSession.hasRightsOn("Teacher")) {
%><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Teacher service."/><%
        return;
    }
    Connection con = null;
    try {
        String userName = p(request,"userName").toUpperCase();
        String password = request.getParameter("password");
        String retypePassword = request.getParameter("retypePassword");
        String title = p(request,"tchrTitle").toUpperCase();
        String tchrName = (title + p(request,"tchrName").toUpperCase()).trim();
        String tchrAbbr = (title + p(request,"tchrAbbr").toUpperCase()).trim();
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
        String cityId = p(request,"cityId");
        String role = p(request,"role").toUpperCase();
        String status = request.getParameter("activeInd") == null ? "N" : "Y";
        String rateValue = p(request,"rte");
        String designationValue = p(request,"tchrDesigId");
        if(!userName.matches("[A-Z0-9._]{1,20}")) throw new SQLException("Username may contain only letters, numbers, periods and underscores.");
        if(password == null || retypePassword == null || !password.equals(retypePassword)) throw new SQLException("Password and Retype Password do not match.");
        if(password.length() < 6) throw new SQLException("Password length should not be less than 6 characters.");
        if(password.equalsIgnoreCase(userName)) throw new SQLException("Password should not be the same as Username.");
        if(tchrName.length() == 0 || tchrAbbr.length() == 0) throw new SQLException("Teacher Name and Abbreviation are required.");
        if(!tchrEmail.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) throw new SQLException("Please enter a valid email address.");
        if(!tchrNic.matches("\\d{13}")) throw new SQLException("CNIC must contain exactly 13 digits without dashes.");
        if(!"P".equals(typeInd) && !"V".equals(typeInd)) throw new SQLException("Invalid Teacher Type.");
        if("V".equals(typeInd) && !rateValue.matches("\\d{1,5}")) throw new SQLException("Teacher Rate is required for visiting faculty.");
        if(role.length() == 0) role = "A";
        if(tchrPersonalWebURL.length() > 0 && !tchrPersonalWebURL.matches("(?i)^https?://.*")) tchrPersonalWebURL = "http://" + tchrPersonalWebURL;
        int facultyId = Integer.parseInt(adminSession.getWorkingFacultyId());
        Integer rate = "V".equals(typeInd) ? Integer.valueOf(rateValue) : null;
        Integer designationId = designationValue.matches("\\d+") ? Integer.valueOf(designationValue) : null;
        con = pool.getConnection();
        con.setAutoCommit(false);
        try(PreparedStatement ps = con.prepareStatement("SELECT 1 FROM UMS.TEACHER WHERE UPPER(TCHR_ABBR)=?")) {
            ps.setString(1,tchrAbbr.toUpperCase());
            try(ResultSet rs = ps.executeQuery()) { if(rs.next()) throw new SQLException("Duplicate Teacher Abbreviation: " + tchrAbbr); }
        }
        try(PreparedStatement ps = con.prepareStatement("SELECT 1 FROM UMS.TEACHER WHERE NIC=?")) {
            ps.setString(1,tchrNic);
            try(ResultSet rs = ps.executeQuery()) { if(rs.next()) throw new SQLException("Duplicate Teacher CNIC: " + tchrNic); }
        }
        try(PreparedStatement ps = con.prepareStatement("SELECT 1 FROM UMS.WEB_USERS WHERE USER_NME=?")) {
            ps.setString(1,userName);
            try(ResultSet rs = ps.executeQuery()) { if(rs.next()) throw new SQLException("Duplicate Username: " + userName); }
        }
        int tchrId = 0;
        try(PreparedStatement ps = con.prepareStatement("SELECT UMS.SEQ_TCHR_ID.NEXTVAL FROM DUAL"); ResultSet rs = ps.executeQuery()) { if(rs.next()) tchrId = rs.getInt(1); else throw new SQLException("Unable to generate Teacher ID."); }
        String teacherSql = "INSERT INTO UMS.TEACHER(TCHR_ID,TCHR_NME,TCHR_ABBR,ADDRESS_TXT,PHONE_NBR,CELL_NBR,OFF_ADDRESS_TXT,OFF_PHONE_NBR,EMAIL_TXT,STATUS_IND,JOINING_DTE,TYPE_IND,TCHR_RTE,FACULTY_ID,DESIG_ID,OFFICE_PHONE_EXT,PERSONAL_WEB_URL,NIC) VALUES(?,?,?,?,?,?,?,?,?,?,TO_DATE(NULLIF(?,'') ,'DD-MM-YYYY'),?,?,?,?,?,?,?)";
        try(PreparedStatement ps = con.prepareStatement(teacherSql)) {
            ps.setInt(1,tchrId); ps.setString(2,tchrName); ps.setString(3,tchrAbbr); ps.setString(4,tchrAddr); ps.setString(5,tchrPhone); ps.setString(6,tchrCell); ps.setString(7,tchrOffAddr); ps.setString(8,tchrOffPhone); ps.setString(9,tchrEmail); ps.setString(10,available); ps.setString(11,joinDate); ps.setString(12,typeInd); if(rate == null) ps.setNull(13,Types.NUMERIC); else ps.setInt(13,rate.intValue()); ps.setInt(14,facultyId); if(designationId == null) ps.setNull(15,Types.NUMERIC); else ps.setInt(15,designationId.intValue()); ps.setString(16,tchrOffPhoneExt); ps.setString(17,tchrPersonalWebURL); ps.setString(18,tchrNic); ps.executeUpdate();
        }
        com.ums.packages.Security security = new com.ums.packages.Security();
        String encryptedPassword = security.encrypt(security.encrypt(password));
        try(PreparedStatement ps = con.prepareStatement("INSERT INTO UMS.WEB_USERS(USER_NME,USER_PASSWORD,ACTIVE_IND_TYPE,TYP_IND,TCHR_ID,EXP_DTE) VALUES(?,?,?,?,?,SYSDATE)")) { ps.setString(1,userName); ps.setString(2,encryptedPassword); ps.setString(3,status); ps.setString(4,role); ps.setInt(5,tchrId); ps.executeUpdate(); }
        try(PreparedStatement readRights = con.prepareStatement("SELECT RIGHT_NME FROM UMS.TEACHER_RIGHTS"); ResultSet rs = readRights.executeQuery(); PreparedStatement addRight = con.prepareStatement("INSERT INTO UMS.USER_RIGHTS(USER_RIGHTS_ID,RIGHT_NME,USER_NME) VALUES(UMS.SEQ_USER_RIGHTS_ID.NEXTVAL,?,?)")) { while(rs.next()) { addRight.setString(1,rs.getString(1)); addRight.setString(2,userName); addRight.addBatch(); } addRight.executeBatch(); }
        try(PreparedStatement ps = con.prepareStatement("INSERT INTO UMS.WEB_USERS_FACULTY(USER_NME,FACULTY_ID) VALUES(?,?)")) { ps.setString(1,userName); ps.setInt(2,facultyId); ps.executeUpdate(); }
        if(cityId.matches("\\d+")) {
            String cityFacultySql = "INSERT INTO UMS.WEB_USERS_FACULTY(USER_NME,FACULTY_ID) SELECT ?,F.FACULTY_ID FROM UMS.FACULTY F JOIN UMS.CAMPUS C ON C.CMP_ID=F.CMP_ID WHERE C.CITY_ID=? AND NOT EXISTS(SELECT 1 FROM UMS.WEB_USERS_FACULTY W WHERE W.USER_NME=? AND W.FACULTY_ID=F.FACULTY_ID)";
            try(PreparedStatement ps = con.prepareStatement(cityFacultySql)) { ps.setString(1,userName); ps.setInt(2,Integer.parseInt(cityId)); ps.setString(3,userName); ps.executeUpdate(); }
        }
        try(Statement logStmt = con.createStatement()) { adminSession.addLog("INSERT TEACHER TCHR_ID=" + tchrId + ", TCHR_ABBR=" + tchrAbbr + ", USER_NME=" + userName,logStmt); }
        con.commit();
        session.setAttribute("flashType","success");
        session.setAttribute("flashMessage","Teacher " + tchrName + " has been added successfully.");
        response.sendRedirect("AdminTeacher.jsp");
    } catch(Exception e) {
        if(con != null) try { con.rollback(); } catch(SQLException ignored) {}
        String message = e.getMessage() == null ? "Unable to add Teacher." : e.getMessage();
        if(message.indexOf("ORA-00001") >= 0) message = "Teacher abbreviation, CNIC or username already exists.";
        session.setAttribute("flashType","error");
        session.setAttribute("flashMessage",message);
        response.sendRedirect("AdminTeacher.jsp");
    } finally {
        if(con != null) pool.close(con);
    }
%>
