package com.example.policyterm.rating;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Derived from HomeownersPremiumCalculator (source/PersonalLines-Rating/HomeownersPremiumCalculator.class.st).
 * Every component is rounded to cents before being combined, as the Smalltalk does.
 */
public final class HomeownersPremiumCalculator {

  private static final BigDecimal THOUSAND = BigDecimal.valueOf(1000);
  private static final BigDecimal HUNDRED = BigDecimal.valueOf(100);
  private static final BigDecimal TWELVE = BigDecimal.valueOf(12);

  private BigDecimal dwellingRatePerThousand = BigDecimal.ZERO;
  private BigDecimal valuableArticlesRatePerThousand = BigDecimal.ZERO;
  private BigDecimal valuableArticlesMinimumPremium = BigDecimal.ZERO;
  private final Map<BigDecimal, Integer> deductibleCreditPercentages = new LinkedHashMap<>();

  /** Derived from HomeownersPremiumCalculator class>>standard: 3.50 per thousand dwelling, 12.50 per thousand scheduled (25 minimum), credits 0/5/12/20 percent for 500/1000/2500/5000 deductibles. */
  public static HomeownersPremiumCalculator standard() {
    return new HomeownersPremiumCalculator()
        .dwellingRatePerThousand(new BigDecimal("3.50"))
        .valuableArticlesRatePerThousand(new BigDecimal("12.50"))
        .valuableArticlesMinimumPremium(new BigDecimal("25"))
        .creditPercentage(0, new BigDecimal("500"))
        .creditPercentage(5, new BigDecimal("1000"))
        .creditPercentage(12, new BigDecimal("2500"))
        .creditPercentage(20, new BigDecimal("5000"));
  }

  /** Derived from HomeownersPremiumCalculator>>dwellingRatePerThousand:. */
  public HomeownersPremiumCalculator dwellingRatePerThousand(BigDecimal rate) {
    this.dwellingRatePerThousand = rate;
    return this;
  }

  /** Derived from HomeownersPremiumCalculator>>valuableArticlesRatePerThousand:. */
  public HomeownersPremiumCalculator valuableArticlesRatePerThousand(BigDecimal rate) {
    this.valuableArticlesRatePerThousand = rate;
    return this;
  }

  /** Derived from HomeownersPremiumCalculator>>valuableArticlesMinimumPremium:. */
  public HomeownersPremiumCalculator valuableArticlesMinimumPremium(BigDecimal amount) {
    this.valuableArticlesMinimumPremium = amount;
    return this;
  }

  /** Derived from HomeownersPremiumCalculator>>creditPercentage:forDeductible:. */
  public HomeownersPremiumCalculator creditPercentage(int percentage, BigDecimal deductible) {
    deductibleCreditPercentages.put(deductible.stripTrailingZeros(), percentage);
    return this;
  }

  /** Derived from HomeownersPremiumCalculator>>dwellingPremiumFor: : coverage / 1000 * rate, rounded to cents; negative coverage fails the AssertionChecker. */
  public BigDecimal dwellingPremium(BigDecimal dwellingCoverage) {
    Money.requireNonNegative(dwellingCoverage, "Coverage amounts cannot be negative");
    return Money.divideToCents(dwellingCoverage.multiply(dwellingRatePerThousand), THOUSAND);
  }

  /** Derived from HomeownersPremiumCalculator>>valuableArticlesPremiumFor: : zero when nothing is scheduled, otherwise max(rounded value / 1000 * rate, minimum premium); the minimum is compared as configured, unrounded, exactly as the Smalltalk does. */
  public BigDecimal valuableArticlesPremium(BigDecimal scheduledValue) {
    Money.requireNonNegative(scheduledValue, "Coverage amounts cannot be negative");
    if (scheduledValue.signum() == 0) {
      return Money.roundToCents(BigDecimal.ZERO);
    }
    BigDecimal premium = Money.divideToCents(scheduledValue.multiply(valuableArticlesRatePerThousand), THOUSAND);
    BigDecimal minimum = valuableArticlesMinimumPremium.setScale(
        Math.max(2, valuableArticlesMinimumPremium.scale()), RoundingMode.UNNECESSARY);
    return premium.max(minimum);
  }

  /** Derived from HomeownersPremiumCalculator>>deductibleCreditForDwelling:deductible: : dwelling premium * credit% / 100 rounded to cents; an unknown deductible raises ObjectNotFound. */
  public BigDecimal deductibleCredit(BigDecimal dwellingCoverage, BigDecimal deductible) {
    Integer percentage = deductibleCreditPercentages.get(deductible.stripTrailingZeros());
    if (percentage == null) {
      throw new IllegalArgumentException("No deductible credit is defined for " + deductible.toPlainString());
    }
    return Money.divideToCents(dwellingPremium(dwellingCoverage).multiply(BigDecimal.valueOf(percentage)), HUNDRED);
  }

  /** Derived from HomeownersPremiumCalculator>>annualPremiumForDwelling:valuableArticles:deductible: : dwelling - credit + valuable articles. */
  public BigDecimal annualPremium(BigDecimal dwellingCoverage, BigDecimal scheduledValue, BigDecimal deductible) {
    return dwellingPremium(dwellingCoverage)
        .subtract(deductibleCredit(dwellingCoverage, deductible))
        .add(valuableArticlesPremium(scheduledValue));
  }

  /** Derived from HomeownersPremiumCalculator>>termPremiumForDwelling:valuableArticles:deductible:over: : annual * term months / 12, rounded to cents. */
  public BigDecimal termPremium(BigDecimal dwellingCoverage, BigDecimal scheduledValue, BigDecimal deductible, PolicyTerm policyTerm) {
    BigDecimal annual = annualPremium(dwellingCoverage, scheduledValue, deductible);
    return Money.divideToCents(annual.multiply(BigDecimal.valueOf(policyTerm.termInMonths())), TWELVE);
  }
}
