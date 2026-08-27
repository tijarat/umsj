package com.ums.db;

import com.ums.functions.Functions;
import com.ums.packages.StudentContainer;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Date;
import javax.naming.NamingException;
import org.apache.tomcat.jdbc.pool.DataSource;
import org.apache.tomcat.jdbc.pool.PoolProperties;

public class Pool implements AutoCloseable
{
    private static final String VALIDATION_QUERY = "SELECT 1 FROM DUAL";
    private static final String DEFAULT_DB_USER = "ucp";
    private int increment = 5;
    private int initConn = 10;
    private int allowedMinutes = 15;
    private int inactiveMinutes = 5;
    private int allowedConnections = 200;
    private int allowedBusyMinutes = 2;
    public static String fromAddress = "webmaster@ucp.edu.pk";
    public static String smtpAddress = "mail.ucp.edu.pk";
    private String currentTerm = "";
    private String workingTerm = "";
    private boolean allowStdLogin = true;

    private DataSource ds;

    public Pool() throws ClassNotFoundException, SQLException, IOException, NamingException{this(createDataSource());}
    public Pool(DataSource dataSource)
    {
        if(dataSource == null) throw new IllegalArgumentException("DataSource cannot be null");
        ds = dataSource;
        log("Connection pool initialized successfully");
    }

    public DataSource getDs(){ return ds; }

    public void setDs(DataSource dataSource)
    {
        if(dataSource == null) throw new IllegalArgumentException("DataSource cannot be null");
        ds = dataSource;
    }

    public boolean isValid(String reg) throws SQLException
    {
        if(isBlank(reg)) return false;
        try(Connection con = getConnection())
        {
            return isValid(reg, con);
        }catch(SQLException e)
        {
            log("Database error in isValid(String): " + e.getMessage());
            return false;
        }
    }

    public boolean isValid(String reg, Connection con)
    {
        if(isBlank(reg) || con == null) return false;
        try
        {
            return exists(con, "SELECT 1 FROM UCP.STUDENT WHERE REG_NBR = ? AND ROWNUM = 1", reg.trim());
        }catch(SQLException e)
        {
            log("Database error in isValid(String, Connection): " + e.getMessage());
            return false;
        }
    }

    public boolean getAllowStdLogin() { return allowStdLogin; }
    public int getIncrement() { return increment; }
    public int getInitialCon() { return initConn; }
    public int getAllowedBusyMinutes() { return allowedBusyMinutes; }
    public int getAllowedMinutes() { return allowedMinutes; }
    public int getAllowedConnections() { return allowedConnections; }
    public int getInactiveMinutes() { return inactiveMinutes; }
    public String getWorkingTerm() { return workingTerm; }
    public int getTotalConnections() { return ds == null ? 0 : ds.getSize(); }
    public int getUsedConnections() { return ds == null ? 0 : ds.getActive(); }

    public void setWorkingTerm(String newVal) { workingTerm = value(newVal); }
    public void setAllowStdLogin(boolean newVal) { allowStdLogin = newVal; }
    public void setIncrement(int newVal) { increment = newVal; }
    public void setAllowedMinutes(int newVal) { allowedMinutes = newVal; }
    public void setInactiveMinutes(int newVal) { inactiveMinutes = newVal; }
    public void setAllowedBusyMinutes(int newVal) { allowedBusyMinutes = newVal; }

    public void setInitialCon(int newVal)
    {
        initConn = newVal;
        if(ds != null) ds.setInitialSize(newVal);
    }

    public void setAllowedConnections(int newVal)
    {
        allowedConnections = newVal;
        if(ds != null) ds.setMaxActive(newVal);
    }

    public boolean canTake56Level(StudentContainer studentDetail, Connection con)
    {
        if(studentDetail == null || con == null) return false;
        String sql =
            "SELECT PPC.VALUE " +
            "FROM PROB_CRITERIA PC " +
            "JOIN PROG_PROB_CRITERIA PPC ON PPC.PROB_CRITERIA_ID = PC.PROB_CRITERIA_ID " +
            "JOIN PROGRAM P ON P.PROG_ID = PPC.PROG_ID " +
            "WHERE P.PROG_ID = ? " +
            "AND PC.PROB_CERITERIA_NME = 'CAN56LEVEL_CGPA'";

        try
        {
            Double threshold = queryDouble(con, sql, studentDetail.majorId);
            return threshold == null || studentDetail.levelCgpa <= 0.0 || studentDetail.levelCgpa >= threshold;
        }catch(SQLException e)
        {
            log("Error in canTake56Level: " + e.getMessage());
            return false;
        }
    }

    public Connection getAdminConnection(String uid, String pass) throws ClassNotFoundException
    {
        try
        {
            String userName = isBlank(uid) ? ds.getPoolProperties().getUsername() : uid.trim();
            String password = isBlank(pass) ? ds.getPoolProperties().getPassword() : pass;
            Connection con = DriverManager.getConnection(ds.getUrl(), userName, password);
            con.setAutoCommit(false);
            return con;
        }catch(SQLException e)
        {
            log("Critical: Admin connection failed for user " + uid + ": " + e.getMessage());
            return null;
        }
    }

    public Connection getConnection() throws SQLException{ return ds.getConnection();}

    @Deprecated
    public String getCurrentTerm()
    {
        return "deprecated getCurrentTerm() function called";
    }

    public String getCurrentTerm(String facultyId, Connection con) throws Exception
    {
        if(isBlank(facultyId)) throw new Exception("Faculty ID is required");
        if(con == null) throw new Exception("Database connection is required");
        String term = queryString(con, "SELECT TERM_CDE FROM CURRENT_TERM WHERE FACULTY_ID = ?", facultyId);
        if(term == null)  throw new Exception("Current term not found for Faculty ID: " + facultyId);
        return term;
    }

    public String getFullValue(String val)
    {
        if(val == null) return "";
        return switch(val.trim().toUpperCase())
        {
            case "L" -> "Leave";
            case "A" -> "Absent";
            case "T" -> "Late";
            case "D" -> "Discipline";
            case "R" -> "Dress code";
            case "B" -> "Late Fee Fine By Bank";
            case "F" -> "Late Fee Fine";
            default -> "From Attendance Form-withdarw".equalsIgnoreCase(val)? "Excessive Absents" : val;
        };
    }

    public String getAdvisingTerm(String workingFacultyId) throws SQLException
    {
        if(isBlank(workingFacultyId)) return "Not Found";

        String sql =
            "SELECT TERM_CDE FROM UCP.TERM WHERE START_DTE = (" +
            "SELECT MAX(START_DTE) FROM UCP.TERM WHERE START_DTE > (" +
            "SELECT START_DTE FROM UCP.TERM WHERE TERM_CDE = (" +
            "SELECT TERM_CDE FROM UCP.CURRENT_TERM WHERE FACULTY_ID = ?)))";

        try(Connection con = getConnection())
        {
            String term = queryString(con, sql, workingFacultyId);
            return term == null ? "Not Found" : term;
        }catch(Exception e)
        {
            log("Error in getAdvisingTerm: " + e.getMessage());
            return "Not Found";
        }
    }

    public void returnConnection(Connection con) throws SQLException{ if(con != null && !con.isClosed()) con.close();}
    public void release(){close();}

    @Override
    public void close()
    {
        if(ds == null) return;
        try
        {
            ds.close();
        }catch(Exception e)
        {
            log("Error closing connection pool: " + e.getMessage());
        }
    }

    private void log(String msg){System.out.println(new Date() + "::ConnectionPool::" + msg); }

    public static Connection getOracleConnection() throws Exception
    {
        String url = Functions.getParameters("d");
        String userName = Functions.getParameters("dbu");
        String password = Functions.getParameters("dbp");

        if(isBlank(url) || isBlank(userName) || isBlank(password))  throw new Exception("Oracle connection properties are not configured.");
        try
        {
            Connection con = DriverManager.getConnection(url, userName, password);
            con.setAutoCommit(false);
            return con;
        }catch(SQLException e)
        {
            throw new Exception("Database connection failed: " + e.getMessage(), e);
        }
    }

    private static DataSource createDataSource()
    {
        String url = Functions.getParameters("DbUrl");
        String userName = Functions.getParameters("id");
        String password = Functions.getParameters("Developer");

        if(isBlank(userName)) userName = DEFAULT_DB_USER;
        if(isBlank(url)) throw new IllegalStateException("Database URL is not configured.");
        if(isBlank(password)) throw new IllegalStateException("Database password is not configured.");

        PoolProperties properties = new PoolProperties();
        properties.setDriverClassName("oracle.jdbc.OracleDriver");
        properties.setUrl(url);
        properties.setUsername(userName);
        properties.setPassword(password);
        properties.setMaxActive(200);
        properties.setInitialSize(10);
        properties.setMinIdle(10);
        properties.setMaxIdle(20);
        properties.setValidationQuery(VALIDATION_QUERY);
        properties.setTestOnBorrow(true);
        properties.setValidationInterval(30000);

        DataSource dataSource = new DataSource();
        dataSource.setPoolProperties(properties);
        return dataSource;
    }

    private static boolean exists(Connection con, String sql, Object... params) throws SQLException
    {
        try(PreparedStatement stmt = con.prepareStatement(sql))
        {
            bind(stmt, params);
            try(ResultSet rs = stmt.executeQuery())
            {
                return rs.next();
            }
        }
    }

    private static String queryString(Connection con, String sql, Object... params) throws SQLException
    {
        try(PreparedStatement stmt = con.prepareStatement(sql))
        {
            bind(stmt, params);

            try(ResultSet rs = stmt.executeQuery())
            {
                return rs.next() ? rs.getString(1) : null;
            }
        }
    }

    private static Double queryDouble(Connection con, String sql, Object... params) throws SQLException
    {
        try(PreparedStatement stmt = con.prepareStatement(sql))
        {
            bind(stmt, params);

            try(ResultSet rs = stmt.executeQuery())
            {
                if(!rs.next()) return null;
                double value = rs.getDouble(1);
                return rs.wasNull() ? null : value;
            }
        }
    }

    private static void bind(PreparedStatement stmt, Object... params) throws SQLException
    {
        if(params == null) return;
        for(int i = 0; i < params.length; i++)
            stmt.setObject(i + 1, params[i]);
    }

    private static String value(String text){return text == null ? "" : text; }
    private static boolean isBlank(String value){ return value == null || value.trim().isEmpty();}
}
