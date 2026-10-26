package com.example.policyterm.parity;

import static org.junit.jupiter.api.Assertions.assertThrows;

import com.example.policyterm.dates.ChaltenDates;
import com.example.policyterm.rating.HomeownersPremiumCalculator;
import com.example.policyterm.rating.PolicyTerm;
import com.example.policyterm.rating.ProRataEarnedPremiumCalculator;
import com.example.policyterm.rating.RenewalOfferWindow;
import com.example.policyterm.rating.ShortRateCancellationTable;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.Map;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvFileSource;

/**
 * Replays modernization/golden/invalid_inputs.csv: every expression the Smalltalk rejected
 * (InstanceCreationFailed, AssertionFailed, ObjectNotFound) must be rejected by the Java with IllegalArgumentException.
 */
class InvalidInputParityTest {

  private static final LocalDate REFERENCE = LocalDate.of(2024, 1, 1);

  private static final Map<String, Runnable> JAVA_EQUIVALENTS = Map.of(
      "PolicyTerm effectiveOn: referenceDate lastingMonths: 7", () -> PolicyTerm.effectiveOn(REFERENCE, 7),
      "PolicyTerm effectiveOn: referenceDate lastingMonths: 0", () -> PolicyTerm.effectiveOn(REFERENCE, 0),
      "( ProRataEarnedPremiumCalculator for: ( PolicyTerm twelveMonthsFrom: referenceDate ) ) earnedPremiumOf: -1 cancelledOn: referenceDate",
      () -> ProRataEarnedPremiumCalculator.forTerm(PolicyTerm.twelveMonthsFrom(REFERENCE)).earnedPremium(BigDecimal.valueOf(-1), REFERENCE),
      "RenewalOfferWindow for: ( PolicyTerm twelveMonthsFrom: referenceDate ) openingDaysBeforeExpiration: 0",
      () -> RenewalOfferWindow.forTerm(PolicyTerm.twelveMonthsFrom(REFERENCE), 0),
      "homeCalculator deductibleCreditForDwelling: 100000 deductible: 750",
      () -> HomeownersPremiumCalculator.standard().deductibleCredit(BigDecimal.valueOf(100000), BigDecimal.valueOf(750)),
      "homeCalculator dwellingPremiumFor: -100", () -> HomeownersPremiumCalculator.standard().dwellingPremium(BigDecimal.valueOf(-100)),
      "ShortRateCancellationTable new addBandUpTo: 10 retaining: 17; addBandUpTo: 5 retaining: 10",
      () -> new ShortRateCancellationTable().addBand(10, 17).addBand(5, 10),
      "dateAt value: 2025 value: 2 value: 29", () -> ChaltenDates.dateAt(YearMonth.of(2025, 2), 29),
      "dateAt value: 2025 value: 4 value: 31", () -> ChaltenDates.dateAt(YearMonth.of(2025, 4), 31));

  @ParameterizedTest(name = "[{index}] {0}: {2}")
  @CsvFileSource(resources = "/golden/invalid_inputs.csv", numLinesToSkip = 1)
  void javaRejectsWhatSmalltalkRejects(String rule, String smalltalkExpression, String expectedError) {
    Runnable javaEquivalent = JAVA_EQUIVALENTS.get(smalltalkExpression);
    if (javaEquivalent == null) {
      throw new IllegalStateException("No Java equivalent registered for golden expression: " + smalltalkExpression);
    }
    assertThrows(IllegalArgumentException.class, javaEquivalent::run,
        rule + " should reject like the Smalltalk (" + expectedError + ")");
  }
}
