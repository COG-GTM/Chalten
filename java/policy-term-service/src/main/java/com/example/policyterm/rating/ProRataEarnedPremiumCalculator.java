package com.example.policyterm.rating;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Derived from ProRataEarnedPremiumCalculator (source/PersonalLines-Rating/ProRataEarnedPremiumCalculator.class.st).
 */
public final class ProRataEarnedPremiumCalculator {

  private final PolicyTerm policyTerm;

  private ProRataEarnedPremiumCalculator(PolicyTerm policyTerm) {
    this.policyTerm = policyTerm;
  }

  /** Derived from ProRataEarnedPremiumCalculator class>>for:. */
  public static ProRataEarnedPremiumCalculator forTerm(PolicyTerm policyTerm) {
    return new ProRataEarnedPremiumCalculator(policyTerm);
  }

  /** Derived from ProRataEarnedPremiumCalculator>>earnedPremiumOf:cancelledOn: : written * daysInForce / termDays, rounded once to cents; negative premiums fail the AssertionChecker. */
  public BigDecimal earnedPremium(BigDecimal writtenPremium, LocalDate cancellationDate) {
    Money.requireNonNegative(writtenPremium, "Written premium cannot be negative");
    BigDecimal daysInForce = BigDecimal.valueOf(policyTerm.daysInForceAt(cancellationDate));
    BigDecimal termDays = BigDecimal.valueOf(policyTerm.numberOfDays());
    return Money.divideToCents(writtenPremium.multiply(daysInForce), termDays);
  }

  /** Derived from ProRataEarnedPremiumCalculator>>unearnedPremiumOf:cancelledOn: : written - earned. */
  public BigDecimal unearnedPremium(BigDecimal writtenPremium, LocalDate cancellationDate) {
    return writtenPremium.subtract(earnedPremium(writtenPremium, cancellationDate));
  }

  public PolicyTerm policyTerm() {
    return policyTerm;
  }
}
