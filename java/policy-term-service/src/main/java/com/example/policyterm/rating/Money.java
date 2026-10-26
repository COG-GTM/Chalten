package com.example.policyterm.rating;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Exact money arithmetic for the port. The Smalltalk works in exact fractions and rounds once,
 * so every helper here divides exactly and rounds to cents in a single step.
 */
public final class Money {

  private Money() {}

  /** Derived from ProRataEarnedPremiumCalculator class>>roundToCents: (source/PersonalLines-Rating/ProRataEarnedPremiumCalculator.class.st): (amount * 100) rounded / 100, i.e. half away from zero to two decimals. */
  public static BigDecimal roundToCents(BigDecimal amount) {
    return amount.setScale(2, RoundingMode.HALF_UP);
  }

  /** Exact {@code numerator / denominator} rounded once to cents, matching roundToCents: applied to a Smalltalk Fraction. */
  public static BigDecimal divideToCents(BigDecimal numerator, BigDecimal denominator) {
    return numerator.divide(denominator, 2, RoundingMode.HALF_UP);
  }

  public static void requireNonNegative(BigDecimal amount, String message) {
    if (amount.signum() < 0) {
      throw new IllegalArgumentException(message);
    }
  }
}
