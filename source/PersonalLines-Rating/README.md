# PersonalLines-Rating (SYNTHETIC)

**This package is synthetic.** It was written for a modernization
demonstration to show how a small enterprise rating module built on Chalten
dates can be catalogued, executed headlessly to produce golden data, ported to
Java and proven equivalent. It does not describe any real insurer's products,
rates, tables or practices. Every class comment repeats this notice.

## Classes

| Class | Responsibility |
|-------|----------------|
| `PolicyTerm` | 6 or 12 month term from an effective date; expiration clamped to the last day of a short anniversary month; days in force at a date |
| `ProRataEarnedPremiumCalculator` | Earned and unearned premium on cancellation, exact fraction rounded once to cents |
| `ShortRateCancellationTable` | 20-band short-rate table keyed by percent of term elapsed; penalty versus pro-rata |
| `RenewalOfferWindow` | Opens 45 days (configurable) before expiration, never before inception; closes on the last date in force |
| `HomeownersPremiumCalculator` | Dwelling and valuable articles premium, deductible credit, annual and term premium |

Tests live in `PersonalLines-Rating-Tests` (29 SUnit tests, subclasses of
`ChaltenTest`).

## Style notes

The code follows the conventions of the surrounding Chalten packages so it
reads like the enterprise Smalltalk it stands in for: class-side factories
(`PolicyTerm class>>sixMonthsFrom:`), message cascades for configuration
(`ShortRateCancellationTable class>>standard`), Buoy `AssertionChecker`
preconditions, and Chalten time quantities (`45 * GregorianDate day`,
`termInMonths * GregorianDate month`) for all date arithmetic. Chalten-Core is
not modified.

## Where the rules are documented

`docs/modernization/RULE_CATALOG.md` Part B lists all 22 rules of this
package with file, line, selector and edge cases (Part A lists the 31
Chalten-Core rules). `modernization/golden/` holds the Pharo-generated
expected outputs, and `java/policy-term-service` holds the Java port.
