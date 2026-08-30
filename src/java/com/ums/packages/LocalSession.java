package com.ums.packages;

import com.ums.db.Pool;
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

    public LocalSession(){}

    public void start(Connection con, String pUser,String ipAddress, Container container) throws Exception
    {
        user = pUser;
        this.container = container;
        setWebCtx(con,ipAddress);
        setRights(con);
        setTeacherId(con);
    }

    public void setWebCtx(Connection con,String ipAddress) throws Exception 
    {
        try(CallableStatement cs = con.prepareCall("{call SET_WEB_CTX(?, ?)}"))
        {
            cs.setString(1, user);
            cs.setString(2, ipAddress);
            cs.execute();
        }

        try(CallableStatement cs = con.prepareCall("{call dbms_session.SET_IDENTIFIER(?)}"))
        {
            cs.setString(1, user);
            cs.execute();
        }
    }

    public void addUserSession(String ipAddress, Connection con) throws SQLException
    {
        this.ipAddress = ipAddress;
        try
        {
            con.setAutoCommit(false);
            String sql = "SELECT UMS.SEQ_USER_SESSION_ID.NEXTVAL FROM DUAL";
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
                "INSERT INTO UMS.USER_SESSION(USER_SESSION_ID, USER_NME, LOGIN_DTE, IP_ADDRESS) " +
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
            rollbackQuietly(con);
            System.out.println("Error in LocalSession.addUserSession(String ipAddress)::" + oops.getMessage());
        }
    }

    public void updateUserSession(Connection con) throws SQLException
    {
        String sql = "UPDATE UMS.USER_SESSION SET LOGOUT_DTE = SYSDATE WHERE USER_SESSION_ID = ?";
        boolean oldAutoCommit = con.getAutoCommit();

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
            rollbackQuietly(con);
            System.out.println("Error in LocalSession.updateUserSession()::" + oops.getMessage());
        }finally
        {
            con.setAutoCommit(oldAutoCommit);
        }
    }

    public void addLog(String statement, Connection con) throws SQLException
    {
        String sql =
            "INSERT INTO UMS.USER_SESSION_DETAIL " +
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
            rollbackQuietly(con);
            System.out.println("Error in LocalSession.addLog(String statement)::" + oops.getMessage());
        }
    }

    public String processLog(String processId, String processNme, String processDesc, String id, Connection con) throws Exception
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
            rollbackQuietly(con);
            System.out.println("Error in LocalSession.processLog()::" + oops.getMessage());
        }
        return id;
    }

    public void addLog(String statement, Statement addLogStmt) throws SQLException
    {
        if(addLogStmt == null) throw new SQLException("Statement cannot be null.");
        String sql =
            "INSERT INTO UMS.USER_SESSION_DETAIL " +
            "(USER_SESSION_DETAIL_ID, USER_SESSION_ID, USER_ACTION, ACTION_DTE) " +
            "VALUES(SEQ_USER_SESSION_DETAIL_ID.NEXTVAL, ?, ?, SYSDATE)";
        try(PreparedStatement st = addLogStmt.getConnection().prepareStatement(sql))
        {
            st.setInt(1, sessionId);
            st.setString(2, statement);
            st.executeUpdate();
        }
    }
    
    public void setRights(Connection con) throws Exception
    {
        rights.clear();
        String sql =
            "SELECT INITCAP(RIGHT_NME), USER_RIGHTS_ID " +
            "FROM UMS.USER_RIGHTS " +
            "WHERE USER_NME = ? " +
            "AND RIGHT_NME IN (SELECT RIGHT_NME FROM UMS.ACTIVE_RIGHTS) ";
        if(Functions.isSuperUser(user, con))
        {
            sql +=
                "UNION " +
                "SELECT INITCAP(RIGHT_NME), USER_RIGHTS_ID " +
                "FROM UMS.USER_RIGHTS " +
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

    @Override
    public void valueUnbound(HttpSessionBindingEvent event)
    {
        Connection con = null;
        Pool pool = null;
        try
        {
            pool = (Pool) event.getSession().getServletContext().getAttribute("pool");
            if(pool == null)
            {
                System.out.println("LocalSession.valueUnbound():: Pool not available");
                return;
            }
            con = pool.getConnection();
            if(sessionId > 0) updateUserSession(con);
        }catch(Exception e)
        {
            System.out.println("Error in valueUnbound()::" + e.getMessage());
        }finally
        {
            if(con != null) pool.close(con); 
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
    
    public List<String> getRights(){return Collections.unmodifiableList(rights);}    
    public boolean hasRightsOn(String privilege){return rights != null && rights.contains(privilege);}
    @Override
    public void valueBound(HttpSessionBindingEvent e) {}
    public String getWorkingFaculty(){return workingFaculty;}
    public String getCampus(){return campus;}
    public int getCampusId(){return campusId;}
    public int getUniId(){return uniId;}
    public void setIpAddress(String ipAddress){this.ipAddress = ipAddress;}
    public String getIpAddress(){return ipAddress;}
    public void setLoginDate(String loginDate){this.loginDate = loginDate;}
    public String getLoginDate(){return loginDate; }
    public int getTeacherId(){return teacherId;}
    public String getWorkingFacultyId(){return workingFacultyId;}
    public void setWorkingFacultyId(String workingFaculty) throws SQLException{workingFacultyId = workingFaculty;}

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

    public boolean hasPrivilegeOverStudent(String regNbr, String workingFacultyId, Connection con) throws Exception
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

    public boolean hasPrivileges(String regNbr, String webUser, Connection con) throws Exception
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

    public void setTeacherId(Connection con)
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



    private void resetFacultyContext()
    {
        tchrId = -1;
        workingFaculty = "";
        workingFacultyId = "";
        campus = "";
        campusId = -1;
        uniId = -1;
    }

    private void rollbackQuietly(Connection con)
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
