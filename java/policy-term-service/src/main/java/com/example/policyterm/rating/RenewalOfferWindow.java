package com.example.policyterm.rating;

import com.example.policyterm.dates.ChaltenDates;
import java.time.LocalDate;

/**
 * Derived from RenewalOfferWindow (source/PersonalLines-Rating/RenewalOfferWindow.class.st).
 */
public final class RenewalOfferWindow {

  /** Derived from RenewalOfferWindow class>>standardLeadTimeInDays. */
  public static final int STANDARD_LEAD_TIME_IN_DAYS = 45;

  private final PolicyTerm policyTerm;
  private final int leadTimeInDays;

  private RenewalOfferWindow(PolicyTerm policyTerm, int leadTimeInDays) {
    this.policyTerm = policyTerm;
    this.leadTimeInDays = leadTimeInDays;
  }

  /** Derived from RenewalOfferWindow class>>for:openingDaysBeforeExpiration: : the lead time must be positive (InstanceCreationFailed otherwise). */
  public static RenewalOfferWindow forTerm(PolicyTerm policyTerm, int leadTimeInDays) {
    if (leadTimeInDays <= 0) {
      throw new IllegalArgumentException("The renewal lead time must be a positive number of days");
    }
    return new RenewalOfferWindow(policyTerm, leadTimeInDays);
  }

  /** Derived from RenewalOfferWindow class>>standardFor:. */
  public static RenewalOfferWindow standardFor(PolicyTerm policyTerm) {
    return forTerm(policyTerm, STANDARD_LEAD_TIME_IN_DAYS);
  }

  /** Derived from RenewalOfferWindow>>opensOn: expiration previous: leadTime (CalendarDate>>previous:), never before the effective date. */
  public LocalDate opensOn() {
    LocalDate candidate = ChaltenDates.previousDays(policyTerm.expirationDate(), leadTimeInDays);
    return candidate.isBefore(policyTerm.effectiveDate()) ? policyTerm.effectiveDate() : candidate;
  }

  /** Derived from RenewalOfferWindow>>closesOn: the policy's last date in force. */
  public LocalDate closesOn() {
    return policyTerm.lastDateInForce();
  }

  /** Derived from RenewalOfferWindow>>isOpenOn: : opensOn <= date <= closesOn. */
  public boolean isOpenOn(LocalDate date) {
    return !date.isBefore(opensOn()) && !date.isAfter(closesOn());
  }

  /** Derived from RenewalOfferWindow>>daysUntilOpeningFrom: : 0 once open, otherwise opensOn - date. */
  public long daysUntilOpeningFrom(LocalDate date) {
    LocalDate opens = opensOn();
    if (!date.isBefore(opens)) {
      return 0;
    }
    return ChaltenDates.daysBetween(date, opens);
  }

  public int leadTimeInDays() {
    return leadTimeInDays;
  }

  public PolicyTerm policyTerm() {
    return policyTerm;
  }
}
