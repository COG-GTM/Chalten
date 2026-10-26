# Presenter run sheet: legacy Smalltalk to Java, proven equivalent

Six steps, about 12 minutes. Every link is a file in this PR, so the
audience can open the same thing afterwards.
PR: <https://github.com/COG-GTM/Chalten/pull/1>

Opening line: "Nobody here is going to trust a converter. So we are not going
to show one. We are going to show three things: the rules written down with
citations, the old code executed to produce an answer key, and the new code
graded against that answer key."

## Step 1. The legacy code as it is

- **Open**: `source/Chalten-Core/CalendarDate.class.st` at
  `CalendarDate>>subtractionFromCalendarDate:` (line 196) and
  `source/Chalten-Core/GregorianMonthOfYear.class.st` at
  `GregorianMonthOfYear>>next:` (line 92).
- **Say**: "This is a real Smalltalk date library, Tonel format, loaded in
  Pharo. Date subtraction is asymmetric and raises if you subtract the wrong
  way round. Month arithmetic has a wrap-around rule with a comment
  explaining it. These are the kinds of rules that get lost in a rewrite."
- **Link**: <https://github.com/COG-GTM/Chalten/pull/1/files> (filter on `source/Chalten-Core`).

## Step 2. The rule catalog with citations

- **Open**: `docs/modernization/RULE_CATALOG.md`, Part A, rows A2.5 and A3.5,
  then Part B.
- **Say**: "53 rules, 31 from the real library and 22 from the synthetic
  package. Every rule is one sentence of English, its edge cases, and the
  file, line and selector it was read from. Nobody has to take the sentence
  on faith. Part B is a small synthetic rating package we added on top of
  the library: term, pro-rata, short-rate, renewal window, homeowners
  premium. It is labelled SYNTHETIC everywhere so nobody mistakes it for a
  product."
- **Link**: <https://github.com/COG-GTM/Chalten/pull/1/files> then `docs/modernization/RULE_CATALOG.md`.

## Step 3. The answer key comes from running the old code

- **Open**: a terminal in the repo. Run
  `modernization/scripts/run_pharo.sh tests` and then
  `modernization/scripts/run_pharo.sh golden`. Then open
  `modernization/golden/cancellations.csv` and scroll to an
  `2024-02-29` row.
- **Say**: "Headless Pharo 12. 265 existing and new SUnit tests pass. Then
  the generator feeds 2,313 boundary cases through the Smalltalk and writes
  what it answered: leap days, every month end, year rollover, cancellations
  before inception and after expiration, premiums of a cent. Nobody typed
  these expected values. The version string and command are in the log."
- **Link**: `modernization/golden/GENERATION_LOG.txt`,
  `modernization/scripts/generate_golden.st`.

## Step 4. The Java port, traceable method by method

- **Open**: `source/PersonalLines-Rating/PolicyTerm.class.st`
  (`calculateExpirationDate`) side by side with
  `java/policy-term-service/src/main/java/com/example/policyterm/rating/PolicyTerm.java`
  (`calculateExpirationDate`, Javadoc line).
- **Say**: "Java 17, Spring Boot 3, `java.time`. Every class and method
  carries a Javadoc line naming the Smalltalk method it came from. The clamp
  to the last day of the month is there because the Smalltalk does it, and
  the comment says so. The REST endpoint and CLI are thin; the rules live in
  five classes that mirror the five Smalltalk classes."
- **Link**: <https://github.com/COG-GTM/Chalten/pull/1/files> then `java/policy-term-service/src/main/java`.

## Step 5. Grading the port against the answer key

- **Open**: terminal, run `modernization/scripts/run_parity.sh`. Then open
  `modernization/PARITY_REPORT.md`.
- **Say**: "JUnit 5 reads the same CSV files the Smalltalk wrote and asserts
  exact BigDecimal and LocalDate equality on every row. 2,313 of 2,313.
  The report also says what is not covered: time zones and instants are
  catalogued but not ported, and it tells the story of the one wrong
  expectation we wrote by hand, which the Smalltalk corrected. If a future
  rule changes, rerun two scripts and the report changes."
- **Link**: `modernization/PARITY_REPORT.md`,
  `modernization/PARITY_RUN_OUTPUT.txt`.

## Step 6. What this would look like on your codebase

- **Open**: the PR description.
- **Say**: "What you saw is a method, not a product: catalogue with
  citations, execute the legacy to build the oracle, port with traceability,
  grade with exact equality, publish the gaps. On your estate the first step
  is the same: point this at one package, get the catalog and the oracle,
  and decide with numbers in hand. Nothing here required the old system to be
  switched off."
- **Link**: <https://github.com/COG-GTM/Chalten/pull/1>.

## If something goes wrong live

- Pharo will not start: show `modernization/golden/GENERATION_LOG.txt` and
  the committed CSVs; they are the output of the last run, with the version
  string.
- Maven is slow: show `modernization/PARITY_RUN_OUTPUT.txt` instead of
  waiting; it is the complete capture of the last run.
- CLI fallback for a single case:

```bash
java -jar java/policy-term-service/target/policy-term-service-0.1.0-SNAPSHOT.jar \
  cli pro-rata 2024-02-29 12 1200.00 2024-08-31
```
