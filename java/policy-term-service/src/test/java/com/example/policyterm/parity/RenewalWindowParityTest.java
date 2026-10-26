package com.example.policyterm.parity;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.example.policyterm.rating.PolicyTerm;
import com.example.policyterm.rating.RenewalOfferWindow;
import java.time.LocalDate;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvFileSource;

/** Replays modernization/golden/renewal_windows.csv (produced by Pharo) through RenewalOfferWindow. */
class RenewalWindowParityTest {

  @ParameterizedTest(name = "[{index}] {0} {1}m lead {2}")
  @CsvFileSource(resources = "/golden/renewal_windows.csv", numLinesToSkip = 1)
  void renewalWindowMatchesSmalltalk(LocalDate effective, int termMonths, int leadDays, LocalDate opensOn,
      LocalDate closesOn, long daysUntilOpeningFromEffective, boolean openDayBeforeOpening, boolean openOnOpening,
      boolean openOnClosing, boolean openOnExpiration) {
    PolicyTerm term = PolicyTerm.effectiveOn(effective, termMonths);
    RenewalOfferWindow window = RenewalOfferWindow.forTerm(term, leadDays);
    assertEquals(opensOn, window.opensOn(), "opensOn");
    assertEquals(closesOn, window.closesOn(), "closesOn");
    assertEquals(daysUntilOpeningFromEffective, window.daysUntilOpeningFrom(effective), "daysUntilOpeningFrom:");
    assertEquals(openDayBeforeOpening, window.isOpenOn(opensOn.minusDays(1)), "isOpenOn: day before opening");
    assertEquals(openOnOpening, window.isOpenOn(opensOn), "isOpenOn: opening");
    assertEquals(openOnClosing, window.isOpenOn(closesOn), "isOpenOn: closing");
    assertEquals(openOnExpiration, window.isOpenOn(term.expirationDate()), "isOpenOn: expiration");
  }
}
