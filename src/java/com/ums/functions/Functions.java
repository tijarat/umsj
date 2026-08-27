package com.ums.functions;

import com.ums.packages.LocalSession;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URLDecoder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.SecureRandom;
import java.sql.*;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;

public class Functions 
{
    private static String path;
    private static volatile Properties properties;
    private String currentTerm = "";
    private String tentativeRegistrationTerm = "";
    private String workingTerm = "";
   
    public Functions() {}

    public static synchronized void setpath(String applicationPath, String separator) 
    {
        path = applicationPath;
        properties = null;
    }

    private static Properties getProperties() 
    {
        Properties current = properties;
        if (current == null) 
        {
            synchronized (Functions.class) 
            {
                current = properties;
                if (current == null) 
                {
                    current = loadProperties();
                    properties = current;
                }
            }
        }
        return current;
    }

    private static Properties loadProperties() 
    {
        Properties prop = new Properties();
        if (path == null || path.trim().isEmpty()) 
            throw new IllegalStateException("Functions.setpath() must be called before accessing db.PROPERTIES.");

        Path propertyFile = Path.of(path,"WEB-INF","db.PROPERTIES");
        try (InputStream input = Files.newInputStream(propertyFile)) 
        {
            prop.load(input);
        } catch (IOException e) 
        {
            throw new IllegalStateException("Unable to load properties file: " + propertyFile,e);
        }
        return prop;
    }

    public static String getParameters(String token) 
    {
        if (token == null) 
            return null;
        Properties prop = getProperties();
        return switch (token) 
        {
            case "d" -> prop.getProperty("DbUrl");
            case "p" -> prop.getProperty("Developer");
            case "dbu" -> prop.getProperty("dbuser");
            case "dbp" -> prop.getProperty("dbpassword");
            case "frmadd" -> prop.getProperty("fromaddress");
            case "smptadd" -> prop.getProperty("smtpaddress");
            case "onlneurl" -> prop.getProperty("onlineurl");
            case "stdmail" -> prop.getProperty("studentmail");
            case "uniname" -> prop.getProperty("uniname");
            case "unitel" -> prop.getProperty("unitel");
            case "uniem" -> prop.getProperty("uniemail");
            case "unihomeadd" -> prop.getProperty("unihomeadd");
            default -> prop.getProperty(token);
        };
    }

    public static String getProperty(String key) 
    {
        if (key == null || key.trim().isEmpty()) return null;
        return getProperties().getProperty(key);
    }
    
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    private static final List<String> INJECTION_BLOCKLIST = Arrays.asList(
        "union select", "--", "all_triggers", "all_tables", "all_tab_columns", "all_sequences",
        "or 1=1", "or 0=0", "execute", "exec ", "grant ", "alter ", "revoke", "@@", "/*", "*/",
        "all_users", "alter session", "alter  session", "union+all", "insert into", "<script", "<scrip",
        "< scri", "< https", "cript>", "onclick", "javascript", "</script>", "alert", "console.log",
        "iframe", ".cookie", "img src", "wget", "settimeout", "setinterval", "%27", "eval()",
        "xmlhttprequest", "base64", "%3c", "encodeuricomponent", "\\x27", "sleep(", "sleep ",
        "php://", "https://", "http://", "src="
    );

    private static void bind(PreparedStatement stmt, Object... params) throws SQLException
    {
        if(params == null) return;
        for(int i = 0; i < params.length; i++) stmt.setObject(i + 1, params[i]);
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

    private static Integer queryInteger(Connection con, String sql, Object... params) throws SQLException
    {
        try(PreparedStatement stmt = con.prepareStatement(sql))
        {
            bind(stmt, params);
            try(ResultSet rs = stmt.executeQuery())
            {
                if(!rs.next()) return null;
                int value = rs.getInt(1);
                return rs.wasNull() ? null : Integer.valueOf(value);
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
                return rs.wasNull() ? null : Double.valueOf(value);
            }
        }
    }

    private static void rollbackQuietly(Connection con)
    {
        if(con == null) return;
        try { con.rollback(); } catch(SQLException ignored) {}
    }

    private static boolean executeTransaction(Connection con, String[] sql, Object[][] params) throws SQLException
    {
        boolean oldAutoCommit = con.getAutoCommit();
        Savepoint savepoint = null;

        try
        {
            if(oldAutoCommit) con.setAutoCommit(false);
            else savepoint = con.setSavepoint();

            for(int i = 0; i < sql.length; i++)
            {
                try(PreparedStatement stmt = con.prepareStatement(sql[i]))
                {
                    bind(stmt, params[i]);
                    stmt.executeUpdate();
                }
            }

            if(oldAutoCommit) con.commit();
            return true;
        }
        catch(SQLException e)
        {
            if(oldAutoCommit) rollbackQuietly(con);
            else if(savepoint != null) con.rollback(savepoint);
            throw e;
        }
        finally
        {
            if(oldAutoCommit)
                try { con.setAutoCommit(true); } catch(SQLException ignored) {}
        }
    }

    private static String randomString(String chars, int length)
    {
        StringBuilder value = new StringBuilder(length);
        for(int i = 0; i < length; i++) value.append(randomChar(chars));
        return value.toString();
    }

    private static char randomChar(String chars)
    {
        return chars.charAt(SECURE_RANDOM.nextInt(chars.length()));
    }


    private static int intValue(Integer value)
    {
        return value == null ? 0 : value.intValue();
    }

    private static void throwFeeNotFound(Connection con, long courseId) throws Exception
    {
        String sql = "SELECT CREDIT_HRS, COURSE_CDE FROM UCP.COURSE WHERE COURSE_ID = ?";
        try(PreparedStatement stmt = con.prepareStatement(sql))
        {
            stmt.setLong(1, courseId);
            try(ResultSet rs = stmt.executeQuery())
            {
                if(rs.next())
                    throw new Exception("Fee for Credit Hour (" + rs.getString("CREDIT_HRS") + ") not found for Course (" + rs.getString("COURSE_CDE") + ") ~ Fee Not Found");
            }
        }
        throw new Exception("Fee not found for course ID " + courseId);
    }

    private static String getCurrentTeacherEvaluationId(String regNbr, Connection con, boolean excludeEvaluated) throws SQLException
    {
        String sql =
            "SELECT TE.TCHR_EVAL_ID FROM TEACHER_EVALUATION TE " +
            "WHERE TE.STATUS = 'C' " +
            "AND TE.FACULTY_ID = (SELECT P.FACULTY_ID FROM STUDENT S JOIN PROGRAM P ON P.PROG_ID = S.PROG_ID WHERE S.REG_NBR = ?) " +
            "AND EXISTS (SELECT 1 FROM REGISTRATION R WHERE R.REG_NBR = ? AND R.TERM_CDE = TE.TERM_CDE AND R.STATUS_TYP = 'Y') " +
            "AND NOT EXISTS (SELECT 1 FROM DISALLOW_EVALUATION D WHERE D.REG_NBR = ? AND D.TCHR_EVAL_ID = TE.TCHR_EVAL_ID) " +
            (excludeEvaluated ? "AND NOT EXISTS (SELECT 1 FROM EVALUATE E WHERE E.REG_NBR = ? AND E.TCHR_EVAL_ID = TE.TCHR_EVAL_ID) " : "") +
            "AND (TRUNC(SYSDATE) BETWEEN TRUNC(TE.START_DTE) AND TRUNC(TE.END_DTE) " +
            "OR EXISTS (SELECT 1 FROM ALLOW_EVALUATION A WHERE A.TCHR_EVAL_ID = TE.TCHR_EVAL_ID AND A.REG_NBR = ?)) " +
            "AND ROWNUM = 1";

        if(excludeEvaluated) return queryString(con, sql, regNbr, regNbr, regNbr, regNbr, regNbr);
        return queryString(con, sql, regNbr, regNbr, regNbr, regNbr);
    }

    
    public static boolean isStudentFeeDefaulter(String regNbr, Connection con) throws Exception
    {
        String sql =
            "SELECT 1 FROM DUAL WHERE EXISTS (" +
            "SELECT 1 FROM UCP.ACCOUNTS WHERE REG_NBR = ? AND PAID_DTE IS NULL) " +
            "OR EXISTS (SELECT 1 FROM UCP.INSTALLMENT WHERE REG_NBR = ? AND STATUS <> 'PAID' AND PAIDDATE IS NULL)";
        return exists(con, sql, regNbr, regNbr);
    }
    
    public static boolean isStdFailedFinalExam(String regNbr, String sectionId, Connection con) throws Exception
    {
        String sql =
            "SELECT 1 FROM UCP.EXAM_RESULT ER " +
            "JOIN UCP.EXAM E ON E.EXAM_ID = ER.EXAM_ID " +
            "JOIN UCP.EXAM_TYPE ET ON ET.EXAM_TYP_ID = E.EXAM_TYP_ID " +
            "WHERE ER.REG_NBR = ? " +
            "AND NVL(E.EXCLUDE_IND, 'N') <> 'Y' " +
            "AND UPPER(ET.EXAM_TYP_NME) = 'FINAL TERM' " +
            "AND ER.OBT_MARKS_NBR / NULLIF(E.MARKS_NBR, 0) < 0.5 " +
            "AND E.SECTION_ID = ?";
        return exists(con, sql, regNbr, sectionId);
    }
    
    
    public static Map getAccountsDetail(String regNbr, String termCde, Connection con) throws Exception
    {
        Map<String, Object> map = new HashMap<String, Object>();
        StringBuilder msg = new StringBuilder();

        String prevTerm = queryString(con,
            "SELECT TERM_CDE FROM TERM WHERE START_DTE = (SELECT MAX(START_DTE) FROM TERM WHERE START_DTE < " +
            "(SELECT START_DTE FROM TERM WHERE TERM_CDE = ?))", termCde);
        if(prevTerm == null) prevTerm = "";
        map.put("Previous Term", prevTerm);

        String stdPrevTerm = queryString(con,
            "SELECT TERM_CDE FROM TERM WHERE START_DTE = (SELECT MAX(START_DTE) FROM TERM WHERE START_DTE < " +
            "(SELECT START_DTE FROM TERM WHERE TERM_CDE = ?) AND TERM_CDE IN " +
            "(SELECT TERM_CDE FROM REGISTRATION WHERE REG_NBR = ?))", termCde, regNbr);
        if(stdPrevTerm == null) stdPrevTerm = "";
        map.put("Student Previous Term", stdPrevTerm);

        String regTerm = "", stdNme = "";
        int batchNbr = 0, perCourseAmt = 0;
        String batchSql =
            "SELECT B.TERM_CDE, B.BATCH_NBR, RS.PER_COURSE_AMT, S.STUDENT_NME " +
            "FROM BATCH B, REGISTRATION_SCHEDULE RS, STUDENT S WHERE B.BATCH_ID = RS.BATCH_ID " +
            "AND S.PROG_ID = B.PROG_ID AND S.REG_NBR = ? AND B.TERM_CDE = SUBSTR(S.REG_NBR, 3, 3)";
        try(PreparedStatement stmt = con.prepareStatement(batchSql))
        {
            stmt.setString(1, regNbr);
            try(ResultSet rs = stmt.executeQuery())
            {
                if(rs.next())
                {
                    regTerm = rs.getString("TERM_CDE");
                    batchNbr = rs.getInt("BATCH_NBR");
                    perCourseAmt = rs.getInt("PER_COURSE_AMT");
                    stdNme = rs.getString("STUDENT_NME");
                }
            }
        }
        map.put("Registration Term", regTerm);
        map.put("Batch Number", batchNbr);
        map.put("Per Course Fee", perCourseAmt);
        map.put("Student Name", stdNme);

        int regCourses = 0, repCourses = 0, spCourses = 0;
        String accountCourseSql =
            "SELECT NVL(COURSE_CNT,0), NVL(REP_COURSE_CNT,0), NVL(SPEC_COURSE_CNT,0) FROM ACCOUNTS " +
            "WHERE REG_NBR = ? AND TERM_CDE = ? AND ACCT_ID = (SELECT MAX(ACCT_ID) FROM ACCOUNTS WHERE REG_NBR = ? AND TERM_CDE = ?)";
        try(PreparedStatement stmt = con.prepareStatement(accountCourseSql))
        {
            bind(stmt, regNbr, termCde, regNbr, termCde);
            try(ResultSet rs = stmt.executeQuery())
            {
                if(rs.next())
                {
                    regCourses = rs.getInt(1);
                    repCourses = rs.getInt(2);
                    spCourses = rs.getInt(3);
                }
            }
        }

        int actualRegular = intValue(queryInteger(con,
            "SELECT COUNT(CTYPE) FROM REGISTRATION_REF WHERE REG_NBR = ? AND TERM_CDE = ? AND CTYPE = 'R'", regNbr, termCde));
        int actualRepeat = intValue(queryInteger(con,
            "SELECT COUNT(CTYPE) FROM REGISTRATION_REF WHERE REG_NBR = ? AND TERM_CDE = ? AND CTYPE = 'RR'", regNbr, termCde));
        int actualSpecial = intValue(queryInteger(con,
            "SELECT COUNT(CTYPE) FROM REGISTRATION_REF WHERE REG_NBR = ? AND TERM_CDE = ? AND CTYPE IN ('S','RS')", regNbr, termCde));
        int totalCourses = intValue(queryInteger(con,
            "SELECT COUNT(*) FROM REGISTRATION_REF WHERE REG_NBR = ? AND TERM_CDE = ?", regNbr, termCde));

        if(actualRegular != regCourses) msg.append("Regular Courses in Registration=").append(actualRegular).append(", accounts=").append(regCourses).append("<br />");
        if(actualRepeat != repCourses) msg.append("Repeat Regular Courses in Registration=").append(actualRepeat).append(", accounts=").append(repCourses).append("<br />");
        if(actualSpecial != spCourses) msg.append("Special Courses in Registration=").append(actualSpecial).append(", accounts=").append(spCourses).append("<br />");
        if(totalCourses != regCourses + repCourses + spCourses)
            msg.append("No of Courses in Registration Table and Accounts Table does not Match. (Registered Courses =")
               .append(totalCourses).append("),(Accounts Courses = ").append(regCourses + repCourses + spCourses).append(")<br />");

        map.put("Regular Courses", regCourses);
        map.put("Repeat Courses", repCourses);
        map.put("Special Courses", spCourses);
        map.put("Total Courses", totalCourses);

        int odAmt = intValue(queryInteger(con, "SELECT AMOUNT FROM EXCESSPAID WHERE REG = ? AND TERM = ?", regNbr, termCde));
        Integer previousODValue = queryInteger(con, "SELECT AMOUNT FROM EXCESSPAID WHERE REG = ? AND TERM = ?", regNbr, stdPrevTerm);
        if(previousODValue == null)
            previousODValue = queryInteger(con,
                "SELECT AMOUNT FROM EXCESSPAID WHERE REG IN (SELECT OLD_REG FROM UCP.STD_TRANSFER WHERE NEW_REG = ?) AND TERM = ?",
                regNbr, stdPrevTerm);
        int previousOD = intValue(previousODValue);

        int paidAmt = intValue(queryInteger(con,
            "SELECT NVL(SUM(PAID_AMT - NVL(CONCESSION,0)),0) FROM ACCOUNTS WHERE REG_NBR = ? AND TERM_CDE = ? AND PAID_DTE IS NOT NULL",
            regNbr, termCde));
        map.put("Paid Amount", paidAmt);

        if(exists(con, "SELECT 1 FROM INSTALLMENT WHERE REG_NBR = ? AND TERM_CDE = ?", regNbr, termCde))
        {
            int installmentPaid = intValue(queryInteger(con,
                "SELECT NVL(SUM(AMOUNT),0) FROM INSTALLMENT WHERE REG_NBR = ? AND TERM_CDE = ? AND PAIDDATE IS NOT NULL", regNbr, termCde));
            if(paidAmt != installmentPaid)
                msg.append("Paid amount difference. Accounts = ").append(paidAmt).append(", Installment = ").append(installmentPaid).append("<br />");
        }

        String dueSql =
            "SELECT NVL(R.DUE_AFTER_DISCOUNT,0) + NVL(W.DUE_AFTER_DISCOUNT,0) - NVL(A.CONCESSION,0) FROM " +
            "(SELECT NVL(SUM(FEE_AMT),0) DUE_AFTER_DISCOUNT FROM REGISTRATION WHERE REG_NBR = ? AND TERM_CDE = ?) R, " +
            "(SELECT NVL(SUM(FEE_AMT),0) DUE_AFTER_DISCOUNT FROM WITHDRAW WHERE REG_NBR = ? AND TERM_CDE = ?) W, " +
            "(SELECT NVL(SUM(CONCESSION),0) CONCESSION FROM ACCOUNTS WHERE REG_NBR = ? AND TERM_CDE = ?) A";
        int dueAmt = intValue(queryInteger(con, dueSql, regNbr, termCde, regNbr, termCde, regNbr, termCde));

        int admissionFee = 0;
        if(isNewStudent(regNbr, termCde))
            admissionFee = intValue(queryInteger(con,
                "SELECT NVL(OTHER_FEE_AMT,0) FROM ACCOUNTS WHERE REG_NBR = ? AND TERM_CDE = ? AND EVENT_NBR = 1", regNbr, termCde));
        dueAmt += admissionFee;

        map.put("Admission Fee", admissionFee);
        map.put("Due Amount", dueAmt);
        map.put("Remaining Amount", dueAmt - paidAmt - odAmt);

        int prevPaidAmt = intValue(queryInteger(con,
            "SELECT NVL(SUM(PAID_AMT),0) - NVL(SUM(CONCESSION),0) FROM ACCOUNTS WHERE REG_NBR = ? AND TERM_CDE = ? AND PAID_DTE IS NOT NULL",
            regNbr, stdPrevTerm));
        map.put("Previous Term Paid Amount", prevPaidAmt);

        if(exists(con, "SELECT 1 FROM INSTALLMENT WHERE REG_NBR = ? AND TERM_CDE = ?", regNbr, stdPrevTerm))
        {
            int installmentPaid = intValue(queryInteger(con,
                "SELECT NVL(SUM(AMOUNT),0) FROM INSTALLMENT WHERE REG_NBR = ? AND TERM_CDE = ? AND PAIDDATE IS NOT NULL", regNbr, stdPrevTerm));
            if(prevPaidAmt != installmentPaid)
                msg.append("Previous Term Paid amount difference. Accounts = ").append(prevPaidAmt)
                   .append(", Installment = ").append(installmentPaid).append("<br />");
        }

        String prevDueSql =
            "SELECT NVL(R.DUE_AFTER_DISCOUNT,0) + NVL(W.DUE_AFTER_DISCOUNT,0) + NVL(AD.NET_AMOUNT,0) - NVL(A.CONCESSION,0) FROM " +
            "(SELECT NVL(SUM(FEE_AMT),0) DUE_AFTER_DISCOUNT FROM REGISTRATION WHERE REG_NBR = ? AND TERM_CDE = ?) R, " +
            "(SELECT NVL(SUM(FEE_AMT),0) DUE_AFTER_DISCOUNT FROM WITHDRAW WHERE REG_NBR = ? AND TERM_CDE = ?) W, " +
            "(SELECT NVL(SUM(CONCESSION),0) CONCESSION FROM ACCOUNTS WHERE REG_NBR = ? AND TERM_CDE = ?) A, " +
            "(SELECT CASE WHEN SUBSTR(S.REG_NBR,3,3) = ? THEN RS.ADMIN_FEE_AMT - (RS.ADMIN_FEE_AMT * (NVL(DT.ADPERCENTS,0) / 100)) ELSE 0 END NET_AMOUNT " +
            "FROM UCP.STUDENT S JOIN UCP.PROGRAM P ON S.PROG_ID = P.PROG_ID JOIN UCP.BATCH B ON P.PROG_ID = B.PROG_ID " +
            "JOIN UCP.REGISTRATION_SCHEDULE RS ON B.BATCH_ID = RS.BATCH_ID AND B.TERM_CDE = RS.TERM_CDE " +
            "LEFT JOIN UCP.DISCOUNTS D ON S.REG_NBR = D.REG_NBR AND D.TERM_CDE = ? " +
            "LEFT JOIN UCP.DISCOUNT_TYPE DT ON D.DISC_TYPE_ID = DT.DISCID " +
            "WHERE S.REG_NBR = ? AND SUBSTR(S.REG_NBR,3,3) = B.TERM_CDE) AD";
        int prevDueAmt = intValue(queryInteger(con, prevDueSql,
            regNbr, stdPrevTerm, regNbr, stdPrevTerm, regNbr, stdPrevTerm,
            stdPrevTerm, stdPrevTerm, regNbr));

        map.put("Previous Term Due Amount", prevDueAmt);
        map.put("Previous Term Remaining Amount", prevDueAmt - prevPaidAmt - previousOD);
        map.put("message", msg.toString());
        return map;
    }

    public static int getCreditHours(String courseCode, String term, Connection con) throws Exception
    {
        String sql = "SELECT CREDIT_HRS FROM UCP.COURSE WHERE UPPER(COURSE_CDE) = ? AND TERM_CDE = ?";
        Integer creditHour = queryInteger(con, sql, courseCode == null ? null : courseCode.toUpperCase(), term);
        if(creditHour == null) throw new Exception("Credit hours not found against course '" + courseCode + "' in term '" + term + "'");
        return creditHour;
    }

    public static String ifBlocked(Connection con, String userName) throws Exception
    {
        String sql = "SELECT MESSAGE FROM UCP.USER_BLOCK_LIST WHERE UPPER(USER_NME) = ?";
        String message = queryString(con, sql, userName == null ? null : userName.toUpperCase());
        return message == null ? "Blocked" : message;
    }

    public static List studentGrades(String regNbr, String termCode, Connection con) throws Exception
    {
        String sql =
            "SELECT G.COURSEID, C.COURSE_NME, G.GRADE " +
            "FROM UCP.TERM T, UCP.COURSE C, ADMINISTRATOR.TRANSCRIPT G " +
            "WHERE G.TERM = T.TERM_CDE " +
            "AND C.COURSE_CDE = G.COURSEID " +
            "AND G.REG = ? " +
            "AND T.TERM_CDE = ? " +
            "AND G.TERM = C.TERM " +
            "AND SUBSTR(G.STATUS, 1, 1) = 'U' " +
            "ORDER BY T.START_DTE";

        List<Map<String, String>> result = new ArrayList<Map<String, String>>();
        try(PreparedStatement stmt = con.prepareStatement(sql))
        {
            bind(stmt, regNbr, termCode);
            try(ResultSet rs = stmt.executeQuery())
            {
                ResultSetMetaData meta = rs.getMetaData();
                int columnCount = meta.getColumnCount();
                while(rs.next())
                {
                    Map<String, String> row = new HashMap<String, String>();
                    for(int i = 1; i <= columnCount; i++) row.put(meta.getColumnName(i), rs.getString(i));
                    result.add(row);
                }
            }
        }
        return result;
    }

    public static int getCreditHours(int sectionId, Connection con) throws Exception
    {
        String sql = "SELECT C.CREDIT_HRS FROM UCP.COURSE C JOIN UCP.SECTION S ON S.COURSE_ID = C.COURSE_ID WHERE S.SECTION_ID = ?";
        Integer creditHour = queryInteger(con, sql, sectionId);
        if(creditHour == null) throw new Exception("Credit hours not found against SectionId " + sectionId);
        return creditHour;
    }

    public static boolean validateIP(String ip, int placeId, Connection con) throws Exception
    {
        return exists(con, "SELECT 1 FROM UCP.PLACE_IP WHERE IP_ADDRESS = ? AND PLACE_ID = ?", ip, placeId);
    }

    public static boolean validateIP(String ip, Connection con) throws Exception
    {
        return exists(con, "SELECT 1 FROM UCP.PLACE_IP WHERE IP_ADDRESS = ?", ip);
    }

    public static String getEnviornmentValue(String var_nme, Connection con) throws Exception
    {
        String value = queryString(con, "SELECT VAR_VAL FROM ENV_VARIABLE WHERE VAR_NME = ? AND FACULTY_ID IS NULL", var_nme);
        return value == null ? "" : value;
    }
    public static String getEnviornmentValue(Connection con)
    {
        try
        {
            String value = queryString(con, "SELECT VAR_VAL FROM ENV_VARIABLE WHERE VAR_NME = 'Enable PIN Code'");
            return value == null ? "" : value;
        }
        catch(Exception e)
        {
            System.out.println(e.toString());
            return "";
        }
    }
    public static int setEnviornmentValue(String var_nme, String newVal, Connection con)
    {
        String sql = "UPDATE ENV_VARIABLE SET VAR_VAL = ? WHERE VAR_NME = ?";
        try(PreparedStatement stmt = con.prepareStatement(sql))
        {
            bind(stmt, newVal, var_nme);
            return stmt.executeUpdate();
        }
        catch(Exception e)
        {
            System.out.println(e.toString());
            return 0;
        }
    }

    public static String getEnviornmentValue(String var_nme, String facId, Connection con) throws Exception
    {
        String value = null;
        if(facId != null && !facId.trim().isEmpty())
            value = queryString(con, "SELECT VAR_VAL FROM ENV_VARIABLE WHERE VAR_NME = ? AND FACULTY_ID = ?", var_nme, facId);

        if(value == null || value.trim().isEmpty())
            value = queryString(con, "SELECT VAR_VAL FROM ENV_VARIABLE WHERE VAR_NME = ? AND FACULTY_ID IS NULL", var_nme);

        return value == null ? "" : value;
    }

    public static int setEnviornmentValue(String var_nme, String fac_abr, String newVal, Connection con)
    {
        String sql =
            "UPDATE ENV_VARIABLE SET VAR_VAL = ? WHERE VAR_NME = ? " +
            "AND FACULTY_ID = (SELECT FACULTY_ID FROM FACULTY WHERE FACULTY_ABBREV = ?)";
        try(PreparedStatement stmt = con.prepareStatement(sql))
        {
            bind(stmt, newVal, var_nme, fac_abr);
            return stmt.executeUpdate();
        }
        catch(Exception e)
        {
            System.out.println(e.toString());
            return 0;
        }
    }

    public static String getFaculty(String regNbr, Connection con) throws SQLException
    {
        String sql =
            "SELECT F.FACULTY_ID FROM STUDENT S " +
            "JOIN PROGRAM P ON P.PROG_ID = S.PROG_ID " +
            "JOIN FACULTY F ON F.FACULTY_ID = P.FACULTY_ID " +
            "WHERE S.REG_NBR = ?";
        String value = queryString(con, sql, regNbr);
        return value == null ? "" : value;
    }

    public static String getCurrentTchrEvalId(String getRegNbr, Connection con) throws Exception
    {
        return getCurrentTeacherEvaluationId(getRegNbr, con, false);
    }

    public static String getCurrentTchrEvalIdWithEvaluated(String getRegNbr, Connection con) throws Exception
    {
        return getCurrentTeacherEvaluationId(getRegNbr, con, true);
    }

    public static boolean isUserAllowedProcess(Connection con, String processNme, String userNme)
    {
        String sql =
            "SELECT 1 FROM PROCESSES P JOIN PROCESS_RIGHTS PR ON PR.PROCESS_ID = P.PROCESS_ID " +
            "WHERE UPPER(P.PROCESS_NME) = ? AND UPPER(PR.USER_NME) = ?";
        try
        {
            return exists(con, sql,
                processNme == null ? null : processNme.toUpperCase(),
                userNme == null ? null : userNme.toUpperCase());
        }
        catch(Exception e)
        {
            return false;
        }
    }
  
    public static List getGradeCorrectionTerm(Connection con, String faculty, String courseCode, String userName) throws Exception
    {
        String sql =
            "SELECT NVL(TERM_CDE, '-1') FROM UCP.TERM WHERE END_DTE = (" +
            "SELECT MAX(T.END_DTE) FROM TERM T, ADMINISTRATOR.GRADES_ENTRY GE, UCP.STUDENT S, ADMINISTRATOR.PROGRAM P, UCP.PROGRAM PR, UCP.FACULTY F " +
            "WHERE T.TERM_CDE = GE.TERM AND GE.REG = S.REG_NBR AND S.PROG_CDE = P.MAJOR AND P.MAJOR = PR.PROG_CDE " +
            "AND F.FACULTY_ABBREV = ? AND F.FACULTY_ID = PR.FACULTY_ID) " +
            "UNION SELECT T.TERM_CDE FROM UCP.TERM T, UCP.GRADE_CORR_TERM_ALLOCATION UTA, UCP.FACULTY F " +
            "WHERE T.TERM_CDE = UTA.TERM_CDE AND UTA.FRM_DTE <= SYSDATE AND UTA.TO_DTE >= SYSDATE " +
            "AND UPPER(UTA.USER_NME) = UPPER(?) AND UTA.FACULTY_ID = F.FACULTY_ID " +
            "AND UTA.FACULTY_ID = (SELECT FACULTY_ID FROM FACULTY WHERE FACULTY_ABBREV = ?) AND UTA.COURSE_CODE = ? " +
            "UNION SELECT T.TERM_CDE FROM UCP.TERM T, UCP.GRADE_CORR_TERM_ALLOCATION UTA, UCP.FACULTY F " +
            "WHERE T.TERM_CDE = UTA.TERM_CDE AND UTA.FRM_DTE IS NULL AND UTA.TO_DTE IS NULL " +
            "AND UPPER(UTA.USER_NME) = UPPER(?) AND UTA.FACULTY_ID = F.FACULTY_ID " +
            "AND UTA.FACULTY_ID = (SELECT FACULTY_ID FROM FACULTY WHERE FACULTY_ABBREV = ?) AND UTA.COURSE_CODE = ?";

        List<String> terms = new ArrayList<String>();
        try(PreparedStatement stmt = con.prepareStatement(sql))
        {
            bind(stmt, faculty, userName, faculty, courseCode, userName, faculty, courseCode);
            try(ResultSet rs = stmt.executeQuery())
            {
                while(rs.next()) terms.add(rs.getString(1));
            }
        }
        return terms;
    }

    
    public static boolean allowGradeCorrection(Connection con, String faculty, String gradeTerm, String grade, String userName, String courseCode) throws Exception
    {
        if(isUserAllowedProcess(con, "AllowGradeCorrectionAnyTerm", userName)) return true;
        List gradeCorrectionTerm = getGradeCorrectionTerm(con, faculty, courseCode, userName);
        return !grade.equalsIgnoreCase("W") && !grade.startsWith("(") && gradeCorrectionTerm.contains(gradeTerm);
    }

    public static int getCourseCredits(Connection con, String courseCode, String term) throws Exception
    {
        Integer credit = queryInteger(con, "SELECT CREDIT_HRS FROM COURSE WHERE COURSE_CDE = ? AND TERM_CDE = ?", courseCode, term);
        if(credit == null) throw new Exception("Course " + courseCode + " not found in term " + term);
        return credit;
    }

    public static boolean bracketPolicyExceeded(Connection con, String regNbr, String courseCode, String term) throws Exception
    {
        Integer count = queryInteger(con,
            "SELECT COUNT(*) FROM GRADES G, COURSE C, TERM T " +
            "WHERE G.REG = ? AND G.COURSEID = C.COURSE_CDE AND G.TERM = C.TERM_CDE " +
            "AND G.GRADE LIKE '%(%)%' AND G.TERM = T.TERM_CDE", regNbr);
        if(count == null) throw new Exception("Student record not found");
        return count + 1 <= 6;
    }

    public static boolean isBracketPolicyExceeded(Connection con, String regNbr) throws Exception
    {
        String query =
            "SELECT COUNT(*) BRACKET_CNT FROM GRADES G, COURSE C " +
            "WHERE G.REG = ? AND G.COURSEID = C.COURSE_CDE AND G.TERM = C.TERM_CDE AND G.GRADE LIKE '(%)'";
        try
        {
            Integer count = queryInteger(con, query, regNbr);
            return count == null || count + 1 > 6;
        }
        catch(Exception e)
        {
            System.out.println(e.getMessage());
            return false;
        }
    }
    
    public static boolean isFeeDefaulter(Connection con, String regNbr, String term) throws Exception
    {
        String sql =
            "SELECT 1 FROM ADMINISTRATOR.INSTALLMENT WHERE TERM = ? AND STATUS <> 'PAID' " +
            "AND PAIDDATE IS NULL AND REG = ? AND DUEDATE < SYSDATE";
        return exists(con, sql, term, regNbr);
    }

    public static String sendSMS(Connection con, String mobileNbr, String smsMsg) throws Exception
    {
        String returnVal = "";
        System.out.println("****Sending SMS [" + smsMsg + "] on [" + mobileNbr + "] at [" + new java.util.Date() + "]");
        try(PreparedStatement stmt = con.prepareStatement("SELECT SENDSMS(?, ?) FROM DUAL"))
        {
            bind(stmt, mobileNbr, smsMsg);
            try(ResultSet rs = stmt.executeQuery())
            {
                returnVal = rs.next() ? rs.getString(1) : "SMS sending failed";
            }
        }
        catch(Exception e)
        {
            System.out.println(e.toString());
        }
        System.out.println("******" + returnVal);
        return returnVal;
    }

    public static String sendSMS(Connection con, String cellNbr, String smsMsg, String smsType, LocalSession session) throws Exception
    {
        String sql =
            "INSERT INTO BULK_SMS(BULK_SMS_ID, MOBILE_NBR, SMS_MSG, STATUS_IND, TMS, USER_NME, SMS_TYP) " +
            "VALUES(SEQ_BULK_SMS_ID.NEXTVAL, ?, ?, 'P', SYSDATE, ?, ?)";
        smsMsg = smsMsg == null ? "" : smsMsg.replace('\'', '`');
        smsType = smsType == null ? "" : smsType.toUpperCase();
        System.out.println("****Sending SMS [" + smsMsg + "] on [" + cellNbr + "] at [" + new java.util.Date() + "]");

        boolean oldAutoCommit = con.getAutoCommit();
        try(PreparedStatement stmt = con.prepareStatement(sql); Statement logStmt = con.createStatement())
        {
            con.setAutoCommit(false);
            bind(stmt, cellNbr, smsMsg, session.user, smsType);
            int rows = stmt.executeUpdate();
            session.addLog(
                "INSERT INTO BULK_SMS(BULK_SMS_ID, MOBILE_NBR, SMS_MSG, STATUS_IND, TMS, USER_NME,SMS_TYP) VALUES(SEQ_BULK_SMS_ID.NEXTVAL," +
                cellNbr + "," + smsMsg + ",P,SYSDATE," + session.user + "," + smsType + ")",
                logStmt);
            con.commit();
            return rows > 0 ? "SUCCESS" : "";
        }
        catch(Exception e)
        {
            rollbackQuietly(con);
            System.out.println(e.toString());
            return "";
        }
        finally
        {
            try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
        }
    }
    
    public static String rand(int seed)
    {
        if(seed <= 0) return "";
        String chars = "ABCDEFGHIJKLMNPQRSTUVWXYZabcdefghijklmnpqrstuvwxyz123456789";
        return randomString(chars, seed);
    }
    
    public static String getPassword(int length)
    {
        if(length < 6) length = 6;
        return randomString("abcdefghjkmnpqrstuvwxyz23456789", length);
    }
    
    
    public static String generateRegNbr(int opId, Connection con) throws SQLException
    {
        String detailSql =
            "SELECT O.TERM_CDE, U.UNI_CDE, P.PROG_ABBR, C.CMP_ID " +
            "FROM OFFERED_PROGRAM O, PROGRAM P, CAMPUS C, UCP.UNIVERSITY U, FACULTY F " +
            "WHERE P.PROG_ID = O.PROG_ID AND F.FACULTY_ID = P.FACULTY_ID AND U.UNI_ID = C.UNI_ID " +
            "AND C.CMP_ID = F.CMP_ID AND O.OP_ID = ?";

        String prog = null, cmpId = null, uniCde = null, batch = null;
        try(PreparedStatement stmt = con.prepareStatement(detailSql))
        {
            stmt.setInt(1, opId);
            try(ResultSet rs = stmt.executeQuery())
            {
                if(rs.next())
                {
                    prog = rs.getString("PROG_ABBR");
                    cmpId = rs.getString("CMP_ID");
                    uniCde = rs.getString("UNI_CDE");
                    batch = rs.getString("TERM_CDE");
                }
            }
        }

        if(prog == null || cmpId == null || uniCde == null || batch == null) return "";

        String regSql =
            "SELECT A.REGSTR || NVL(B.REGNBR, '001') REGNBR FROM " +
            "(SELECT DISTINCT C.CMP_PREFIX || OP.TERM_CDE || U.UNI_CDE || P.PROG_ABBR REGSTR " +
            "FROM PROGRAM P, FACULTY F, CAMPUS C, OFFERED_PROGRAM OP, UCP.UNIVERSITY U " +
            "WHERE U.UNI_ID = C.UNI_ID AND OP.PROG_ID = P.PROG_ID AND P.FACULTY_ID = F.FACULTY_ID " +
            "AND F.CMP_ID = C.CMP_ID AND P.PROG_ABBR = ? AND OP.TERM_CDE = ? AND C.CMP_ID = ?) A, " +
            "(SELECT LPAD(MAX(TO_NUMBER(SUBSTR(REG_NBR, LENGTH(REG_NBR)-2, LENGTH(REG_NBR)))) + 1, 3, '0') REGNBR " +
            "FROM STUDENT S WHERE REG_NBR LIKE ? AND REG_NBR LIKE '%' || " +
            "(SELECT CMP_PREFIX FROM CAMPUS WHERE CMP_ID = ?) || ? || ? || ? || '%') B";

        try(PreparedStatement stmt = con.prepareStatement(regSql))
        {
            bind(stmt, prog, batch, cmpId, "%" + batch + "%", cmpId, batch, uniCde, prog);
            try(ResultSet rs = stmt.executeQuery())
            {
                return rs.next() ? rs.getString("REGNBR") : "";
            }
        }
    }

    public static String passwordExpireStatus(Connection con, String userName) throws Exception
    {
        String notificationPeriod = getEnviornmentValue("Passwords Expiry Warning Period", con);
        int days = 0;
        try { days = Integer.parseInt(notificationPeriod); } catch(Exception ignored) {}

        String sql =
            "SELECT CASE " +
            "WHEN TRUNC(TO_DATE(EXP_DTE,'DD-MM-YYYY')) - TRUNC(SYSDATE) BETWEEN 1 AND ? THEN 'WARNING' " +
            "WHEN TRUNC(TO_DATE(EXP_DTE,'DD-MM-YYYY')) <= TRUNC(SYSDATE) THEN 'EXPIRED' " +
            "WHEN TRUNC(TO_DATE(EXP_DTE,'DD-MM-YYYY')) > TRUNC(SYSDATE) THEN 'NOT EXPIRED' END RESULT " +
            "FROM WEB_USERS WHERE USER_NME = ?";
        String status = queryString(con, sql, days, userName);
        return status == null ? "" : status;
    }

    public static String passwordExpireRemaningDays(Connection con, String userName) throws Exception
    {
        String days = queryString(con,
            "SELECT TRUNC(TO_DATE(EXP_DTE,'DD-MM-YYYY')) - TRUNC(SYSDATE) DAYS FROM WEB_USERS WHERE USER_NME = ?", userName);
        return days == null ? "" : days;
    }

    public static byte[] getImage(Connection con, String regNbr)
    {
        String sql = "SELECT PHOTO_PIC FROM ADMINISTRATOR.STUDENT_PICTURE WHERE REG = ?";
        try(PreparedStatement stmt = con.prepareStatement(sql))
        {
            stmt.setString(1, regNbr);
            try(ResultSet rs = stmt.executeQuery())
            {
                return rs.next() ? rs.getBytes("PHOTO_PIC") : null;
            }
        }
        catch(SQLException e)
        {
            System.out.println("Error while trying to fetch picture in StudentDetail: " + e.getMessage());
            return null;
        }
    }

    public static String getFullValue(String val)
    {
        if(val == null) return null;
        switch(val.toUpperCase())
        {
            case "L": return "Leave";
            case "A": return "Absent";
            case "T": return "Late";
            case "D": return "Discipline";
            case "R": return "Dress code";
            case "B": return "Late Fee Fine By Bank";
            case "F": return "Late Fee Fine";
            default:
                return "From Attendance Form-withdarw".equalsIgnoreCase(val) ? "Excessive Absents" : val;
        }
    }

    public static boolean classTimeOver(String classId, Connection con)
    {
        String sql =
            "SELECT COUNT(*) FROM CLASS_HELD H, SLOT S WHERE H.SLOT_ID = S.SLOT_ID " +
            "AND CLASS_ID = ? AND H.END_TIM IS NULL AND H.STATUS_IND = 'E' " +
            "AND (CLASS_DTE < TO_CHAR(SYSDATE,'DD-MON-YYYY') OR (" +
            "CLASS_DTE = TO_CHAR(SYSDATE,'DD-MON-YYYY') AND TO_CHAR(SYSDATE,'HH24MI') > " +
            "NVL((SELECT END_TIME FROM ALTERNATE_SLOT_TIM WHERE SLOT_ID = S.SLOT_ID " +
            "AND DAY_ID = (SELECT DAY_ID FROM DAY WHERE DAY_TXT = TRIM(TO_CHAR(SYSDATE,'DAY'))) " +
            "AND TO_DATE(START_DTE,'DD-MM-YY') <= TO_DATE(SYSDATE,'DD-MM-YY') " +
            "AND TO_DATE(END_DTE,'DD-MM-YY') >= TO_DATE(SYSDATE,'DD-MM-YY')), END_TIME)))";
        try
        {
            Integer count = queryInteger(con, sql, classId);
            return count != null && count > 0;
        }
        catch(Exception e)
        {
            return false;
        }
    }

//method taken form connection pool
    public static int getAbsentLimit(int creditHRs, String facultyId, Connection con, String regNbr) throws Exception
    {
        String sports = queryString(con, "SELECT NVL(SPORTS_PRSN_IND, 'N') FROM STUDENT WHERE REG_NBR = ?", regNbr);
        String column = "Y".equalsIgnoreCase(sports) ? "AL.ABSENT_LIMIT_SPORTS" : "AL.ABSENT_LIMIT";
        String sql =
            "SELECT " + column + " ABSENT_LIMIT FROM ABSENT_LIMIT AL, FACULTY F " +
            "WHERE AL.FACULTY_ID = F.FACULTY_ID AND F.FACULTY_ID = ? AND CREDIT_HRS = ?";
        Integer limit = queryInteger(con, sql, facultyId, creditHRs);
        return limit == null ? -1 : limit;
    }

    public static boolean isActivityOn(String activity, String termCode, String facultyId, Connection con) throws Exception
    {
        String sql =
            "SELECT 1 FROM ACADEMIC_CALENDAR AC, FACULTY F WHERE AC.ACTIVITY_NAME = ? AND AC.TERM_CDE = ? " +
            "AND AC.FACULTY_ID = F.FACULTY_ID AND F.FACULTY_ID = ? AND TRUNC(SYSDATE) BETWEEN AC.START_DATE AND AC.END_DATE";
        return exists(con, sql, activity, termCode, facultyId);
    }

    public static int getActivityStatus(String activity, String termCode, String facultyId, Connection con) throws Exception
    {
        String sql =
            "SELECT CASE WHEN TRUNC(SYSDATE) < AC.START_DATE THEN -1 " +
            "WHEN TRUNC(SYSDATE) BETWEEN AC.START_DATE AND AC.END_DATE THEN 0 ELSE 1 END ACTIVITY_STATUS " +
            "FROM ACADEMIC_CALENDAR AC, FACULTY F WHERE AC.ACTIVITY_NAME = ? AND AC.TERM_CDE = ? " +
            "AND AC.FACULTY_ID = F.FACULTY_ID AND F.FACULTY_ID = ?";
        Integer status = queryInteger(con, sql, activity, termCode, facultyId);
        return status == null ? -1 : status;
    }

    public static String getActivityStartDate(String activity, String termCode, String facultyId, Connection con) throws Exception
    {
        String sql =
            "SELECT TO_CHAR(AC.START_DATE,'DD-MM-YYYY') FROM ACADEMIC_CALENDAR AC, FACULTY F " +
            "WHERE AC.ACTIVITY_NAME = ? AND AC.TERM_CDE = ? AND AC.FACULTY_ID = F.FACULTY_ID AND F.FACULTY_ID = ?";
        String value = queryString(con, sql, activity, termCode, facultyId);
        return value == null ? "" : value;
    }

    public static String getActivityEndtDate(String activity, String termCode, String facultyId, Connection con) throws Exception
    {
        String sql =
            "SELECT TO_CHAR(AC.END_DATE,'DD-MM-YYYY') FROM ACADEMIC_CALENDAR AC, FACULTY F " +
            "WHERE AC.ACTIVITY_NAME = ? AND AC.TERM_CDE = ? AND AC.FACULTY_ID = F.FACULTY_ID AND F.FACULTY_ID = ?";
        String value = queryString(con, sql, activity, termCode, facultyId);
        return value == null ? "" : value;
    }

    public static String getActivityWdExtraDays(String activity, String termCode, String facultyId, Connection con) throws Exception
    {
        String sql =
            "SELECT TO_CHAR(AC.END_DATE + 30,'DD-MM-YYYY') FROM ACADEMIC_CALENDAR AC, FACULTY F " +
            "WHERE AC.ACTIVITY_NAME = ? AND AC.TERM_CDE = ? AND AC.FACULTY_ID = F.FACULTY_ID AND F.FACULTY_ID = ?";
        String value = queryString(con, sql, activity, termCode, facultyId);
        return value == null ? "" : value;
    }

    public static int verifyDate(String endDteWdExtraDays, String endDate, Connection con) throws Exception
    {
        String sql =
            "SELECT CASE WHEN TRUNC(SYSDATE) BETWEEN TO_DATE(?,'DD-MM-RRRR') AND TO_DATE(?,'DD-MM-RRRR') THEN 1 ELSE 0 END FROM DUAL";
        Integer status = queryInteger(con, sql, endDate, endDteWdExtraDays);
        return status == null ? 0 : status;
    }

    public static boolean canModifySectionActivity(int teacherId, int sectionId, Connection con) throws Exception
    {
        if(isUserAllowedProcess(con, "CanModifyAnySectionActivity", "WASEE")) return true;
        return exists(con, "SELECT 1 FROM SECTION WHERE SECTION_ID = ? AND TCHR_ID = ?", sectionId, teacherId);
    }

    public static boolean slotTimeOver(int slotId, String extTime, Connection con) throws Exception
    {
        double extraMinutes;
        try { extraMinutes = Double.parseDouble(extTime); }
        catch(Exception e) { extraMinutes = 0; }

        String sql =
            "SELECT SL.SLOT_NBR FROM SLOT SL WHERE TO_CHAR(SYSDATE,'HH24MI') < TO_CHAR(" +
            "NVL((SELECT SLOT_START_TIME FROM ALTERNATE_SLOT_TIM WHERE SLOT_ID = SL.SLOT_ID " +
            "AND DAY_ID = (SELECT DAY_ID FROM DAY WHERE DAY_TXT = TRIM(TO_CHAR(SYSDATE,'DAY'))) " +
            "AND TO_DATE(START_DTE,'DD-MM-YY') <= TO_DATE(SYSDATE,'DD-MM-YY') " +
            "AND TO_DATE(END_DTE,'DD-MM-YY') >= TO_DATE(SYSDATE,'DD-MM-YY')), SL.SLOT_START_TIME) + (? / 1440), 'HH24MI') " +
            "AND SL.SLOT_ID = ?";
        return !exists(con, sql, extraMinutes, slotId);
    }

    public static boolean isProject(String courseCode, Connection con) throws Exception
    {
        String sql = "SELECT 1 FROM COURSES C, COURSE_PROJECT P WHERE C.COURSEID = P.C_ID AND C.COURSEID = ?";
        return exists(con, sql, courseCode);
    }

    public static boolean isNewStudent(String regNbr, String term) throws Exception
    {
        return regNbr != null && regNbr.length() >= 5 && regNbr.substring(2, 5).equals(term);
    }

    public static int calulatePosition(double ttlMarks, double obtMarks, String progId, Connection con) throws Exception
    {
        String selectSql =
            "SELECT ML.TTL_MARKS, ML.OBT_MARKS, ML.MERIT_POSITION, ML.MERIT_LIST_ID " +
            "FROM MERIT_LIST ML, CANDIDATE C, OFFERED_PROGRAM OP, PROGRAM P " +
            "WHERE C.CANDIDATE_ID = ML.CANDIDATE_ID AND C.OP_ID = OP.OP_ID AND OP.PROG_ID = P.PROG_ID " +
            "AND P.PROG_ID = ? ORDER BY MERIT_POSITION DESC";
        String updateSql = "UPDATE MERIT_LIST SET MERIT_POSITION = ? WHERE MERIT_LIST_ID = ?";
        boolean oldAutoCommit = con.getAutoCommit();
        int pos = 0;
        List<Integer> rowsToShift = new ArrayList<Integer>();

        try(PreparedStatement stmt = con.prepareStatement(selectSql, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY);
            PreparedStatement updateStmt = con.prepareStatement(updateSql))
        {
            con.setAutoCommit(false);
            stmt.setObject(1, progId);
            try(ResultSet rs = stmt.executeQuery())
            {
                boolean equal = false, breakWhile = false;
                if(rs.next())
                {
                    do
                    {
                        double currentRatio = rs.getDouble(2) / rs.getDouble(1);
                        double newRatio = obtMarks / ttlMarks;
                        if(currentRatio == newRatio)
                        {
                            pos = rs.getInt(3);
                            equal = true;
                            break;
                        }
                        if(currentRatio < newRatio) rowsToShift.add(rs.getRow());
                        else
                        {
                            pos = rs.getInt(3) + 1;
                            breakWhile = true;
                            break;
                        }
                    }
                    while(rs.next());

                    if(!equal && !rowsToShift.isEmpty() && breakWhile)
                    {
                        for(Integer row : rowsToShift)
                        {
                            rs.absolute(row);
                            updateStmt.setInt(1, rs.getInt(3) + 1);
                            updateStmt.setString(2, rs.getString("MERIT_LIST_ID"));
                            updateStmt.executeUpdate();
                        }
                    }
                }
                else pos = 1;
            }
            con.commit();
            return pos;
        }
        catch(Exception e)
        {
            rollbackQuietly(con);
            throw e;
        }
        finally
        {
            try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
        }
    }

    public static String getSectionCampus(String sectionId, Connection con) throws Exception
    {
        String value = queryString(con,
            "SELECT F.CMP_ID FROM FACULTY F, SECTION_FACULTY SF WHERE F.FACULTY_ID = SF.FACULTY_ID AND SF.SECTION_ID = ?", sectionId);
        if(value == null) throw new Exception("Campus not found for sectionId " + sectionId);
        return value;
    }

    public static int getStudentCourseRate(String regNbr, Connection con) throws Exception
    {
        String sql =
            "SELECT RS.PER_COURSE_AMT FROM STUDENT S, BATCH B, REGISTRATION_SCHEDULE RS " +
            "WHERE S.PROG_ID = B.PROG_ID AND B.BATCH_ID = RS.BATCH_ID AND S.REG_NBR = ? " +
            "AND B.TERM_CDE = SUBSTR(S.REG_NBR, 3, 3) " +
            "AND RS.REG_SCHED_ID = (SELECT MAX(RS2.REG_SCHED_ID) FROM REGISTRATION_SCHEDULE RS2 WHERE RS2.BATCH_ID = B.BATCH_ID)";
        Integer rate = queryInteger(con, sql, regNbr);
        if(rate == null) throw new Exception("Course Rate not found for student " + regNbr);
        return rate;
    }

    public static void reCalculateAccounts(String termCode, Connection con) throws Exception
    {
        String selectSql =
            "SELECT A.REG_NBR, D.PERCENTS, D.DISC_TYPE_ID, A.COURSE_CNT, A.CHALLAN_NBR " +
            "FROM ACCOUNTS A, DISCOUNTS D WHERE A.REG_NBR = D.REG_NBR AND A.TERM_CDE = D.TERM_CDE " +
            "AND A.TERM_CDE = ? AND A.DISC_ID <> D.DISC_TYPE_ID AND A.PAID_DTE IS NULL";
        String courseRateSql =
            "SELECT RS.PER_COURSE_AMT FROM STUDENT S, BATCH B, REGISTRATION_SCHEDULE RS " +
            "WHERE S.PROG_ID = B.PROG_ID AND B.BATCH_ID = RS.BATCH_ID AND S.REG_NBR = ?";
        String discountSql = "SELECT PERCENTS, DISC_TYPE_ID FROM DISCOUNTS WHERE TERM_CDE = ? AND REG_NBR = ?";
        String excessSql = "SELECT AMOUNT FROM EXCESSPAID WHERE TERM = ? AND REG = ?";
        String updateRegSql = "UPDATE REGISTRATION SET FEE_AMT = ? WHERE TERM_CDE = ? AND REG_NBR = ?";
        String updateAccountSql =
            "UPDATE ACCOUNTS SET COURSE_RTE = ?, DISC_ID = ?, DISC_PCT = ?, DUE_AMT = ?, PAID_AMT = ? " +
            "WHERE TERM_CDE = ? AND REG_NBR = ? AND CHALLAN_NBR = ?";
        String updateInst1Sql = "UPDATE INSTALLMENT SET AMOUNT = ?, RAMOUNT = ? WHERE INSTNO = 1 AND TERM_CDE = ? AND REG_NBR = ?";
        String updateInst2Sql = "UPDATE INSTALLMENT SET AMOUNT = ? WHERE INSTNO = 2 AND TERM_CDE = ? AND REG_NBR = ?";

        boolean oldAutoCommit = con.getAutoCommit();
        try(PreparedStatement selectStmt = con.prepareStatement(selectSql);
            PreparedStatement courseStmt = con.prepareStatement(courseRateSql);
            PreparedStatement discountStmt = con.prepareStatement(discountSql);
            PreparedStatement excessStmt = con.prepareStatement(excessSql);
            PreparedStatement updateRegStmt = con.prepareStatement(updateRegSql);
            PreparedStatement updateAccountStmt = con.prepareStatement(updateAccountSql);
            PreparedStatement updateInst1Stmt = con.prepareStatement(updateInst1Sql);
            PreparedStatement updateInst2Stmt = con.prepareStatement(updateInst2Sql))
        {
            con.setAutoCommit(false);
            selectStmt.setString(1, termCode);
            try(ResultSet rs = selectStmt.executeQuery())
            {
                while(rs.next())
                {
                    String regNbr = rs.getString("REG_NBR");
                    int courseCnt = rs.getInt("COURSE_CNT");
                    String challanNbr = rs.getString("CHALLAN_NBR");
                    int courseRate = 0, odAmount = 0;
                    double discPct = 0, stdCourseRate;
                    String discTypeId = "0";

                    courseStmt.setString(1, regNbr);
                    try(ResultSet rateRs = courseStmt.executeQuery())
                    {
                        if(rateRs.next()) courseRate = rateRs.getInt("PER_COURSE_AMT");
                    }

                    bind(discountStmt, termCode, regNbr);
                    try(ResultSet discRs = discountStmt.executeQuery())
                    {
                        if(discRs.next())
                        {
                            discPct = discRs.getDouble("PERCENTS");
                            discTypeId = discRs.getString("DISC_TYPE_ID");
                        }
                    }

                    bind(excessStmt, termCode, regNbr);
                    try(ResultSet odRs = excessStmt.executeQuery())
                    {
                        if(odRs.next()) odAmount = odRs.getInt("AMOUNT");
                    }

                    stdCourseRate = courseRate * (100 - discPct) / 100;
                    double dueAmount = (stdCourseRate * courseCnt) - odAmount;
                    double installmentAmount = dueAmount / 2;

                    bind(updateRegStmt, stdCourseRate, termCode, regNbr);
                    updateRegStmt.executeUpdate();
                    bind(updateAccountStmt, stdCourseRate, discTypeId, discPct, dueAmount, installmentAmount, termCode, regNbr, challanNbr);
                    updateAccountStmt.executeUpdate();
                    bind(updateInst1Stmt, installmentAmount, installmentAmount, termCode, regNbr);
                    updateInst1Stmt.executeUpdate();
                    bind(updateInst2Stmt, installmentAmount, termCode, regNbr);
                    updateInst2Stmt.executeUpdate();
                }
            }
            con.commit();
        }
        catch(Exception e)
        {
            rollbackQuietly(con);
            throw e;
        }
        finally
        {
            try { con.setAutoCommit(oldAutoCommit); } catch(SQLException ignored) {}
        }
    }
    
    public static boolean isImedDegreeOfOldPunjabian(String opId, String candId, Connection con) throws Exception
    {
        String sql =
            "SELECT 1 FROM CANDIDATE C, ACCBAK AB, EXAMDESC ED, EXAM_NME EN " +
            "WHERE C.CANDIDATE_ID = AB.CANDIDATE_ID AND AB.EXAMCODE = ED.EXAMCODE AND ED.EXAMNAME = EN.EXAMNAME " +
            "AND C.CANDIDATE_ID = ? AND C.OP_ID = ? AND AB.PGCNO IS NOT NULL AND C.OLD_REG IS NOT NULL";
        try { return exists(con, sql, candId, opId); }
        catch(Exception e) { throw new Exception("Error in previous degree verification", e); }
    }
    
    public static boolean haveKinshipConcession(String candId, Connection con) throws Exception
    {
        String sql = "SELECT 1 FROM CANDIDATE WHERE CANDIDATE_ID = ? AND KIN_REL IS NOT NULL AND KIN_REGNBR IS NOT NULL";
        try { return exists(con, sql, candId); }
        catch(Exception e) { throw new Exception("Error in previous degree verification", e); }
    }
    
    public static boolean isSportsPerson(String candId, Connection con) throws Exception
    {
        return "Y".equalsIgnoreCase(queryString(con, "SELECT SPORTS_PRSN_IND FROM CANDIDATE WHERE CANDIDATE_ID = ?", candId));
    }
    
    public static boolean isPwwfPerson(String candId, Connection con) throws Exception
    {
        return "Y".equalsIgnoreCase(queryString(con, "SELECT PWWF_IND FROM CANDIDATE WHERE CANDIDATE_ID = ?", candId));
    }
    
    public static boolean isStdPwwfPerson(String regNbr, Connection con) throws Exception
    {
        return "Y".equalsIgnoreCase(queryString(con, "SELECT PWWF_IND FROM STUDENT WHERE REG_NBR = UPPER(?)", regNbr));
    }
    
    public static boolean isStdSportsPerson(String regNbr, Connection con) throws Exception
    {
        return "Y".equalsIgnoreCase(queryString(con, "SELECT SPORTS_PRSN_IND FROM STUDENT WHERE REG_NBR = UPPER(?)", regNbr));
    }
    
    public static String allowDiscountOrNot(String reg, String facId, String curTerm, Connection con) throws Exception
    {
        String eligibilitySql =
            "SELECT DISTINCT CASE WHEN DT.CGPA_LIMIT <= ADMINISTRATOR.NUTILITY.GET_TCGPA(?, 'U', 1, ?) THEN 'GD' ELSE 'ND' END " +
            "FROM DISCOUNTS D, DISCOUNT_TYPE DT WHERE D.REG_NBR = ? AND DT.DISCID = D.DISC_TYPE_ID " +
            "AND DT.CGPA_LIMIT <= ADMINISTRATOR.NUTILITY.GET_TCGPA(?, 'U', 1, ?)";
        String status = queryString(con, eligibilitySql, reg, curTerm, reg, reg, curTerm);
        if(!"GD".equalsIgnoreCase(status)) return "";

        String discountSql =
            "SELECT DISTINCT D.DISC_TYPE_ID FROM BATCH B, STUDENT S, DISCOUNTS D " +
            "WHERE B.PROG_ID = S.PROG_ID AND S.REG_NBR = ? AND D.REG_NBR = S.REG_NBR AND B.TERM_CDE = D.TERM_CDE";
        String discId = queryString(con, discountSql, reg);
        return discId == null ? "" : discId;
    }
    public static boolean isParametersInjectable(Object[] params)
    {
        if(params == null) return true;
        for(Object value : params)
        {
            if(value == null) continue;
            String param = value.toString().replaceAll("\\s+", " ").trim().toLowerCase();
            for(String word : INJECTION_BLOCKLIST)
                if(param.contains(word)) return false;
        }
        return true;
    }
    
    public static int getNewStudentCountByTermCampusProg(Connection con, String term, String cmpPrefix, String progCode) throws Exception
    {
        String sql =
            "SELECT COUNT(DISTINCT R.REG_NBR) FROM REGISTRATION R, STUDENT S, PROGRAM P, FACULTY F, CAMPUS C " +
            "WHERE R.REG_NBR = S.REG_NBR AND S.PROG_ID = P.PROG_ID AND SUBSTR(R.REG_NBR,1,2) = C.CMP_PREFIX " +
            "AND SUBSTR(R.REG_NBR,3,3) = ? AND R.TERM_CDE = ? AND R.STATUS_TYP = 'Y' AND P.FACULTY_ID = F.FACULTY_ID " +
            "AND F.CMP_ID = C.CMP_ID AND C.CMP_PREFIX = ? AND P.PROG_CDE = ?";
        return intValue(queryInteger(con, sql, term, term, cmpPrefix, progCode));
    }
       
    public static int getOnGoingStudentCountByTermCampusProg(Connection con, String term, String cmpPrefix, String progCode) throws Exception
    {
        String sql =
            "SELECT COUNT(DISTINCT R.REG_NBR) FROM REGISTRATION R, STUDENT S, PROGRAM P, FACULTY F, CAMPUS C " +
            "WHERE R.REG_NBR = S.REG_NBR AND S.PROG_ID = P.PROG_ID AND SUBSTR(R.REG_NBR,1,2) = C.CMP_PREFIX " +
            "AND SUBSTR(R.REG_NBR,3,3) IN (SELECT TERM_CDE FROM TERM WHERE TERM_CDE <> ? AND TERM_CDE NOT LIKE 'R%') " +
            "AND R.TERM_CDE = ? AND R.STATUS_TYP = 'Y' AND P.FACULTY_ID = F.FACULTY_ID AND F.CMP_ID = C.CMP_ID " +
            "AND C.CMP_PREFIX = ? AND P.PROG_CDE = ?";
        return intValue(queryInteger(con, sql, term, term, cmpPrefix, progCode));
    }
    
    public static int getNewStudentCountByTermCampusDegree(Connection con, String term, String cmpPrefix, String degree) throws Exception
    {
        String sql =
            "SELECT COUNT(DISTINCT R.REG_NBR) FROM REGISTRATION R, STUDENT S, PROGRAM P, FACULTY F, CAMPUS C " +
            "WHERE R.REG_NBR = S.REG_NBR AND S.PROG_ID = P.PROG_ID AND SUBSTR(R.REG_NBR,1,2) = C.CMP_PREFIX " +
            "AND SUBSTR(R.REG_NBR,3,3) = ? AND R.TERM_CDE = ? AND R.STATUS_TYP = 'Y' AND P.FACULTY_ID = F.FACULTY_ID " +
            "AND F.CMP_ID = C.CMP_ID AND C.CMP_PREFIX = ? AND P.PROG_CDE IN (SELECT PROG_CDE FROM DEGREE_MAPPING WHERE DEGREE_NME = ?)";
        return intValue(queryInteger(con, sql, term, term, cmpPrefix, degree));
    }
    
    public static int getOnGoingStudentCountByTermCampusDegree(Connection con, String term, String cmpPrefix, String degree) throws Exception
    {
        String sql =
            "SELECT COUNT(DISTINCT R.REG_NBR) FROM REGISTRATION R, STUDENT S, PROGRAM P, FACULTY F, CAMPUS C " +
            "WHERE R.REG_NBR = S.REG_NBR AND S.PROG_ID = P.PROG_ID AND SUBSTR(R.REG_NBR,1,2) = C.CMP_PREFIX " +
            "AND SUBSTR(R.REG_NBR,3,3) IN (SELECT TERM_CDE FROM TERM WHERE TERM_CDE <> ? AND TERM_CDE NOT LIKE 'R%') " +
            "AND R.TERM_CDE = ? AND R.STATUS_TYP = 'Y' AND P.FACULTY_ID = F.FACULTY_ID AND F.CMP_ID = C.CMP_ID " +
            "AND C.CMP_PREFIX = ? AND P.PROG_CDE IN (SELECT PROG_CDE FROM DEGREE_MAPPING WHERE DEGREE_NME = ?)";
        return intValue(queryInteger(con, sql, term, term, cmpPrefix, degree));
    }
    
    public static int getSumOnGoingStudentByProg(Connection con, String term, String progCode) throws Exception
    {
        String sql =
            "SELECT COUNT(DISTINCT R.REG_NBR) FROM REGISTRATION R, STUDENT S, PROGRAM P, FACULTY F, CAMPUS C " +
            "WHERE R.REG_NBR = S.REG_NBR AND S.PROG_ID = P.PROG_ID AND SUBSTR(R.REG_NBR,1,2) = C.CMP_PREFIX " +
            "AND SUBSTR(R.REG_NBR,3,3) IN (SELECT TERM_CDE FROM TERM WHERE TERM_CDE <> ? AND TERM_CDE NOT LIKE 'R%') " +
            "AND R.TERM_CDE = ? AND R.STATUS_TYP = 'Y' AND P.FACULTY_ID = F.FACULTY_ID AND F.CMP_ID = C.CMP_ID AND P.PROG_CDE = ?";
        return intValue(queryInteger(con, sql, term, term, progCode));
    }
    
    public static int getSumOnGoingStudentByDegree(Connection con, String term, String degree) throws Exception
    {
        String sql =
            "SELECT COUNT(DISTINCT R.REG_NBR) FROM REGISTRATION R, STUDENT S, PROGRAM P, FACULTY F, CAMPUS C " +
            "WHERE R.REG_NBR = S.REG_NBR AND S.PROG_ID = P.PROG_ID AND SUBSTR(R.REG_NBR,1,2) = C.CMP_PREFIX " +
            "AND SUBSTR(R.REG_NBR,3,3) IN (SELECT TERM_CDE FROM TERM WHERE TERM_CDE <> ? AND TERM_CDE NOT LIKE 'R%') " +
            "AND R.TERM_CDE = ? AND R.STATUS_TYP = 'Y' AND P.FACULTY_ID = F.FACULTY_ID AND F.CMP_ID = C.CMP_ID " +
            "AND P.PROG_CDE IN (SELECT PROG_CDE FROM DEGREE_MAPPING WHERE DEGREE_NME = ?)";
        return intValue(queryInteger(con, sql, term, term, degree));
    }
    
    public static int getSumNewStudentByProg(Connection con, String term, String progCode) throws Exception
    {
        String sql =
            "SELECT COUNT(DISTINCT R.REG_NBR) FROM REGISTRATION R, STUDENT S, PROGRAM P, FACULTY F, CAMPUS C " +
            "WHERE R.REG_NBR = S.REG_NBR AND S.PROG_ID = P.PROG_ID AND SUBSTR(R.REG_NBR,1,2) = C.CMP_PREFIX " +
            "AND SUBSTR(R.REG_NBR,3,3) = ? AND R.TERM_CDE = ? AND R.STATUS_TYP = 'Y' AND P.FACULTY_ID = F.FACULTY_ID " +
            "AND F.CMP_ID = C.CMP_ID AND P.PROG_CDE = ?";
        return intValue(queryInteger(con, sql, term, term, progCode));
    }
    
    public static int getSumNewStudentByDegree(Connection con, String term, String degree) throws Exception
    {
        String sql =
            "SELECT COUNT(DISTINCT R.REG_NBR) FROM REGISTRATION R, STUDENT S, PROGRAM P, FACULTY F, CAMPUS C " +
            "WHERE R.REG_NBR = S.REG_NBR AND S.PROG_ID = P.PROG_ID AND SUBSTR(R.REG_NBR,1,2) = C.CMP_PREFIX " +
            "AND SUBSTR(R.REG_NBR,3,3) = ? AND R.TERM_CDE = ? AND R.STATUS_TYP = 'Y' AND P.FACULTY_ID = F.FACULTY_ID " +
            "AND F.CMP_ID = C.CMP_ID AND P.PROG_CDE IN (SELECT PROG_CDE FROM DEGREE_MAPPING WHERE DEGREE_NME = ?)";
        return intValue(queryInteger(con, sql, term, term, degree));
    }
    
    public static int getTotalOnGoingStudentByCampus(Connection con, String term, String cmpPrefix) throws Exception
    {
        String sql =
            "SELECT COUNT(DISTINCT R.REG_NBR) FROM REGISTRATION R, STUDENT S, PROGRAM P, FACULTY F, CAMPUS C " +
            "WHERE R.REG_NBR = S.REG_NBR AND S.PROG_ID = P.PROG_ID AND SUBSTR(R.REG_NBR,1,2) = C.CMP_PREFIX " +
            "AND SUBSTR(R.REG_NBR,3,3) IN (SELECT TERM_CDE FROM TERM WHERE TERM_CDE <> ? AND TERM_CDE NOT LIKE 'R%') " +
            "AND R.TERM_CDE = ? AND R.STATUS_TYP = 'Y' AND P.FACULTY_ID = F.FACULTY_ID AND F.CMP_ID = C.CMP_ID AND C.CMP_PREFIX = ?";
        return intValue(queryInteger(con, sql, term, term, cmpPrefix));
    }
    
    public static int getTotalNewStudentByCampus(Connection con, String term, String cmpPrefix) throws Exception
    {
        String sql =
            "SELECT COUNT(DISTINCT R.REG_NBR) FROM REGISTRATION R, STUDENT S, PROGRAM P, FACULTY F, CAMPUS C " +
            "WHERE R.REG_NBR = S.REG_NBR AND S.PROG_ID = P.PROG_ID AND SUBSTR(R.REG_NBR,1,2) = C.CMP_PREFIX " +
            "AND SUBSTR(R.REG_NBR,3,3) = ? AND R.TERM_CDE = ? AND R.STATUS_TYP = 'Y' " +
            "AND P.FACULTY_ID = F.FACULTY_ID AND F.CMP_ID = C.CMP_ID AND C.CMP_PREFIX = ?";
        return intValue(queryInteger(con, sql, term, term, cmpPrefix));
    }
    
    public static int getTotalStudentByCampus(Connection con, String term, String cmpPrefix) throws Exception
    {
        String sql =
            "SELECT COUNT(DISTINCT R.REG_NBR) FROM REGISTRATION R, STUDENT S, PROGRAM P, FACULTY F, CAMPUS C " +
            "WHERE R.REG_NBR = S.REG_NBR AND S.PROG_ID = P.PROG_ID AND SUBSTR(R.REG_NBR,1,2) = C.CMP_PREFIX " +
            "AND R.TERM_CDE = ? AND R.STATUS_TYP = 'Y' AND P.FACULTY_ID = F.FACULTY_ID AND F.CMP_ID = C.CMP_ID AND C.CMP_PREFIX = ?";
        return intValue(queryInteger(con, sql, term, cmpPrefix));
    }
    
    public static int getGrandTotalNewStudent(Connection con, String term) throws Exception
    {
        String sql =
            "SELECT COUNT(DISTINCT R.REG_NBR) FROM REGISTRATION R, STUDENT S, PROGRAM P, FACULTY F, CAMPUS C " +
            "WHERE R.REG_NBR = S.REG_NBR AND S.PROG_ID = P.PROG_ID AND SUBSTR(R.REG_NBR,1,2) = C.CMP_PREFIX " +
            "AND SUBSTR(R.REG_NBR,3,3) = ? AND R.TERM_CDE = ? AND R.STATUS_TYP = 'Y' " +
            "AND P.FACULTY_ID = F.FACULTY_ID AND F.CMP_ID = C.CMP_ID";
        return intValue(queryInteger(con, sql, term, term));
    }
    
    public static int getGrandTotalOnGoingStudent(Connection con, String term) throws Exception
    {
        String sql =
            "SELECT COUNT(DISTINCT R.REG_NBR) FROM REGISTRATION R, STUDENT S, PROGRAM P, FACULTY F, CAMPUS C " +
            "WHERE R.REG_NBR = S.REG_NBR AND S.PROG_ID = P.PROG_ID AND SUBSTR(R.REG_NBR,1,2) = C.CMP_PREFIX " +
            "AND SUBSTR(R.REG_NBR,3,3) IN (SELECT TERM_CDE FROM TERM WHERE TERM_CDE <> ? AND TERM_CDE NOT LIKE 'R%') " +
            "AND R.TERM_CDE = ? AND R.STATUS_TYP = 'Y' AND P.FACULTY_ID = F.FACULTY_ID AND F.CMP_ID = C.CMP_ID";
        return intValue(queryInteger(con, sql, term, term));
    }
    
    public static int getGrandTotalofStudent(Connection con, String term) throws Exception
    {
        String sql =
            "SELECT COUNT(DISTINCT R.REG_NBR) FROM REGISTRATION R, STUDENT S, PROGRAM P, FACULTY F, CAMPUS C " +
            "WHERE R.REG_NBR = S.REG_NBR AND S.PROG_ID = P.PROG_ID AND SUBSTR(R.REG_NBR,1,2) = C.CMP_PREFIX " +
            "AND R.TERM_CDE = ? AND R.STATUS_TYP = 'Y' AND P.FACULTY_ID = F.FACULTY_ID AND F.CMP_ID = C.CMP_ID";
        return intValue(queryInteger(con, sql, term));
    }
     
    public static String generatePinCode(int seed)
    {
        String upper = "ABCDEFGHIJKLMNPQRSTUVWXYZ";
        String lower = "abcdefghijklmnpqrstuvwxyz";
        String digits = "123456789";
        String symbols = "?@$!";
        StringBuilder pin = new StringBuilder(8);
        pin.append(randomChar(upper));
        pin.append(randomChar(lower));
        pin.append(randomChar(digits));
        pin.append(randomChar(digits));
        pin.append(randomChar(symbols));
        pin.append(randomChar(lower));
        pin.append(randomChar(upper));
        pin.append(randomChar(digits));
        return pin.toString();
    }
    public String campusInfo(String facultyId, Connection con) throws Exception
    {
        String value = queryString(con,
            "SELECT C.FRANCHISE FROM CAMPUS C, FACULTY F WHERE C.CMP_ID = F.CMP_ID AND F.FACULTY_ID = ?", facultyId);
        if(value == null) throw new Exception("Campus not found for selected facultyId");
        return value;
    }
    public static String getCurrentTerm(String facId, Connection con)
    {
        try
        {
            return queryString(con, "SELECT CT.TERM_CDE FROM CURRENT_TERM CT WHERE CT.FACULTY_ID = ?", facId);
        }
        catch(Exception e)
        {
            e.printStackTrace();
            return null;
        }
    }
    public static boolean isValidLocation(int campusId, Connection con)
    {
        try
        {
            return exists(con,
                "SELECT 1 FROM PLACE P, PLACE_IP PI WHERE P.PLACE_ID = PI.PLACE_ID AND P.CMP_ID = ?", campusId);
        }
        catch(Exception e)
        {
            e.printStackTrace();
            return false;
        }
    }
    public static List getStudentInfo(String regNbr, Connection con)
    {
        String sql =
            "SELECT S.STUDENT_NME, CP.PROG_CDE COURSE_PROG_CDE, P.PROG_CDE, B.BATCH_ID, B.BATCH_NBR, RS.REG_DTE, RS.PER_COURSE_AMT, " +
            "S.DOB_DTE, S.FATHER_NME, S.L_ADDRESS1_TXT, S.L_ADDRESS2_TXT, S.L_ADDRESS3_TXT, S.L_CITY_NME, S.L_PHONE_NBR, S.P_PHONE_NBR, " +
            "DECODE(S.GENDER_IND,'M','Male','F','Female',S.GENDER_IND) SEX, S.COURSE_PROG_ID, P.PROG_ID, NVL(S.NIC,'') NIC, " +
            "NVL(S.FATHER_NIC,'') FNIC, NVL(S.FATHER_NTN,'') FNTN, ADMINISTRATOR.NUTILITY.GET_CGPA(?) CGPA " +
            "FROM UCP.STUDENT S, UCP.PROGRAM P, UCP.PROGRAM CP, UCP.BATCH B, UCP.REGISTRATION_SCHEDULE RS " +
            "WHERE S.REG_NBR = ? AND S.PROG_ID = P.PROG_ID AND P.PROG_ID = B.PROG_ID AND S.COURSE_PROG_ID = CP.PROG_ID " +
            "AND B.TERM_CDE = ? AND B.BATCH_ID = RS.BATCH_ID AND RS.REG_DTE = (" +
            "SELECT MAX(REG_DTE) FROM UCP.REGISTRATION_SCHEDULE WHERE BATCH_ID = B.BATCH_ID)";

        List<Map<String, String>> data = new ArrayList<Map<String, String>>();
        String batchTerm = regNbr != null && regNbr.length() >= 5 ? regNbr.substring(2, 5) : "";

        try(PreparedStatement stmt = con.prepareStatement(sql))
        {
            bind(stmt, regNbr, regNbr, batchTerm);

            try(ResultSet rs = stmt.executeQuery())
            {
                ResultSetMetaData meta = rs.getMetaData();
                int columnCount = meta.getColumnCount();

                while(rs.next())
                {
                    Map<String, String> row = new HashMap<String, String>();
                    for(int i = 1; i <= columnCount; i++) row.put(meta.getColumnLabel(i), rs.getString(i));
                    data.add(row);
                }
            }
        }
        catch(SQLException e)
        {
            e.printStackTrace();
        }

        return data;
    }

    public static String getGrade(String regNbr, double exResult, Connection con)
    {
        String sql = "SELECT LETTER_GRADE FROM GRADE_KEY WHERE ? BETWEEN LOWER_LIMIT AND UPPER_LIMIT AND TERM_CDE = SUBSTR(?, 3, 3)";
        try
        {
            String grade = queryString(con, sql, exResult, regNbr);
            return grade == null ? "" : grade;
        }
        catch(Exception e)
        {
            e.printStackTrace();
            return "";
        }
    }
    public static double geExamResult(String sectionId, String regNbr, Connection con)
    {
        String gradeSql =
            "SELECT EXAM_TYP_ID, PCT, CONSIDER_TOP FROM GRADE_CALCULATOR WHERE SECTION_ID = ?";
        double result = 0.0;

        try(PreparedStatement gradeStmt = con.prepareStatement(gradeSql))
        {
            gradeStmt.setString(1, sectionId);

            try(ResultSet gradeRs = gradeStmt.executeQuery())
            {
                while(gradeRs.next())
                {
                    String considerTop = gradeRs.getString("CONSIDER_TOP");
                    double pct = gradeRs.getDouble("PCT");
                    if(gradeRs.wasNull() || considerTop == null) continue;

                    Object examTypeId = gradeRs.getObject("EXAM_TYP_ID");
                    Double average;

                    if(!"-1".equals(considerTop))
                    {
                        int top = Integer.parseInt(considerTop);
                        String sql =
                            "SELECT SUM(RESULT_TAB.OBT_OVER_TOTAL) / ? FROM (" +
                            "SELECT (ER.OBT_MARKS_NBR / EX.MARKS_NBR) * 100 OBT_OVER_TOTAL " +
                            "FROM EXAM EX, EXAM_RESULT ER " +
                            "WHERE EX.EXAM_ID = ER.EXAM_ID AND NVL(EX.EXCLUDE_IND,'N') = 'N' " +
                            "AND EX.SECTION_ID = ? AND EX.EXAM_TYP_ID = ? AND ER.REG_NBR = ? " +
                            "ORDER BY ER.OBT_MARKS_NBR DESC) RESULT_TAB WHERE ROWNUM <= ?";
                        average = queryDouble(con, sql, top, sectionId, examTypeId, regNbr, top);
                    }
                    else
                    {
                        String sql =
                            "SELECT SUM((ER.OBT_MARKS_NBR / EX.MARKS_NBR) * 100) / COUNT(EX.EXAM_ID) " +
                            "FROM EXAM EX, EXAM_RESULT ER WHERE EX.EXAM_ID = ER.EXAM_ID " +
                            "AND NVL(EX.EXCLUDE_IND,'N') = 'N' AND EX.SECTION_ID = ? " +
                            "AND EX.EXAM_TYP_ID = ? AND ER.REG_NBR = ?";
                        average = queryDouble(con, sql, sectionId, examTypeId, regNbr);
                    }

                    if(average != null) result += average * pct / 100;
                }
            }
        }
        catch(Exception e)
        {
            e.printStackTrace();
        }

        return result;
    }

    public static boolean isGradeChanged(double adjustedPctg, String curGrade, String term, Connection con)
    {
        try
        {
            String grade = queryString(con,
                "SELECT LETTER_GRADE FROM GRADE_KEY WHERE TERM_CDE = ? AND ? BETWEEN LOWER_LIMIT AND UPPER_LIMIT", term, adjustedPctg);
            return grade != null && !grade.equals(curGrade);
        }
        catch(Exception e)
        {
            e.printStackTrace();
            return false;
        }
    }
    public static boolean isCGPALimitByPassed(String regNbr, String termCde, Connection con)
    {
        try
        {
            String remarks = queryString(con, "SELECT REMARKS FROM UCP.DISCOUNT_ON_CGPA WHERE REG = ? AND TERM = ?", regNbr, termCde);
            return remarks != null && !remarks.trim().isEmpty();
        }
        catch(Exception e)
        {
            e.printStackTrace();
            return false;
        }
    }
    public static String getAdvanceTerm(String facId, Connection con)
    {
        String sql =
            "SELECT TERM_CDE FROM UCP.TERM WHERE START_DTE = (SELECT MAX(START_DTE) FROM UCP.TERM WHERE START_DTE > " +
            "(SELECT START_DTE FROM UCP.TERM WHERE TERM_CDE = (SELECT TERM_CDE FROM UCP.CURRENT_TERM WHERE FACULTY_ID = ?)))";
        try { return queryString(con, sql, facId); }
        catch(Exception e) { e.printStackTrace(); return null; }
    }
    
    public String isStdOnProbation(String regNbr, Connection con)
    {
        try
        {
            String value = queryString(con, "SELECT NVL(FUN_BLOCK_CONSEC_CGPA_DEF(?), 0) FROM DUAL", regNbr);
            return value == null ? "" : value;
        }
        catch(Exception e)
        {
            System.out.println(e.getMessage());
            return "";
        }
    }
    public static boolean isStdRegtdInFall(String regNbr, String fallTermCde, Connection con)
    {
        try
        {
            Integer count = queryInteger(con,
                "SELECT COUNT(*) FROM REGISTRATION WHERE TERM_CDE = ? AND REG_NBR = ? AND FEE_AMT = -1 AND STATUS_TYP = 'N'",
                fallTermCde, regNbr);
            return count != null && count > 0;
        }
        catch(Exception e)
        {
            e.printStackTrace();
            return false;
        }
    }
    public static boolean cancelStdFallRegistration(String regNbr, String fallTermCde, int sessionId, Connection con)
    {
        String[] sql =
        {
            "UPDATE UCP.SECTION_STATUS SET STRENGTH = STRENGTH - 1 WHERE SECTION_ID IN (" +
            "SELECT SECTION_ID FROM REGISTRATION WHERE REG_NBR = ? AND TERM_CDE = ? AND FEE_AMT = -1 AND EVENT_NBR = 2 AND STATUS_TYP = 'N')",
            "DELETE FROM REGISTRATION_REF WHERE REG_NBR = ? AND TERM_CDE = ?",
            "DELETE FROM REGISTRATION WHERE REG_NBR = ? AND TERM_CDE = ? AND FEE_AMT = -1 AND EVENT_NBR = 2 AND STATUS_TYP = 'N'"
        };

        Object[][] params =
        {
            {regNbr, fallTermCde},
            {regNbr, fallTermCde},
            {regNbr, fallTermCde}
        };

        try { return executeTransaction(con, sql, params); }
        catch(SQLException e) { e.printStackTrace(); return false; }
    }

    public String getImagePath()
    {
        try
        {
            String path = getClass().getClassLoader().getResource("").getPath();
            String fullPath = URLDecoder.decode(path, "UTF-8");
            fullPath = fullPath.split("/WEB-INF/")[0];
            File file = new File(new File(fullPath, "WEB-INF"), "path.properties");
            Properties props = new Properties();
            try(FileInputStream in = new FileInputStream(file))
            {
                props.load(in);
            }
            return props.getProperty("imagePath", "");
        }
        catch(Exception e)
        {
            e.printStackTrace();
            return "";
        }
    }
    
    public static boolean isStdDegReqCom(String regNbr, String termCde, Connection con)
    {
        try
        {
            Integer value = queryInteger(con, "SELECT ADMINISTRATOR.NUTILITY.IS_DEGREE_REQ_COMP(?, ?) FROM DUAL", regNbr, termCde);
            return value != null && value == 1;
        }
        catch(Exception e)
        {
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean chckStdMainReg(String regNbr, String termCde, Connection con)
    {
        try
        {
            String sql =
                "SELECT 1 FROM REG_EVENTS RE, ACCOUNTS A WHERE A.EVENT_NBR = RE.EVENTNO " +
                "AND UPPER(EVENTDESC) LIKE '%REGISTRATION' AND A.REG_NBR = ? AND A.TERM_CDE = ? AND A.PAID_DTE IS NOT NULL";
            return exists(con, sql, regNbr, termCde);
        }
        catch(Exception e)
        {
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean chckStdAddDrpReg(String regNbr, String termCde, Connection con)
    {
        try
        {
            String sql =
                "SELECT 1 FROM REG_EVENTS RE, ACCOUNTS A WHERE A.EVENT_NBR = RE.EVENTNO " +
                "AND EVENT LIKE 'ADD%' AND A.REG_NBR = ? AND A.TERM_CDE = ? AND A.PAID_DTE IS NULL";
            return exists(con, sql, regNbr, termCde);
        }
        catch(Exception e)
        {
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean chckStdInstallmentCnt(String regNbr, String termCde, Connection con)
    {
        try
        {
            Integer count = queryInteger(con, "SELECT COUNT(REG_NBR) FROM INSTALLMENT WHERE REG_NBR = ? AND TERM_CDE = ?", regNbr, termCde);
            return count != null && count == 0;
        }
        catch(Exception e)
        {
            e.printStackTrace();
            return false;
        }
    }
    
    public static boolean setMainChallanFine(String regNbr, String workingTerm, Connection con, int sessionId) throws SQLException
    {
        String[] sql =
        {
            "UPDATE ATTENDANCE_FINE SET RECEIPT_NBR = '-99' WHERE FINE_ID IN (" +
            "SELECT FINE_ID FROM ATTENDANCE_FINE AF, ATTENDANCE AT WHERE AT.ATTEND_ID = AF.ATTEND_ID " +
            "AND AT.REG_NBR = ? AND AF.FINE_AMT > 0 AND PAID_DTE IS NULL AND AF.RECEIPT_NBR IS NULL)",
            "UPDATE OTHER_FINE SET RECEIPT_NBR = '-99' WHERE REG_NBR = ? AND RECEIPT_NBR IS NULL AND PAID_DTE IS NULL"
        };

        Object[][] params =
        {
            {regNbr},
            {regNbr}
        };

        return executeTransaction(con, sql, params);
    }

    public static String getStudentStatus(String regNbr, Connection con) throws Exception
    {
        String status = queryString(con, "SELECT STATUS_IND FROM STUDENT WHERE REG_NBR = ?", regNbr);
        return status == null ? "A" : status;
    }
    
    public static boolean isGraduateLineEntered(String regNbr, Connection con) throws Exception
    {
        return exists(con, "SELECT 1 FROM UCP.DEGREE_COMPLETION WHERE REG = ?", regNbr);
    }
    public static boolean checkDiscount(String regNbr, String term, String discTyp, Connection con) throws Exception
    {
        if("discInPer".equals(discTyp))
        {
            Integer value = queryInteger(con, "SELECT NVL(PERCENTS, 0) FROM DISCOUNTS WHERE REG_NBR = ? AND TERM_CDE = ?", regNbr, term);
            return value != null && value > 0;
        }
        if("concession".equals(discTyp))
        {
            Integer value = queryInteger(con, "SELECT NVL(SUM(CONCESSION), 0) FROM ACCOUNTS WHERE REG_NBR = ? AND TERM_CDE = ?", regNbr, term);
            return value != null && value > 0;
        }
        return false;
    }
   
    public static boolean isStdHasDiscount(String regNbr, String term, Connection con) throws Exception
    {
        return exists(con, "SELECT 1 FROM DISCOUNTS WHERE TERM_CDE = ? AND REG_NBR = ? AND PERCENTS <> 0", term, regNbr);
    }
   
    public static boolean isStdRegistered(String regNbr, String term, Connection con) throws Exception
    {
        return exists(con, "SELECT 1 FROM REGISTRATION WHERE TERM_CDE = ? AND REG_NBR = ?", term, regNbr);
    }
   
    public static boolean hasClassEnded(String classId, Connection con)
    {
        try { return !exists(con, "SELECT 1 FROM CLASS_HELD WHERE CLASS_ID = ? AND END_TIM IS NULL", classId); }
        catch(Exception e) { return false; }
    }
    
    public static int getSemesterNumber(String reg, boolean withSummer, Connection con)
    {
        String sql = "SELECT COUNT(DISTINCT TERM) FROM COR_GRADES WHERE REG = ?" + (withSummer ? "" : " AND TERM NOT LIKE '%R%'");
        try
        {
            Integer count = queryInteger(con, sql, reg);
            return count == null ? 0 : count;
        }
        catch(Exception e)
        {
            e.printStackTrace();
            return 0;
        }
    }
    
    public static double getCGPA(String regNbr, Connection con) throws Exception
    {
        Double cgpa = queryDouble(con, "SELECT ADMINISTRATOR.NUTILITY.GET_CGPA(?) FROM DUAL", regNbr);
        return cgpa == null ? 0 : cgpa;
    }

        
    public static boolean isOldStudent(String regNbr, Connection con) throws Exception
    {
        String sql =
            "SELECT 1 FROM STUDENT S, REG_CAND RC, CANDIDATE C " +
            "WHERE S.REG_NBR = RC.REG_NBR AND RC.CANDIDATE_ID = C.CANDIDATE_ID AND S.REG_NBR = ? AND C.OLD_REG IS NOT NULL";
        return exists(con, sql, regNbr);
    }
    
    public static boolean isKinship(String regNbr, Connection con) throws Exception
    {
        String sql =
            "SELECT 1 FROM STUDENT S, REG_CAND RC, CANDIDATE C " +
            "WHERE S.REG_NBR = RC.REG_NBR AND RC.CANDIDATE_ID = C.CANDIDATE_ID AND S.REG_NBR = ? AND C.KIN_REGNBR IS NOT NULL";
        return exists(con, sql, regNbr);
    }
    
    public static boolean isStudentDuesPending(String regNbr, Connection con) throws Exception
    {
        String sql =
            "SELECT 1 FROM DUAL WHERE EXISTS (SELECT 1 FROM DMC_CHALLAN WHERE REG_NBR = ? AND PAID_DTE IS NULL) " +
            "OR EXISTS (SELECT 1 FROM ACCOUNTS WHERE REG_NBR = ? AND PAID_DTE IS NULL) " +
            "OR EXISTS (SELECT 1 FROM UCP.INSTALLMENT WHERE REG_NBR = ? AND PAIDDATE IS NULL) " +
            "OR EXISTS (SELECT 1 FROM UCP.INSTALLMENT I WHERE I.REG_NBR = ? AND I.INSTNO IN (" +
            "SELECT MAX(I2.INSTNO) FROM UCP.INSTALLMENT I2 WHERE I2.REG_NBR = I.REG_NBR AND I2.PAIDDATE IS NOT NULL AND I2.TERM_CDE = I.TERM_CDE) " +
            "AND I.RAMOUNT > 0)";
        return exists(con, sql, regNbr, regNbr, regNbr, regNbr);
    }
    
    public static boolean isStudentFinePending(String regNbr, Connection con) throws Exception
    {
        String sql =
            "SELECT 1 FROM DUAL WHERE EXISTS (SELECT 1 FROM ATTENDANCE A, ATTENDANCE_FINE AF " +
            "WHERE A.ATTEND_ID = AF.ATTEND_ID AND A.REG_NBR = ? AND AF.PAID_DTE IS NULL) " +
            "OR EXISTS (SELECT 1 FROM OTHER_FINE WHERE REG_NBR = ? AND PAID_DTE IS NULL)";
        return exists(con, sql, regNbr, regNbr);
    }
    
    public static boolean isSuperUser(String userName, Connection con) throws Exception
    {
        return exists(con, "SELECT 1 FROM WEB_USERS WHERE USER_CLASS_IND = 'S' AND USER_NME = ?", userName);
    }
    
    public static String courseLoadLimit(String regNbr, String term, Connection con) throws Exception
    {
        String sql =
            "SELECT CASE WHEN COURSE_LIMIT >= (SELECT COUNT(*) FROM REGISTRATION WHERE REG_NBR = S.REG_NBR AND TERM_CDE = PCL.TERM_CDE) " +
            "THEN 'TRUE' ELSE 'FALSE' END IS_LIMIT_OVER FROM PROG_COURSE_LIMIT PCL, STUDENT S " +
            "WHERE PCL.PROG_ID = S.COURSE_PROG_ID AND REG_NBR = ? AND TERM_CDE = ?";
        String value = queryString(con, sql, regNbr, term);
        return value == null ? "TRUE" : value;
    }
    
    public static boolean isChallanApproval(String regNbr, Connection con) throws Exception
    {
        if(regNbr == null || regNbr.length() < 2) return false;
        return exists(con, "SELECT 1 FROM CHALLAN_APPROVAL_CAMPUS WHERE CMP_PREFIX = ?", regNbr.substring(0, 2));
    }
    
    public static boolean isChallanApproved(String regNbr, String term, Connection con) throws Exception
    {
        String sql =
            "SELECT 1 FROM CHALLAN_STATUS CS, ACCOUNTS A WHERE A.ACCT_ID = CS.ACCT_ID " +
            "AND A.REG_NBR = ? AND A.PAID_DTE IS NULL AND A.TERM_CDE = ? AND CS.STATUS_IND = 'Y'";
        return exists(con, sql, regNbr, term);
    }
    
    public static boolean isClassLimitExceed(String facultyId, String sectionId, Connection con) throws Exception
    {
        String sql =
            "SELECT 1 FROM UCP.CREDIT_LOAD_DEFINITION CLD, SECTION S, COURSE C " +
            "WHERE CLD.FACULTY_ID = ? AND CLD.CREDIT_HRS = C.CREDIT_HRS AND C.COURSE_ID = S.COURSE_ID " +
            "AND S.SECTION_ID = ? AND CLD.CLASS_LIMIT <= (SELECT COUNT(*) FROM UCP.CLASS_HELD CH " +
            "WHERE S.SECTION_ID = CH.SECTION_ID AND CH.CLASS_TYP <> 'U')";
        return exists(con, sql, facultyId, sectionId);
    }
    
    public static boolean sendSMS(String regNbr, String msg, LocalSession session) throws Exception
    {
        String mobileSql =
            "SELECT SM.MOBILE_NBR, U.UNI_ID FROM STUDENT_MOBILE SM, UCP.STUDENT S, UCP.PROGRAM P, " +
            "UCP.FACULTY F, UCP.CAMPUS C, UCP.UNIVERSITY U WHERE SM.REG_NBR = S.REG_NBR " +
            "AND S.PROG_ID = P.PROG_ID AND P.FACULTY_ID = F.FACULTY_ID AND F.CMP_ID = C.CMP_ID " +
            "AND C.UNI_ID = U.UNI_ID AND SM.REG_NBR = ?";
        try(PreparedStatement selectStmt = session.con.prepareStatement(mobileSql))
        {
            selectStmt.setString(1, regNbr);
            try(ResultSet rs = selectStmt.executeQuery())
            {
                if(!rs.next()) return false;
                String mobile = rs.getString(1);
                String mask = rs.getInt(2) > 1 ? "PGC" : "UCP";
                String insertSql =
                    "INSERT INTO BULK_SMS(BULK_SMS_ID, MOBILE_NBR, SMS_MSG, STATUS_IND, TMS, USER_NME, SMS_TYP, MASK) " +
                    "VALUES(SEQ_BULK_SMS_ID.NEXTVAL, ?, ?, 'P', SYSDATE, ?, 'ABSENT', ?)";
                try(PreparedStatement insertStmt = session.con.prepareStatement(insertSql))
                {
                    bind(insertStmt, mobile, msg, session.user, mask);
                    return insertStmt.executeUpdate() > 0;
                }
            }
        }
        catch(Exception e)
        {
            return false;
        }
    }
    
    @Deprecated
    public static int getCourseFee1(String reg_Nbr, long courseId, Connection con) throws Exception
    {
        String batchFeeSql =
            "SELECT BF.PER_COURSE_AMT FROM UCP.COURSE C, UCP.BATCH_FEE BF, UCP.BATCH B, UCP.PROGRAM P, UCP.STUDENT S " +
            "WHERE C.CREDIT_HRS = BF.CREDIT_HRS AND BF.BATCH_ID = B.BATCH_ID AND B.PROG_ID = P.PROG_ID " +
            "AND P.PROG_ID = S.PROG_ID AND S.REG_NBR = ? AND SUBSTR(S.REG_NBR, 3, 3) = B.TERM_CDE AND C.COURSE_ID = ?";
        Integer fee = queryInteger(con, batchFeeSql, reg_Nbr, courseId);
        if(fee != null) return fee;

        String fallbackSql =
            "SELECT NVL((SELECT SF.FEE FROM PREREQ PR, PROGRAM P, SEMESTER_FEE SF, STUDENT S " +
            "WHERE PR.COURSE_ID = ? AND PR.PROG_ID = S.PROG_ID AND S.REG_NBR = ? AND PR.COURSE_NBR = SF.SEMESTER " +
            "AND P.PROG_ABBR = SF.PROG_ABBR AND SF.CMP_PREFIX = SUBSTR(S.REG_NBR, 1, 2) " +
            "AND SUBSTR(S.REG_NBR, 3, 3) = BATCH_TERM AND PR.PROG_ID = P.PROG_ID), " +
            "(SELECT PER_COURSE_AMT FROM BATCH B, PROGRAM P, REGISTRATION_SCHEDULE RS, STUDENT S " +
            "WHERE B.PROG_ID = P.PROG_ID AND S.REG_NBR = ? AND B.BATCH_ID = RS.BATCH_ID AND S.PROG_ID = P.PROG_ID " +
            "AND B.TERM_CDE = SUBSTR(S.REG_NBR, 3, 3) AND RS.REG_SCHED_ID = (SELECT MAX(REG_SCHED_ID) " +
            "FROM UCP.REGISTRATION_SCHEDULE WHERE BATCH_ID = B.BATCH_ID))) FEE FROM DUAL";
        fee = queryInteger(con, fallbackSql, courseId, reg_Nbr, reg_Nbr);
        if(fee == null) throw new Exception("Fee not defined.");
        return fee;
    }
    
    public static int getCourseFee(String reg_Nbr, long courseId, Connection con) throws Exception
    {
        String term = reg_Nbr != null && reg_Nbr.length() >= 5 ? reg_Nbr.substring(2, 5) : "";
        String cmpPrefix = reg_Nbr != null && reg_Nbr.length() >= 2 ? reg_Nbr.substring(0, 2) : "";
        boolean hasTermFee = exists(con,
            "SELECT 1 FROM UCP.BATCH_TERM_FEE BTF, UCP.BATCH B, UCP.STUDENT S " +
            "WHERE BTF.BATCH_ID = B.BATCH_ID AND B.PROG_ID = S.PROG_ID AND S.REG_NBR = ? AND B.TERM_CDE = SUBSTR(S.REG_NBR,3,3)", reg_Nbr);

        if(hasTermFee)
        {
            String sql =
                "SELECT X.PER_COURSE_AMT FROM (SELECT BF.PER_COURSE_AMT FROM UCP.COURSE C " +
                "JOIN UCP.BATCH_TERM_FEE BF ON BF.CREDIT_HRS = C.CREDIT_HRS JOIN UCP.TERM T ON T.TERM_CDE = BF.TERM_CDE " +
                "JOIN UCP.BATCH B ON B.BATCH_ID = BF.BATCH_ID JOIN UCP.PROGRAM P ON P.PROG_ID = B.PROG_ID " +
                "JOIN UCP.STUDENT S ON S.PROG_ID = P.PROG_ID WHERE S.REG_NBR = ? AND B.TERM_CDE = ? AND C.COURSE_ID = ? " +
                "ORDER BY DECODE(BF.TERM_CDE, C.TERM_CDE, 1, 2), T.START_DTE DESC) X WHERE ROWNUM = 1";
            Integer fee = queryInteger(con, sql, reg_Nbr, term, courseId);
            if(fee != null) return fee;
            throwFeeNotFound(con, courseId);
        }

        Integer fee = queryInteger(con,
            "SELECT BF.PER_COURSE_AMT FROM UCP.COURSE C, UCP.BATCH_FEE BF, UCP.BATCH B, UCP.PROGRAM P, UCP.STUDENT S " +
            "WHERE C.CREDIT_HRS = BF.CREDIT_HRS AND BF.BATCH_ID = B.BATCH_ID AND B.PROG_ID = P.PROG_ID AND P.PROG_ID = S.PROG_ID " +
            "AND S.REG_NBR = ? AND B.TERM_CDE = ? AND C.COURSE_ID = ?", reg_Nbr, term, courseId);
        if(fee != null) return fee;

        String fallbackSql =
            "SELECT NVL((SELECT SF.FEE FROM PREREQ PR, PROGRAM P, SEMESTER_FEE SF, STUDENT S " +
            "WHERE PR.COURSE_ID = ? AND PR.PROG_ID = S.PROG_ID AND S.REG_NBR = ? AND PR.COURSE_NBR = SF.SEMESTER " +
            "AND P.PROG_ABBR = SF.PROG_ABBR AND SF.CMP_PREFIX = ? AND BATCH_TERM = ? AND PR.PROG_ID = P.PROG_ID), " +
            "(SELECT PER_COURSE_AMT FROM BATCH B, PROGRAM P, REGISTRATION_SCHEDULE RS, STUDENT S " +
            "WHERE B.PROG_ID = P.PROG_ID AND S.REG_NBR = ? AND B.BATCH_ID = RS.BATCH_ID AND S.PROG_ID = P.PROG_ID " +
            "AND B.TERM_CDE = ? AND RS.REG_SCHED_ID = (SELECT MAX(REG_SCHED_ID) FROM UCP.REGISTRATION_SCHEDULE WHERE BATCH_ID = B.BATCH_ID))) FEE FROM DUAL";
        fee = queryInteger(con, fallbackSql, courseId, reg_Nbr, cmpPrefix, term, reg_Nbr, term);
        if(fee == null) throw new Exception("Fee not defined.");
        return fee;
    }

    public static int getCourseFee(long candId, long courseId, Connection con) throws Exception
    {
        boolean hasTermFee = exists(con,
            "SELECT 1 FROM UCP.BATCH_TERM_FEE BTF, UCP.BATCH B, UCP.OFFERED_PROGRAM OP, UCP.CANDIDATE C " +
            "WHERE BTF.BATCH_ID = B.BATCH_ID AND B.PROG_ID = OP.PROG_ID AND BTF.TERM_CDE = OP.TERM_CDE " +
            "AND B.TERM_CDE = OP.TERM_CDE AND C.OP_ID = OP.OP_ID AND C.CANDIDATE_ID = ?", candId);

        if(hasTermFee)
        {
            Integer fee = queryInteger(con,
                "SELECT BF.PER_COURSE_AMT FROM UCP.COURSE C, UCP.BATCH_TERM_FEE BF, UCP.BATCH B, UCP.OFFERED_PROGRAM OP, UCP.CANDIDATE CAN " +
                "WHERE C.CREDIT_HRS = BF.CREDIT_HRS AND BF.BATCH_ID = B.BATCH_ID AND B.PROG_ID = OP.PROG_ID AND CAN.OP_ID = OP.OP_ID " +
                "AND BF.TERM_CDE = C.TERM_CDE AND C.TERM_CDE = OP.TERM_CDE AND B.TERM_CDE = OP.TERM_CDE " +
                "AND CAN.CANDIDATE_ID = ? AND C.COURSE_ID = ?", candId, courseId);
            if(fee != null) return fee;
            throwFeeNotFound(con, courseId);
        }

        Integer fee = queryInteger(con,
            "SELECT BF.PER_COURSE_AMT FROM UCP.COURSE C, UCP.BATCH_FEE BF, UCP.BATCH B, UCP.OFFERED_PROGRAM OP, UCP.CANDIDATE CAN " +
            "WHERE C.CREDIT_HRS = BF.CREDIT_HRS AND BF.BATCH_ID = B.BATCH_ID AND B.PROG_ID = OP.PROG_ID AND CAN.OP_ID = OP.OP_ID " +
            "AND B.TERM_CDE = OP.TERM_CDE AND C.TERM_CDE = OP.TERM_CDE AND CAN.CANDIDATE_ID = ? AND C.COURSE_ID = ?", candId, courseId);
        if(fee != null) return fee;

        String fallbackSql =
            "SELECT NVL((SELECT SF.FEE FROM UCP.PREREQ PR, UCP.PROGRAM P, UCP.SEMESTER_FEE SF, UCP.CANDIDATE CAN, UCP.OFFERED_PROGRAM OP " +
            "WHERE PR.COURSE_ID = ? AND CAN.CANDIDATE_ID = ? AND CAN.OP_ID = OP.OP_ID AND OP.PROG_ID = P.PROG_ID " +
            "AND PR.COURSE_NBR = SF.SEMESTER AND P.PROG_ABBR = SF.PROG_ABBR AND PR.PROG_ID = P.PROG_ID), " +
            "(SELECT PER_COURSE_AMT FROM UCP.BATCH B, UCP.PROGRAM P, UCP.REGISTRATION_SCHEDULE RS, UCP.CANDIDATE CAN, UCP.OFFERED_PROGRAM OP " +
            "WHERE B.PROG_ID = P.PROG_ID AND CAN.CANDIDATE_ID = ? AND B.BATCH_ID = RS.BATCH_ID AND CAN.OP_ID = OP.OP_ID " +
            "AND OP.PROG_ID = P.PROG_ID AND B.TERM_CDE = OP.TERM_CDE AND RS.REG_SCHED_ID = (SELECT MAX(REG_SCHED_ID) " +
            "FROM UCP.REGISTRATION_SCHEDULE WHERE BATCH_ID = B.BATCH_ID))) FEE FROM DUAL";
        fee = queryInteger(con, fallbackSql, courseId, candId, candId);
        if(fee == null) throw new Exception("Fee not defined.");
        return fee;
    }
}