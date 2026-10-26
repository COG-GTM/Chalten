# Parity report: Smalltalk oracle vs Java port

## Summary

Every expected value below was produced by **running the Smalltalk** in a
headless Pharo image (see "How the golden data was produced"). The Java port
replays each case through JUnit 5 parameterized tests and asserts exact
equality: `BigDecimal.equals` for money (scale 2) and `LocalDate.equals` for
dates. The numbers are from the final run recorded in
`modernization/PARITY_RUN_OUTPUT.txt`.

| Rule (test class) | Golden file | Cases | Pass | Fail | Error |
|-------------------|-------------|------:|-----:|-----:|------:|
| Policy term: expiration, term days, last date in force, standard renewal window (`PolicyTermParityTest`) | `policy_terms.csv` | 52 | 52 | 0 | 0 |
| Pro-rata and short-rate cancellation: days in force, in-force flag, earned, unearned, retained percent, short-rate earned, penalty (`CancellationParityTest`) | `cancellations.csv` | 988 | 988 | 0 | 0 |
| Renewal offer window: opens, closes, days until opening, open/closed at four boundary dates (`RenewalWindowParityTest`) | `renewal_windows.csv` | 208 | 208 | 0 | 0 |
| Homeowners premium: dwelling, valuable articles, deductible credit, annual, 6 and 12 month term premium (`HomeownersPremiumParityTest`) | `homeowners_premiums.csv` | 160 | 160 | 0 | 0 |
| Chalten-Core date rules: leap year, days in year and month, last day of month, day of week, next, previous, next: n days, month-of-year arithmetic, date subtraction (`ChaltenCoreDateParityTest`) | `chalten_core_dates.csv` | 896 | 896 | 0 | 0 |
| Invalid inputs rejected by the Smalltalk must be rejected by the Java (`InvalidInputParityTest`) | `invalid_inputs.csv` | 9 | 9 | 0 | 0 |
| **Golden total** | | **2313** | **2313** | **0** | **0** |
| REST facade smoke tests (`PolicyTermControllerTest`, not golden) | | 2 | 2 | 0 | 0 |

Each golden *case* is one CSV row, and most rows assert several outputs
(a cancellation row checks seven values), so the number of individual
equalities checked is above 7,000.

## How the golden data was produced

- Pharo image:
  `Pharo-12.0.0+SNAPSHOT.build.1599.sha.7d5f14cb47c000853271e85a27706569614966e7`
  (64 bit)
- Pharo VM: `v10.3.12+0.4b06224 - Commit: 4b06224 - Date: 2026-10-23`
  (downloaded with `curl https://get.pharo.org/64/120+vm | bash`)
- Dependencies: Buoy `v8` and Aconcagua `v11`, cloned from `ba-st` and
  loaded from the local clones with Metacello (`gitlocal://`), then this
  checkout of Chalten loaded from `source/` with `tonel://` so the working
  tree is what runs.
- Command (re-runnable, deterministic, no random inputs):

```bash
modernization/scripts/run_pharo.sh bootstrap   # download Pharo, clone deps, load Chalten + PersonalLines-Rating
modernization/scripts/run_pharo.sh tests       # SUnit: Chalten-Core 226, Chalten-Timezones 10, PersonalLines-Rating 29, all green
modernization/scripts/run_pharo.sh golden      # ./pharo Chalten.image st modernization/scripts/generate_golden.st
```

The generator (`modernization/scripts/generate_golden.st`) builds the input
set from fixed lists: 26 effective dates chosen for boundaries (Feb 28 and
29 of 2024, Feb 28 of 2025, every 30 and 31 day month end, Dec 31 and
Jan 1, Aug 31 of 2023/2027/2099 so six-month terms land on Feb 29, Feb 28
and the non-leap century 2100), two term lengths, 19 cancellation offsets
(-30, -1, 0, 1, 29, 30, 31, 59, 73, 90, 120, 181, 182, 183, 270, 364, 365,
366, 400 days), seven written premiums including 0, 0.01 and 0.87, four
renewal lead times (45, 30, 60, 400), and an 8 x 5 x 4 grid of dwelling
coverages, scheduled values and deductibles. Running the generator twice
produces byte-identical CSVs (`git status` is clean after a rerun). The run
log with the version string is `modernization/golden/GENERATION_LOG.txt`.

## How the Java was run

- `java -version`: OpenJDK 17 (`/usr/lib/jvm/java-17-openjdk-amd64`), Maven 3.9.9,
  Spring Boot 3.3.5, JUnit 5 (Jupiter) via `spring-boot-starter-test`.
- Command: `modernization/scripts/run_parity.sh`, which runs
  `mvn -B test` in `java/policy-term-service` and then tabulates the
  surefire XML reports per test class.
- The golden directory is mounted as a Maven test resource
  (`<testResource><directory>${golden.dir}</directory>`), so the tests read
  the same CSV files the Smalltalk wrote, with no copy step.

## Mismatches found and fixed

The final run has zero mismatches. Two things worth saying so this does not
read as a vendor claim:

1. **The first Java run against the golden data passed 2313/2313.** This is
   not surprising for *this* package, and it is the point of the method: the
   port was written from the rule catalog with the Smalltalk open beside it,
   and the two rounding decisions that usually cause drift were decided up
   front rather than discovered in production:
   - The Smalltalk works in exact fractions and rounds once with
     `(amount * 100) rounded / 100`, where Pharo's `Number>>rounded` is
     half away from zero. The Java therefore never rounds an intermediate
     quotient: `BigDecimal.divide(divisor, 2, RoundingMode.HALF_UP)` returns
     the correctly rounded exact quotient, and `HALF_UP` is also half away
     from zero. A port that computed `premium * days / termDays` with
     `double` or with a 10-digit intermediate scale would have been off by a
     cent on some of the 988 cancellation rows.
   - Short-rate band lookup compares the *exact* percentage elapsed with the
     band's upper bound. The Java cross-multiplies integers
     (`daysInForce * 100 <= bound * termDays`) instead of dividing, so the
     exact-boundary rows (73 of 365 days is exactly 20 percent) agree.
2. **The one failure during the work was in a hand-written expectation, not
   in the Smalltalk or the Java.** While writing the SUnit tests for the
   synthetic package, `RenewalOfferWindowTest>>testDaysUntilOpening` asserted
   that the standard window for a 2025 annual term opens 319 days after
   inception. Pharo reported 320 (Jan 1 to Nov 17, 2025 is 320 days). The
   test was corrected to 320; the Smalltalk was right and the person was
   wrong. That is exactly why the oracle has to come from executing the
   legacy code rather than from someone writing down what they believe it
   does.

3. **One divergence the oracle could not see was caught in code review.**
   `HomeownersPremiumCalculator>>valuableArticlesPremiumFor:` compares the
   rounded premium with the configured minimum *unrounded*; the first Java
   version rounded the minimum before comparing. Every golden row uses the
   standard minimum of 25, so the oracle passed either way. The Java now
   compares the minimum exactly as configured (only normalising its scale
   to two decimals so `25` prints as `25.00`). The lesson for a real
   engagement: the oracle proves the inputs you sampled, and a reviewer
   reading the two methods side by side still earns their keep.

## What exact equality means here

- Money: `BigDecimal` with scale 2 on both sides. `1225.00` and `1225.0`
  would *not* be equal under `assertEquals`, so the Smalltalk formatter
  always writes two decimals and the Java always rounds to scale 2. A
  mismatch in scale would show up as a failure, not be hidden by
  `compareTo`.
- Dates: `LocalDate` parsed from the ISO 8601 text the Chalten formatter
  wrote.
- Booleans and integers: parsed from the CSV text.
- Errors: the Smalltalk error class (`InstanceCreationFailed`,
  `AssertionFailed`, `ObjectNotFound`) is recorded in `invalid_inputs.csv`;
  the Java asserts `IllegalArgumentException` for every one of those rows.

## Known limits of this proof

- The oracle covers the rules listed in Part C of
  `docs/modernization/RULE_CATALOG.md`. Time-of-day, instants, time offsets
  and time zone transitions (A5) are catalogued but not ported and not in
  the oracle.
- Dates in the oracle run from 1900 to 2100. Both Chalten and `java.time`
  are proleptic Gregorian, so earlier dates are expected to agree, but they
  were not sampled.
- The REST and CLI layers are thin facades; the two `PolicyTermControllerTest`
  cases check wiring and error mapping, not business rules.

## Final run output

See `modernization/PARITY_RUN_OUTPUT.txt` for the complete capture. The
tail of that file:

```text
[INFO] Tests run: 9, Failures: 0, Errors: 0, Skipped: 0 -- in com.example.policyterm.parity.InvalidInputParityTest
[INFO] Tests run: 52, Failures: 0, Errors: 0, Skipped: 0 -- in com.example.policyterm.parity.PolicyTermParityTest
[INFO] Tests run: 896, Failures: 0, Errors: 0, Skipped: 0 -- in com.example.policyterm.parity.ChaltenCoreDateParityTest
[INFO] Tests run: 208, Failures: 0, Errors: 0, Skipped: 0 -- in com.example.policyterm.parity.RenewalWindowParityTest
[INFO] Tests run: 988, Failures: 0, Errors: 0, Skipped: 0 -- in com.example.policyterm.parity.CancellationParityTest
[INFO] Tests run: 160, Failures: 0, Errors: 0, Skipped: 0 -- in com.example.policyterm.parity.HomeownersPremiumParityTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0 -- in com.example.policyterm.api.PolicyTermControllerTest
[INFO] Tests run: 2315, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```
