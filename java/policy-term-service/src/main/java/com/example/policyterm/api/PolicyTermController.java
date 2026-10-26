package com.example.policyterm.api;

import com.example.policyterm.rating.HomeownersPremiumCalculator;
import com.example.policyterm.rating.PolicyTerm;
import com.example.policyterm.rating.ProRataEarnedPremiumCalculator;
import com.example.policyterm.rating.RenewalOfferWindow;
import com.example.policyterm.rating.ShortRateCancellationTable;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Thin REST facade over the ported rating rules. No persistence, no UI: every endpoint is a pure calculation.
 */
@RestController
public class PolicyTermController {

  public record TermRequest(@NotNull LocalDate effectiveDate, @NotNull Integer termMonths) {}

  public record TermResponse(LocalDate effectiveDate, int termMonths, LocalDate expirationDate, long termDays,
      LocalDate lastDateInForce, LocalDate renewalOpensOn, LocalDate renewalClosesOn) {}

  public record CancellationRequest(@NotNull LocalDate effectiveDate, @NotNull Integer termMonths,
      @NotNull BigDecimal writtenPremium, @NotNull LocalDate cancellationDate) {}

  public record ProRataResponse(long daysInForce, long termDays, BigDecimal earnedPremium, BigDecimal unearnedPremium) {}

  public record ShortRateResponse(long daysInForce, int retainedPercentage, BigDecimal earnedPremium,
      BigDecimal proRataEarnedPremium, BigDecimal penalty) {}

  public record RenewalWindowRequest(@NotNull LocalDate effectiveDate, @NotNull Integer termMonths, Integer leadDays,
      LocalDate asOf) {}

  public record RenewalWindowResponse(LocalDate opensOn, LocalDate closesOn, Boolean openAsOf, Long daysUntilOpening) {}

  public record HomeownersRequest(@NotNull BigDecimal dwellingCoverage, @NotNull BigDecimal scheduledValue,
      @NotNull BigDecimal deductible, Integer termMonths) {}

  public record HomeownersResponse(BigDecimal dwellingPremium, BigDecimal valuableArticlesPremium,
      BigDecimal deductibleCredit, BigDecimal annualPremium, BigDecimal termPremium) {}

  /** Derived from PolicyTerm class>>effectiveOn:lastingMonths: and friends. */
  @PostMapping("/policy-terms")
  public TermResponse policyTerm(@Valid @RequestBody TermRequest request) {
    PolicyTerm term = PolicyTerm.effectiveOn(request.effectiveDate(), request.termMonths());
    RenewalOfferWindow window = term.renewalOfferWindow();
    return new TermResponse(term.effectiveDate(), term.termInMonths(), term.expirationDate(), term.numberOfDays(),
        term.lastDateInForce(), window.opensOn(), window.closesOn());
  }

  /** Derived from ProRataEarnedPremiumCalculator>>earnedPremiumOf:cancelledOn:. */
  @PostMapping("/policy-terms/pro-rata")
  public ProRataResponse proRata(@Valid @RequestBody CancellationRequest request) {
    PolicyTerm term = PolicyTerm.effectiveOn(request.effectiveDate(), request.termMonths());
    ProRataEarnedPremiumCalculator calculator = ProRataEarnedPremiumCalculator.forTerm(term);
    return new ProRataResponse(term.daysInForceAt(request.cancellationDate()), term.numberOfDays(),
        calculator.earnedPremium(request.writtenPremium(), request.cancellationDate()),
        calculator.unearnedPremium(request.writtenPremium(), request.cancellationDate()));
  }

  /** Derived from ShortRateCancellationTable>>earnedPremiumOf:for:cancelledOn:. */
  @PostMapping("/policy-terms/short-rate")
  public ShortRateResponse shortRate(@Valid @RequestBody CancellationRequest request) {
    PolicyTerm term = PolicyTerm.effectiveOn(request.effectiveDate(), request.termMonths());
    ShortRateCancellationTable table = ShortRateCancellationTable.standard();
    BigDecimal proRata = ProRataEarnedPremiumCalculator.forTerm(term)
        .earnedPremium(request.writtenPremium(), request.cancellationDate());
    return new ShortRateResponse(term.daysInForceAt(request.cancellationDate()),
        table.retainedPercentage(term, request.cancellationDate()),
        table.earnedPremium(request.writtenPremium(), term, request.cancellationDate()), proRata,
        table.penalty(request.writtenPremium(), term, request.cancellationDate()));
  }

  /** Derived from RenewalOfferWindow>>opensOn, closesOn, isOpenOn:, daysUntilOpeningFrom:. */
  @PostMapping("/policy-terms/renewal-window")
  public RenewalWindowResponse renewalWindow(@Valid @RequestBody RenewalWindowRequest request) {
    PolicyTerm term = PolicyTerm.effectiveOn(request.effectiveDate(), request.termMonths());
    RenewalOfferWindow window = request.leadDays() == null
        ? RenewalOfferWindow.standardFor(term)
        : RenewalOfferWindow.forTerm(term, request.leadDays());
    LocalDate asOf = request.asOf();
    return new RenewalWindowResponse(window.opensOn(), window.closesOn(),
        asOf == null ? null : window.isOpenOn(asOf), asOf == null ? null : window.daysUntilOpeningFrom(asOf));
  }

  /** Derived from HomeownersPremiumCalculator>>annualPremiumForDwelling:valuableArticles:deductible: and termPremium...over:. */
  @PostMapping("/premiums/homeowners")
  public HomeownersResponse homeowners(@Valid @RequestBody HomeownersRequest request) {
    HomeownersPremiumCalculator calculator = HomeownersPremiumCalculator.standard();
    int termMonths = request.termMonths() == null ? 12 : request.termMonths();
    PolicyTerm term = PolicyTerm.effectiveOn(LocalDate.of(2025, 1, 1), termMonths);
    return new HomeownersResponse(calculator.dwellingPremium(request.dwellingCoverage()),
        calculator.valuableArticlesPremium(request.scheduledValue()),
        calculator.deductibleCredit(request.dwellingCoverage(), request.deductible()),
        calculator.annualPremium(request.dwellingCoverage(), request.scheduledValue(), request.deductible()),
        calculator.termPremium(request.dwellingCoverage(), request.scheduledValue(), request.deductible(), term));
  }

  @ExceptionHandler({IllegalArgumentException.class, ArithmeticException.class, MethodArgumentNotValidException.class})
  @ResponseStatus(HttpStatus.BAD_REQUEST)
  public Map<String, String> badRequest(Exception exception) {
    return Map.of("error", exception.getMessage() == null ? exception.getClass().getSimpleName() : exception.getMessage());
  }
}
