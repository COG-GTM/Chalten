package com.example.policyterm.parity;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.example.policyterm.rating.PolicyTerm;
import com.example.policyterm.rating.RenewalOfferWindow;
import java.time.LocalDate;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvFileSource;

/** Replays modernization/golden/policy_terms.csv (produced by Pharo) through the Java PolicyTerm. */
class PolicyTermParityTest {

  @ParameterizedTest(name = "[{index}] {0} {1}m -> {2}")
  @CsvFileSource(resources = "/golden/policy_terms.csv", numLinesToSkip = 1)
  void policyTermMatchesSmalltalk(LocalDate effective, int termMonths, LocalDate expiration, long termDays,
      LocalDate lastDateInForce, LocalDate renewalOpensOn, LocalDate renewalClosesOn) {
    PolicyTerm term = PolicyTerm.effectiveOn(effective, termMonths);
    RenewalOfferWindow window = term.renewalOfferWindow();
    assertEquals(expiration, term.expirationDate(), "expirationDate");
    assertEquals(termDays, term.numberOfDays(), "numberOfDays");
    assertEquals(lastDateInForce, term.lastDateInForce(), "lastDateInForce");
    assertEquals(renewalOpensOn, window.opensOn(), "renewal opensOn");
    assertEquals(renewalClosesOn, window.closesOn(), "renewal closesOn");
  }
}
