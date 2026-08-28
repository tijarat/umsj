package com.ums.packages;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Enumeration;
import java.util.List;
import java.util.Vector;

public class ReserveSection
{
    private final List<Section> sectionList = new ArrayList<>();
    private final List<String> courseTypes = new ArrayList<>();
    private final List<Section> advisorSectionList = new ArrayList<>();

    public String regNbr = "";
    public String regStatus = "InProcess";

    public ReserveSection()
    {
    }

    public synchronized boolean advisorContainCourse(String courseId)
    {
        if(courseId == null) return false;

        for(Section section : advisorSectionList)
            if(courseId.equals(section.getCourseCode())) return true;

        return false;
    }

    public synchronized int advisorGetSectionCount()
    {
        return advisorSectionList.size();
    }

    public synchronized void adminFillSections(List<Section> list)
    {
        advisorSectionList.clear();
        if(list != null) advisorSectionList.addAll(list);
    }

    public synchronized void advisorFillSections(List<Section> list)
    {
        advisorSectionList.clear();
        if(list != null) advisorSectionList.addAll(list);
    }

    public synchronized void setRegnbr(String reg)
    {
        regNbr = reg == null ? "" : reg;

        cancelReservations(sectionList);
        cancelReservations(advisorSectionList);

        sectionList.clear();
        courseTypes.clear();
        advisorSectionList.clear();
    }

    public synchronized boolean containSection(Section section)
    {
        if(section == null) return false;

        for(Section current : sectionList)
            if(current.getSectionId() == section.getSectionId()) return true;

        return false;
    }

    public synchronized boolean advisorContainSection(Section section)
    {
        if(section == null) return false;

        for(Section current : advisorSectionList)
            if(current.getSectionId() == section.getSectionId()) return true;

        return false;
    }

    public synchronized boolean addSection(Section section, String courseType)
    {
        if(section == null) return false;
        if(containSection(section)) return true;

        int existingIndex = findCourseIndex(sectionList, section.getCourseCode());
        if(existingIndex >= 0)
        {
            sectionList.get(existingIndex).cancelSectionReservation();
            sectionList.remove(existingIndex);
            courseTypes.remove(existingIndex);
        }

        if(!section.reserveSection(true)) return false;

        sectionList.add(section);
        courseTypes.add(courseType);
        return true;
    }

    public synchronized boolean advisorAddSection(Section section, String courseType)
    {
        if(section == null) return false;
        if(advisorContainSection(section)) return true;

        int existingIndex = findCourseIndex(advisorSectionList, section.getCourseCode());
        if(existingIndex >= 0)
        {
            advisorSectionList.get(existingIndex).cancelSectionReservation();
            advisorSectionList.remove(existingIndex);
        }

        if(!section.reserveSection(true)) return false;

        advisorSectionList.add(section);
        return true;
    }

    public synchronized List<Section> getClashSections(Section section, Connection con, String term) throws SQLException
    {
        return findClashSections(sectionList, section, con, term);
    }

    public synchronized List<Section> advisorGetClashSections(Section section, Connection con, String term) throws SQLException
    {
        return findClashSections(advisorSectionList, section, con, term);
    }

    public synchronized boolean removeSection(Section section)
    {
        if(section == null) return false;

        for(int i = 0; i < sectionList.size(); i++)
        {
            if(sectionList.get(i).getSectionId() != section.getSectionId()) continue;

            sectionList.get(i).cancelSectionReservation();
            sectionList.remove(i);
            courseTypes.remove(i);
            return true;
        }

        return false;
    }

    public synchronized boolean advisorRemoveSection(Section section)
    {
        if(section == null) return false;

        for(int i = 0; i < advisorSectionList.size(); i++)
        {
            if(advisorSectionList.get(i).getSectionId() != section.getSectionId()) continue;

            advisorSectionList.get(i).cancelSectionReservation();
            advisorSectionList.remove(i);
            return true;
        }

        return false;
    }

    public synchronized void removeAllSections()
    {
        cancelReservations(sectionList);
        sectionList.clear();
        courseTypes.clear();
    }

    public synchronized void advisorRemoveAllSections()
    {
        cancelReservations(advisorSectionList);
        advisorSectionList.clear();
    }

    public synchronized Section getSection(String courseCode)
    {
        if(courseCode == null) return null;

        for(Section section : sectionList)
            if(courseCode.equals(section.getCourseCode())) return section;

        return null;
    }

    public synchronized Section advisorGetSection(String courseCode)
    {
        if(courseCode == null) return null;

        for(Section section : advisorSectionList)
            if(courseCode.equals(section.getCourseCode())) return section;

        return null;
    }

    public synchronized String getCType(int index)
    {
        return courseTypes.get(index);
    }

    public synchronized String getReserveSection(String courseCode)
    {
        Section section = getSection(courseCode);
        return section == null ? "" : section.getSection();
    }

    public synchronized String advisorGetReserveSection(String courseCode)
    {
        Section section = advisorGetSection(courseCode);
        return section == null ? "" : section.getSection();
    }

    public synchronized String getSectionsString()
    {
        return buildSectionsString(sectionList);
    }

    public synchronized String advisorGetSectionsString()
    {
        return buildSectionsString(advisorSectionList);
    }

    @Deprecated
    public boolean studentCourseEligibility(String courseCode, String term, String regis, Vector<?> courses) throws Exception
    {
        return false;
    }

    public synchronized void emptySecionList()
    {
        sectionList.clear();
        courseTypes.clear();
    }

    public synchronized Enumeration<Section> elements()
    {
        return Collections.enumeration(new ArrayList<>(sectionList));
    }

    public synchronized Enumeration<Section> advisorElements()
    {
        return Collections.enumeration(new ArrayList<>(advisorSectionList));
    }

    private static int findCourseIndex(List<Section> sections, String courseCode)
    {
        for(int i = 0; i < sections.size(); i++)
        {
            Section section = sections.get(i);
            if(courseCode == null ? section.getCourseCode() == null : courseCode.equals(section.getCourseCode()))
                return i;
        }

        return -1;
    }

    private static void cancelReservations(List<Section> sections)
    {
        for(Section section : sections)
            if(section != null) section.cancelSectionReservation();
    }

    private static String buildSectionsString(List<Section> sections)
    {
        if(sections.isEmpty()) return " (NULL) ";

        StringBuilder value = new StringBuilder(" (");
        for(int i = 0; i < sections.size(); i++)
        {
            if(i > 0) value.append(',');
            value.append(sections.get(i).getSectionId());
        }
        return value.append(") ").toString();
    }

    private static List<Section> findClashSections(
        List<Section> reservedSections,
        Section newSection,
        Connection con,
        String term
    ) throws SQLException
    {
        Vector<Section> clashes = new Vector<>();
        if(newSection == null || con == null) return clashes;

        for(Section section : reservedSections)
            if(section.getSectionId() == newSection.getSectionId()) return clashes;

        String sql =
            "SELECT COUNT(DISTINCT T.SECTION_ID) " +
            "FROM UMS.TIME_TABLE T " +
            "JOIN UMS.SLOT S ON S.SLOT_ID = T.SLOT_ID " +
            "WHERE T.SECTION_ID = ? " +
            "AND S.TERM_CDE = ? " +
            "AND (T.DAY_ID || '-' || T.SLOT_ID) IN (" +
            "    SELECT DAY_ID || '-' || SLOT_ID " +
            "    FROM UMS.TIME_TABLE " +
            "    WHERE SECTION_ID = ?" +
            ")";

        try(PreparedStatement stmt = con.prepareStatement(sql))
        {
            for(Section section : reservedSections)
            {
                stmt.setInt(1, section.getSectionId());
                stmt.setString(2, term);
                stmt.setInt(3, newSection.getSectionId());

                try(ResultSet rs = stmt.executeQuery())
                {
                    if(rs.next() && rs.getInt(1) > 0) clashes.add(section);
                }
            }
        }

        return clashes;
    }
}
