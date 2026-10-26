package com.example.policyterm.dates;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.temporal.ChronoUnit;

/**
 * The Chalten-Core Gregorian date rules the rating port depends on, expressed with java.time.
 * Each method cites the Smalltalk method it was derived from (file under source/Chalten-Core/).
 * Chalten is proleptic Gregorian, as is java.time, so the two agree for every year.
 */
public final class ChaltenDates {

  private ChaltenDates() {}

  /** Derived from GregorianYear>>isLeapYear (source/Chalten-Core/GregorianYear.class.st): divisible by 4 and not a century, or a century divisible by 400. */
  public static boolean isLeapYear(int year) {
    boolean divisibleByFour = year % 4 == 0;
    boolean centennial = year % 100 == 0;
    boolean divisibleByFourHundred = year % 400 == 0;
    return (divisibleByFour && !centennial) || (centennial && divisibleByFourHundred);
  }

  /** Derived from GregorianYear>>numberOfDays (source/Chalten-Core/GregorianYear.class.st): 366 in a leap year, 365 otherwise. */
  public static int numberOfDaysInYear(int year) {
    return isLeapYear(year) ? 366 : 365;
  }

  /** Derived from GregorianMonthOfYear>>numberOfDays and GregorianMonth class>>initialize (source/Chalten-Core/GregorianMonth.class.st): February has 29 days in a leap year and 28 otherwise; April, June, September and November have 30; the rest 31. */
  public static int numberOfDaysInMonth(YearMonth monthOfYear) {
    return switch (monthOfYear.getMonthValue()) {
      case 2 -> isLeapYear(monthOfYear.getYear()) ? 29 : 28;
      case 4, 6, 9, 11 -> 30;
      default -> 31;
    };
  }

  /** Derived from GregorianMonthOfYear>>dateAt: (source/Chalten-Core/GregorianMonthOfYear.class.st): the day number must be between 1 and the month's number of days, otherwise InstanceCreationFailed. */
  public static LocalDate dateAt(YearMonth monthOfYear, int dayNumber) {
    int lastDay = numberOfDaysInMonth(monthOfYear);
    if (dayNumber < 1 || dayNumber > lastDay) {
      throw new IllegalArgumentException(dayNumber + " is an invalid day number in " + monthOfYear);
    }
    return monthOfYear.atDay(dayNumber);
  }

  /** Derived from CalendarDate>>next (source/Chalten-Core/CalendarDate.class.st): the following day, rolling into the next month and year as needed. */
  public static LocalDate next(LocalDate date) {
    return nextDays(date, 1);
  }

  /** Derived from CalendarDate>>previous (source/Chalten-Core/CalendarDate.class.st): the preceding day, rolling into the previous month and year as needed. */
  public static LocalDate previous(LocalDate date) {
    return previousDays(date, 1);
  }

  /** Derived from CalendarDate>>next: (source/Chalten-Core/CalendarDate.class.st): zero leaves the date unchanged, a negative quantity delegates to previous:, otherwise moves forward that many days. */
  public static LocalDate nextDays(LocalDate date, long days) {
    if (days == 0) {
      return date;
    }
    if (days < 0) {
      return previousDays(date, -days);
    }
    return date.plusDays(days);
  }

  /** Derived from CalendarDate>>previous: (source/Chalten-Core/CalendarDate.class.st): zero leaves the date unchanged, a negative quantity delegates to next:, otherwise moves back that many days. */
  public static LocalDate previousDays(LocalDate date, long days) {
    if (days == 0) {
      return date;
    }
    if (days < 0) {
      return nextDays(date, -days);
    }
    return date.minusDays(days);
  }

  /** Derived from CalendarDate>>subtractionFromCalendarDate: (source/Chalten-Core/CalendarDate.class.st): days from start to end; equal dates give 0 and a start after the end raises ArithmeticError. */
  public static long daysBetween(LocalDate start, LocalDate end) {
    if (start.isAfter(end)) {
      throw new ArithmeticException("Cannot subtract two dates when the second one is greater than the first one.");
    }
    return ChronoUnit.DAYS.between(start, end);
  }

  /** Derived from GregorianMonthOfYear>>next: and GregorianMonthOfYear>>previous: (source/Chalten-Core/GregorianMonthOfYear.class.st): whole years keep the month; a partial year wraps into the following year when the month index goes down. */
  public static YearMonth monthOfYearNext(YearMonth monthOfYear, int months) {
    return monthOfYear.plusMonths(months);
  }

  /** Derived from CalendarDate>>isLastDayOfMonth (source/Chalten-Core/CalendarDate.class.st): true when the date equals its month's last date. */
  public static boolean isLastDayOfMonth(LocalDate date) {
    return date.getDayOfMonth() == numberOfDaysInMonth(YearMonth.from(date));
  }

  /** Derived from DayOfWeek class>>initializeDaysOfWeek and GregorianDate>>dayOfWeek (source/Chalten-Core/DayOfWeek.class.st): ISO week, Monday through Sunday, printed by English name. */
  public static String dayOfWeekName(LocalDate date) {
    DayOfWeek dayOfWeek = date.getDayOfWeek();
    String name = dayOfWeek.name();
    return name.charAt(0) + name.substring(1).toLowerCase();
  }
}
