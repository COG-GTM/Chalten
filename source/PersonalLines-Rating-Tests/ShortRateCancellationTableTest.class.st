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
