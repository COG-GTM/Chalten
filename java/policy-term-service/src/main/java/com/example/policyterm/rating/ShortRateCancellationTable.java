package com.example.policyterm.rating;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * Derived from ShortRateCancellationTable (source/PersonalLines-Rating/ShortRateCancellationTable.class.st).
 * Bands are (upper bound of percent elapsed, inclusive) to (percent of premium retained).
 */
public final class ShortRateCancellationTable {

  private record Band(int elapsedPercentageUpTo, int retainedPercentage) {}

  private final List<Band> bands = new ArrayList<>();

  /** Derived from ShortRateCancellationTable class>>standard: the twenty-band demonstration table. */
  public static ShortRateCancellationTable standard() {
    ShortRateCancellationTable table = new ShortRateCancellationTable();
    int[][] standardBands = {
      {5, 10}, {10, 17}, {15, 24}, {20, 31}, {25, 37}, {30, 43}, {35, 49}, {40, 55}, {45, 60}, {50, 65},
      {55, 70}, {60, 75}, {65, 80}, {70, 84}, {75, 88}, {80, 91}, {85, 94}, {90, 97}, {95, 99}, {100, 100}
    };
    for (int[] band : standardBands) {
      table.addBand(band[0], band[1]);
    }
    return table;
  }

  /** Derived from ShortRateCancellationTable>>addBandUpTo:retaining: : bands must be added in increasing order of elapsed percentage. */
  public ShortRateCancellationTable addBand(int elapsedPercentageUpTo, int retainedPercentage) {
    if (!bands.isEmpty() && bands.get(bands.size() - 1).elapsedPercentageUpTo() >= elapsedPercentageUpTo) {
      throw new IllegalArgumentException("Short-rate bands must be added in increasing order of elapsed percentage");
    }
    bands.add(new Band(elapsedPercentageUpTo, retainedPercentage));
    return this;
  }

  /** Derived from ShortRateCancellationTable>>retainedPercentageFor:cancelledOn: : zero days in force retains nothing; otherwise the first band whose upper bound >= exact percent elapsed. */
  public int retainedPercentage(PolicyTerm policyTerm, LocalDate cancellationDate) {
    long daysInForce = policyTerm.daysInForceAt(cancellationDate);
    if (daysInForce == 0) {
      return 0;
    }
    long termDays = policyTerm.numberOfDays();
    // elapsedPercentage <= band upper bound, compared exactly: daysInForce * 100 / termDays <= bound
    return bands.stream()
        .filter(band -> daysInForce * 100 <= (long) band.elapsedPercentageUpTo() * termDays)
        .findFirst()
        .orElseThrow(() -> new IllegalStateException("No short-rate band covers " + daysInForce + " days of " + termDays))
        .retainedPercentage();
  }

  /** Derived from ShortRateCancellationTable>>earnedPremiumOf:for:cancelledOn: : written * retained% / 100, rounded to cents. */
  public BigDecimal earnedPremium(BigDecimal writtenPremium, PolicyTerm policyTerm, LocalDate cancellationDate) {
    int retained = retainedPercentage(policyTerm, cancellationDate);
    return Money.divideToCents(writtenPremium.multiply(BigDecimal.valueOf(retained)), BigDecimal.valueOf(100));
  }

  /** Derived from ShortRateCancellationTable>>penaltyOf:for:cancelledOn: : short-rate earned minus pro-rata earned. */
  public BigDecimal penalty(BigDecimal writtenPremium, PolicyTerm policyTerm, LocalDate cancellationDate) {
    BigDecimal proRata = ProRataEarnedPremiumCalculator.forTerm(policyTerm).earnedPremium(writtenPremium, cancellationDate);
    return earnedPremium(writtenPremium, policyTerm, cancellationDate).subtract(proRata);
  }
}
