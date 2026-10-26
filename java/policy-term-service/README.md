# policy-term-service

Java 17 / Spring Boot 3.3 port of the **SYNTHETIC** `PersonalLines-Rating`
Smalltalk package and the Chalten-Core date rules it depends on. Every class
and method carries a Javadoc line citing the Smalltalk method it was derived
from. There is no UI and no persistence layer: the service is a pure
calculator behind a small REST API and a CLI.

## Build and test

```bash
cd java/policy-term-service
mvn -B test        # includes the parity suite that replays modernization/golden/*.csv
mvn -B package     # builds target/policy-term-service-0.1.0-SNAPSHOT.jar
```

Or from the repository root: `modernization/scripts/run_parity.sh`.

## REST API

```bash
java -jar target/policy-term-service-0.1.0-SNAPSHOT.jar

curl -s -X POST localhost:8080/policy-terms -H 'content-type: application/json' \
  -d '{"effectiveDate":"2023-08-31","termMonths":6}'
curl -s -X POST localhost:8080/policy-terms/pro-rata -H 'content-type: application/json' \
  -d '{"effectiveDate":"2024-02-29","termMonths":12,"writtenPremium":1200.00,"cancellationDate":"2024-08-31"}'
curl -s -X POST localhost:8080/policy-terms/short-rate -H 'content-type: application/json' \
  -d '{"effectiveDate":"2024-02-29","termMonths":12,"writtenPremium":1200.00,"cancellationDate":"2024-08-31"}'
curl -s -X POST localhost:8080/policy-terms/renewal-window -H 'content-type: application/json' \
  -d '{"effectiveDate":"2025-01-01","termMonths":12,"asOf":"2025-11-17"}'
curl -s -X POST localhost:8080/premiums/homeowners -H 'content-type: application/json' \
  -d '{"dwellingCoverage":350000,"scheduledValue":20000,"deductible":1000,"termMonths":6}'
```

Invalid input (a 7-month term, a negative premium, an unknown deductible)
returns HTTP 400 with `{"error": "..."}`, mirroring the Smalltalk
`InstanceCreationFailed` / `AssertionFailed` / `ObjectNotFound` signals.

## CLI

```bash
java -jar target/policy-term-service-0.1.0-SNAPSHOT.jar cli term 2023-08-31 6
java -jar target/policy-term-service-0.1.0-SNAPSHOT.jar cli pro-rata 2024-02-29 12 1200.00 2024-08-31
java -jar target/policy-term-service-0.1.0-SNAPSHOT.jar cli short-rate 2024-02-29 12 1200.00 2024-08-31
java -jar target/policy-term-service-0.1.0-SNAPSHOT.jar cli renewal 2025-01-01 12 45 2025-11-17
java -jar target/policy-term-service-0.1.0-SNAPSHOT.jar cli homeowners 350000 20000 1000 6
```

## Layout

- `dates/ChaltenDates` - the Chalten-Core rules (leap years, month lengths,
  `next:`/`previous:`, date subtraction, month-of-year arithmetic).
- `rating/*` - one class per Smalltalk class: `PolicyTerm`,
  `ProRataEarnedPremiumCalculator`, `ShortRateCancellationTable`,
  `RenewalOfferWindow`, `HomeownersPremiumCalculator`, plus `Money` for
  exact cent rounding.
- `api/PolicyTermController` - REST facade.
- `cli/PolicyTermCli` - command-line runner.
- `src/test/.../parity/*` - JUnit 5 parameterized tests, one per golden file.
