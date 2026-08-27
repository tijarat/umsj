package com.ums.packages;

public class ShowedCourse 
{
  public String courseCde = null;
  public int courseOrder = 0;
  public int courseSemester = 0;
  public ShowedCourse(String cCode,int cNbr, int sNbr)
  {
    courseCde = cCode;
    courseOrder = cNbr;
    courseSemester = sNbr;
  }
}