"
SYNTHETIC - tests for the demonstration ShortRateCancellationTable class.
"
Class {
	#name : 'ShortRateCancellationTableTest',
	#superclass : 'ChaltenTest',
	#category : 'PersonalLines-Rating-Tests',
	#package : 'PersonalLines-Rating-Tests'
}

{ #category : 'tests' }
ShortRateCancellationTableTest >> testBandUpperBoundIsInclusive [

  | term table |

  "73 days of 365 is exactly 20%, so the 20% band applies, not the 25% one."
  term := PolicyTerm twelveMonthsFrom: january first , 2025.
  table := ShortRateCancellationTable standard.
  self
    assert: ( table retainedPercentageFor: term cancelledOn: march fifteenth , 2025 ) equals: 31;
    assert: ( table retainedPercentageFor: term cancelledOn: march sixteenth , 2025 ) equals: 37
]

{ #category : 'tests' }
ShortRateCancellationTableTest >> testBandsMustBeIncreasing [

  self
    should: [
      ShortRateCancellationTable new
        addBandUpTo: 10 retaining: 17;
        addBandUpTo: 5 retaining: 10 ]
    raise: AssertionFailed
]

{ #category : 'tests' }
ShortRateCancellationTableTest >> testFlatCancellationRetainsNothing [

  | term table |

  term := PolicyTerm sixMonthsFrom: january first , 2025.
  table := ShortRateCancellationTable standard.
  self
    assert: ( table retainedPercentageFor: term cancelledOn: january first , 2025 ) equals: 0;
    assert: ( table earnedPremiumOf: 600 for: term cancelledOn: january first , 2025 ) equals: 0
]

{ #category : 'tests' }
ShortRateCancellationTableTest >> testFullTermRetainsEverything [

  | term table |

  term := PolicyTerm sixMonthsFrom: january first , 2025.
  table := ShortRateCancellationTable standard.
  self
    assert: ( table retainedPercentageFor: term cancelledOn: july first , 2025 ) equals: 100;
    assert: ( table earnedPremiumOf: 600 for: term cancelledOn: july first , 2025 ) equals: 600;
    assert: ( table penaltyOf: 600 for: term cancelledOn: july first , 2025 ) equals: 0
]

{ #category : 'tests' }
ShortRateCancellationTableTest >> testFlatCancellationRetainsNothingDespiteMinimum [

  | term table |

  term := PolicyTerm twelveMonthsFrom: january first , 2025.
  table := ShortRateCancellationTable standard.
  self
    assert: ( table earnedPremiumOf: 200 for: term cancelledOn: january first , 2025 ) equals: 0;
    assert: ( table earnedPremiumOf: 200 for: term cancelledOn: december first , 2024 ) equals: 0;
    assert: ( table penaltyOf: 200 for: term cancelledOn: january first , 2025 ) equals: 0
]

{ #category : 'tests' }
ShortRateCancellationTableTest >> testMinimumRetainedPremiumAppliesWhenBandAmountIsLower [

  | term table |

  "1 day of 365 retains 10%: 200 * 10% = 20.00, raised to the 25.00 minimum. Pro-rata earns 0.55."
  term := PolicyTerm twelveMonthsFrom: january first , 2025.
  table := ShortRateCancellationTable standard.
  self
    assert: ( table retainedPercentageFor: term cancelledOn: january second , 2025 ) equals: 10;
    assert: ( table earnedPremiumOf: 200 for: term cancelledOn: january second , 2025 ) equals: 25;
    assert: ( table penaltyOf: 200 for: term cancelledOn: january second , 2025 ) equals: 2445 / 100
]

{ #category : 'tests' }
ShortRateCancellationTableTest >> testMinimumRetainedPremiumAppliesToZeroPercentBand [

  | term table |

  "A configured 0% band is not a flat cancellation: once a day is in force the minimum still applies."
  term := PolicyTerm twelveMonthsFrom: january first , 2025.
  table := ShortRateCancellationTable new
             addBandUpTo: 100 retaining: 0;
             retainingAtLeast: 25;
             yourself.
  self
    assert: ( table retainedPercentageFor: term cancelledOn: january second , 2025 ) equals: 0;
    assert: ( table earnedPremiumOf: 200 for: term cancelledOn: january second , 2025 ) equals: 25;
    assert: ( table earnedPremiumOf: 200 for: term cancelledOn: january first , 2025 ) equals: 0
]

{ #category : 'tests' }
ShortRateCancellationTableTest >> testMinimumRetainedPremiumBoundary [

  | term table |

  "At 10% retained, 249.90 earns 24.99 (minimum applies), 250 earns exactly 25.00, 250.10 earns 25.01 (band applies)."
  term := PolicyTerm twelveMonthsFrom: january first , 2025.
  table := ShortRateCancellationTable standard.
  self
    assert: ( table earnedPremiumOf: 24990 / 100 for: term cancelledOn: january second , 2025 ) equals: 25;
    assert: ( table earnedPremiumOf: 250 for: term cancelledOn: january second , 2025 ) equals: 25;
    assert: ( table earnedPremiumOf: 25010 / 100 for: term cancelledOn: january second , 2025 ) equals: 2501 / 100
]

{ #category : 'tests' }
ShortRateCancellationTableTest >> testMinimumRetainedPremiumCannotBeNegative [

  self should: [ ShortRateCancellationTable new retainingAtLeast: -1 ] raise: AssertionFailed
]

{ #category : 'tests' }
ShortRateCancellationTableTest >> testMinimumRetainedPremiumNeverExceedsWrittenPremium [

  | term table |

  term := PolicyTerm twelveMonthsFrom: january first , 2025.
  table := ShortRateCancellationTable standard.
  self
    assert: ( table earnedPremiumOf: 20 for: term cancelledOn: january second , 2025 ) equals: 20;
    assert: ( table earnedPremiumOf: 25 for: term cancelledOn: january second , 2025 ) equals: 25;
    assert: ( table earnedPremiumOf: 87 / 100 for: term cancelledOn: january second , 2025 ) equals: 87 / 100;
    assert: ( table earnedPremiumOf: 0 for: term cancelledOn: january second , 2025 ) equals: 0
]

{ #category : 'tests' }
ShortRateCancellationTableTest >> testTableWithoutMinimumRetainsBandAmountOnly [

  | term table |

  term := PolicyTerm twelveMonthsFrom: january first , 2025.
  table := ShortRateCancellationTable new
             addBandUpTo: 100 retaining: 10;
             yourself.
  self
    assert: table minimumRetainedPremium equals: 0;
    assert: ShortRateCancellationTable standard minimumRetainedPremium equals: 25;
    assert: ( table earnedPremiumOf: 200 for: term cancelledOn: january second , 2025 ) equals: 20
]

{ #category : 'tests' }
ShortRateCancellationTableTest >> testShortRateExceedsProRata [

  | term table |

  "1 day of 365 falls in the first band: 10% retained versus 0.27% pro-rata."
  term := PolicyTerm twelveMonthsFrom: january first , 2025.
  table := ShortRateCancellationTable standard.
  self
    assert: ( table retainedPercentageFor: term cancelledOn: january second , 2025 ) equals: 10;
    assert: ( table earnedPremiumOf: 1000 for: term cancelledOn: january second , 2025 ) equals: 100;
    assert: ( table penaltyOf: 1000 for: term cancelledOn: january second , 2025 ) equals: 9726 / 100
]
