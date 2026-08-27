package com.ums.packages;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class Section
{
    private int sectionId = -1;
    private String courseCode = "";
    private String title = "";
    private String sectionText = "";
    private String teacherAbbr = "";
    private int courseId = -1;
    private String statusInd = "";
    private final List<String> majors = new ArrayList<>();
    private final List<String> majorIds = new ArrayList<>();
    private int strength = -1;
    private int currentStrength = -1;
    private int finalStrength = -1;
    private String typeInd = "";
    private int courseRate = 0;
    private boolean discountAllowed = false;
    private String courseAbbr = "";
    private String termCde = "";
    private String cmpId = "";

    public Section()
    {
    }

    public Section(
        int sectionId,
        String courseCode,
        String sectionText,
        String teacherAbbr,
        int courseId,
        String statusInd,
        ResultSet programs,
        int strength,
        int currentStrength,
        String typeInd,
        int courseRate,
        boolean discountAllowed,
        String title,
        String courseAbbr,
        String termCde)
    {
        this.sectionId = sectionId;
        this.courseCode = value(courseCode);
        this.sectionText = value(sectionText);
        this.teacherAbbr = value(teacherAbbr);
        this.courseId = courseId;
        this.statusInd = value(statusInd);
        this.strength = strength;
        this.finalStrength = currentStrength;
        this.currentStrength = currentStrength;
        this.typeInd = value(typeInd);
        this.courseRate = courseRate;
        this.discountAllowed = discountAllowed;
        this.title = value(title);
        this.courseAbbr = value(courseAbbr);
        this.termCde = value(termCde);

        loadMajors(programs, false);
        updateStatus();
    }

    public Section(
        int sectionId,
        String courseCode,
        String sectionText,
        String teacherAbbr,
        int courseId,
        String statusInd,
        ResultSet programs,
        int strength,
        int currentStrength,
        String typeInd,
        String title,
        String courseAbbr,
        String termCde)
    {
        this.sectionId = sectionId;
        this.courseCode = value(courseCode);
        this.sectionText = value(sectionText);
        this.teacherAbbr = value(teacherAbbr);
        this.courseId = courseId;
        this.statusInd = value(statusInd);
        this.strength = strength;
        this.finalStrength = currentStrength;
        this.currentStrength = currentStrength;
        this.typeInd = value(typeInd);
        this.title = value(title);
        this.courseAbbr = value(courseAbbr);
        this.termCde = value(termCde);

        loadMajors(programs, true);
        updateStatus();
    }

    public boolean isDefineInTimetable(Connection con)
    {
        if(con == null) return false;

        String sql = "SELECT 1 FROM UCP.TIME_TABLE WHERE SECTION_ID = ? AND ROWNUM = 1";

        try(PreparedStatement stmt = con.prepareStatement(sql))
        {
            stmt.setInt(1, sectionId);

            try(ResultSet rs = stmt.executeQuery())
            {
                return rs.next();
            }
        }
        catch(SQLException e)
        {
            System.out.println("Error in isDefineInTimetable(Connection con): " + e.getMessage());
            return false;
        }
    }

    public synchronized void updateStrength(int newStrength)
    {
        strength = newStrength;
        updateStatus();
    }

    public synchronized void updateTeacher(String newTeacher)
    {
        teacherAbbr = value(newTeacher);
    }

    public synchronized void updateStatus()
    {
        if("O".equals(statusInd) && currentStrength >= strength) closeSection();
        else if("C".equals(statusInd) && currentStrength < strength) openSection();
    }

    public synchronized void updateFinalStrength(int newFinalStrength)
    {
        int difference = newFinalStrength - finalStrength;
        finalStrength = newFinalStrength;
        currentStrength += difference;
        updateStatus();
    }

    public synchronized void increaseCurrentStrengthBy(int value)
    {
        currentStrength += value;
        updateStatus();
    }

    public synchronized void updateMajors(List<String> newMajors)
    {
        majors.clear();
        if(newMajors != null) majors.addAll(newMajors);
    }

    public synchronized void increaseFinalStrength()
    {
        finalStrength++;
    }

    public synchronized void increaseFinalStrengthBy(int by)
    {
        if(by <= 0) return;

        finalStrength += by;
        currentStrength += by;
        updateStatus();
    }

    public synchronized void decreaseFinalStrengthBy(int by)
    {
        if(by <= 0) return;

        finalStrength -= by;
        currentStrength -= by;
        updateStatus();
    }

    public synchronized void decreaseFinalStrength()
    {
        finalStrength--;
    }

    public synchronized int getFinalStrength()
    {
        return finalStrength;
    }

    public synchronized void increaseStrength(int by)
    {
        strength += by;
        updateStatus();
    }

    public synchronized void decreaseStrength(int by)
    {
        strength -= by;
        updateStatus();
    }

    public synchronized void openSection()
    {
        statusInd = "O";
    }

    public synchronized void closeSection()
    {
        statusInd = "C";
    }

    public synchronized boolean reserveSection(boolean adminOption)
    {
        if(!adminOption && !"O".equals(statusInd)) return false;

        currentStrength++;
        if(currentStrength >= strength) closeSection();
        return true;
    }

    public synchronized boolean cancelSectionReservation()
    {
        if(currentStrength <= finalStrength) return false;

        currentStrength--;
        if("C".equals(statusInd) && currentStrength < strength) openSection();
        return true;
    }

    public String getCourseCode()
    {
        return courseCode;
    }

    public int getCourseId()
    {
        return courseId;
    }

    public synchronized int getCurrentStrength()
    {
        return currentStrength;
    }

    public synchronized boolean isMajorExists(String major)
    {
        return major != null && majors.contains(major);
    }

    public synchronized boolean isMajorIdExists(String majorId)
    {
        return majorId != null && majorIds.contains(majorId);
    }

    public int getSectionId()
    {
        return sectionId;
    }

    public String getSection()
    {
        return sectionText;
    }

    public synchronized String getStatus()
    {
        return statusInd;
    }

    public synchronized int getStrength()
    {
        return strength;
    }

    public String getTitle()
    {
        return title;
    }

    public String getTeacherAbbr()
    {
        return teacherAbbr;
    }

    public String getCourseAbbr()
    {
        return courseAbbr;
    }

    public String getTypeIndicator()
    {
        return typeInd;
    }

    public int getCourseRate()
    {
        return courseRate;
    }

    public boolean getDiscountAllowed()
    {
        return discountAllowed;
    }

    public synchronized String getMajorList()
    {
        return String.join(", ", majors);
    }

    public synchronized void refreshMajor(Connection con)
    {
        if(con == null) return;

        String sql =
            "SELECT P.PROG_CDE, P.PROG_ID " +
            "FROM UCP.SECTION_PROGRAM SP " +
            "JOIN UCP.PROGRAM P ON P.PROG_ID = SP.PROG_ID " +
            "WHERE SP.SECTION_ID = ?";

        try(PreparedStatement stmt = con.prepareStatement(sql))
        {
            stmt.setInt(1, sectionId);

            try(ResultSet rs = stmt.executeQuery())
            {
                majors.clear();
                majorIds.clear();

                while(rs.next())
                {
                    majors.add(rs.getString("PROG_CDE"));
                    majorIds.add(rs.getString("PROG_ID"));
                }
            }
        }
        catch(SQLException e)
        {
            System.out.println("Error in refreshMajor(Connection con): " + e.getMessage());
        }
    }

    public synchronized void refreshMajor(ResultSet rs)
    {
        if(rs == null) return;

        majors.clear();
        majorIds.clear();

        try
        {
            while(rs.next())
            {
                majors.add(rs.getString(1));
                majorIds.add(rs.getString(2));
            }
        }
        catch(SQLException e)
        {
            System.out.println("Error in refreshMajor(ResultSet): " + e.getMessage());
        }
    }

    public synchronized void addMajor(String major)
    {
        if(major != null && !majors.contains(major)) majors.add(major);
    }

    public synchronized void addMajor(String[] newMajors)
    {
        if(newMajors == null) return;

        for(String major : newMajors) addMajor(major);
    }

    public synchronized void removeMajor(String[] majorsToRemove)
    {
        if(majorsToRemove == null) return;

        for(String major : majorsToRemove) majors.remove(major);
    }

    public synchronized void removeMajor(String major)
    {
        if(major != null) majors.remove(major);
    }

    public void setTerm_cde(String termCde)
    {
        this.termCde = value(termCde);
    }

    public String getTerm_cde()
    {
        return termCde;
    }

    public String getCmp_id()
    {
        return cmpId;
    }

    public void setCmp_id(String cmpId)
    {
        this.cmpId = value(cmpId);
    }

    private void loadMajors(ResultSet rs, boolean loadIds)
    {
        if(rs == null) return;

        try(ResultSet result = rs)
        {
            while(result.next())
            {
                majors.add(result.getString(1));
                if(loadIds) majorIds.add(result.getString(2));
            }
        }
        catch(SQLException e)
        {
            System.out.println("Error loading section majors: " + e.getMessage());
        }
    }

    private static String value(String text)
    {
        return text == null ? "" : text;
    }
}
