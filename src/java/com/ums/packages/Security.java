package com.ums.packages;

import java.security.*;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Calendar;
import java.util.GregorianCalendar;
import jakarta.servlet.http.HttpServletRequest;

public class Security 
{
    private static final String ADMIN_MODE = "Admin";
    private static final String STUDENT_MODE = "Student";
    private static final String WEBMASTER_MODE = "Webmaster";
    private static final String STATUS_FAIL = "Fail";
    private static final String STATUS_SUCCESS = "Success";
    private static final String SHA_ALGORITHM = "SHA3-512";
    private static final int MAX_WRONG_ATTEMPTS = 5;
    private static final int WRONG_ATTEMPT_MINUTES = 60;
    private static final String SECURITY_PROVIDER_BOUNCY_CASTLE = "BC";

    private String errorMessage = null;

    public Security(){}
    public String getErrorMsg(){return errorMessage;}
    public String getErrorMessage(){return errorMessage;}
    public void setErrorMessage(String errorMessage){this.errorMessage = errorMessage;}
    private void log(String message){System.out.println(new java.util.Date() + "::Verification::" + message);    }
    
    public void logWrongAttempt(Connection con,HttpServletRequest req,String usr,String pass,String type,String status)
    {
        if(con == null) return;
        String sql = "INSERT INTO UCP.WRONG_ATTEMPTS VALUES(SYSDATE,?,?,?,?,?,?,?)";
        try(PreparedStatement ps = con.prepareStatement(sql))
        {
            ps.setString(1,nvl(usr));
            ps.setString(2,"");
            ps.setString(3,req == null ? "" : nvl(req.getRemoteAddr()));
            ps.setString(4,req == null ? "" : nvl(req.getRemoteHost()));
            ps.setString(5,req == null ? "" : nvl(req.getRemoteUser()));
            ps.setString(6,nvl(type));
            ps.setString(7,nvl(status));
            ps.executeUpdate();
            if(!con.getAutoCommit()) con.commit();
        }catch(Exception ex)
        {
            log("Unable to save wrong attempt for user [" + nvl(usr) + "]: " + ex.getMessage());
        }
    }

    public boolean verify(Connection con,String user,String password,String mode,HttpServletRequest req)
    {
        errorMessage = null;
        if(con == null)
        {
            errorMessage = "Database connection is not available";
            return false;
        }

        user = nvl(user).toUpperCase();
        mode = nvl(mode);
        if(user.length() == 0 || password == null)
        {
            errorMessage = "Invalid Username/Password";
            logWrongAttempt(con,req,user,"",mode,STATUS_FAIL);
            return false;
        }

        try
        {
            if(ADMIN_MODE.equalsIgnoreCase(mode)) return verifyAdmin(con,user,password,req);
            if(STUDENT_MODE.equalsIgnoreCase(mode)) return verifyStudent(con,user,password,req);
            if(WEBMASTER_MODE.equalsIgnoreCase(mode)) return verifyWebmaster(con,user,password,req);
            errorMessage = "Invalid login mode";
            return false;
        }
        catch(Exception ex)
        {
            logWrongAttempt(con,req,user,"",mode,STATUS_FAIL);
            errorMessage = "Invalid Username/Password";
            log("Error while verifying user [" + user + "] in mode [" + mode + "]: " + ex.getMessage());
            return false;
        }
    }
    
    public String getDigest(String algorithm, String message) throws NoSuchAlgorithmException, NoSuchProviderException 
    {
        MessageDigest messageDigest = MessageDigest.getInstance(algorithm, SECURITY_PROVIDER_BOUNCY_CASTLE);
        messageDigest.reset();
        messageDigest.update(message.getBytes());
        return byteArrayToHexString(messageDigest.digest());
    }  
    
    public static String byteArrayToHexString(byte[] b) 
    {
        StringBuffer sb = new StringBuffer(b.length * 2);
        for (int i = 0; i < b.length; i++) 
        {
            int v = b[i] & 0xff;
            if (v < 16)  sb.append('0');
            sb.append(Integer.toHexString(v));
        }
        return sb.toString().toUpperCase();
    }   
    
    public String encrypt(String str) 
    {
        if (str == null || str.length() == 0)   throw new IllegalArgumentException( "String to encrypt cannot be null or zero length");
        StringBuffer hexString = new StringBuffer();

        try
        {
            MessageDigest md = MessageDigest.getInstance("MD5");
            md.update(str.getBytes());
            byte[] hash = md.digest();
            for (int i = 0; i < hash.length; i++) 
            {
                if ((0xff & hash[i]) < 0x10) hexString.append("0" + Integer.toHexString((0xFF & hash[i])));
                else  hexString.append(Integer.toHexString(0xFF & hash[i]));
            }
        } catch (NoSuchAlgorithmException e) 
        {
            System.out.println(e.toString());
        }
        return hexString.toString();
    }    

    private boolean verifyAdmin(Connection con,String user,String encryptedPassword,HttpServletRequest req) throws Exception
    {
        String plainPassword = com.ums.packages.Security.decryptData(encryptedPassword);

        if(hasIllegalChars(user))
        {
            errorMessage = "Illegal characters are not allowed in Username";
            logWrongAttempt(con,req,user,"",ADMIN_MODE,STATUS_FAIL);
            return false;
        }

        boolean newPasswordUser = exists(con,"SELECT 1 FROM UCP.NEW_WEB_USERS WHERE USER_NME = ?",user);
        String databasePassword;
        if(newPasswordUser)
        {
            databasePassword = getDigest(SHA_ALGORITHM,plainPassword);
        } else
        {
            databasePassword = encrypt(plainPassword);
            databasePassword = encrypt(databasePassword);
        }

        String sql;
        if(newPasswordUser)
        {
            sql = "SELECT U.ACTIVE_IND_TYPE,U.USER_CLASS_IND,U.USER_NME,NU.USER_PASSWORD " +
                  "FROM UCP.WEB_USERS U JOIN UCP.NEW_WEB_USERS NU ON NU.USER_NME = U.USER_NME " +
                  "WHERE U.USER_NME = ? AND NU.USER_PASSWORD = ?";
        }else
        {
            sql = "SELECT ACTIVE_IND_TYPE,USER_CLASS_IND,USER_NME,USER_PASSWORD " +
                  "FROM UCP.WEB_USERS WHERE USER_NME = ? AND USER_PASSWORD = ?";
        }

        try(PreparedStatement ps = con.prepareStatement(sql))
        {
            ps.setString(1,user);
            ps.setString(2,databasePassword);
            try(ResultSet rs = ps.executeQuery())
            {
                if(!rs.next())
                {
                    errorMessage = "Invalid Username/Password";
                    logWrongAttempt(con,req,user,"",ADMIN_MODE,STATUS_FAIL);
                    return false;
                }

                if(!"Y".equalsIgnoreCase(rs.getString("ACTIVE_IND_TYPE")))
                {
                    errorMessage = "Your account is disabled";
                    logWrongAttempt(con,req,user,"",ADMIN_MODE,STATUS_FAIL);
                    return false;
                }
            }
        }
        return true;
    }

    private boolean verifyStudent(Connection con,String user,String password,HttpServletRequest req) throws Exception
    {
        if(hasIllegalChars(user))
        {
            errorMessage = "Illegal characters are not allowed in Username";
            logWrongAttempt(con,req,user,"",STUDENT_MODE,STATUS_FAIL);
            return false;
        }
        if(exists(con,"SELECT 1 FROM UCP.PASSWORDS WHERE REG_NBR = ? AND PASSWORD_TXT = ?",user,password)) return true;
        errorMessage = "Invalid Username/Password";
        logWrongAttempt(con,req,user,"",STUDENT_MODE,STATUS_FAIL);
        blockStudentAfterRepeatedFailures(con,user);
        return false;
    }

    private boolean verifyWebmaster(Connection con,String user,String password,HttpServletRequest req)
    {
        errorMessage = "Webmaster login is disabled";
        logWrongAttempt(con,req,user,"",WEBMASTER_MODE,STATUS_FAIL);
        return false;
    }

    private void blockStudentAfterRepeatedFailures(Connection con,String user) throws SQLException
    {
        String countSql ="SELECT COUNT(*) FROM UCP.WRONG_ATTEMPTS " +
            "WHERE STATUS = 'Fail' " +
            "AND USER_NME = ? " +
            "AND DTE >= SYSDATE-(?/1440) " +
            "AND DTE > NVL((SELECT MAX(LOGIN_DTE) FROM UCP.USER_SESSION WHERE USER_NME = ? AND LOGIN_DTE >= SYSDATE-(?/1440)),SYSDATE-(?/1440))";

        int attemptCount = 0;
        try(PreparedStatement ps = con.prepareStatement(countSql))
        {
            ps.setString(1,user);
            ps.setInt(2,WRONG_ATTEMPT_MINUTES);
            ps.setString(3,user);
            ps.setInt(4,WRONG_ATTEMPT_MINUTES);
            ps.setInt(5,WRONG_ATTEMPT_MINUTES);

            try(ResultSet rs = ps.executeQuery())
            {
                if(rs.next()) attemptCount = rs.getInt(1);
            }
        }

        if(attemptCount <= MAX_WRONG_ATTEMPTS) return;
        errorMessage = "Your account has been blocked due to excessive wrong attempts.";

        String blockSql ="INSERT INTO UCP.USER_BLOCK_LIST (USER_NME,MESSAGE) " +
            "SELECT ?,? FROM DUAL " +
            "WHERE NOT EXISTS (SELECT 1 FROM UCP.USER_BLOCK_LIST WHERE USER_NME = ?)";
        try(PreparedStatement ps = con.prepareStatement(blockSql))
        {
            ps.setString(1,user);
            ps.setString(2,errorMessage);
            ps.setString(3,user);
            ps.executeUpdate();
            if(!con.getAutoCommit()) con.commit();
        }
    }

    public String decode(String password)
    {
        if(password == null || password.length() == 0) return "";
        String[] text = password.split(",");
        if(text.length == 0 || text.length % 3 != 0) throw new IllegalArgumentException("Invalid encoded password format");
        int[] temp = new int[text.length / 3];
        int[] temp2 = new int[text.length / 3];
        char[] decrypted = new char[text.length / 3];
        int j = 0;
        for(int i = 0;i < text.length;i += 3)
        {
            temp[j] = Integer.parseInt(text[i]);
            temp2[j] = Integer.parseInt(text[i + 1]);
            if("=".equals(text[i + 2])) decrypted[j] = (char)(Math.sqrt(temp[j]) - temp2[j]);
            else decrypted[j] = (char)(temp[j] + temp2[j]);
            j++;
        }
        return new String(decrypted);
    }

    public boolean hasIllegalChars(String value)
    {
        if(value == null) return true;
        return value.indexOf("'") >= 0 || value.indexOf("=") >= 0 || value.indexOf("\"") >= 0 || value.indexOf("-") >= 0 || value.indexOf("*") >= 0;
    }

    public static boolean hasSectionRights(boolean hasRightOnAllSections,String userName,String sectionId,Connection con) throws Exception
    {
        if(con == null) throw new Exception("Database connection is required");
        if(isBlank(userName) || isBlank(sectionId)) return false;

        long sectionIdValue;
        try
        {
            sectionIdValue = Long.parseLong(sectionId.trim());
        }catch(NumberFormatException ex)
        {
            return false;
        }

        if(hasRightOnAllSections)
        {
            String sql =
                "SELECT 1 " +
                "FROM UCP.SECTION S " +
                "JOIN UCP.COURSE C ON C.COURSE_ID = S.COURSE_ID " +
                "JOIN UCP.TEACHER T ON T.TCHR_ID = S.TCHR_ID " +
                "JOIN UCP.SECTION_FACULTY SF ON SF.SECTION_ID = S.SECTION_ID " +
                "WHERE SF.FACULTY_ID IN (SELECT FACULTY_ID FROM UCP.WEB_USERS_FACULTY WHERE USER_NME = ?) " +
                "AND T.STATUS_IND = 'A' AND S.SECTION_ID = ?";

            return exists(con,sql,userName,Long.valueOf(sectionIdValue));
        }

        String sql =
            "SELECT S.SECTION_ID " +
            "FROM UCP.SECTION S " +
            "JOIN UCP.COURSE C ON C.COURSE_ID = S.COURSE_ID " +
            "JOIN UCP.TEACHER T ON T.TCHR_ID = S.TCHR_ID " +
            "JOIN UCP.WEB_USERS W ON W.TCHR_ID = T.TCHR_ID " +
            "WHERE T.STATUS_IND = 'A' " +
            "AND S.TCHR_ID = (SELECT TCHR_ID FROM UCP.SECTION WHERE SECTION_ID = ?) " +
            "AND S.SECTION_ID = ? AND W.USER_NME = ? " +
            "UNION " +
            "SELECT S.SECTION_ID " +
            "FROM UCP.SECTION S " +
            "JOIN UCP.COURSE C ON C.COURSE_ID = S.COURSE_ID " +
            "JOIN UCP.TEACHER T ON T.TCHR_ID = S.TCHR_ID " +
            "JOIN UCP.USER_ALLOWED_SECTIONS UAS ON UAS.SECTION_ID = S.SECTION_ID " +
            "WHERE UAS.CLASS_ACT_IND = 'Y' AND T.STATUS_IND = 'A' " +
            "AND UAS.USER_NME = ? AND S.SECTION_ID = ?";
        return exists(con,sql,Long.valueOf(sectionIdValue),Long.valueOf(sectionIdValue),userName,userName,Long.valueOf(sectionIdValue));
    }


    public boolean isValidPassword(String password,Connection con) throws SQLException,Exception
    {
        if(password == null || password.length() == 0)
        {
            errorMessage = "Password is required";
            return false;
        }

        int digitCount = 0,charCount = 0;

        for(int i = 0;i < password.length();i++)
        {
            char ch = password.charAt(i);
            if(Character.isDigit(ch)) digitCount++;
            if(Character.isLetter(ch)) charCount++;
        }
        if(digitCount >= 3 && charCount >= 1) return true;
        errorMessage = "Your new password must contain at least 3 digits and 1 character, for example abc197, 197abc or 1a2b3c.";
        return false;
    }

    private static boolean exists(Connection con,String sql,Object... params) throws SQLException
    {
        try(PreparedStatement ps = con.prepareStatement(sql))
        {
            bind(ps,params);

            try(ResultSet rs = ps.executeQuery())
            {
                return rs.next();
            }
        }
    }

    private static void bind(PreparedStatement ps,Object... params) throws SQLException
    {
        if(params == null) return;
        for(int i = 0;i < params.length;i++) ps.setObject(i + 1,params[i]);
    }

    private static String nvl(String value) { return value == null ? "" : value.trim();}
    private static boolean isBlank(String value){return value == null || value.trim().length() == 0;}

    public static String decryptData(String password)
    {
        String[] text = password.split(",");
        int[] temp = new int[text.length/3];
        int[] temp2 = new int[text.length/3];
        char[] decrypted = new char[text.length/3];
    
        password = "";
    
        int j = 0;
        for (int i=0 ; i<text.length ; i+=3 ) 
        {
            temp[j] = Integer.parseInt(text[i]);
            temp2[j] = Integer.parseInt(text[i+1]);
      
            if(text[i+2].equals("=")) decrypted[j] = ((char)(Math.sqrt(temp[j]) - temp2[j]));
            else decrypted[j] = ((char)(temp[j] + temp2[j]));
            j++;
        }
        password = new String(decrypted);
        return password;
    }    
}