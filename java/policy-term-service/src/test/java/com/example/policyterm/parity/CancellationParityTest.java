package com.example.policyterm.parity;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.example.policyterm.rating.PolicyTerm;
import com.example.policyterm.rating.ProRataEarnedPremiumCalculator;
import com.example.policyterm.rating.ShortRateCancellationTable;
import java.math.BigDecimal;
import java.time.LocalDate;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvFileSource;

/** Replays modernization/golden/cancellations.csv (produced by Pharo): pro-rata and short-rate rules, exact BigDecimal equality. */
class CancellationParityTest {

  @ParameterizedTest(name = "[{index}] {0} {1}m premium {2} cancelled {3}")
  @CsvFileSource(resources = "/golden/cancellations.csv", numLinesToSkip = 1)
  void cancellationMatchesSmalltalk(LocalDate effective, int termMonths, BigDecimal writtenPremium,
      LocalDate cancellation, long daysInForce, boolean inForce, BigDecimal proRataEarned, BigDecimal proRataUnearned,
      int shortRatePct, BigDecimal shortRateEarned, BigDecimal shortRatePenalty) {
    PolicyTerm term = PolicyTerm.effectiveOn(effective, termMonths);
    ProRataEarnedPremiumCalculator proRata = ProRataEarnedPremiumCalculator.forTerm(term);
    ShortRateCancellationTable shortRate = ShortRateCancellationTable.standard();
    assertEquals(daysInForce, term.daysInForceAt(cancellation), "daysInForceAt:");
    assertEquals(inForce, term.includes(cancellation), "includes:");
    assertEquals(proRataEarned, proRata.earnedPremium(writtenPremium, cancellation), "pro-rata earnedPremiumOf:cancelledOn:");
    assertEquals(proRataUnearned, proRata.unearnedPremium(writtenPremium, cancellation), "pro-rata unearnedPremiumOf:cancelledOn:");
    assertEquals(shortRatePct, shortRate.retainedPercentage(term, cancellation), "retainedPercentageFor:cancelledOn:");
    assertEquals(shortRateEarned, shortRate.earnedPremium(writtenPremium, term, cancellation), "short-rate earnedPremiumOf:for:cancelledOn:");
    assertEquals(shortRatePenalty, shortRate.penalty(writtenPremium, term, cancellation), "penaltyOf:for:cancelledOn:");
  }
}
