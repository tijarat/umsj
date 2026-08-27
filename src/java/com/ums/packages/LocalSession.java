package com.ums.packages;

import com.ums.functions.Functions;
import java.io.Serial;
import java.io.Serializable;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import jakarta.servlet.http.HttpSessionBindingEvent;
import jakarta.servlet.http.HttpSessionBindingListener;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class LocalSession implements HttpSessionBindingListener, Serializable
{
    @Serial
    private static final long serialVersionUID = 1L;

    public Connection con = null;
    public String user = "";
    public int sessionId;
    private final List<String> rights = new ArrayList<>();
    public Container container = null;
    public String workingTerm = "";
    public StudentContainer studentContainer = null;
    public int tchrId = -1;

    private String workingFaculty = "";
    private String workingFacultyId = "";
    private String ipAddress = "";
    private String loginDate = "";
    private int teacherId = -1;
    private String campus = "";
    private int campusId = -1;
    private int uniId = -1;

    public LocalSession() {}

    public void start(Connection pCon, String pUser, Container container) throws Exception
    {
        con = pCon;
        user = pUser;
        this.container = container;
        setWebCtx();
        setRights();
        setTeacherId();
    }

    public void setWebCtx() throws Exception
    {
        try(CallableStatement cs = con.prepareCall("{call SET_WEB_CTX(?)}"))
        {
            cs.setString(1, user);
            cs.execute();
        }
        try(CallableStatement cs = con.prepareCall("{call dbms_session.SET_IDENTIFIER(?)}"))
        {
            cs.setString(1, user);
            cs.execute();
        }
    }

    public void addUserSession(String ipAddress) throws SQLException
    {
        this.ipAddress = ipAddress;
        try
        {
            con.setAutoCommit(false);
            String sql = "SELECT UCP.SEQ_USER_SESSION_ID.NEXTVAL FROM DUAL";
            try(Statement st = con.createStatement(); ResultSet rs = st.executeQuery(sql))
            {
                if(rs.next()) sessionId = rs.getInt(1);
                else throw new SQLException("Unable to generate USER_SESSION_ID.");
            }

            sql =
                "SELECT F.FACULTY_ABBREV, F.FACULTY_ID, C.CMP_ID, C.CMP_NAME, W.TCHR_ID, C.UNI_ID " +
                "FROM WEB_USERS_FACULTY WUF " +
                "JOIN FACULTY F ON F.FACULTY_ID = WUF.FACULTY_ID " +
                "JOIN CAMPUS C ON C.CMP_ID = F.CMP_ID " +
                "JOIN WEB_USERS W ON W.USER_NME = WUF.USER_NME " +
                "WHERE WUF.USER_NME = ? " +
                "ORDER BY F.FACULTY_ABBREV";

            boolean facultyFound = false;
            try(PreparedStatement st = con.prepareStatement(sql))
            {
                st.setString(1, user);
                try(ResultSet rs = st.executeQuery())
                {
                    if(rs.next())
                    {
                        facultyFound = true;
                        if(rs.getString("TCHR_ID") != null) tchrId = rs.getInt("TCHR_ID");
                        workingFaculty = rs.getString("FACULTY_ABBREV");
                        workingFacultyId = rs.getString("FACULTY_ID");
                        campusId = rs.getInt("CMP_ID");
                        campus = rs.getString("CMP_NAME");
                        uniId = rs.getInt("UNI_ID");
                    }
                }
            }

            if(!facultyFound)
            {
                sql =
                    "SELECT T.TCHR_ID, F.FACULTY_ABBREV, F.FACULTY_ID, C.CMP_ID, C.CMP_NAME, C.UNI_ID " +
                    "FROM TEACHER T " +
                    "JOIN WEB_USERS WU ON WU.TCHR_ID = T.TCHR_ID " +
                    "JOIN FACULTY F ON F.FACULTY_ID = T.FACULTY_ID " +
                    "JOIN CAMPUS C ON C.CMP_ID = F.CMP_ID " +
                    "WHERE WU.USER_NME = ?";

                try(PreparedStatement st = con.prepareStatement(sql))
                {
                    st.setString(1, user);
                    try(ResultSet rs = st.executeQuery())
                    {
                        if(rs.next())
                        {
                            tchrId = rs.getInt("TCHR_ID");
                            workingFaculty = rs.getString("FACULTY_ABBREV");
                            workingFacultyId = rs.getString("FACULTY_ID");
                            campusId = rs.getInt("CMP_ID");
                            campus = rs.getString("CMP_NAME");
                            uniId = rs.getInt("UNI_ID");

                            sql = "INSERT INTO WEB_USERS_FACULTY(USER_NME, FACULTY_ID) VALUES(?, ?)";
                            try(PreparedStatement insertSt = con.prepareStatement(sql))
                            {
                                insertSt.setString(1, user);
                                insertSt.setString(2, workingFacultyId);
                                insertSt.executeUpdate();
                            }
                        }else
                            resetFacultyContext();
                    }
                }
            }
            sql = "SELECT CT.TERM_CDE FROM CURRENT_TERM CT WHERE CT.FACULTY_ID = ?";
            try(PreparedStatement st = con.prepareStatement(sql))
            {
                st.setString(1, workingFacultyId);
                try(ResultSet rs = st.executeQuery())
                {
                    if(rs.next()) workingTerm = rs.getString(1);
                }
            }

            sql =
                "INSERT INTO UCP.USER_SESSION(USER_SESSION_ID, USER_NME, LOGIN_DTE, IP_ADDRESS) " +
                "VALUES(?, ?, SYSDATE, ?)";

            try(PreparedStatement st = con.prepareStatement(sql))
            {
                st.setInt(1, sessionId);
                st.setString(2, user);
                st.setString(3, ipAddress);
                st.executeUpdate();
            }
            con.commit();
        }catch(SQLException oops)
        {
            rollbackQuietly();
            System.out.println("Error in LocalSession.addUserSession(String ipAddress)::" + oops.getMessage());
        }
    }

    public void updateUserSession() throws SQLException
    {
        String sql = "UPDATE UCP.USER_SESSION SET LOGOUT_DTE = SYSDATE WHERE USER_SESSION_ID = ?";
        try
        {
            con.setAutoCommit(false);
            try(PreparedStatement st = con.prepareStatement(sql))
            {
                st.setInt(1, sessionId);
                st.executeUpdate();
            }
            con.commit();
        }catch(SQLException oops)
        {
            rollbackQuietly();
            System.out.println("Error in LocalSession.updateUserSession()::" + oops.getMessage());
        }
    }

    public void addLog(String statement) throws SQLException
    {
        String sql =
            "INSERT INTO UCP.USER_SESSION_DETAIL " +
            "(USER_SESSION_DETAIL_ID, USER_SESSION_ID, USER_ACTION, ACTION_DTE) " +
            "VALUES(SEQ_USER_SESSION_DETAIL_ID.NEXTVAL, ?, ?, SYSDATE)";
        try
        {
            con.setAutoCommit(false);
            try(PreparedStatement st = con.prepareStatement(sql))
            {
                st.setInt(1, sessionId);
                st.setString(2, statement);
                st.executeUpdate();
            }
            con.commit();
        }catch(SQLException oops)
        {
            rollbackQuietly();
            System.out.println("Error in LocalSession.addLog(String statement)::" + oops.getMessage());
        }
    }

    public String processLog(String processId, String processNme, String processDesc, String id) throws Exception
    {
        try
        {
            con.setAutoCommit(false);
            if(id == null || "-1".equalsIgnoreCase(id) || id.trim().isEmpty())
            {
                try(Statement st = con.createStatement(); ResultSet rs = st.executeQuery("SELECT SEQ_PROCESS_LOG_ID.NEXTVAL FROM DUAL"))
                {
                    if(rs.next()) id = rs.getString(1);
                }

                String sql = "INSERT INTO PROCESS_LOG VALUES(?, ?, ?, ?, SYSDATE, NULL)";
                try(PreparedStatement st = con.prepareStatement(sql))
                {
                    st.setString(1, id);
                    st.setString(2, processId);
                    st.setString(3, processNme);
                    st.setString(4, processDesc);
                    st.executeUpdate();
                }
            }else
            {
                String sql = "UPDATE PROCESS_LOG SET END_TMS = SYSDATE WHERE ID = ?";
                try(PreparedStatement st = con.prepareStatement(sql))
                {
                    st.setString(1, id);
                    st.executeUpdate();
                }
            }
            con.commit();
        }catch(Exception oops)
        {
            rollbackQuietly();
            System.out.println("Error in LocalSession.processLog()::" + oops.getMessage());
        }
        return id;
    }

    public void addLog(String statement, Statement addLogStmt) throws SQLException
    {
        if(addLogStmt == null) throw new SQLException("Statement cannot be null.");
        String sql =
            "INSERT INTO UCP.USER_SESSION_DETAIL " +
            "(USER_SESSION_DETAIL_ID, USER_SESSION_ID, USER_ACTION, ACTION_DTE) " +
            "VALUES(SEQ_USER_SESSION_DETAIL_ID.NEXTVAL, ?, ?, SYSDATE)";
        try(PreparedStatement st = addLogStmt.getConnection().prepareStatement(sql))
        {
            st.setInt(1, sessionId);
            st.setString(2, statement);
            st.executeUpdate();
        }
    }
    
    public List<String> getRights()
    {
        return Collections.unmodifiableList(rights);
    }    

    public void setRights() throws Exception
    {
        rights.clear();
        String sql =
            "SELECT INITCAP(RIGHT_NME), USER_RIGHTS_ID " +
            "FROM UCP.USER_RIGHTS " +
            "WHERE USER_NME = ? " +
            "AND RIGHT_NME IN (SELECT RIGHT_NME FROM UCP.ACTIVE_RIGHTS) ";
        if(Functions.isSuperUser(user, con))
        {
            sql +=
                "UNION " +
                "SELECT INITCAP(RIGHT_NME), USER_RIGHTS_ID " +
                "FROM UCP.USER_RIGHTS " +
                "WHERE RIGHT_NME IN ('Active Rights') ";
        }
        sql += "ORDER BY USER_RIGHTS_ID";

        try(PreparedStatement st = con.prepareStatement(sql))
        {
            st.setString(1, user);
            try(ResultSet rs = st.executeQuery())
            {
                while(rs.next()) rights.add(rs.getString(1));
            }
        }
    }

    public boolean hasRightsOn(String privilege)
    {
        return rights != null && rights.contains(privilege);
    }

    @Override
    public void valueBound(HttpSessionBindingEvent e) {}

    @Override
    public void valueUnbound(HttpSessionBindingEvent e)
    {
        try
        {
            if(con != null && !con.isClosed()) updateUserSession();
            if(container != null)
            {
                container.removeUser(user);
                if(studentContainer != null) container.removeUser(studentContainer.regNbr);
            }
            if(con != null && !con.isClosed()) con.close();
        }catch(SQLException oops)
        {
            System.out.println("LocalSession.valueUnbound()::" + oops.getMessage());
        }
    }

    public void setWorkingFaculty(Connection con, String workingFaculty) throws Exception
    {
        setWorkingFacultyId(workingFaculty);
        setWorkingTerm(con);
        String sql =
            "SELECT F.FACULTY_ABBREV, C.CMP_ID, C.CMP_NAME, C.UNI_ID " +
            "FROM FACULTY F " +
            "JOIN CAMPUS C ON C.CMP_ID = F.CMP_ID " +
            "WHERE F.FACULTY_ID = ?";

        try(PreparedStatement st = con.prepareStatement(sql))
        {
            st.setString(1, workingFaculty);
            try(ResultSet rs = st.executeQuery())
            {
                if(rs.next())
                {
                    this.workingFaculty = rs.getString("FACULTY_ABBREV");
                    campusId = rs.getInt("CMP_ID");
                    campus = rs.getString("CMP_NAME");
                    uniId = rs.getInt("UNI_ID");
                }else
                {
                    this.workingFaculty = "Faculty not found";
                    campus = "Campus Not Found";
                    campusId = -1;
                    uniId = -1;
                }
            }
        }catch(Exception oops)
        {
            System.out.println("Error in LocalSession.setWorkingFaculty()::" + oops.getMessage());
        }
    }

    public String getWorkingFaculty()
    {
        return workingFaculty;
    }

    public String getCampus()
    {
        return campus;
    }

    public int getCampusId()
    {
        return campusId;
    }

    public int getUniId()
    {
        return uniId;
    }

    public void setWorkingTerm(Connection con)
    {
        String sql = "SELECT CT.TERM_CDE FROM CURRENT_TERM CT WHERE CT.FACULTY_ID = ?";
        try(PreparedStatement st = con.prepareStatement(sql))
        {
            st.setString(1, workingFacultyId);
            try(ResultSet rs = st.executeQuery())
            {
                if(rs.next()) workingTerm = rs.getString(1);
                else workingTerm = "No Working Term Found";
            }
        }catch(Exception oops)
        {
            System.out.println("Error in LocalSession.setWorkingTerm()::" + oops.getMessage());
        }
    }

    public boolean hasPrivilegeOverStudent(String regNbr, String workingFacultyId) throws Exception
    {
        String sql =
            "SELECT F.FACULTY_ID " +
            "FROM STUDENT S " +
            "JOIN PROGRAM P ON P.PROG_ID = S.PROG_ID " +
            "JOIN FACULTY F ON F.FACULTY_ID = P.FACULTY_ID " +
            "WHERE UPPER(S.REG_NBR) = ?";

        try(PreparedStatement st = con.prepareStatement(sql))
        {
            st.setString(1, regNbr == null ? null : regNbr.toUpperCase());
            try(ResultSet rs = st.executeQuery())
            {
                return rs.next() && workingFacultyId != null &&  workingFacultyId.equals(rs.getString("FACULTY_ID"));
            }
        }catch(Exception oops)
        {
            throw new Exception(oops.toString(), oops);
        }
    }

    public boolean hasPrivileges(String regNbr, String webUser) throws Exception
    {
        String sql =
            "SELECT F.FACULTY_ID " +
            "FROM STUDENT S " +
            "JOIN PROGRAM P ON P.PROG_ID = S.PROG_ID " +
            "JOIN FACULTY F ON F.FACULTY_ID = P.FACULTY_ID " +
            "JOIN WEB_USERS_FACULTY WUF ON WUF.FACULTY_ID = F.FACULTY_ID " +
            "WHERE UPPER(S.REG_NBR) = ? " +
            "AND WUF.USER_NME = ?";

        try(PreparedStatement st = con.prepareStatement(sql))
        {
            st.setString(1, regNbr == null ? null : regNbr.toUpperCase());
            st.setString(2, webUser);
            try(ResultSet rs = st.executeQuery())
            {
                return rs.next();
            }
        }
    }

    public void setIpAddress(String ipAddress)
    {
        this.ipAddress = ipAddress;
    }

    public String getIpAddress()
    {
        return ipAddress;
    }

    public void setLoginDate(String loginDate)
    {
        this.loginDate = loginDate;
    }

    public String getLoginDate()
    {
        return loginDate;
    }

//    public void endClasses(LocalSession adminSession) throws SQLException
//    {
//        String sql =
//            "SELECT H.CLASS_ID " +
//            "FROM CLASS_HELD H, SLOT S " +
//            "WHERE H.SLOT_ID = S.SLOT_ID " +
//            "AND H.END_TIM IS NULL " +
//            "AND H.STATUS_IND = 'E' " +
//            "AND H.TCHR_ID = ? " +
//            "AND (" +
//            "CLASS_DTE < TO_CHAR(SYSDATE,'DD-MON-YYYY') " +
//            "OR (" +
//            "CLASS_DTE = TO_CHAR(SYSDATE,'DD-MON-YYYY') " +
//            "AND TO_CHAR(SYSDATE,'HH24MI') > NVL((" +
//            "SELECT END_TIME FROM ALTERNATE_SLOT_TIM " +
//            "WHERE SLOT_ID = S.SLOT_ID " +
//            "AND DAY_ID = (SELECT DAY_ID FROM DAY WHERE DAY_TXT = TRIM(TO_CHAR(SYSDATE,'DAY'))) " +
//            "AND TO_DATE(START_DTE,'DD-MM-YY') <= TO_DATE(SYSDATE,'DD-MM-YY') " +
//            "AND TO_DATE(END_DTE,'DD-MM-YY') >= TO_DATE(SYSDATE,'DD-MM-YY')" +
//            "), END_TIME)" +
//            ")" +
//            ")";
//
//        try(PreparedStatement st = con.prepareStatement(sql))
//        {
//            st.setInt(1, getTeacherId());
//            try(ResultSet rs = st.executeQuery())
//            {
//                AttendanceUtility attendanceUtility = new AttendanceUtility();
//                while(rs.next())
//                {
//                    String classId = rs.getString("CLASS_ID");
//                    attendanceUtility.endClass(true, classId, "T", adminSession);
//                    System.out.println("CLASS_ID " + classId + " of user " + user + " automatically ended on session expire.");
//                }
//            }
//        }catch(Exception oops)
//        {
//            System.out.println("Error in LocalSession.endClasses()::" + oops.getMessage());
//        }
//        System.out.println("EndAdvisorClass called");
//    }

    public void setTeacherId()
    {
        String sql =
            "SELECT T.TCHR_ID " +
            "FROM TEACHER T " +
            "JOIN WEB_USERS WU ON WU.TCHR_ID = T.TCHR_ID " +
            "WHERE WU.USER_NME = ?";

        try(PreparedStatement st = con.prepareStatement(sql))
        {
            st.setString(1, user);
            try(ResultSet rs = st.executeQuery())
            {
                if(rs.next()) teacherId = rs.getInt("TCHR_ID");
            }
        }catch(Exception oops)
        {
            System.out.println("LocalSession.setTeacherId()::" + oops.getMessage());
        }
    }

    public int getTeacherId()
    {
        return teacherId;
    }

    public String getWorkingFacultyId()
    {
        return workingFacultyId;
    }

    public void setWorkingFacultyId(String workingFaculty) throws SQLException
    {
        workingFacultyId = workingFaculty;
    }

    private void resetFacultyContext()
    {
        tchrId = -1;
        workingFaculty = "";
        workingFacultyId = "";
        campus = "";
        campusId = -1;
        uniId = -1;
    }

    private void rollbackQuietly()
    {
        if(con == null) return;
        try
        {
            con.rollback();
        }catch(SQLException oops)
        {
            System.out.println("LocalSession.rollbackQuietly()::" + oops.getMessage());
        }
    }
}
