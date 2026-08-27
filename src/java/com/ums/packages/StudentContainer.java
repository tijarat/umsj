package com.ums.packages;

import com.ums.functions.Functions;
import java.awt.Image;
import java.io.File;
import java.io.FileInputStream;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Savepoint;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import javax.swing.ImageIcon;

public class StudentContainer
{
    private static final Set<String> STUDENT_MAJORS = Set.of("BCS", "BS", "BS-MS", "BS-MSSE", "BS-SE", "BS-TE", "MCS", "MS", "MS-SE");

    public java.sql.Date stdRegDate;
    public java.sql.Date stdDOB;

    public final List<String> oldRegNbrs = new ArrayList<>();
    public final List<String> oldMajors = new ArrayList<>();
    public final List<ShowedCourse> showedCourses = new ArrayList<>();
    public final List<String> rights = new ArrayList<>();

    public String oldRegNbr = "";
    public String candId = "";
    public String regNbr = "";
    public String password = "";
    public String currentTerm = "";
    public String workingTerm = "";
    public String RegStatus = "InProcess";
    public String AddDropRegStatus = "InProcess";
    public String stdName = "";
    public String major = "";
    public String majorId = "";
    public String vMajor = "";
    public String vMajorId = "";
    public String stdTerm = "";
    public String stdAddDrpDetail = "";
    public String tentRegTerm = "";
    public String fatherNme = "";
    public String mailingAdd1 = "";
    public String mailingAdd2 = "";
    public String mailingAdd3 = "";
    public String mailingCity = "";
    public String mailingPhone = "";
    public String personalPhone = "";
    public String sex = "";
    public String regDueDate = "";
    public String faculty = "";

    private String cmpId = "";

    public int stdBatchNbr;
    public int stdBatchId;
    public int courseAmount;
    public int[][] courseAmounts;
    public int adminFee;
    public int lastEvent;
    public int totalCreditEarned;
    public int totalDegreeEarned;
    public int totalDegreeCourseEarned;
    public int totalSpecCourseEarned;
    public int regSemesterNbr;
    public int courseLimit;
    public int reqCourseCount;
    public int canTakeCourseCount;
    public Double cgpa;
    public double levelCgpa;
    public boolean directStudent;
    public boolean duesDefaulter;
    public boolean alreadyRegister;
    public boolean alreadyAddDrop;
    public boolean lastEventConfirmed;
    public boolean clearByAdvisor;
    public boolean onSemesterBreak;
    public boolean isConCGPADefaulter;
    public boolean isConGPADefaulter;
    public boolean isAfterR03;
    public boolean isInstChallanPrinted;
    public Image studentImage;
    public byte[] stdImgByte;
    public String nic = "";
    public String fatherNic = "";
    public String fatherNtn = "";
    public String kinshipInd = "";
    public String sportsInd = "";
    public String pwwf = "";
    public String mobileNbr = "";
    public String uniRegNbr = "";
    public String regDte = "";
    public String specialization = "";
    public String oldReg = "";
    public int uniId;

    private int sessionId;

    public StudentContainer(){}

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

    private static int queryInt(Connection con, int defaultValue, String sql, Object... params) throws SQLException
    {
        try(PreparedStatement stmt = con.prepareStatement(sql))
        {
            bind(stmt, params);
            try(ResultSet rs = stmt.executeQuery())
            {
                if(!rs.next()) return defaultValue;
                int value = rs.getInt(1);
                return rs.wasNull() ? defaultValue : value;
            }
        }
    }

    private static double queryDouble(Connection con, double defaultValue, String sql, Object... params) throws SQLException
    {
        try(PreparedStatement stmt = con.prepareStatement(sql))
        {
            bind(stmt, params);
            try(ResultSet rs = stmt.executeQuery())
            {
                if(!rs.next()) return defaultValue;
                double value = rs.getDouble(1);
                return rs.wasNull() ? defaultValue : value;
            }
        }
    }

    private static String safe(String value){return value == null ? "" : value;}

    private static double parseDouble(String value)
    {
        if(value == null || value.trim().isEmpty()) return 0.0;
        try { return Double.parseDouble(value.trim()); }
        catch(NumberFormatException e) { return 0.0; }
    }

    private static int applyDiscount(int amount, double percentage)
    {
        if(percentage <= 0) return amount;
        return (int) Math.ceil(amount - (amount * percentage / 100.0));
    }

    private static int callInt(Connection con, String call, Object... params) throws SQLException
    {
        try(CallableStatement cs = con.prepareCall(call))
        {
            cs.registerOutParameter(1, Types.DOUBLE);
            for(int i = 0; i < params.length; i++) cs.setObject(i + 2, params[i]);
            cs.execute();
            return (int) cs.getDouble(1);
        }
    }

    private static String quoteSqlValue(String value){return "'" + safe(value).replace("'", "''") + "'";}

    private static String toSqlInList(String firstValue, List<String> additionalValues)
    {
        StringBuilder result = new StringBuilder("(").append(quoteSqlValue(firstValue));
        for(String value : additionalValues) result.append(",").append(quoteSqlValue(value));
        return result.append(")").toString();
    }

    private static boolean ownsTransaction(Connection con) throws SQLException{ return con.getAutoCommit();}

    private static void rollback(Connection con, boolean ownTransaction, Savepoint savepoint)
    {
        try
        {
            if(ownTransaction) con.rollback();
            else if(savepoint != null) con.rollback(savepoint);
        }catch(SQLException ignored){}
    }

    public void addShowedCourses(String cCode, int cNbr, int sNbr){showedCourses.add(new ShowedCourse(cCode, cNbr, sNbr));}

    public boolean canTakeCourse(String cde, ReserveSection srs, int cnbr)
    {
        for(ShowedCourse sc : showedCourses)
        {
            if(sc.courseSemester < cnbr && srs.advisorGetSection(sc.courseCde) == null) return false;
            if(sc.courseSemester == cnbr) return true;
        }
        return false;
    }


    public boolean canDropCourse(String cde, ReserveSection srs, int cnbr)
    {
        for(int i = showedCourses.size() - 1; i >= 0; i--)
        {
            ShowedCourse sc = showedCourses.get(i);
            if(sc.courseSemester > cnbr && srs.getSection(sc.courseCde) != null) return false;
            if(sc.courseSemester == cnbr) return true;
        }
        return false;
    }

    public int getCandidateTutionFee(Connection con, String candId, String term, String discPer) throws Exception
    {
        long candidateId = Long.parseLong(candId);
        double discountPercentage = parseDouble(discPer);
        int netTuitionFee = 0;

        String sql =
            "SELECT DISTINCT C.COURSE_ID, NVL(SC.DISCOUNT_IND, '-') DISC, NVL(SC.FEE_AMT, -1) FEE_AMT " +
            "FROM COURSE C " +
            "JOIN PREREQ P ON P.COURSE_ID = C.COURSE_ID AND P.COURSE_NBR = 1 " +
            "JOIN OFFERED_PROGRAM O ON O.PROG_ID = P.PROG_ID AND O.TERM_CDE = C.TERM_CDE " +
            "JOIN UCP.BATCH B ON B.PROG_ID = O.PROG_ID AND B.TERM_CDE = O.TERM_CDE " +
            "LEFT JOIN SPECIAL_COURSE SC ON SC.COURSE_ID = C.COURSE_ID " +
            "WHERE O.OP_ID = (SELECT OP_ID FROM CANDIDATE WHERE CANDIDATE_ID = ?)";

        try(PreparedStatement stmt = con.prepareStatement(sql))
        {
            stmt.setLong(1, candidateId);
            try(ResultSet rs = stmt.executeQuery())
            {
                while(rs.next())
                {
                    long courseId = rs.getLong("COURSE_ID");
                    int specialFee = rs.getInt("FEE_AMT");
                    boolean discountable = "Y".equalsIgnoreCase(rs.getString("DISC"));
                    int grossFee = specialFee < 0? Functions.getCourseFee(candidateId, courseId, con) : specialFee;
                    if(specialFee < 0 || discountable) grossFee = applyDiscount(grossFee, discountPercentage);
                    netTuitionFee += grossFee;
                }
            }
        }catch(SQLException e)
        {
            throw new Exception("Error in getCandidateTutionFee for candidate ID " + candId + ": " + e.getMessage(), e);
        }
        return netTuitionFee;
    }

    private static class RegistrationCourse
    {
        private final long courseId;
        private final int grossFee;
        private final int netFee;
        private RegistrationCourse(long courseId, int grossFee, int netFee)
        {
            this.courseId = courseId;
            this.grossFee = grossFee;
            this.netFee = netFee;
        }
    }

    public int newStudentRegistration(Connection con, String candId, String term, String discPer) throws Exception
    {
        long candidateId = Long.parseLong(candId);
        double discountPercentage = parseDouble(discPer);
        List<RegistrationCourse> courses = new ArrayList<>();
        int grossTotal = 0;
        int netTotal = 0;
        String courseSql =
            "SELECT DISTINCT C.COURSE_ID, NVL(SC.DISCOUNT_IND, '-') DISC, NVL(SC.FEE_AMT, -1) FEE_AMT " +
            "FROM COURSE C " +
            "JOIN PREREQ P ON P.COURSE_ID = C.COURSE_ID AND P.COURSE_NBR = 1 " +
            "JOIN OFFERED_PROGRAM O ON O.PROG_ID = P.PROG_ID AND O.TERM_CDE = C.TERM_CDE " +
            "JOIN UCP.BATCH B ON B.PROG_ID = O.PROG_ID AND B.TERM_CDE = O.TERM_CDE " +
            "LEFT JOIN SPECIAL_COURSE SC ON SC.COURSE_ID = C.COURSE_ID " +
            "WHERE O.OP_ID = (SELECT OP_ID FROM CANDIDATE WHERE CANDIDATE_ID = ?)";
        try(PreparedStatement stmt = con.prepareStatement(courseSql))
        {
            stmt.setLong(1, candidateId);
            try(ResultSet rs = stmt.executeQuery())
            {
                while(rs.next())
                {
                    long courseId = rs.getLong("COURSE_ID");
                    int specialFee = rs.getInt("FEE_AMT");
                    boolean discountable = "Y".equalsIgnoreCase(rs.getString("DISC"));
                    int grossFee = specialFee < 0 ? Functions.getCourseFee(candidateId, courseId, con) : specialFee;
                    int netFee = specialFee < 0 || discountable? applyDiscount(grossFee, discountPercentage): grossFee;
                    courses.add(new RegistrationCourse(courseId, grossFee, netFee));
                    grossTotal += grossFee;
                    netTotal += netFee;
                }
            }
        }

        String sectionSql =
            "SELECT S.SECTION_ID " +
            "FROM UCP.COURSE C, UCP.TEACHER T, UCP.SECTION S, SECTION_FACULTY SF, FACULTY F " +
            "WHERE S.COURSE_ID = C.COURSE_ID AND S.TCHR_ID = T.TCHR_ID " +
            "AND S.SECTION_ID = SF.SECTION_ID(+) AND C.TERM_CDE = ? " +
            "AND F.FACULTY_ID IN (SELECT P1.FACULTY_ID FROM CANDIDATE C1, OFFERED_PROGRAM OP1, PROGRAM P1 " +
            "WHERE C1.OP_ID = OP1.OP_ID AND OP1.PROG_ID = P1.PROG_ID AND C1.CANDIDATE_ID = ?) " +
            "AND F.FACULTY_ID = SF.FACULTY_ID AND C.COURSE_ID = ? " +
            "AND S.STRENGTH_NBR > (SELECT COUNT(DISTINCT CANDIDATE_ID) FROM NEW_REGISTRATION NR WHERE NR.SECTION_ID = S.SECTION_ID) " +
            "ORDER BY S.SECTION_ID, C.COURSE_CDE, S.SECTION_TXT";

        String insertRegistrationSql = "INSERT INTO NEW_REGISTRATION VALUES(SEQ_NEW_REG_ID.NEXTVAL, ?, ?, ?, 'Y', ?, ?)";
        String insertFeeSql = "INSERT INTO UCP.CANDIDATE_FEE VALUES(?, ?, ?, ?)";
        int totalRegisteredCourses = 0;
        try(PreparedStatement sectionStmt = con.prepareStatement(sectionSql); PreparedStatement insertRegistrationStmt = con.prepareStatement(insertRegistrationSql); PreparedStatement insertFeeStmt = con.prepareStatement(insertFeeSql))
        {
            for(RegistrationCourse course : courses)
            {
                bind(sectionStmt, term, candidateId, course.courseId);
                String sectionId;
                try(ResultSet rs = sectionStmt.executeQuery())
                {
                    if(!rs.next()) throw new Exception("Section is Full or Section not Found. Define Section");
                    sectionId = rs.getString("SECTION_ID");
                }
                bind(insertRegistrationStmt, sectionId, term, course.netFee, candidateId, course.grossFee);
                if(insertRegistrationStmt.executeUpdate() > 0) totalRegisteredCourses++;
            }
            bind(insertFeeStmt, candidateId, term, netTotal, grossTotal);
            insertFeeStmt.executeUpdate();
        }catch(Exception e)
        {
            throw new Exception("Error occurred in StudentContainer.newStudentRegistration: " + e.getMessage(), e);
        }
        return totalRegisteredCourses;
    }

    @Deprecated
    public int newStudentRegistration2(Connection con, String candId, String term, String discPer) throws Exception
    {
        return newStudentRegistration(con, candId, term, discPer);
    }

    @Deprecated
    public int newStudentRegistration1(Connection con, String candId, String term, String discPer) throws Exception
    {
        return newStudentRegistration(con, candId, term, discPer);
    }

    public int updateNewRegistration(LocalSession session, String candId, String term, String discPer) throws Exception
    {
        Connection con = session.con;
        long candidateId = Long.parseLong(candId);
        double discountPercentage = parseDouble(discPer);
        int regularFee = queryInt(con, 0,
            "SELECT RS.PER_COURSE_AMT FROM BATCH B, REGISTRATION_SCHEDULE RS, PROGRAM P, OFFERED_PROGRAM OP, CANDIDATE C " +
            "WHERE B.BATCH_ID = RS.BATCH_ID AND B.PROG_ID = P.PROG_ID AND P.PROG_ID = OP.PROG_ID " +
            "AND OP.OP_ID = C.OP_ID AND C.CANDIDATE_ID = ? AND RS.TERM_CDE = B.TERM_CDE AND B.TERM_CDE = ?",
            candidateId, term);
        regularFee = applyDiscount(regularFee, discountPercentage);
        String coursesSql =
            "SELECT DISTINCT C.COURSE_ID, NVL(SC.FEE_AMT, -1) FEE_AMT, NVL(SC.DISCOUNT_IND, '-') DISC " +
            "FROM COURSE C, PREREQ P, OFFERED_PROGRAM O, SPECIAL_COURSE SC " +
            "WHERE P.COURSE_ID = C.COURSE_ID AND P.COURSE_NBR = 1 AND SC.COURSE_ID(+) = C.COURSE_ID " +
            "AND O.TERM_CDE = C.TERM_CDE AND O.PROG_ID = P.PROG_ID " +
            "AND O.OP_ID = (SELECT OP_ID FROM CANDIDATE WHERE CANDIDATE_ID = ?)";
        String sectionSql =
            "SELECT S.SECTION_ID FROM UCP.COURSE C, UCP.TEACHER T, UCP.SECTION S, SECTION_FACULTY SF, FACULTY F " +
            "WHERE S.COURSE_ID = C.COURSE_ID AND S.TCHR_ID = T.TCHR_ID AND S.SECTION_ID = SF.SECTION_ID(+) " +
            "AND C.TERM_CDE = ? AND F.FACULTY_ID IN (SELECT P1.FACULTY_ID FROM CANDIDATE C1, OFFERED_PROGRAM OP1, PROGRAM P1 " +
            "WHERE C1.OP_ID = OP1.OP_ID AND OP1.PROG_ID = P1.PROG_ID AND C1.CANDIDATE_ID = ?) " +
            "AND F.FACULTY_ID = SF.FACULTY_ID AND C.COURSE_ID = ? ORDER BY C.COURSE_CDE, S.SECTION_TXT";
        String updateSql = "UPDATE NEW_REGISTRATION SET FEE_AMT = ? WHERE CANDIDATE_ID = ? AND SECTION_ID = ?";

        int updated = 0;
        try(PreparedStatement coursesStmt = con.prepareStatement(coursesSql); PreparedStatement sectionStmt = con.prepareStatement(sectionSql); PreparedStatement updateStmt = con.prepareStatement(updateSql))
        {
            coursesStmt.setLong(1, candidateId);
            try(ResultSet rs = coursesStmt.executeQuery())
            {
                while(rs.next())
                {
                    long courseId = rs.getLong("COURSE_ID");
                    int specialFee = rs.getInt("FEE_AMT");
                    int fee = specialFee < 0 ? regularFee : ("Y".equalsIgnoreCase(rs.getString("DISC")) ? applyDiscount(specialFee, discountPercentage) : specialFee);
                    bind(sectionStmt, term, candidateId, courseId);
                    try(ResultSet sectionRs = sectionStmt.executeQuery())
                    {
                        if(!sectionRs.next()) continue;
                        String sectionId = sectionRs.getString("SECTION_ID");
                        bind(updateStmt, fee, candidateId, sectionId);
                        int rows = updateStmt.executeUpdate();
                        if(rows > 0)
                        {
                            updated += rows;
                            session.addLog("UPDATE NEW_REGISTRATION SET FEE_AMT=" + fee +" WHERE CANDIDATE_ID=" + candId + " AND SECTION_ID=" + sectionId,updateStmt);
                        }
                    }
                }
            }
        }
        return updated;
    }

    public int getCourseLimit(Connection con) throws Exception
    {
        return queryInt(con, 4, "SELECT COURSE_LIMIT FROM PROG_COURSE_LIMIT WHERE PROG_ID = ? AND TERM_CDE = ?", majorId, workingTerm);
    }

    public int getCourseLimit(String term, Connection con)
    {
        int result = 6;
        try
        {
            result = queryInt(con, result, "SELECT COURSE_LIMIT FROM PROG_COURSE_LIMIT WHERE PROG_ID = ? AND TERM_CDE = ?",majorId, term);
            result = Math.min(result, reqCourseCount - totalDegreeCourseEarned);
            return Math.max(result, 0);
        }catch(Exception e)
        {
            return result;
        }
    }

    public void emptyShowedCourses(){showedCourses.clear();}

    public void setAddDropStatus(Connection con) throws SQLException
    {
        String value = queryString(con, "SELECT EVENTDESC FROM ADMINISTRATOR.REG_EVENTS WHERE EVENTNO = ?", lastEvent);
        stdAddDrpDetail = value == null ? "Unknown" : value;
    }

    public void initStudentDetail(String pRegnbr, String pPassword, String pTerm, String pTentTerm, String pWorkingTerm, Connection pCon) throws Exception
    {
        if(pRegnbr == null || pRegnbr.length() < 5) throw new IllegalArgumentException("Invalid registration number.");
        regNbr = pRegnbr.toUpperCase();
        password = pPassword;
        currentTerm = pTerm;
        tentRegTerm = pTentTerm;
        workingTerm = pWorkingTerm;
        stdTerm = regNbr.substring(2, 5);
        setRights(pCon);
        directStudent = !(regNbr.length() >= 4 && "1".equals(regNbr.substring(regNbr.length() - 4, regNbr.length() - 3)));
        if(!directStudent) getOldMajor(regNbr, pCon, oldMajors);
        lastEvent = getLastEvent(pCon);
        RegStatus = lastEvent >= 1 ? "OK" : "InProcess";
        AddDropRegStatus = lastEvent >= 3 ? "OK" : "InProcess";
        clearByAdvisor = true;
        onSemesterBreak = isOnSemesterBreak(pCon);
        getStdInfo(pCon);
        alreadyAddDrop = isAlreadyAddDrop(pCon);
        isConCGPADefaulter = getConsecutiveCGPAResult(pCon);
        isConGPADefaulter = getConsecutiveGPAResult(pCon);
        totalCreditEarned = getTotalCreditEarned(pCon);
        totalDegreeEarned = getDegreeCEarned(pCon);
        totalDegreeCourseEarned = getDegreeCourseEarned(pCon);
        totalSpecCourseEarned = getSpecCourseEarned(pCon);
        duesDefaulter = getDuesDefaulterResult(pCon);
        courseLimit = getCourseLimit(pCon);
        setAddDropStatus(pCon);
        studentImage = getImage(pCon);
        regSemesterNbr = currentTerm.equals(workingTerm) ? getRegSemesterNbr(pCon) : getAdvisorRegSemesterNbr(pCon);
        canTakeCourseCount = Math.max(0, Math.min(courseLimit, reqCourseCount - totalDegreeCourseEarned));
        levelCgpa = getLevelCgpa(pCon);
        isInstChallanPrinted = hasInstChallanPrinted(regNbr, pCon);
        faculty = Functions.getFaculty(regNbr, pCon);
        setCmpId(pCon);
    }

    public String getRegString(){return toSqlInList(regNbr, oldRegNbrs);}
    public String getMajorString(){ return toSqlInList(major, oldMajors);}
    public void getOldRegNbr(String reg, Connection con, List<String> data){loadOldRegNbrs(reg, con, data, new HashSet<String>());}

    private void loadOldRegNbrs(String reg, Connection con, List<String> data, Set<String> visited)
    {
        if(reg == null || !visited.add(reg)) return;
        try
        {
            String oldReg = queryString(con, "SELECT OLD_REG_NBR FROM UCP.EXSTUDENT WHERE NEW_REG_NBR = ?", reg);
            if(oldReg == null || oldReg.isEmpty()) return;
            loadOldRegNbrs(oldReg, con, data, visited);
            if(!data.contains(oldReg)) data.add(oldReg);
        }catch(SQLException e)
        {
            System.out.println("Error in StudentContainer.getOldRegNbr: " + e.getMessage());
        }
    }

    public void getOldMajor(String reg, Connection con, List<String> data) throws Exception
    {
        String sql = "SELECT COURSE_PROG_ID FROM UCP.STUDENT WHERE REG_NBR = ?";
        try(PreparedStatement stmt = con.prepareStatement(sql))
        {
            for(String oldReg : oldRegNbrs)
            {
                stmt.setString(1, oldReg);
                try(ResultSet rs = stmt.executeQuery())
                {
                    if(rs.next())
                    {
                        String value = rs.getString("COURSE_PROG_ID");
                        if(value != null && !data.contains(value)) data.add(value);
                    }
                }
            }
        }
    }

    public int getCurrentTermCourseCount(Connection con)
    {
        try
        {
            return queryInt(con, 0,
                "SELECT COUNT(C.COURSE_CDE) FROM UCP.COURSE C, UCP.SECTION S, UCP.REGISTRATION R " +
                "WHERE C.COURSE_ID = S.COURSE_ID AND S.SECTION_ID = R.SECTION_ID " +
                "AND R.REG_NBR = ? AND R.STATUS_TYP = 'Y' AND R.TERM_CDE = ?",
                regNbr, currentTerm);
        } catch(SQLException e)
        {
            System.out.println("Error in StudentContainer.getCurrentTermCourseCount: " + e.getMessage());
            return 0;
        }
    }

    public boolean getDuesDefaulterResult(Connection con) throws Exception
    {
        return exists(con,"SELECT 1 FROM UCP.DUES_DEFAULTER WHERE REG_NBR = ? AND TERM_CDE = ?", regNbr, workingTerm);
    }

    public int getTotalCreditEarned(Connection con) throws Exception
    {
        try { return callInt(con, "{ ? = call ADMINISTRATOR.NUTILITY.GET_TOTCEARN(?) }", regNbr); }
        catch(Exception e)
        {
            System.out.println("Error in StudentContainer.getTotalCreditEarned: " + e.getMessage());
            return 0;
        }
    }

    public int getDegreeCEarned(Connection con) throws Exception
    {
        try { return callInt(con, "{ ? = call ADMINISTRATOR.NUTILITY.GET_DEGREECEARN(?) }", regNbr); }
        catch(Exception e)
        {
            System.out.println("Error in StudentContainer.getDegreeCEarned: " + e.getMessage());
            return 0;
        }
    }

    public int getSpecCourseEarned(Connection con) throws Exception
    {
        try
        {
            return callInt(con, "{ ? = call ADMINISTRATOR.NUTILITY.GET_SPECCOURSECOUNT(?,?,?) }", regNbr, currentTerm, major);
        }catch(Exception e)
        {
            System.out.println("Error in StudentContainer.getSpecCourseEarned: " + e.getMessage());
            return 0;
        }
    }

    public int getDegreeCourseEarned(Connection con) throws Exception
    {
        try
        {
            return callInt(con,"{ ? = call ADMINISTRATOR.NUTILITY.GET_DEGREECOURSECOUNT(?,?) }", regNbr, currentTerm);
        } catch(Exception e)
        {
            System.out.println("Error in StudentContainer.getDegreeCourseEarned: " + e.getMessage());
            return 0;
        }
    }

    public void getStdInfo(Connection con) throws Exception
    {
        oldReg = getStdOldRegNbr(regNbr, con);
        oldReg = oldReg == null ? "" : oldReg;

        String otherInfoSql =
            "SELECT C.KIN_REGNBR, C.OLD_REG, C.CANDIDATE_ID, S.SPORTS_PRSN_IND, S.PWWF_IND " +
            "FROM REG_CAND RC, CANDIDATE C, STUDENT S " +
            "WHERE C.CANDIDATE_ID = RC.CANDIDATE_ID AND S.REG_NBR = RC.REG_NBR AND RC.REG_NBR = ?";

        try(PreparedStatement stmt = con.prepareStatement(otherInfoSql))
        {
            stmt.setString(1, regNbr);
            try(ResultSet rs = stmt.executeQuery())
            {
                if(rs.next())
                {
                    kinshipInd = safe(rs.getString("KIN_REGNBR"));
                    sportsInd = safe(rs.getString("SPORTS_PRSN_IND"));
                    pwwf = safe(rs.getString("PWWF_IND"));
                    if(pwwf.isEmpty()) pwwf = "N";
                    oldRegNbr = safe(rs.getString("OLD_REG"));
                    candId = safe(rs.getString("CANDIDATE_ID"));
                }
            }
        }

        String studentSql =
            "SELECT S.STUDENT_NME, CP.PROG_CDE COURSE_PROG_CDE, P.PROG_CDE, B.BATCH_ID, B.BATCH_NBR, " +
            "RS.REG_DTE, RS.PER_COURSE_AMT, S.DOB_DTE, S.FATHER_NME, S.L_ADDRESS1_TXT, S.L_ADDRESS2_TXT, " +
            "S.L_ADDRESS3_TXT, S.L_CITY_NME, S.L_PHONE_NBR, S.P_PHONE_NBR, S.GENDER_IND, S.COURSE_PROG_ID, " +
            "P.PROG_ID, NVL(S.NIC,'') NIC, NVL(S.FATHER_NIC,'') FNIC, NVL(S.FATHER_NTN,'') FNTN, " +
            "(SELECT MOBILE_NBR FROM STUDENT_MOBILE WHERE REG_NBR = S.REG_NBR) MOB_NBR, S.UNI_REG, S.PWWF_IND, " +
            "NVL((SELECT TO_CHAR(MIN(A1.PAID_DTE),'DD Mon, RRRR') FROM UCP.ACCOUNTS A1 WHERE A1.REG_NBR = S.REG_NBR),'-') REGISTRATION_DATE, " +
            "SP.SPECIALIZATION_ABBREV " +
            "FROM UCP.STUDENT S, UCP.PROGRAM P, UCP.PROGRAM CP, UCP.BATCH B, UCP.REGISTRATION_SCHEDULE RS, UCP.SPECIALIZATION SP " +
            "WHERE S.REG_NBR = ? AND S.PROG_ID = P.PROG_ID AND P.PROG_ID = B.PROG_ID AND S.SP_ID = SP.SP_ID(+) " +
            "AND S.COURSE_PROG_ID = CP.PROG_ID AND B.TERM_CDE = ? AND B.BATCH_ID = RS.BATCH_ID " +
            "AND RS.REG_DTE = (SELECT MAX(REG_DTE) FROM UCP.REGISTRATION_SCHEDULE WHERE BATCH_ID = B.BATCH_ID)";

        try(PreparedStatement stmt = con.prepareStatement(studentSql))
        {
            bind(stmt, regNbr, stdTerm);
            try(ResultSet rs = stmt.executeQuery())
            {
                if(rs.next())
                {
                    stdName = safe(rs.getString("STUDENT_NME"));
                    major = safe(rs.getString("COURSE_PROG_CDE"));
                    majorId = safe(rs.getString("COURSE_PROG_ID"));
                    vMajor = safe(rs.getString("PROG_CDE"));
                    vMajorId = safe(rs.getString("PROG_ID"));
                    stdBatchId = rs.getInt("BATCH_ID");
                    stdBatchNbr = rs.getInt("BATCH_NBR");
                    stdRegDate = rs.getDate("REG_DTE");
                    courseAmount = rs.getInt("PER_COURSE_AMT");
                    stdDOB = rs.getDate("DOB_DTE");
                    fatherNme = safe(rs.getString("FATHER_NME"));
                    mailingAdd1 = safe(rs.getString("L_ADDRESS1_TXT"));
                    mailingAdd2 = safe(rs.getString("L_ADDRESS2_TXT"));
                    mailingAdd3 = safe(rs.getString("L_ADDRESS3_TXT"));
                    mailingCity = safe(rs.getString("L_CITY_NME"));
                    mailingPhone = safe(rs.getString("L_PHONE_NBR"));
                    personalPhone = safe(rs.getString("P_PHONE_NBR"));
                    sex = safe(rs.getString("GENDER_IND"));
                    nic = safe(rs.getString("NIC"));
                    fatherNic = safe(rs.getString("FNIC"));
                    fatherNtn = safe(rs.getString("FNTN"));
                    mobileNbr = safe(rs.getString("MOB_NBR"));
                    uniRegNbr = safe(rs.getString("UNI_REG"));
                    regDte = safe(rs.getString("REGISTRATION_DATE"));
                    specialization = safe(rs.getString("SPECIALIZATION_ABBREV"));
                }
            }
        }

        List<int[]> amounts = new ArrayList<>();
        try(PreparedStatement stmt = con.prepareStatement("SELECT CREDIT_HRS, PER_COURSE_AMT FROM UCP.BATCH_FEE WHERE BATCH_ID = ? ORDER BY CREDIT_HRS"))
        {
            stmt.setInt(1, stdBatchId);
            try(ResultSet rs = stmt.executeQuery())
            {
                while(rs.next()) amounts.add(new int[]{rs.getInt("CREDIT_HRS"), rs.getInt("PER_COURSE_AMT")});
            }
        }
        courseAmounts = amounts.toArray(new int[amounts.size()][]);

        String termDateSql = "SELECT T.START_DTE, TT.START_DTE FROM TERM T, TERM TT WHERE T.TERM_CDE = 'F03' AND TT.TERM_CDE = ?";
        try(PreparedStatement stmt = con.prepareStatement(termDateSql))
        {
            stmt.setString(1, stdTerm);
            try(ResultSet rs = stmt.executeQuery())
            {
                if(rs.next())
                {
                    java.sql.Date f03Date = rs.getDate(1);
                    java.sql.Date studentTermDate = rs.getDate(2);
                    isAfterR03 = studentTermDate == null || f03Date == null || !studentTermDate.before(f03Date);
                } else isAfterR03 = true;
            }
        }

        String requirementSql = "SELECT COURSE_LIMIT_L1, COURSE_LIMIT_L2 FROM UCP.BATCH_REQUIREMENT WHERE BATCH_ID = ?";
        try(PreparedStatement stmt = con.prepareStatement(requirementSql))
        {
            stmt.setInt(1, stdBatchId);
            try(ResultSet rs = stmt.executeQuery())
            {
                reqCourseCount = rs.next() ? rs.getInt(regNbr.startsWith("L1") ? "COURSE_LIMIT_L1" : "COURSE_LIMIT_L2") : 100;
            }
        }

        regDueDate = queryString(con, "SELECT TO_CHAR(DDATE,'DD-MM-YYYY') FROM ADMINISTRATOR.BATCH WHERE TERM = ? AND MAJOR = ?", stdTerm, major);
        if(regDueDate == null) regDueDate = "Due Date";
    }

    public boolean isAlreadyAddDrop(Connection con) throws SQLException
    {
        if(lastEvent >= 3) return true;
        return exists(con, "SELECT 1 FROM UCP.DROPPED_COURSE WHERE REG_NBR = ? AND TERM_CDE = ?", regNbr, workingTerm);
    }

    public boolean getConsecutiveCGPAResult(Connection con) throws Exception
    {
        try
        {
            cgpa = queryDouble(con, 0.0, "SELECT ADMINISTRATOR.NUTILITY.GET_CGPA(?) FROM DUAL", regNbr);
        } catch(Exception e)
        {
            System.out.println("Error in StudentContainer.getConsecutiveCGPAResult: " + e.getMessage());
        }
        return false;
    }

    public boolean getConsecutiveGPAResult(Connection con) throws Exception
    {
        try
        {
            return callInt(con, "{ ? = call ADMINISTRATOR.NUTILITY.GET_CONS_GPA_RESULT(?) }", regNbr) < 0;
        } catch(Exception e)
        {
            System.out.println("Error in StudentContainer.getConsecutiveGPAResult: " + e.getMessage());
            return false;
        }
    }

    public double getLevelCgpa(Connection con) throws Exception
    {
        String sql =
            "SELECT NVL(ROUND(SUM(GP.GP * C.COURSECREDITS), 2), 0), NVL(SUM(C.COURSECREDITS), 0) " +
            "FROM GRADES G, UCP.GRADE_KEY GP, HISTADMINISTRATOR.COURSES C " +
            "WHERE G.REG = ? AND G.GRADE = GP.LETTER_GRADE AND G.GRADE NOT IN('I','W','RA','TR','N') " +
            "AND G.GRADE NOT LIKE '%(%)%' AND C.COURSEID = G.COURSEID " +
            "AND SUBSTR(C.COURSEID, LENGTH(C.COURSEID)-3, 1) IN('5','6') " +
            "AND G.TERM = C.TERM AND G.TERM = GP.TERM_CDE AND SUBSTR(STATUS,1,1) IN('U','P') " +
            "AND G.TERM IN (SELECT TERM FROM ADMINISTRATOR.TERM_ORDER WHERE TNO <= " +
            "(SELECT NVL(MAX(TNO),0) FROM ADMINISTRATOR.TERM_ORDER))";

        try(PreparedStatement stmt = con.prepareStatement(sql))
        {
            stmt.setString(1, regNbr);
            try(ResultSet rs = stmt.executeQuery())
            {
                if(!rs.next()) return 0.0;
                double points = rs.getDouble(1);
                double credits = rs.getDouble(2);
                return credits == 0.0 ? 0.0 : points / credits;
            }
        } catch(Exception e)
        {
            System.out.println("Error in StudentContainer.getLevelCgpa: " + e.getMessage());
            return 0.0;
        }
    }

    public int getLastEvent(Connection con) throws Exception
    {
        String sql =
            "SELECT EVENT_NBR, PAID_DTE FROM UCP.ACCOUNTS WHERE REG_NBR = ? AND TERM_CDE = ? " +
            "AND EVENT_NBR = (SELECT NVL(MAX(EVENT_NBR),0) FROM UCP.ACCOUNTS WHERE REG_NBR = ? AND TERM_CDE = ?)";

        try(PreparedStatement stmt = con.prepareStatement(sql))
        {
            bind(stmt, regNbr, workingTerm, regNbr, workingTerm);
            try(ResultSet rs = stmt.executeQuery())
            {
                if(!rs.next())
                {
                    lastEventConfirmed = false;
                    return 0;
                }
                lastEventConfirmed = rs.getObject("PAID_DTE") != null;
                return rs.getInt("EVENT_NBR");
            }
        }catch(Exception e)
        {
            System.out.println("Error in StudentContainer.getLastEvent: " + e.getMessage());
            return 0;
        }
    }

    public boolean isClearByAdvisor(Connection con)
    {
        try
        {
            return exists(con, "SELECT 1 FROM ADMINISTRATOR.CLEAR_4_REGISTRATION WHERE REG = ? AND TERM = ?",
                regNbr, tentRegTerm);
        }
        catch(SQLException e)
        {
            System.out.println("Error in StudentContainer.isClearByAdvisor: " + e.getMessage());
            return false;
        }
    }

    public boolean isOnSemesterBreak(Connection con) throws SQLException
    {
        return exists(con, "SELECT 1 FROM ADMINISTRATOR.SEMESTER_BREAK WHERE REG = ? AND TERM = ?", regNbr, workingTerm);
    }

    private int countAvailableCourses(Connection con, int semesterNbr, boolean includeCurrentRegistration) throws SQLException
    {
        String regList = getRegString();

        StringBuilder sql = new StringBuilder(
            "SELECT COUNT(*) FROM (" +
            "SELECT DISTINCT C.COURSE_CDE, C.TYP_IND, P.COURSE_NBR " +
            "FROM UCP.PREREQ P, UCP.COURSE C, UCP.SECTION S, UCP.SLOT SL, UCP.TIME_TABLE T, UCP.SECTION_PROGRAM SP " +
            "WHERE C.COURSE_ID = P.COURSE_ID AND SP.SECTION_ID = S.SECTION_ID AND C.COURSE_ID = S.COURSE_ID " +
            "AND S.SECTION_ID = T.SECTION_ID AND T.SLOT_ID = SL.SLOT_ID AND SP.PROG_ID = ? AND SP.PROG_ID = P.PROG_ID " +
            "AND C.TERM_CDE = ? AND C.COURSE_CDE NOT IN (" +
            "SELECT NCOURSEID FROM COR_GRADES WHERE REG IN " + regList + " AND GRADE NOT IN('W') "
        );

        if(includeCurrentRegistration)
        {
            sql.append(
                "UNION SELECT C2.COURSE_CDE FROM UCP.COURSE C2, UCP.SECTION S2, UCP.REGISTRATION R2 " +
                "WHERE C2.COURSE_ID = S2.COURSE_ID AND S2.SECTION_ID = R2.SECTION_ID " +
                "AND R2.REG_NBR IN " + regList + " AND R2.TERM_CDE = ? "
            );
        }

        sql.append(
            ") AND C.TYP_IND = 'R' AND C.COURSE_CDE NOT IN (" +
            "SELECT NCOURSEID FROM COR_GRADES WHERE REG IN " + regList +
            " AND GRADE IN (SELECT GRADE FROM HADMIN.REPEAT_GRADES_NEW)) " +
            "AND P.COURSE_NBR <= ?)"
        );

        try(PreparedStatement stmt = con.prepareStatement(sql.toString()))
        {
            int index = 1;
            stmt.setObject(index++, majorId);
            stmt.setString(index++, workingTerm);
            if(includeCurrentRegistration) stmt.setString(index++, currentTerm);
            stmt.setInt(index, semesterNbr);

            try(ResultSet rs = stmt.executeQuery())
            {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    public int getRegSemesterNbr(Connection con) throws Exception
    {
        int result = queryInt(con, 0,
            "SELECT COUNT(DISTINCT TERM) FROM COR_GRADES WHERE REG = ?", regNbr) + 1;

        int count = countAvailableCourses(con, result, false);
        if(count >= 4) return result;

        for(int i = 1; i < 5; i++)
        {
            if(countAvailableCourses(con, result + i, false) >= 8) return result + i;
        }

        return result;
    }

    public int getAdvisorRegSemesterNbr(Connection con) throws SQLException
    {
        String sql =
            "SELECT (SELECT COUNT(DISTINCT TERM) FROM COR_GRADES WHERE REG = ?) + " +
            "(SELECT COUNT(DISTINCT TERM_CDE) FROM UCP.REGISTRATION WHERE TERM_CDE = ? AND REG_NBR = ?) FROM DUAL";

        int result = queryInt(con, 0, sql, regNbr, currentTerm, regNbr) + 1;
        int count = countAvailableCourses(con, result, true);

        if(count < 4)
        {
            for(int i = 1; i < 5; i++)
            {
                if(countAvailableCourses(con, result + i, true) >= 8)
                {
                    result += i;
                    break;
                }
            }
        }

        return result - 1;
    }

    public Image getImage(Connection con) throws Exception
    {
        stdImgByte = null;

        try(PreparedStatement stmt = con.prepareStatement(
            "SELECT IMAGE FROM STUDENT_PICTURE WHERE REG_NBR = ?"))
        {
            stmt.setString(1, regNbr);
            try(ResultSet rs = stmt.executeQuery())
            {
                if(rs.next()) stdImgByte = rs.getBytes("IMAGE");
            }
        }
        catch(Exception e)
        {
            System.out.println("Error while trying to fetch picture in StudentContainer: " + e.getMessage());
        }

        return stdImgByte == null ? null : new ImageIcon(stdImgByte).getImage();
    }

    public boolean isItStudent()
    {
        return STUDENT_MAJORS.contains(major);
    }

    public boolean hasInstChallanPrinted(String regNbr, Connection con) throws Exception
    {
        return exists(con,
            "SELECT 1 FROM ADMINISTRATOR.INSTALLMENT WHERE REG = ? AND TERM = ? AND STATUS = 'PRINTED'",
            regNbr, workingTerm);
    }

    public int getCourseAmount(int creditHrs)
    {
        if(courseAmounts != null)
        {
            for(int[] amount : courseAmounts)
                if(amount != null && amount.length >= 2 && amount[0] == creditHrs) return amount[1];
        }

        return courseAmount;
    }

    public void setRights(Connection con) throws Exception
    {
        rights.clear();

        String facultyId = Functions.getFaculty(regNbr, con);
        String sql =
            "SELECT INITCAP(RIGHT_NME) RIGHT_NME, ID, PARENT_ID, FILE_NME, PREFIX_NME, TARGET " +
            "FROM STUDENT_RIGHTS WHERE ACTIVE_IND = 'Y' ORDER BY ID";

        try(PreparedStatement stmt = con.prepareStatement(sql);
            ResultSet rs = stmt.executeQuery())
        {
            while(rs.next())
            {
                String rightName = rs.getString("RIGHT_NME");
                if(rightName == null) continue;

                if("REGISTRATION".equalsIgnoreCase(rightName) &&
                   !"True".equalsIgnoreCase(Functions.getEnviornmentValue("Registration By Students", facultyId, con)))
                    continue;

                if("NEXT ADVISING".equalsIgnoreCase(rightName) &&
                   !"True".equalsIgnoreCase(Functions.getEnviornmentValue("Advising By Student", facultyId, con)))
                    continue;

                if("MY COURSES".equalsIgnoreCase(rightName) &&
                   !"True".equalsIgnoreCase(Functions.getEnviornmentValue("Show My Courses Link in Student Login", facultyId, con)))
                    continue;

                if("TEACHER EVALUATION".equalsIgnoreCase(rightName))
                {
                    String evaluationId = Functions.getCurrentTchrEvalId(regNbr, con);
                    if(evaluationId == null || evaluationId.isEmpty()) continue;
                }

                rights.add(rightName);
            }
        }
        catch(Exception e)
        {
            System.out.println("Error in StudentContainer.setRights: " + e.getMessage());
        }
    }

    public boolean hasRightsOn(String privilege)
    {
        return privilege != null && rights.contains(privilege);
    }

    public String getCmpId()
    {
        return cmpId;
    }

    public void setCmpId(Connection con) throws Exception
    {
        String sql =
            "SELECT C.CMP_ID, C.UNI_ID FROM STUDENT S, PROGRAM P, FACULTY F, UCP.CAMPUS C " +
            "WHERE F.CMP_ID = C.CMP_ID AND S.PROG_ID = P.PROG_ID AND P.FACULTY_ID = F.FACULTY_ID " +
            "AND S.REG_NBR = ?";

        try(PreparedStatement stmt = con.prepareStatement(sql))
        {
            stmt.setString(1, regNbr);
            try(ResultSet rs = stmt.executeQuery())
            {
                if(rs.next())
                {
                    cmpId = safe(rs.getString("CMP_ID"));
                    uniId = rs.getInt("UNI_ID");
                }
            }
        }
    }

    public String generateRegNbr(Connection con, String op) throws SQLException
    {
        String prog = queryString(con,
            "SELECT PROG_ID FROM OFFERED_PROGRAM WHERE OP_ID = ?", op);
        if(prog == null) return "";

        String initial = "9".equals(prog) ? "0201" : "0001";
        String sql =
            "SELECT A.REGSTR || NVL(B.REGNBR, ?) REGNBR FROM " +
            "(SELECT DISTINCT C.CMP_PREFIX || OP.TERM_CDE || P.PROG_ABBR REGSTR " +
            "FROM PROGRAM P, FACULTY F, CAMPUS C, OFFERED_PROGRAM OP " +
            "WHERE OP.PROG_ID = P.PROG_ID AND P.FACULTY_ID = F.FACULTY_ID AND F.CMP_ID = C.CMP_ID AND OP.OP_ID = ?) A, " +
            "(SELECT LPAD(MAX(TO_NUMBER(SUBSTR(REG_NBR, LENGTH(REG_NBR)-3, LENGTH(REG_NBR)))) + 1, 4, '0') REGNBR " +
            "FROM STUDENT S, PROGRAM P, FACULTY F, CAMPUS C, OFFERED_PROGRAM OP " +
            "WHERE OP.PROG_ID = P.PROG_ID AND S.PROG_ID = P.PROG_ID AND P.FACULTY_ID = F.FACULTY_ID " +
            "AND F.CMP_ID = C.CMP_ID AND OP.OP_ID = ? AND OP.TERM_CDE = 'F13' AND REG_NBR LIKE '%F13%') B";

        String value = queryString(con, sql, initial, op, op);
        return value == null ? "" : value;
    }

    public String newStudentConfirmation(
        Connection con,
        String opId,
        String facId,
        String candId,
        Map<String, String> crsSctn,
        String fcltyId,
        String dSDte,
        String paidDate,
        String trm
    ) throws SQLException
    {
        String newRegNbr = generateRegNbr(con, opId);
        if(newRegNbr.isEmpty()) throw new SQLException("Unable to generate registration number.");

        boolean ownTransaction = ownsTransaction(con);
        Savepoint savepoint = null;

        try
        {
            if(ownTransaction) con.setAutoCommit(false);
            else savepoint = con.setSavepoint();

            String insertStudentSql =
                "INSERT INTO STUDENT " +
                "SELECT ?, FIRST_NAME || ' ' || MID_NAME || ' ' || LAST_NAME, F_NAME, PADD1, PADD2, PADD3, PCITY, PHONE1, DOB, " +
                "MADD1, MADD2, MADD3, MCITY, PHONE2, SEX, P.PROG_ID, P.PROG_ID, P.PROG_CDE, P.PROG_ABBR, " +
                "C.NID, C.FATHER_NIC, C.FATHER_NTN, C.SP_ID, 'A', '' " +
                "FROM CANDIDATE C, OFFERED_PROGRAM OP, PROGRAM P " +
                "WHERE C.OP_ID = OP.OP_ID AND OP.PROG_ID = P.PROG_ID AND C.CANDIDATE_ID = ?";

            try(PreparedStatement stmt = con.prepareStatement(insertStudentSql))
            {
                bind(stmt, newRegNbr, candId);
                stmt.executeUpdate();
            }

            String insertRegistrationSql =
                "INSERT INTO REGISTRATION(REG_ID, REG_NBR, SECTION_ID, TERM_CDE, FEE_AMT, STATUS_TYP, EVENT_NBR) " +
                "SELECT SEQ_REG_ID.NEXTVAL, ?, ?, TERM_CDE, FEE_AMT, STATUS_TYP, 1 " +
                "FROM (SELECT DISTINCT TERM_CDE, FEE_AMT, STATUS_TYP FROM NEW_REGISTRATION WHERE CANDIDATE_ID = ?)";

            String insertRefSql =
                "INSERT INTO REGISTRATION_REF " +
                "SELECT ?, ?, TERM_CDE, 'R' FROM (SELECT DISTINCT TERM_CDE FROM NEW_REGISTRATION WHERE CANDIDATE_ID = ?)";

            String updateStrengthSql =
                "UPDATE SECTION_STATUS SET STRENGTH = STRENGTH + 1 WHERE SECTION_ID = ?";

            try(PreparedStatement registrationStmt = con.prepareStatement(insertRegistrationSql);
                PreparedStatement refStmt = con.prepareStatement(insertRefSql);
                PreparedStatement strengthStmt = con.prepareStatement(updateStrengthSql))
            {
                for(String sectionId : crsSctn.values())
                {
                    bind(registrationStmt, newRegNbr, sectionId, candId);
                    registrationStmt.executeUpdate();

                    bind(refStmt, newRegNbr, sectionId, candId);
                    refStmt.executeUpdate();

                    strengthStmt.setObject(1, sectionId);
                    strengthStmt.executeUpdate();
                }
            }

            try(PreparedStatement stmt = con.prepareStatement("INSERT INTO REG_CAND VALUES(?, ?)"))
            {
                bind(stmt, candId, newRegNbr);
                stmt.executeUpdate();
            }

            String newPassword = Functions.rand(8);
            Security passwordSecurity = new Security();
            String encryptedPassword = passwordSecurity.encrypt(newPassword);
            String doubleEncryptedPassword = passwordSecurity.encrypt(encryptedPassword);

            try(PreparedStatement passwordStmt = con.prepareStatement("INSERT INTO UCP.PASSWORDS VALUES(?, ?)");
                PreparedStatement newPasswordStmt = con.prepareStatement("INSERT INTO UCP.NEW_PASSWORDS VALUES(?, ?)"))
            {
                bind(passwordStmt, newRegNbr, doubleEncryptedPassword);
                passwordStmt.executeUpdate();

                bind(newPasswordStmt, newRegNbr, newPassword);
                newPasswordStmt.executeUpdate();
            }

            String discountSql =
                "INSERT INTO DISCOUNTS " +
                "SELECT SEQ_DISC_ID.NEXTVAL, ?, NA.DISCID, DT.PERCENTS, SUBSTR(?,3,3) " +
                "FROM NEW_ACCOUNTS NA, DISCOUNT_TYPE DT " +
                "WHERE NA.DISCID = DT.DISCID AND NA.ADMISSIONFEE IS NOT NULL AND CANDIDATE_ID = ?";

            try(PreparedStatement stmt = con.prepareStatement(discountSql))
            {
                bind(stmt, newRegNbr, newRegNbr, candId);
                stmt.executeUpdate();
            }

            String accountPaidSql =
                "INSERT INTO ACCOUNTS(ACCT_ID,REG_NBR,TERM_CDE,COURSE_CNT,COURSE_RTE,DISC_ID,DISC_PCT,OTHER_FEE_AMT,DUE_AMT,PAID_AMT,FINE_AMT,PREV_PAID_AMT,CHALLAN_NBR,PAID_DTE,EVENT_NBR) " +
                "SELECT SEQ_ACCT_ID.NEXTVAL, ?, OP.TERM_CDE, NA.NCOURSES, NA.NRATE, NA.DISCID, D.PERCENTS, NA.ADMISSIONFEE, " +
                "NA.AMOUNT, NA.AMOUNT, 0, 0, NA.CHALLAN_NO, TO_DATE(?,'DD/MM/YYYY'), 1 " +
                "FROM NEW_ACCOUNTS NA, CANDIDATE C, OFFERED_PROGRAM OP, DISCOUNT_TYPE D " +
                "WHERE NA.CANDIDATE_ID = C.CANDIDATE_ID AND C.OP_ID = OP.OP_ID AND NA.DISCID = D.DISCID " +
                "AND NA.ADMISSIONFEE IS NOT NULL AND C.CANDIDATE_ID = ?";

            String installmentPaidSql =
                "INSERT INTO INSTALLMENT(INSTNO,REG_NBR,EVENT,AMOUNT,RAMOUNT,STATUS,DUEDATE,PAIDDATE,REMARKS,TERM_CDE) " +
                "SELECT NEW_INSTNO, ?, 'NEW', AMOUNT, RAMOUNT, 'PAID', DUEDATE, TO_DATE(?,'DD/MM/YYYY'), REMARKS, ? " +
                "FROM NEW_INSTALLMENT WHERE CANDIDATE_ID = ? AND NEW_INSTNO = 1";

            String accountOtherSql =
                "INSERT INTO ACCOUNTS(ACCT_ID,REG_NBR,TERM_CDE,COURSE_CNT,COURSE_RTE,DISC_ID,DISC_PCT,OTHER_FEE_AMT,DUE_AMT,PAID_AMT,FINE_AMT,PREV_PAID_AMT,CHALLAN_NBR,PAID_DTE,EVENT_NBR) " +
                "SELECT SEQ_ACCT_ID.NEXTVAL, ?, OP.TERM_CDE, NA.NCOURSES, NA.NRATE, NA.DISCID, D.PERCENTS, NA.ADMISSIONFEE, " +
                "NA.AMOUNT, NA.AMOUNT, 0, 0, NA.CHALLAN_NO, SYSDATE, 1.2 " +
                "FROM NEW_ACCOUNTS NA, CANDIDATE C, OFFERED_PROGRAM OP, DISCOUNT_TYPE D " +
                "WHERE NA.CANDIDATE_ID = C.CANDIDATE_ID AND C.OP_ID = OP.OP_ID AND NA.DISCID = D.DISCID " +
                "AND NA.ADMISSIONFEE IS NULL AND C.CANDIDATE_ID = ?";

            String installmentDueSql =
                "INSERT INTO INSTALLMENT(INSTNO,REG_NBR,EVENT,AMOUNT,RAMOUNT,STATUS,DUEDATE,REMARKS,TERM_CDE) " +
                "SELECT NEW_INSTNO, ?, 'NEW', AMOUNT, RAMOUNT, STATUS, TO_DATE(?,'DD/MM/YYYY'), REMARKS, ? " +
                "FROM NEW_INSTALLMENT WHERE CANDIDATE_ID = ? AND NEW_INSTNO = 2";

            try(PreparedStatement stmt = con.prepareStatement(accountPaidSql))
            {
                bind(stmt, newRegNbr, paidDate, candId);
                stmt.executeUpdate();
            }

            try(PreparedStatement stmt = con.prepareStatement(installmentPaidSql))
            {
                bind(stmt, newRegNbr, paidDate, trm, candId);
                stmt.executeUpdate();
            }

            try(PreparedStatement stmt = con.prepareStatement(accountOtherSql))
            {
                bind(stmt, newRegNbr, candId);
                stmt.executeUpdate();
            }

            try(PreparedStatement stmt = con.prepareStatement(installmentDueSql))
            {
                bind(stmt, newRegNbr, dSDte, trm, candId);
                stmt.executeUpdate();
            }

            if(ownTransaction) con.commit();
            return newRegNbr;
        }
        catch(Exception e)
        {
            rollback(con, ownTransaction, savepoint);
            if(e instanceof SQLException) throw (SQLException) e;
            throw new SQLException(e.getMessage(), e);
        }
        finally
        {
            if(ownTransaction)
            {
                try { con.setAutoCommit(true); }
                catch(SQLException ignored) {}
            }
        }
    }

    public boolean newStudentImage(Connection con, File image, String regNbr) throws SQLException, Exception
    {
        if(image == null || !image.isFile()) return false;

        String sql = "INSERT INTO STUDENT_PICTURE VALUES(?, ?)";
        try(FileInputStream input = new FileInputStream(image);
            PreparedStatement stmt = con.prepareStatement(sql))
        {
            stmt.setString(1, regNbr);
            stmt.setBinaryStream(2, input, image.length());
            return stmt.executeUpdate() > 0;
        }
    }

    public static String getStdOldRegNbr(String regNbr, Connection con) throws Exception
    {
        String oldReg = queryString(con,
            "SELECT OLD_REG FROM STD_TRANSFER WHERE NEW_REG = ?", regNbr);
        return oldReg == null ? regNbr : oldReg;
    }

    public void setSessionId(int sessionId)
    {
        this.sessionId = sessionId;
    }

    public int getSessionId()
    {
        return sessionId;
    }
}
