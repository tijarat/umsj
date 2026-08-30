<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" language="java" import="java.sql.*,java.util.*" session="true" errorPage="../error.jsp" %>
<jsp:useBean id="pool" scope="application" class="com.ums.db.Pool"/>
<%!
    private String html(String value) {
        if(value == null) return "";
        return value.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
    }
%>
<%
    com.ums.packages.LocalSession adminSession = (com.ums.packages.LocalSession) session.getAttribute("adminSession");
    if(adminSession == null) { %><jsp:forward page="../SessionExpire.jsp?des=Your Session/Connection closed please login again."/><% return; }
    if(!adminSession.hasRightsOn("Teacher")) { %><jsp:forward page="../UnauthorizedAdmin.jsp?des=You don't have privileges over Teacher service."/><% return; }
    String teacherIdValue = request.getParameter("tchrId");
    if(teacherIdValue == null || !teacherIdValue.matches("\\d+")) { session.setAttribute("flashType","error"); session.setAttribute("flashMessage","Invalid Teacher ID."); response.sendRedirect("AdminTeacher.jsp"); return; }
    int teacherId = Integer.parseInt(teacherIdValue);
    Connection con = null;
    try {
        con = pool.getConnection();
        String[] teacher = null;
        String teacherSql = "SELECT T.TCHR_NME,T.TCHR_ABBR,NVL(T.ADDRESS_TXT,''),NVL(T.PHONE_NBR,''),NVL(T.CELL_NBR,''),NVL(T.OFF_ADDRESS_TXT,''),NVL(T.OFF_PHONE_NBR,''),NVL(T.EMAIL_TXT,''),T.STATUS_IND,TO_CHAR(T.JOINING_DTE,'DD-MM-YYYY'),NVL(T.TYPE_IND,'V'),NVL(TO_CHAR(T.TCHR_RTE),''),NVL(TO_CHAR(T.DESIG_ID),''),NVL(T.OFFICE_PHONE_EXT,''),NVL(T.PERSONAL_WEB_URL,''),NVL(T.NIC,''),NVL(TO_CHAR(T.FACULTY_ID),'') FROM UMS.TEACHER T WHERE T.TCHR_ID=?";
        try(PreparedStatement ps = con.prepareStatement(teacherSql)) { ps.setInt(1,teacherId); try(ResultSet rs = ps.executeQuery()) { if(rs.next()) { teacher = new String[17]; for(int i=0;i<17;i++) teacher[i] = rs.getString(i+1); } } }
        if(teacher == null) { session.setAttribute("flashType","error"); session.setAttribute("flashMessage","Teacher was not found."); response.sendRedirect("AdminTeacher.jsp"); return; }
        List<String[]> designations = new ArrayList<String[]>();
        try(PreparedStatement ps = con.prepareStatement("SELECT DESIG_ID,LONG_DESIG FROM UMS.DESIGNATION ORDER BY LONG_DESIG"); ResultSet rs = ps.executeQuery()) { while(rs.next()) designations.add(new String[]{String.valueOf(rs.getInt(1)),rs.getString(2)}); }
        List<String[]> faculties = new ArrayList<String[]>();
        try(PreparedStatement ps = con.prepareStatement("SELECT F.FACULTY_ID,C.CMP_ABBERV,F.FACULTY_NME FROM UMS.FACULTY F JOIN UMS.CAMPUS C ON C.CMP_ID=F.CMP_ID ORDER BY C.CMP_ABBERV,F.FACULTY_NME"); ResultSet rs = ps.executeQuery()) { while(rs.next()) faculties.add(new String[]{String.valueOf(rs.getInt(1)),rs.getString(2),rs.getString(3)}); }
        String selectedCity = "";
        String selectedCitySql = "SELECT MIN(C.CITY_ID) FROM UMS.WEB_USERS WU JOIN UMS.WEB_USERS_FACULTY WUF ON WUF.USER_NME=WU.USER_NME JOIN UMS.FACULTY F ON F.FACULTY_ID=WUF.FACULTY_ID JOIN UMS.CAMPUS C ON C.CMP_ID=F.CMP_ID WHERE WU.TCHR_ID=? AND WUF.FACULTY_ID<>?";
        try(PreparedStatement ps = con.prepareStatement(selectedCitySql)) { ps.setInt(1,teacherId); ps.setInt(2,Integer.parseInt(adminSession.getWorkingFacultyId())); try(ResultSet rs = ps.executeQuery()) { if(rs.next() && rs.getObject(1) != null) selectedCity = String.valueOf(rs.getInt(1)); } }
        List<String[]> cities = new ArrayList<String[]>();
        try(PreparedStatement ps = con.prepareStatement("SELECT CITY_ID,CITY_NAME FROM UMS.CITY ORDER BY CITY_NAME"); ResultSet rs = ps.executeQuery()) { while(rs.next()) cities.add(new String[]{String.valueOf(rs.getInt(1)),rs.getString(2)}); }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Teacher</title>
    <link href="../extra/css/style.css?v=20260830" rel="stylesheet" type="text/css">
    <link href="../extra/css/ums-module.css?v=20260830-teacher" rel="stylesheet" type="text/css">
</head>
<body class="ums-admin-main-body">
<main class="ums-module-page">
    <section class="ums-module-header"><div><p class="ums-module-eyebrow">Academic Setup</p><h1>Edit Teacher</h1><p>Update teacher profile, faculty, designation, availability and additional campus access.</p></div></section>
    <section class="ums-module-card">
        <div class="ums-module-card-header"><h2><%=html(teacher[0])%></h2><span>Teacher ID: <%=teacherId%></span></div>
        <form action="AdminProcessEditTeacher.jsp" method="post" name="editTeacherForm" id="editTeacherForm" class="ums-module-form" data-ums-teacher-form="edit">
            <input type="hidden" name="tchrId" value="<%=teacherId%>">
            <div class="ums-form-grid">
                <div class="ums-field"><label for="tchrName">Teacher Name *</label><input name="tchrName" id="tchrName" type="text" maxlength="80" value="<%=html(teacher[0])%>" required></div>
                <div class="ums-field"><label for="tchrAbbr">Teacher Abbreviation *</label><input name="tchrAbbr" id="tchrAbbr" type="text" maxlength="20" value="<%=html(teacher[1])%>" required></div>
                <div class="ums-field"><label for="tchrEmail">Email *</label><input name="tchrEmail" id="tchrEmail" type="email" maxlength="80" value="<%=html(teacher[7])%>" required></div>
                <div class="ums-field"><label for="nic">CNIC *</label><input name="nic" id="nic" type="text" inputmode="numeric" maxlength="13" value="<%=html(teacher[15])%>" required></div>
                <div class="ums-field ums-field-wide"><label for="tchrAddr">Home Address</label><input name="tchrAddr" id="tchrAddr" type="text" maxlength="100" value="<%=html(teacher[2])%>"></div>
                <div class="ums-field"><label for="tchrPhone">Home Phone</label><input name="tchrPhone" id="tchrPhone" type="text" maxlength="20" value="<%=html(teacher[3])%>"></div>
                <div class="ums-field"><label for="tchrCell">Cell Number</label><input name="tchrCell" id="tchrCell" type="text" maxlength="20" value="<%=html(teacher[4])%>"></div>
                <div class="ums-field ums-field-wide"><label for="tchrOffAddr">Office Address</label><input name="tchrOffAddr" id="tchrOffAddr" type="text" maxlength="100" value="<%=html(teacher[5])%>"></div>
                <div class="ums-field"><label for="tchrOffPhone">Office Phone</label><input name="tchrOffPhone" id="tchrOffPhone" type="text" maxlength="20" value="<%=html(teacher[6])%>"></div>
                <div class="ums-field"><label for="tchrOffPhoneExt">Extension</label><input name="tchrOffPhoneExt" id="tchrOffPhoneExt" type="text" maxlength="4" value="<%=html(teacher[13])%>"></div>
                <div class="ums-field"><label for="tchrPersonalWebURL">Personal Web URL</label><input name="tchrPersonalWebURL" id="tchrPersonalWebURL" type="text" maxlength="128" value="<%=html(teacher[14])%>"></div>
                <div class="ums-field"><label for="joinDateDisplay">Joining Date</label><div class="ums-date-picker"><input type="text" id="joinDateDisplay" class="ums-date-display" value="<%=html(teacher[9])%>" readonly><input type="hidden" name="joinDate" id="joinDate" value="<%=html(teacher[9])%>"><button type="button" class="ums-date-button" aria-label="Choose joining date">📅</button><input type="date" id="joinDatePicker" class="ums-native-date" tabindex="-1"></div></div>
                <div class="ums-field"><label for="typeInd">Teacher Type *</label><select name="typeInd" id="typeInd" data-ums-teacher-type required><option value="V" <%= "V".equalsIgnoreCase(teacher[10]) ? "selected" : "" %>>Visiting</option><option value="P" <%= "P".equalsIgnoreCase(teacher[10]) ? "selected" : "" %>>Permanent</option></select></div>
                <div class="ums-field"><label for="rte">Teacher Rate</label><input name="rte" id="rte" type="number" min="0" max="99999" step="1" value="<%=html(teacher[11])%>"><small>Required for visiting faculty.</small></div>
                <div class="ums-field"><label for="tchrDesigId">Designation</label><select name="tchrDesigId" id="tchrDesigId"><option value="">-- Select --</option><% for(String[] row : designations) { %><option value="<%=row[0]%>" <%=row[0].equals(teacher[12]) ? "selected" : ""%>><%=html(row[1])%></option><% } %></select></div>
                <div class="ums-field"><label for="faculty">Faculty *</label><select name="faculty" id="faculty" required><% for(String[] row : faculties) { %><option value="<%=row[0]%>" <%=row[0].equals(teacher[16]) ? "selected" : ""%>><%=html(row[1])%> - <%=html(row[2])%></option><% } %></select></div>
                <div class="ums-field"><label for="cityId">Additional Campus City</label><select name="cityId" id="cityId"><option value="-">-- Select campus city --</option><% for(String[] row : cities) { %><option value="<%=row[0]%>" <%=row[0].equals(selectedCity) ? "selected" : ""%>><%=html(row[1])%></option><% } %></select></div>
                <div class="ums-field ums-field-check"><label class="ums-check-label"><input name="available" id="available" type="checkbox" value="A" <%= "A".equalsIgnoreCase(teacher[8]) ? "checked" : "" %>><span>Teacher Available</span></label></div>
            </div>
            <div class="ums-form-actions"><button type="submit">Update Teacher</button><a href="AdminTeacher.jsp" class="ums-secondary-button">Cancel</a></div>
        </form>
    </section>
</main>
<script src="../extra/js/ums-module.js?v=20260830"></script>
<script src="../extra/js/teacher.js?v=20260830"></script>
</body>
</html>
<%
    } finally {
        if(con != null) pool.close(con);
    }
%>
