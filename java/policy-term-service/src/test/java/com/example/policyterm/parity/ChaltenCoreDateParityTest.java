package com.example.policyterm.parity;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.example.policyterm.dates.ChaltenDates;
import java.time.LocalDate;
import java.time.YearMonth;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvFileSource;

/** Replays modernization/golden/chalten_core_dates.csv (produced by Pharo running Chalten-Core itself) through ChaltenDates. */
class ChaltenCoreDateParityTest {

  @ParameterizedTest(name = "[{index}] {0} {1} {2} -> {3}")
  @CsvFileSource(resources = "/golden/chalten_core_dates.csv", numLinesToSkip = 1, nullValues = "")
  void chaltenCoreDateRuleMatchesSmalltalk(LocalDate date, String operation, String argument, String expected) {
    String actual = switch (operation) {
      case "isLeapYear" -> String.valueOf(ChaltenDates.isLeapYear(date.getYear()));
      case "yearNumberOfDays" -> String.valueOf(ChaltenDates.numberOfDaysInYear(date.getYear()));
      case "monthNumberOfDays" -> String.valueOf(ChaltenDates.numberOfDaysInMonth(YearMonth.from(date)));
      case "isLastDayOfMonth" -> String.valueOf(ChaltenDates.isLastDayOfMonth(date));
      case "dayOfWeek" -> ChaltenDates.dayOfWeekName(date);
      case "next" -> ChaltenDates.next(date).toString();
      case "previous" -> ChaltenDates.previous(date).toString();
      case "daysSinceReference" -> {
        LocalDate reference = LocalDate.parse(argument);
        yield String.valueOf(date.isBefore(reference)
            ? -ChaltenDates.daysBetween(date, reference)
            : ChaltenDates.daysBetween(reference, date));
      }
      case "nextDays" -> ChaltenDates.nextDays(date, Long.parseLong(argument)).toString();
      case "monthOfYearNextMonths" -> ChaltenDates.monthOfYearNext(YearMonth.from(date), Integer.parseInt(argument)).toString();
      default -> throw new IllegalArgumentException("unknown golden operation " + operation);
    };
    assertEquals(expected, actual, operation + " " + (argument == null ? "" : argument));
  }
}
