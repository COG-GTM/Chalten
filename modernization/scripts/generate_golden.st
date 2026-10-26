"Golden data generator. Executes the PersonalLines-Rating rules and selected Chalten-Core date rules
 over a deterministic input set and writes the inputs and outputs to CSV files under CHALTEN_GOLDEN_DIR.
 These files are the equivalence oracle replayed by the Java parity tests. Nothing here is hand-written:
 every expected value is the result of sending the message to the Smalltalk objects."
| goldenDir day month iso money quantity dateAt effectiveDates terms cancellationOffsets premiums leadTimes
  dwellings scheduledValues deductibles coreDates writeCsv rowCount table homeCalculator referenceDate
  shortRate boolean |

goldenDir := OSEnvironment current at: 'CHALTEN_GOLDEN_DIR'.
day := InternationalSystemOfUnits units >> #day.
month := TimeUnits units >> #month.
iso := [ :aDate | ISO8601Formatter new format: aDate ].
quantity := [ :aQuantity | aQuantity numericalValue printString ].
boolean := [ :aBoolean | aBoolean printString ].
money := [ :anAmount | | cents |
  cents := ( anAmount * 100 ) rounded.
  ( cents < 0 then: [ '-' ] otherwise: [ '' ] ) ,
    ( cents abs // 100 ) printString , '.' , ( ( cents abs \\ 100 ) printPaddedWith: $0 to: 2 ) ].
dateAt := [ :y :m :d | ( y asGregorianYear monthAt: m ) dateAt: d ].
writeCsv := [ :fileName :header :rows |
  | file |
  file := ( goldenDir asFileReference / fileName ) ensureDelete; yourself.
  file writeStreamDo: [ :stream |
    stream nextPutAll: header; lf.
    rows do: [ :row | stream nextPutAll: ( row joinUsing: ',' ); lf ] ].
  Transcript show: fileName , ': ' , rows size printString , ' cases'; cr.
  rows size ].
rowCount := 0.

"---- deterministic input sets ----"
effectiveDates := {
  dateAt value: 2023 value: 8 value: 31.   dateAt value: 2023 value: 12 value: 31.
  dateAt value: 2024 value: 1 value: 1.    dateAt value: 2024 value: 1 value: 31.
  dateAt value: 2024 value: 2 value: 28.   dateAt value: 2024 value: 2 value: 29.
  dateAt value: 2024 value: 3 value: 1.    dateAt value: 2024 value: 3 value: 31.
  dateAt value: 2024 value: 4 value: 30.   dateAt value: 2024 value: 5 value: 31.
  dateAt value: 2024 value: 6 value: 30.   dateAt value: 2024 value: 8 value: 31.
  dateAt value: 2024 value: 10 value: 31.  dateAt value: 2024 value: 12 value: 1.
  dateAt value: 2024 value: 12 value: 31.  dateAt value: 2025 value: 1 value: 1.
  dateAt value: 2025 value: 2 value: 28.   dateAt value: 2025 value: 3 value: 1.
  dateAt value: 2025 value: 5 value: 31.   dateAt value: 2025 value: 8 value: 29.
  dateAt value: 2025 value: 8 value: 30.   dateAt value: 2025 value: 8 value: 31.
  dateAt value: 2025 value: 11 value: 30.  dateAt value: 2027 value: 8 value: 31.
  dateAt value: 2099 value: 8 value: 31.   dateAt value: 2099 value: 12 value: 31 }.
terms := OrderedCollection new.
effectiveDates do: [ :effective |
  terms add: ( PolicyTerm sixMonthsFrom: effective ); add: ( PolicyTerm twelveMonthsFrom: effective ) ].
cancellationOffsets := #( -30 -1 0 1 29 30 31 59 73 90 120 181 182 183 270 364 365 366 400 ).
premiums := { 1200. 59999/100. 1000. 1/100. 0. 245075/100. 87/100 }.
leadTimes := #( 45 30 60 400 ).
dwellings := #( 0 100000 123456 250000 350000 499999 750000 1000001 ).
scheduledValues := #( 0 1000 2001 20000 55555 ).
deductibles := #( 500 1000 2500 5000 ).
shortRate := ShortRateCancellationTable standard.
homeCalculator := HomeownersPremiumCalculator standard.

"---- rule 1: policy terms ----"
rowCount := rowCount + ( writeCsv
  value: 'policy_terms.csv'
  value: 'effective_date,term_months,expiration_date,term_days,last_date_in_force,renewal_opens_on,renewal_closes_on'
  value: ( terms collect: [ :term | {
    iso value: term effectiveDate. term termInMonths printString. iso value: term expirationDate.
    quantity value: term numberOfDays. iso value: term lastDateInForce.
    iso value: term renewalOfferWindow opensOn. iso value: term renewalOfferWindow closesOn } ] ) ).

"---- rules 2 and 3: pro-rata and short-rate cancellations ----"
rowCount := rowCount + ( writeCsv
  value: 'cancellations.csv'
  value: 'effective_date,term_months,written_premium,cancellation_date,days_in_force,in_force,pro_rata_earned,pro_rata_unearned,short_rate_pct,short_rate_earned,short_rate_penalty'
  value: ( ( terms collectWithIndex: [ :term :termIndex |
    cancellationOffsets collectWithIndex: [ :offset :offsetIndex |
      | cancellation premium proRata |
      cancellation := term effectiveDate next: offset * day.
      premium := premiums at: ( termIndex + offsetIndex ) \\ premiums size + 1.
      proRata := ProRataEarnedPremiumCalculator for: term.
      { iso value: term effectiveDate. term termInMonths printString. money value: premium. iso value: cancellation.
        quantity value: ( term daysInForceAt: cancellation ). boolean value: ( term includes: cancellation ).
        money value: ( proRata earnedPremiumOf: premium cancelledOn: cancellation ).
        money value: ( proRata unearnedPremiumOf: premium cancelledOn: cancellation ).
        ( shortRate retainedPercentageFor: term cancelledOn: cancellation ) printString.
        money value: ( shortRate earnedPremiumOf: premium for: term cancelledOn: cancellation ).
        money value: ( shortRate penaltyOf: premium for: term cancelledOn: cancellation ) } ] ] )
      inject: OrderedCollection new into: [ :all :rows | all addAll: rows; yourself ] ) ).

"---- rule 4: renewal offer window ----"
rowCount := rowCount + ( writeCsv
  value: 'renewal_windows.csv'
  value: 'effective_date,term_months,lead_days,opens_on,closes_on,days_until_opening_from_effective,open_day_before_opening,open_on_opening,open_on_closing,open_on_expiration'
  value: ( ( terms collect: [ :term |
    leadTimes collect: [ :leadDays |
      | window |
      window := RenewalOfferWindow for: term openingDaysBeforeExpiration: leadDays.
      { iso value: term effectiveDate. term termInMonths printString. leadDays printString.
        iso value: window opensOn. iso value: window closesOn.
        quantity value: ( window daysUntilOpeningFrom: term effectiveDate ).
        boolean value: ( window isOpenOn: window opensOn previous ).
        boolean value: ( window isOpenOn: window opensOn ).
        boolean value: ( window isOpenOn: window closesOn ).
        boolean value: ( window isOpenOn: term expirationDate ) } ] ] )
      inject: OrderedCollection new into: [ :all :rows | all addAll: rows; yourself ] ) ).

"---- rule 5: homeowners premium ----"
table := OrderedCollection new.
dwellings do: [ :dwelling | scheduledValues do: [ :scheduled | deductibles do: [ :deductible |
  table add: {
    dwelling printString. scheduled printString. deductible printString.
    money value: ( homeCalculator dwellingPremiumFor: dwelling ).
    money value: ( homeCalculator valuableArticlesPremiumFor: scheduled ).
    money value: ( homeCalculator deductibleCreditForDwelling: dwelling deductible: deductible ).
    money value: ( homeCalculator annualPremiumForDwelling: dwelling valuableArticles: scheduled deductible: deductible ).
    money value: ( homeCalculator termPremiumForDwelling: dwelling valuableArticles: scheduled deductible: deductible
                    over: ( PolicyTerm sixMonthsFrom: ( dateAt value: 2025 value: 1 value: 1 ) ) ).
    money value: ( homeCalculator termPremiumForDwelling: dwelling valuableArticles: scheduled deductible: deductible
                    over: ( PolicyTerm twelveMonthsFrom: ( dateAt value: 2025 value: 1 value: 1 ) ) ) } ] ] ].
rowCount := rowCount + ( writeCsv
  value: 'homeowners_premiums.csv'
  value: 'dwelling_coverage,scheduled_value,deductible,dwelling_premium,valuable_articles_premium,deductible_credit,annual_premium,six_month_premium,twelve_month_premium'
  value: table ).

"---- Chalten-Core date rules the port depends on ----"
coreDates := effectiveDates , {
  dateAt value: 1900 value: 2 value: 28. dateAt value: 2000 value: 2 value: 29. dateAt value: 2100 value: 2 value: 28.
  dateAt value: 2024 value: 11 value: 30. dateAt value: 2025 value: 12 value: 31. dateAt value: 2026 value: 1 value: 1 }.
referenceDate := dateAt value: 2024 value: 1 value: 1.
table := OrderedCollection new.
coreDates do: [ :aDate |
  table
    add: { iso value: aDate. 'isLeapYear'. ''. boolean value: aDate year isLeapYear };
    add: { iso value: aDate. 'yearNumberOfDays'. ''. quantity value: aDate year numberOfDays };
    add: { iso value: aDate. 'monthNumberOfDays'. ''. quantity value: aDate monthOfYear numberOfDays };
    add: { iso value: aDate. 'isLastDayOfMonth'. ''. boolean value: aDate isLastDayOfMonth };
    add: { iso value: aDate. 'dayOfWeek'. ''. aDate dayOfWeek printString };
    add: { iso value: aDate. 'next'. ''. iso value: aDate next };
    add: { iso value: aDate. 'previous'. ''. iso value: aDate previous };
    add: { iso value: aDate. 'daysSinceReference'. iso value: referenceDate.
           ( aDate >= referenceDate then: [ aDate - referenceDate ] otherwise: [ ( referenceDate - aDate ) negated ] ) numericalValue printString }.
  #( 0 1 28 29 30 31 45 365 366 -1 -31 -366 ) do: [ :n |
    table add: { iso value: aDate. 'nextDays'. n printString. iso value: ( aDate next: n * day ) } ].
  #( 1 6 12 13 24 -1 -6 -12 ) do: [ :n |
    table add: { iso value: aDate. 'monthOfYearNextMonths'. n printString.
                 ( ISO8601Formatter new format: ( aDate monthOfYear next: n * month ) ) } ] ].
rowCount := rowCount + ( writeCsv
  value: 'chalten_core_dates.csv'
  value: 'date,operation,argument,expected'
  value: table ).

"---- invalid inputs: the Smalltalk rejects these; the Java must reject them too ----"
table := OrderedCollection new.
{ 'PolicyTerm effectiveOn:lastingMonths:' -> [ PolicyTerm effectiveOn: referenceDate lastingMonths: 7 ].
  'PolicyTerm effectiveOn:lastingMonths:' -> [ PolicyTerm effectiveOn: referenceDate lastingMonths: 0 ].
  'ProRataEarnedPremiumCalculator earnedPremiumOf:cancelledOn:' -> [ ( ProRataEarnedPremiumCalculator for: ( PolicyTerm twelveMonthsFrom: referenceDate ) ) earnedPremiumOf: -1 cancelledOn: referenceDate ].
  'RenewalOfferWindow for:openingDaysBeforeExpiration:' -> [ RenewalOfferWindow for: ( PolicyTerm twelveMonthsFrom: referenceDate ) openingDaysBeforeExpiration: 0 ].
  'HomeownersPremiumCalculator deductibleCreditForDwelling:deductible:' -> [ homeCalculator deductibleCreditForDwelling: 100000 deductible: 750 ].
  'HomeownersPremiumCalculator dwellingPremiumFor:' -> [ homeCalculator dwellingPremiumFor: -100 ].
  'ShortRateCancellationTable addBandUpTo:retaining:' -> [ ShortRateCancellationTable new addBandUpTo: 10 retaining: 17; addBandUpTo: 5 retaining: 10 ].
  'GregorianMonthOfYear dateAt:' -> [ dateAt value: 2025 value: 2 value: 29 ].
  'GregorianMonthOfYear dateAt:' -> [ dateAt value: 2025 value: 4 value: 31 ] }
  do: [ :association |
    table add: { association key. association value sourceNode body sourceCode copyReplaceAll: ',' with: ';'.
                 [ association value value. 'NO ERROR' ] on: Error do: [ :error | error class name ] } ].
rowCount := rowCount + ( writeCsv value: 'invalid_inputs.csv' value: 'rule,smalltalk_expression,expected_error' value: table ).

Transcript show: 'TOTAL golden cases: ' , rowCount printString; cr.
Transcript show: 'Pharo: ' , SystemVersion current printString; cr.
Smalltalk snapshot: false andQuit: true.
