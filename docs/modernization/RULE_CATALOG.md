# Business rule catalog: Chalten-Core and PersonalLines-Rating

This catalog lists the behavioural rules found in the Smalltalk source of this
repository. It was produced by reading the Tonel source under `source/`, not by
an automated converter. Every row cites the class and method the rule was read
from, so each statement can be checked against the code in a few seconds.

How to read a row:

- **Rule**: one plain-English sentence describing the behaviour.
- **Edge cases**: the boundaries the method handles explicitly.
- **Smalltalk**: `path/under/source:line` followed by the method selector.
  Line numbers refer to the `release-candidate` branch at the time of writing.
- **Java**: the method in `java/policy-term-service` derived from it, or
  `not ported` when the rule is outside the scope of the port.
- **Golden**: the file under `modernization/golden/` whose rows exercise the
  rule (empty when the rule is not part of the equivalence oracle).

Part A covers the real Chalten-Core library. Part B covers the
`PersonalLines-Rating` package, which is **SYNTHETIC**: it was written for this
demonstration to show how a small enterprise rating module built on Chalten
can be catalogued, ported and proven equivalent. Nothing in Part B describes a
real insurer's products or rates.

## Part A: Chalten-Core date rules

### A1. Years

| # | Rule | Edge cases | Smalltalk | Java | Golden |
|---|------|------------|-----------|------|--------|
| A1.1 | A year is a leap year when its number is divisible by 4 and it is not a century, or when it is a century divisible by 400. | 1900 and 2100 are common; 2000 is leap; the calendar is proleptic so this also applies before 1582. | `Chalten-Core/GregorianYear.class.st:102` `GregorianYear>>isLeapYear` | `ChaltenDates.isLeapYear` | `chalten_core_dates.csv` (`isLeapYear`) |
| A1.2 | A year has 366 days when it is a leap year and 365 otherwise. | Result is a day quantity (`366 * day`), not a bare integer. | `Chalten-Core/GregorianYear.class.st:196` `GregorianYear>>numberOfDays` | `ChaltenDates.numberOfDaysInYear` | `chalten_core_dates.csv` (`yearNumberOfDays`) |
| A1.3 | A year's first date is January 1 and its last date is December 31 of that year. | Used as the pivot for cross-year day arithmetic (A3.4). | `Chalten-Core/CalendarYear.class.st:67` `CalendarYear>>firstDate`, `:85` `CalendarYear>>lastDate` | folded into `java.time` | |
| A1.4 | Moving a year forward by a relative quantity adds the number of years; the quantity must be expressed in year-compatible units. | Zero returns the same year; negative delegates to `previous:`. | `Chalten-Core/CalendarYear.class.st:97` `CalendarYear>>next:` | `YearMonth.plusMonths` (via A2.5) | |
| A1.5 | The difference between two years is a quantity of years; the years must belong to the same calendar. | Different calendars raise an error through `assertIsCommensurableWith:`. | `Chalten-Core/CalendarYear.class.st:134` `CalendarYear>>subtractionFromCalendarYear:` | not ported | |
| A1.6 | A year number must be an integer. | Non-integers fail with `InstanceCreationFailed`. | `Chalten-Core/CalendarYear.class.st:14` `CalendarYear class>>assertIsValid:` | `int` parameter type | |
| A1.7 | `anInteger asGregorianYear` is the canonical way to obtain a year from a number. | Years are cached per number (flyweights). | `Chalten-Core-Extensions/Integer.extension.st:4` `Integer>>asGregorianYear`, `Chalten-Core/GregorianYear.class.st:172` `GregorianYear>>monthAt:` | `YearMonth.of` | |

### A2. Months and months of a year

| # | Rule | Edge cases | Smalltalk | Java | Golden |
|---|------|------------|-----------|------|--------|
| A2.1 | February has 29 days in a leap year and 28 in a common year; April, June, September and November have 30; every other month has 31. | Month lengths are declared once per month as a (common, leap) pair. | `Chalten-Core/GregorianMonth.class.st:56` `GregorianMonth class>>initialize` | `ChaltenDates.numberOfDaysInMonth` | `chalten_core_dates.csv` (`monthNumberOfDays`) |
| A2.2 | A month of a specific year takes its length from the month's leap or common value depending on that year. | Only February differs between the two. | `Chalten-Core/GregorianMonthOfYear.class.st:114` `GregorianMonthOfYear>>numberOfDays` | `ChaltenDates.numberOfDaysInMonth` | `chalten_core_dates.csv` (`monthNumberOfDays`) |
| A2.3 | A date is built from a month of a year and a day number; the day number must be between 1 and that month's number of days. | February 29 of a common year and April 31 fail with `InstanceCreationFailed`. Dates are cached per month. | `Chalten-Core/GregorianMonthOfYear.class.st:47` `GregorianMonthOfYear>>dateAt:`, `Chalten-Core/CalendarDate.class.st:13` `CalendarDate class>>assert:isValidIn:` | `ChaltenDates.dateAt` | `invalid_inputs.csv` |
| A2.4 | Months cycle: moving January back one month gives December; moving December forward gives January. | Arithmetic is modulo 12 on the month position. | `Chalten-Core/GregorianMonth.class.st:242` `GregorianMonth>>next:`, `:271` `GregorianMonth>>previous:` | `YearMonth.plusMonths` | `chalten_core_dates.csv` (`monthOfYearNextMonths`) |
| A2.5 | Moving a month of a year forward by a relative quantity: whole years keep the month and add the years; a fractional year is converted to months, and if the resulting month position is lower than the current one the year is incremented once more (wrap-around). | Zero returns the receiver; negative delegates to `previous:`; `1/2 * year` means six months; `13 * month` is one year and one month. | `Chalten-Core/GregorianMonthOfYear.class.st:92` `GregorianMonthOfYear>>next:`, `:204` `GregorianMonthOfYear>>when:isWholeYearsDo:otherwise:` | `ChaltenDates.monthOfYearNext` | `chalten_core_dates.csv` (`monthOfYearNextMonths`, positive) |
| A2.6 | Moving a month of a year backward mirrors A2.5: when the new month position is higher than the current one the year is decremented once more. | Negative delegates to `next:`. | `Chalten-Core/GregorianMonthOfYear.class.st:122` `GregorianMonthOfYear>>previous:` | `ChaltenDates.monthOfYearNext` (negative) | `chalten_core_dates.csv` (`monthOfYearNextMonths`, negative) |
| A2.7 | The difference between two months of a year is `(yearDifference * 12 + monthPositionDifference)` months, computed in constant time. | Works in both directions; result is a month quantity. | `Chalten-Core/GregorianMonthOfYear.class.st:168` `GregorianMonthOfYear>>subtractionFromGregorianMonthOfYear:` | not ported | |

### A3. Dates

| # | Rule | Edge cases | Smalltalk | Java | Golden |
|---|------|------------|-----------|------|--------|
| A3.1 | The next date is the following day; on the last day of a month it rolls to the first day of the next month (and year, in December). | December 31 rolls to January 1 of the next year. | `Chalten-Core/CalendarDate.class.st:108` `CalendarDate>>next` | `ChaltenDates.next` | `chalten_core_dates.csv` (`next`) |
| A3.2 | The previous date is the preceding day; on the first day of a month it rolls to the last day of the previous month. | January 1 rolls to December 31 of the previous year; March 1 rolls to February 28 or 29. | `Chalten-Core/CalendarDate.class.st:172` `CalendarDate>>previous` | `ChaltenDates.previous` | `chalten_core_dates.csv` (`previous`) |
| A3.3 | Adding a day quantity: zero returns the same date; a negative quantity delegates to `previous:`; if the quantity fits in the current year the date moves within the year, otherwise the remainder is applied from January 1 of the next year, recursively. | Crosses leap days and year boundaries; `-1 * day` equals `previous`. | `Chalten-Core/CalendarDate.class.st:118` `CalendarDate>>next:`, `:132` `CalendarDate>>onSameYearNext:` | `ChaltenDates.nextDays` | `chalten_core_dates.csv` (`nextDays`) |
| A3.4 | Subtracting a day quantity mirrors A3.3 using the first date of the year as the pivot. | Negative delegates to `next:`. | `Chalten-Core/CalendarDate.class.st:182` `CalendarDate>>previous:` | `ChaltenDates.previousDays` | `chalten_core_dates.csv` (`nextDays`, negative) |
| A3.5 | The difference between two dates is the number of days from the receiver to the argument: zero for equal dates; same month, same year and different years are counted separately. | If the receiver is later than the argument, `ArithmeticError` is raised: date subtraction is not symmetric. | `Chalten-Core/CalendarDate.class.st:196` `CalendarDate>>subtractionFromCalendarDate:` | `ChaltenDates.daysBetween` (throws `ArithmeticException`) | `chalten_core_dates.csv` (`daysSinceReference`) |
| A3.6 | `aDate + aQuantity` and `aDate - aQuantity` are double-dispatched to `next:` and `previous:`. | `aDate - anotherDate` dispatches to A3.5 instead. | `Chalten-Core/CalendarDate.class.st:30` `CalendarDate>>+`, `:36` `CalendarDate>>-`, `Chalten-Core-Aconcagua-Extensions/Quantity.extension.st:4` `Quantity>>additionWithCalendarDate:`, `:10` `Quantity>>subtractionFromCalendarDate:` | explicit method calls | |
| A3.7 | A date is the last day of its month when it equals its month's last date. | Depends on A2.2 for February. | `Chalten-Core/CalendarDate.class.st:84` `CalendarDate>>isLastDayOfMonth` | `ChaltenDates.isLastDayOfMonth` | `chalten_core_dates.csv` (`isLastDayOfMonth`) |
| A3.8 | Dates are totally ordered within one calendar: earlier year, then earlier month, then earlier day. | Comparison across calendars (Gregorian vs Hebrew) is rejected. | `Chalten-Core/GregorianDate.class.st:24` `GregorianDate>><` | `LocalDate.isBefore` / `isAfter` | `cancellations.csv` (`in_force`) |
| A3.9 | Days of the week follow ISO 8601: Monday is 1 and Sunday is 7; the day of week of a date is derived from its Julian day number. | `asISODayOfWeek` exposes the ISO number. | `Chalten-Core/DayOfWeek.class.st:29` `DayOfWeek class>>initialize`, `:81` `DayOfWeek>>asISODayOfWeek`, `Chalten-Core/GregorianDate.class.st:63` `GregorianDate>>dayOfWeek` | `ChaltenDates.dayOfWeekName` | `chalten_core_dates.csv` (`dayOfWeek`) |
| A3.10 | A date interval `from to: to` enumerates every date in order; `to:by:` steps by a day quantity. | Empty when `to` precedes `from`. | `Chalten-Core/CalendarDate.class.st:233` `CalendarDate>>to:`, `:239` `CalendarDate>>to:by:` | not ported | |
| A3.11 | Dates print and parse in ISO 8601 (`YYYY-MM-DD`); months of a year as `YYYY-MM`. | Negative and five-digit years are handled by the parser. | `Chalten-Core/ISO8601Formatter.class.st:13` `ISO8601Formatter>>format:on:`, `Chalten-Core/ISO8601Parser.class.st:95` `ISO8601Parser>>parseDate:` | `LocalDate.toString` / `parse` | all golden files use this format |

### A4. Relative time units

| # | Rule | Edge cases | Smalltalk | Java | Golden |
|---|------|------------|-----------|------|--------|
| A4.1 | One month is 1/12 of a year; a lustrum is 5 years, a decade 10, a jubilee 50, a century 100 and a millennium 1000. | These are *relative* units: a month quantity has no fixed number of days, which is why month arithmetic (A2.5) and day arithmetic (A3.3) are separate rules. | `Chalten-Core/TimeUnits.class.st:42` `TimeUnits class>>initializeRelativeUnits` | `int termInMonths` plus `java.time` | `policy_terms.csv` (6 and 12 month terms) |

### A5. Date-times, instants and time offsets

| # | Rule | Edge cases | Smalltalk | Java | Golden |
|---|------|------------|-----------|------|--------|
| A5.1 | A Gregorian date-time is a date plus a time of day with no time zone attached; two date-times compare by Julian day number. | Not an absolute point on the timeline until a ruleset is applied (A5.4). | `Chalten-Core/GregorianDateTime.class.st:16` `GregorianDateTime class>>on:at:`, `:54` `GregorianDateTime>>julianDayNumber` | not ported (no time-of-day rules in the rating package) | |
| A5.2 | An instant is a count of microseconds since the Unix epoch and can be converted to and from Unix seconds and Julian day numbers. | `Instant class>>now` reads the VM clock; `epoch` is 1970-01-01T00:00Z. | `Chalten-Core/Instant.class.st:50` `Instant class>>fromUnixTime:`, `:75` `Instant class>>microsecondsSinceEpoch:`, `:128` `Instant>>asUnixTime` | not ported | |
| A5.3 | Instants move forward and backward by absolute time quantities (seconds, hours, days as 86400 s). | Unlike dates, instants never use relative units. | `Chalten-Core/Instant.class.st:183` `Instant>>next:`, `:190` `Instant>>previous:` | not ported | |
| A5.4 | A fixed-offset ruleset converts between date-times and instants by applying one constant UTC offset; the offset must lie between -16:00 and +16:00. | Out-of-range offsets fail at creation. | `Chalten-Core/FixedOffsetRuleset.class.st:15` `FixedOffsetRuleset class>>for:`, `Chalten-Core/TimeOffsetRuleset.class.st:22` `TimeOffsetRuleset>>convertToGregorianDate:withOffset:` | not ported | |
| A5.5 | A time zone ruleset with transitions converts a local date-time by comparing the offsets one day before and one day after: equal offsets convert directly; an increasing offset means the local time was skipped (error); a decreasing offset means it is ambiguous (error naming both offsets). | Only the `Chalten-Timezones` package carries transition data; `Chalten-Core` itself has no DST rules. | `Chalten-Timezones/TimeZoneRuleset.class.st:43` `TimeZoneRuleset>>convertGregorianDateTime:`, `:78` `TimeZoneRuleset>>offsetToUniversalCoordinatedTimeAt:` | not ported | |

## Part B: PersonalLines-Rating (SYNTHETIC) policy-period rules

All rows below cite `source/PersonalLines-Rating/`. The package is marked
SYNTHETIC in every class comment and in its README. It exists to show the
method, not to describe any real product.

### B1. Policy term

| # | Rule | Edge cases | Smalltalk | Java | Golden |
|---|------|------------|-----------|------|--------|
| B1.1 | A policy term lasts exactly 6 or 12 months from its effective date. | 0, 7 or any other length fails with `InstanceCreationFailed`. | `PersonalLines-Rating/PolicyTerm.class.st` `PolicyTerm class>>effectiveOn:lastingMonths:`, `allowedTermsInMonths`, `sixMonthsFrom:`, `twelveMonthsFrom:` | `PolicyTerm.effectiveOn`, `sixMonthsFrom`, `twelveMonthsFrom` | `policy_terms.csv`, `invalid_inputs.csv` |
| B1.2 | The expiration date is the same day number in the anniversary month (A2.5); if that month is shorter, the last day of the month is used. | Aug 31 + 6 months expires Feb 28 or Feb 29; Feb 29 + 12 months expires Feb 28; May 31 + 6 months expires Nov 30. | `PolicyTerm.class.st` `PolicyTerm>>calculateExpirationDate` | `PolicyTerm.calculateExpirationDate` | `policy_terms.csv` (`expiration_date`) |
| B1.3 | The number of days in the term is `expiration - effective` (A3.5): 365 or 366 for annual terms, 181 to 184 for six-month terms. | Terms spanning Feb 29 have one more day. | `PolicyTerm.class.st` `PolicyTerm>>numberOfDays` | `PolicyTerm.numberOfDays` | `policy_terms.csv` (`term_days`) |
| B1.4 | Coverage is in force from the effective date up to but not including the expiration date; the last date in force is the day before expiration. | The expiration date itself is not covered. | `PolicyTerm.class.st` `PolicyTerm>>includes:`, `PolicyTerm>>lastDateInForce` | `PolicyTerm.includes`, `lastDateInForce` | `cancellations.csv` (`in_force`), `policy_terms.csv` |
| B1.5 | Days in force at a date: 0 on or before the effective date, the whole term on or after expiration, otherwise `date - effective`. | Never negative, never exceeds the term; a cancellation dated before inception counts as zero days. | `PolicyTerm.class.st` `PolicyTerm>>daysInForceAt:`, `PolicyTerm>>elapsedFractionAt:` | `PolicyTerm.daysInForceAt` | `cancellations.csv` (`days_in_force`) |

### B2. Pro-rata earned premium

| # | Rule | Edge cases | Smalltalk | Java | Golden |
|---|------|------------|-----------|------|--------|
| B2.1 | Earned premium on cancellation is `written * daysInForce / termDays`, computed exactly and rounded once to cents, half away from zero. | Written premium 0 earns 0; premiums of 0.01 round to 0.00 or 0.01 depending on the fraction. | `PersonalLines-Rating/ProRataEarnedPremiumCalculator.class.st` `ProRataEarnedPremiumCalculator>>earnedPremiumOf:cancelledOn:`, `ProRataEarnedPremiumCalculator class>>roundToCents:` | `ProRataEarnedPremiumCalculator.earnedPremium`, `Money.divideToCents` | `cancellations.csv` (`pro_rata_earned`) |
| B2.2 | Unearned premium is the written premium minus the earned premium. | Earned plus unearned always equals written, to the cent. | `ProRataEarnedPremiumCalculator.class.st` `ProRataEarnedPremiumCalculator>>unearnedPremiumOf:cancelledOn:` | `ProRataEarnedPremiumCalculator.unearnedPremium` | `cancellations.csv` (`pro_rata_unearned`) |
| B2.3 | Cancelling on or before the effective date is a flat cancellation: nothing is earned. Cancelling on or after expiration earns everything. | Follows from B1.5. | `ProRataEarnedPremiumCalculator.class.st` (via `PolicyTerm>>daysInForceAt:`) | same | `cancellations.csv` (offsets -30, -1, 0, 365, 366, 400) |
| B2.4 | A negative written premium is rejected. | `AssertionFailed`. | `ProRataEarnedPremiumCalculator.class.st` `ProRataEarnedPremiumCalculator>>assertIsValidPremium:` | `Money.requireNonNegative` | `invalid_inputs.csv` |

### B3. Short-rate cancellation table

| # | Rule | Edge cases | Smalltalk | Java | Golden |
|---|------|------------|-----------|------|--------|
| B3.1 | The standard table has 20 bands of 5 percent of the term elapsed; each band names the percent of written premium retained (10, 17, 24, 31, 37, 43, 49, 55, 60, 65, 70, 75, 80, 84, 88, 91, 94, 97, 99, 100). | Bands must be added in increasing order; otherwise `AssertionFailed`. | `PersonalLines-Rating/ShortRateCancellationTable.class.st` `ShortRateCancellationTable class>>standard`, `ShortRateCancellationTable>>addBandUpTo:retaining:` | `ShortRateCancellationTable.standard`, `addBand` | `invalid_inputs.csv` |
| B3.2 | The retained percentage is taken from the first band whose upper bound is greater than or equal to the exact percentage of the term elapsed (upper bound inclusive). | 73 of 365 days is exactly 20 percent and falls in the 20 percent band (31), not the 25 percent band. The comparison is exact (fractions), not floating point. | `ShortRateCancellationTable.class.st` `ShortRateCancellationTable>>retainedPercentageFor:cancelledOn:` | `ShortRateCancellationTable.retainedPercentage` (integer cross-multiplication) | `cancellations.csv` (`short_rate_pct`) |
| B3.3 | Zero days in force is a flat cancellation and retains nothing, even though the first band starts at 10 percent. | Cancellation before or on the effective date. | `ShortRateCancellationTable.class.st` `ShortRateCancellationTable>>retainedPercentageFor:cancelledOn:` | same | `cancellations.csv` (`short_rate_pct` = 0) |
| B3.4 | Short-rate earned premium is `written * retained / 100`, rounded to cents; the penalty is short-rate earned minus pro-rata earned. | Penalty is 0 for flat cancellations and for full terms. | `ShortRateCancellationTable.class.st` `ShortRateCancellationTable>>earnedPremiumOf:for:cancelledOn:`, `penaltyOf:for:cancelledOn:` | `ShortRateCancellationTable.earnedPremium`, `penalty` | `cancellations.csv` (`short_rate_earned`, `short_rate_penalty`) |

### B4. Renewal offer window

| # | Rule | Edge cases | Smalltalk | Java | Golden |
|---|------|------------|-----------|------|--------|
| B4.1 | The standard renewal window opens 45 days before the expiration date (A3.4) and closes on the last date in force. | The lead time must be positive (`InstanceCreationFailed`). | `PersonalLines-Rating/RenewalOfferWindow.class.st` `RenewalOfferWindow class>>standardFor:`, `for:openingDaysBeforeExpiration:`, `RenewalOfferWindow>>opensOn`, `closesOn` | `RenewalOfferWindow.standardFor`, `forTerm`, `opensOn`, `closesOn` | `renewal_windows.csv`, `policy_terms.csv` |
| B4.2 | The window never opens before the policy's own effective date. | A 400-day lead time on a 6-month term opens on the effective date. | `RenewalOfferWindow.class.st` `RenewalOfferWindow>>opensOn` | `RenewalOfferWindow.opensOn` | `renewal_windows.csv` (`lead_days` = 400) |
| B4.3 | The window is open on a date when `opensOn <= date <= closesOn`; it is closed on the expiration date. | Both ends inclusive. | `RenewalOfferWindow.class.st` `RenewalOfferWindow>>isOpenOn:` | `RenewalOfferWindow.isOpenOn` | `renewal_windows.csv` (four `open_*` columns) |
| B4.4 | Days until the window opens is 0 once it is open, otherwise `opensOn - date`. | Counted with A3.5, so leap days are included. | `RenewalOfferWindow.class.st` `RenewalOfferWindow>>daysUntilOpeningFrom:` | `RenewalOfferWindow.daysUntilOpeningFrom` | `renewal_windows.csv` (`days_until_opening_from_effective`) |

### B5. Homeowners premium with valuable articles and deductible credit

| # | Rule | Edge cases | Smalltalk | Java | Golden |
|---|------|------------|-----------|------|--------|
| B5.1 | Dwelling premium is `coverage / 1000 * 3.50`, rounded to cents. | Coverage 0 gives 0.00; negative coverage fails with `AssertionFailed`. | `PersonalLines-Rating/HomeownersPremiumCalculator.class.st` `HomeownersPremiumCalculator>>dwellingPremiumFor:`, `HomeownersPremiumCalculator class>>standard` | `HomeownersPremiumCalculator.dwellingPremium` | `homeowners_premiums.csv` (`dwelling_premium`), `invalid_inputs.csv` |
| B5.2 | Valuable articles premium is `scheduledValue / 1000 * 12.50`, rounded to cents, with a minimum of 25.00 when anything is scheduled; nothing scheduled costs 0. | 1000 and 2000 both cost 25.00; 2001 costs 25.01. | `HomeownersPremiumCalculator.class.st` `HomeownersPremiumCalculator>>valuableArticlesPremiumFor:` | `HomeownersPremiumCalculator.valuableArticlesPremium` | `homeowners_premiums.csv` (`valuable_articles_premium`) |
| B5.3 | Deductible credit is the (already rounded) dwelling premium times 0, 5, 12 or 20 percent for deductibles of 500, 1000, 2500 or 5000, rounded to cents. | Any other deductible fails with `ObjectNotFound`. | `HomeownersPremiumCalculator.class.st` `HomeownersPremiumCalculator>>deductibleCreditForDwelling:deductible:`, `creditPercentage:forDeductible:` | `HomeownersPremiumCalculator.deductibleCredit` | `homeowners_premiums.csv` (`deductible_credit`), `invalid_inputs.csv` |
| B5.4 | Annual premium is dwelling premium minus deductible credit plus valuable articles premium; each component is rounded before combining. | Rounding each component first is what a legacy declarations page does; a port that rounds only the total would drift by a cent. | `HomeownersPremiumCalculator.class.st` `HomeownersPremiumCalculator>>annualPremiumForDwelling:valuableArticles:deductible:` | `HomeownersPremiumCalculator.annualPremium` | `homeowners_premiums.csv` (`annual_premium`) |
| B5.5 | Term premium is `annual * termMonths / 12`, rounded to cents. | A 6-month term is half the annual, with half-cents rounded away from zero. | `HomeownersPremiumCalculator.class.st` `HomeownersPremiumCalculator>>termPremiumForDwelling:valuableArticles:deductible:over:` | `HomeownersPremiumCalculator.termPremium` | `homeowners_premiums.csv` (`six_month_premium`, `twelve_month_premium`) |

## Part C: what is in the equivalence oracle and what is not

In the oracle (`modernization/golden/`, 2313 cases generated by Pharo):
A1.1, A1.2, A2.1 to A2.6 (through `dateAt:` and `next:`), A3.1 to A3.5, A3.7
to A3.9, and every rule in Part B.

Not in the oracle and not ported: A1.5, A2.7, A3.10 (intervals), and all of
A5 (date-times, instants, offsets and time zones). The rating package never
touches a time of day, so porting those rules would have been speculative.
They are catalogued here so the scope is explicit.
