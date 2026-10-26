"
SYNTHETIC - demonstration code, not a real insurer's rating logic.

I calculate the earned and unearned portion of a written premium when a policy is
cancelled on a given date, on a pro-rata (daily) basis:

  earned = written premium * days in force / days in the term, rounded to cents (half away from zero)
  unearned = written premium - earned

A cancellation on or before the effective date earns nothing (flat cancellation);
a cancellation on or after the expiration date earns the whole written premium.
"
Class {
	#name : 'ProRataEarnedPremiumCalculator',
	#superclass : 'Object',
	#instVars : [
		'policyTerm'
	],
	#category : 'PersonalLines-Rating',
	#package : 'PersonalLines-Rating'
}

{ #category : 'instance creation' }
ProRataEarnedPremiumCalculator class >> for: aPolicyTerm [

  ^ self new initializeFor: aPolicyTerm
]

{ #category : 'rounding' }
ProRataEarnedPremiumCalculator class >> roundToCents: anAmount [

  "Half-away-from-zero rounding to two decimals, kept exact by working with fractions."

  ^ ( anAmount * 100 ) rounded / 100
]

{ #category : 'private - asserting' }
ProRataEarnedPremiumCalculator >> assertIsValidPremium: aWrittenPremium [

  AssertionChecker
    enforce: [ aWrittenPremium >= 0 ]
    because: 'Written premium cannot be negative'
]

{ #category : 'calculating' }
ProRataEarnedPremiumCalculator >> earnedPremiumOf: aWrittenPremium cancelledOn: aGregorianDate [

  self assertIsValidPremium: aWrittenPremium.
  ^ self class roundToCents:
      aWrittenPremium * ( policyTerm elapsedFractionAt: aGregorianDate )
]

{ #category : 'initialization' }
ProRataEarnedPremiumCalculator >> initializeFor: aPolicyTerm [

  policyTerm := aPolicyTerm
]

{ #category : 'accessing' }
ProRataEarnedPremiumCalculator >> policyTerm [

  ^ policyTerm
]

{ #category : 'calculating' }
ProRataEarnedPremiumCalculator >> unearnedPremiumOf: aWrittenPremium cancelledOn: aGregorianDate [

  ^ aWrittenPremium - ( self earnedPremiumOf: aWrittenPremium cancelledOn: aGregorianDate )
]
