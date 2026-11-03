"
SYNTHETIC - demonstration code, not a real insurer's rating logic.

A short-rate cancellation table retains more premium than pro-rata when the insured
cancels mid-term. The table is a list of bands keyed by the percentage of the term
elapsed (upper bound, inclusive) and the percentage of written premium retained.

Lookup rule: the first band whose upper bound is greater than or equal to the exact
percentage of the term elapsed applies. Zero days in force is a flat cancellation
and retains nothing, regardless of the first band.

Minimum retained premium: once any day is in force, the short-rate earned premium is
never less than the table's minimum retained premium (25.00 in the standard table),
capped at the written premium. A flat cancellation still retains nothing.
"
Class {
	#name : 'ShortRateCancellationTable',
	#superclass : 'Object',
	#instVars : [
		'bands',
		'minimumRetainedPremium'
	],
	#category : 'PersonalLines-Rating',
	#package : 'PersonalLines-Rating'
}

{ #category : 'instance creation' }
ShortRateCancellationTable class >> new [

  ^ super new initialize
]

{ #category : 'instance creation' }
ShortRateCancellationTable class >> standard [

  ^ self new
      addBandUpTo: 5 retaining: 10;
      addBandUpTo: 10 retaining: 17;
      addBandUpTo: 15 retaining: 24;
      addBandUpTo: 20 retaining: 31;
      addBandUpTo: 25 retaining: 37;
      addBandUpTo: 30 retaining: 43;
      addBandUpTo: 35 retaining: 49;
      addBandUpTo: 40 retaining: 55;
      addBandUpTo: 45 retaining: 60;
      addBandUpTo: 50 retaining: 65;
      addBandUpTo: 55 retaining: 70;
      addBandUpTo: 60 retaining: 75;
      addBandUpTo: 65 retaining: 80;
      addBandUpTo: 70 retaining: 84;
      addBandUpTo: 75 retaining: 88;
      addBandUpTo: 80 retaining: 91;
      addBandUpTo: 85 retaining: 94;
      addBandUpTo: 90 retaining: 97;
      addBandUpTo: 95 retaining: 99;
      addBandUpTo: 100 retaining: 100;
      retainingAtLeast: 25;
      yourself
]

{ #category : 'configuring' }
ShortRateCancellationTable >> addBandUpTo: anElapsedPercentage retaining: aRetainedPercentage [

  AssertionChecker
    enforce: [ bands isEmpty or: [ bands last key < anElapsedPercentage ] ]
    because: 'Short-rate bands must be added in increasing order of elapsed percentage'.
  bands add: anElapsedPercentage -> aRetainedPercentage
]

{ #category : 'calculating' }
ShortRateCancellationTable >> earnedPremiumOf: aWrittenPremium for: aPolicyTerm cancelledOn: aGregorianDate [

  | retainedPercentage |

  retainedPercentage := self retainedPercentageFor: aPolicyTerm cancelledOn: aGregorianDate.
  retainedPercentage isZero then: [ ^ 0 ].
  ^ ( ProRataEarnedPremiumCalculator roundToCents: aWrittenPremium * retainedPercentage / 100 )
    max: ( ProRataEarnedPremiumCalculator roundToCents: ( minimumRetainedPremium min: aWrittenPremium ) )
]

{ #category : 'initialization' }
ShortRateCancellationTable >> initialize [

  bands := OrderedCollection new.
  minimumRetainedPremium := 0
]

{ #category : 'accessing' }
ShortRateCancellationTable >> minimumRetainedPremium [

  ^ minimumRetainedPremium
]

{ #category : 'calculating' }
ShortRateCancellationTable >> penaltyOf: aWrittenPremium for: aPolicyTerm cancelledOn: aGregorianDate [

  "How much more the insured pays under short-rate than under pro-rata."

  | proRata |

  proRata := ProRataEarnedPremiumCalculator for: aPolicyTerm.
  ^ ( self earnedPremiumOf: aWrittenPremium for: aPolicyTerm cancelledOn: aGregorianDate )
    - ( proRata earnedPremiumOf: aWrittenPremium cancelledOn: aGregorianDate )
]

{ #category : 'configuring' }
ShortRateCancellationTable >> retainingAtLeast: aMinimumRetainedPremium [

  AssertionChecker
    enforce: [ aMinimumRetainedPremium >= 0 ]
    because: 'The minimum retained premium cannot be negative'.
  minimumRetainedPremium := aMinimumRetainedPremium
]

{ #category : 'calculating' }
ShortRateCancellationTable >> retainedPercentageFor: aPolicyTerm cancelledOn: aGregorianDate [

  | elapsedPercentage |

  ( aPolicyTerm daysInForceAt: aGregorianDate ) isZero then: [ ^ 0 ].
  elapsedPercentage := ( aPolicyTerm elapsedFractionAt: aGregorianDate ) * 100.
  ^ ( bands detect: [ :band | elapsedPercentage <= band key ] ) value
]
