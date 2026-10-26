"
SYNTHETIC - demonstration code, not a real insurer's rating logic.

A PolicyTerm is the period during which a personal lines policy is in force.
It starts on the effective date and ends on the expiration date, which is the
anniversary of the effective date 6 or 12 months later. When the anniversary
month is shorter than the effective day number (e.g. effective August 31,
expiring in February) the expiration date is clamped to the last day of that month.

The expiration date itself is not in force: coverage runs from the effective date
up to, but not including, the expiration date.
"
Class {
	#name : 'PolicyTerm',
	#superclass : 'Object',
	#instVars : [
		'effectiveDate',
		'termInMonths',
		'expirationDate'
	],
	#category : 'PersonalLines-Rating',
	#package : 'PersonalLines-Rating'
}

{ #category : 'private - accessing' }
PolicyTerm class >> allowedTermsInMonths [

  ^ #( 6 12 )
]

{ #category : 'instance creation' }
PolicyTerm class >> effectiveOn: aGregorianDate lastingMonths: anInteger [

  AssertionChecker
    enforce: [ self allowedTermsInMonths includes: anInteger ]
    because: 'Policy terms must last 6 or 12 months'
    raising: InstanceCreationFailed.

  ^ self new initializeEffectiveOn: aGregorianDate lastingMonths: anInteger
]

{ #category : 'instance creation' }
PolicyTerm class >> sixMonthsFrom: aGregorianDate [

  ^ self effectiveOn: aGregorianDate lastingMonths: 6
]

{ #category : 'instance creation' }
PolicyTerm class >> twelveMonthsFrom: aGregorianDate [

  ^ self effectiveOn: aGregorianDate lastingMonths: 12
]

{ #category : 'private - calculating' }
PolicyTerm >> calculateExpirationDate [

  | anniversaryMonth lastValidDayNumber |

  anniversaryMonth := effectiveDate monthOfYear next: termInMonths * GregorianDate month.
  lastValidDayNumber := anniversaryMonth numberOfDays numericalValue.
  ^ anniversaryMonth dateAt: ( effectiveDate dayNumber min: lastValidDayNumber )
]

{ #category : 'calculating' }
PolicyTerm >> daysInForceAt: aGregorianDate [

  "Days of coverage consumed at the start of aGregorianDate. Never negative, never more than the whole term."

  aGregorianDate <= effectiveDate then: [ ^ 0 * GregorianDate day ].
  aGregorianDate >= expirationDate then: [ ^ self numberOfDays ].
  ^ aGregorianDate - effectiveDate
]

{ #category : 'accessing' }
PolicyTerm >> effectiveDate [

  ^ effectiveDate
]

{ #category : 'calculating' }
PolicyTerm >> elapsedFractionAt: aGregorianDate [

  ^ ( self daysInForceAt: aGregorianDate ) numericalValue / self numberOfDays numericalValue
]

{ #category : 'accessing' }
PolicyTerm >> expirationDate [

  ^ expirationDate
]

{ #category : 'testing' }
PolicyTerm >> includes: aGregorianDate [

  ^ aGregorianDate >= effectiveDate and: [ aGregorianDate < expirationDate ]
]

{ #category : 'initialization' }
PolicyTerm >> initializeEffectiveOn: aGregorianDate lastingMonths: anInteger [

  effectiveDate := aGregorianDate.
  termInMonths := anInteger.
  expirationDate := self calculateExpirationDate
]

{ #category : 'testing' }
PolicyTerm >> isAnnual [

  ^ termInMonths = 12
]

{ #category : 'accessing' }
PolicyTerm >> lastDateInForce [

  ^ expirationDate previous
]

{ #category : 'accessing' }
PolicyTerm >> numberOfDays [

  ^ expirationDate - effectiveDate
]

{ #category : 'printing' }
PolicyTerm >> printOn: aStream [

  aStream
    print: termInMonths;
    nextPutAll: '-month term from ';
    print: effectiveDate;
    nextPutAll: ' to ';
    print: expirationDate
]

{ #category : 'accessing' }
PolicyTerm >> renewalOfferWindow [

  ^ RenewalOfferWindow standardFor: self
]

{ #category : 'accessing' }
PolicyTerm >> termInMonths [

  ^ termInMonths
]
