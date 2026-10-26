package com.example.policyterm.cli;

import com.example.policyterm.rating.HomeownersPremiumCalculator;
import com.example.policyterm.rating.PolicyTerm;
import com.example.policyterm.rating.ProRataEarnedPremiumCalculator;
import com.example.policyterm.rating.RenewalOfferWindow;
import com.example.policyterm.rating.ShortRateCancellationTable;
import java.io.PrintStream;
import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Command-line runner for the ported rules, so a presenter can type one case and read the answer.
 *
 * <pre>
 *   cli term 2024-02-29 12
 *   cli pro-rata 2024-02-29 12 1200.00 2024-08-31
 *   cli short-rate 2024-02-29 12 1200.00 2024-08-31
 *   cli renewal 2024-02-29 12 [leadDays] [asOf]
 *   cli homeowners 350000 20000 1000 [termMonths]
 * </pre>
 */
public final class PolicyTermCli {

  private PolicyTermCli() {}

  public static int run(String[] args, PrintStream out, PrintStream err) {
    try {
      if (args.length == 0) {
        throw new IllegalArgumentException("missing command");
      }
      switch (args[0]) {
        case "term" -> term(args, out);
        case "pro-rata" -> proRata(args, out);
        case "short-rate" -> shortRate(args, out);
        case "renewal" -> renewal(args, out);
        case "homeowners" -> homeowners(args, out);
        default -> throw new IllegalArgumentException("unknown command " + args[0]);
      }
      return 0;
    } catch (RuntimeException e) {
      err.println("error: " + e.getMessage());
      err.println("usage: cli term <effective> <6|12> | pro-rata <effective> <6|12> <premium> <cancellation>"
          + " | short-rate <effective> <6|12> <premium> <cancellation> | renewal <effective> <6|12> [leadDays] [asOf]"
          + " | homeowners <dwelling> <scheduled> <deductible> [6|12]");
      return 1;
    }
  }

  private static PolicyTerm termFrom(String[] args) {
    return PolicyTerm.effectiveOn(LocalDate.parse(args[1]), Integer.parseInt(args[2]));
  }

  private static void term(String[] args, PrintStream out) {
    PolicyTerm term = termFrom(args);
    out.println(term);
    out.println("term days:          " + term.numberOfDays());
    out.println("last date in force: " + term.lastDateInForce());
    out.println("renewal window:     " + term.renewalOfferWindow().opensOn() + " to " + term.renewalOfferWindow().closesOn());
  }

  private static void proRata(String[] args, PrintStream out) {
    PolicyTerm term = termFrom(args);
    BigDecimal premium = new BigDecimal(args[3]);
    LocalDate cancellation = LocalDate.parse(args[4]);
    ProRataEarnedPremiumCalculator calculator = ProRataEarnedPremiumCalculator.forTerm(term);
    out.println(term);
    out.println("days in force:    " + term.daysInForceAt(cancellation) + " of " + term.numberOfDays());
    out.println("earned premium:   " + calculator.earnedPremium(premium, cancellation));
    out.println("unearned premium: " + calculator.unearnedPremium(premium, cancellation));
  }

  private static void shortRate(String[] args, PrintStream out) {
    PolicyTerm term = termFrom(args);
    BigDecimal premium = new BigDecimal(args[3]);
    LocalDate cancellation = LocalDate.parse(args[4]);
    ShortRateCancellationTable table = ShortRateCancellationTable.standard();
    out.println(term);
    out.println("retained:         " + table.retainedPercentage(term, cancellation) + "%");
    out.println("earned premium:   " + table.earnedPremium(premium, term, cancellation));
    out.println("penalty vs pro-rata: " + table.penalty(premium, term, cancellation));
  }

  private static void renewal(String[] args, PrintStream out) {
    PolicyTerm term = termFrom(args);
    RenewalOfferWindow window = args.length > 3
        ? RenewalOfferWindow.forTerm(term, Integer.parseInt(args[3]))
        : RenewalOfferWindow.standardFor(term);
    out.println(term);
    out.println("window opens: " + window.opensOn() + "  closes: " + window.closesOn());
    if (args.length > 4) {
      LocalDate asOf = LocalDate.parse(args[4]);
      out.println("open on " + asOf + ": " + window.isOpenOn(asOf) + " (days until opening: "
          + window.daysUntilOpeningFrom(asOf) + ")");
    }
  }

  private static void homeowners(String[] args, PrintStream out) {
    BigDecimal dwelling = new BigDecimal(args[1]);
    BigDecimal scheduled = new BigDecimal(args[2]);
    BigDecimal deductible = new BigDecimal(args[3]);
    int termMonths = args.length > 4 ? Integer.parseInt(args[4]) : 12;
    HomeownersPremiumCalculator calculator = HomeownersPremiumCalculator.standard();
    PolicyTerm term = PolicyTerm.effectiveOn(LocalDate.of(2025, 1, 1), termMonths);
    out.println("dwelling premium:          " + calculator.dwellingPremium(dwelling));
    out.println("valuable articles premium: " + calculator.valuableArticlesPremium(scheduled));
    out.println("deductible credit:         " + calculator.deductibleCredit(dwelling, deductible));
    out.println("annual premium:            " + calculator.annualPremium(dwelling, scheduled, deductible));
    out.println(termMonths + "-month term premium:     " + calculator.termPremium(dwelling, scheduled, deductible, term));
  }
}
