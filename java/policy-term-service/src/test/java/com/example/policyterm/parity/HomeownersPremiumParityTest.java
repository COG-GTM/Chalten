package com.example.policyterm.parity;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.example.policyterm.rating.HomeownersPremiumCalculator;
import com.example.policyterm.rating.PolicyTerm;
import java.math.BigDecimal;
import java.time.LocalDate;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvFileSource;

/** Replays modernization/golden/homeowners_premiums.csv (produced by Pharo) through HomeownersPremiumCalculator. */
class HomeownersPremiumParityTest {

  private static final PolicyTerm SIX_MONTHS = PolicyTerm.sixMonthsFrom(LocalDate.of(2025, 1, 1));
  private static final PolicyTerm TWELVE_MONTHS = PolicyTerm.twelveMonthsFrom(LocalDate.of(2025, 1, 1));

  @ParameterizedTest(name = "[{index}] dwelling {0} scheduled {1} deductible {2}")
  @CsvFileSource(resources = "/golden/homeowners_premiums.csv", numLinesToSkip = 1)
  void homeownersPremiumMatchesSmalltalk(BigDecimal dwelling, BigDecimal scheduled, BigDecimal deductible,
      BigDecimal dwellingPremium, BigDecimal valuableArticlesPremium, BigDecimal deductibleCredit,
      BigDecimal annualPremium, BigDecimal sixMonthPremium, BigDecimal twelveMonthPremium) {
    HomeownersPremiumCalculator calculator = HomeownersPremiumCalculator.standard();
    assertEquals(dwellingPremium, calculator.dwellingPremium(dwelling), "dwellingPremiumFor:");
    assertEquals(valuableArticlesPremium, calculator.valuableArticlesPremium(scheduled), "valuableArticlesPremiumFor:");
    assertEquals(deductibleCredit, calculator.deductibleCredit(dwelling, deductible), "deductibleCreditForDwelling:deductible:");
    assertEquals(annualPremium, calculator.annualPremium(dwelling, scheduled, deductible), "annualPremiumForDwelling:valuableArticles:deductible:");
    assertEquals(sixMonthPremium, calculator.termPremium(dwelling, scheduled, deductible, SIX_MONTHS), "termPremium... over: 6 months");
    assertEquals(twelveMonthPremium, calculator.termPremium(dwelling, scheduled, deductible, TWELVE_MONTHS), "termPremium... over: 12 months");
  }
}
