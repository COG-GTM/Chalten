package com.example.policyterm.rating;

import com.example.policyterm.dates.ChaltenDates;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.Set;

/**
 * Derived from PolicyTerm (source/PersonalLines-Rating/PolicyTerm.class.st).
 * The period a policy is in force: [effectiveDate, expirationDate).
 */
public final class PolicyTerm {

  /** Derived from PolicyTerm class>>allowedTermsInMonths. */
  private static final Set<Integer> ALLOWED_TERMS_IN_MONTHS = Set.of(6, 12);

  private final LocalDate effectiveDate;
  private final int termInMonths;
  private final LocalDate expirationDate;

  private PolicyTerm(LocalDate effectiveDate, int termInMonths) {
    this.effectiveDate = effectiveDate;
    this.termInMonths = termInMonths;
    this.expirationDate = calculateExpirationDate();
  }

  /** Derived from PolicyTerm class>>effectiveOn:lastingMonths: : only 6 or 12 month terms are allowed (InstanceCreationFailed otherwise). */
  public static PolicyTerm effectiveOn(LocalDate effectiveDate, int termInMonths) {
    if (!ALLOWED_TERMS_IN_MONTHS.contains(termInMonths)) {
      throw new IllegalArgumentException("Policy terms must last 6 or 12 months");
    }
    return new PolicyTerm(effectiveDate, termInMonths);
  }

  /** Derived from PolicyTerm class>>sixMonthsFrom:. */
  public static PolicyTerm sixMonthsFrom(LocalDate effectiveDate) {
    return effectiveOn(effectiveDate, 6);
  }

  /** Derived from PolicyTerm class>>twelveMonthsFrom:. */
  public static PolicyTerm twelveMonthsFrom(LocalDate effectiveDate) {
    return effectiveOn(effectiveDate, 12);
  }

  /** Derived from PolicyTerm>>calculateExpirationDate: the anniversary month via GregorianMonthOfYear>>next:, with the day clamped to that month's last day. */
  private LocalDate calculateExpirationDate() {
    YearMonth anniversaryMonth = ChaltenDates.monthOfYearNext(YearMonth.from(effectiveDate), termInMonths);
    int lastValidDayNumber = ChaltenDates.numberOfDaysInMonth(anniversaryMonth);
    return ChaltenDates.dateAt(anniversaryMonth, Math.min(effectiveDate.getDayOfMonth(), lastValidDayNumber));
  }

  /** Derived from PolicyTerm>>daysInForceAt: : 0 on or before the effective date, the whole term on or after expiration, otherwise date - effectiveDate. */
  public long daysInForceAt(LocalDate date) {
    if (!date.isAfter(effectiveDate)) {
      return 0;
    }
    if (!date.isBefore(expirationDate)) {
      return numberOfDays();
    }
    return ChaltenDates.daysBetween(effectiveDate, date);
  }

  /** Derived from PolicyTerm>>numberOfDays: expirationDate - effectiveDate via CalendarDate>>subtractionFromCalendarDate:. */
  public long numberOfDays() {
    return ChaltenDates.daysBetween(effectiveDate, expirationDate);
  }

  /** Derived from PolicyTerm>>includes: : effectiveDate <= date < expirationDate. */
  public boolean includes(LocalDate date) {
    return !date.isBefore(effectiveDate) && date.isBefore(expirationDate);
  }

  /** Derived from PolicyTerm>>lastDateInForce: the day before expiration (CalendarDate>>previous). */
  public LocalDate lastDateInForce() {
    return ChaltenDates.previous(expirationDate);
  }

  /** Derived from PolicyTerm>>isAnnual. */
  public boolean isAnnual() {
    return termInMonths == 12;
  }

  /** Derived from PolicyTerm>>renewalOfferWindow. */
  public RenewalOfferWindow renewalOfferWindow() {
    return RenewalOfferWindow.standardFor(this);
  }

  public LocalDate effectiveDate() {
    return effectiveDate;
  }

  public int termInMonths() {
    return termInMonths;
  }

  public LocalDate expirationDate() {
    return expirationDate;
  }

  @Override
  public String toString() {
    return termInMonths + "-month term from " + effectiveDate + " to " + expirationDate;
  }
}
