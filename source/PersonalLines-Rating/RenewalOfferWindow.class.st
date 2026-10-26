"
SYNTHETIC - demonstration code, not a real insurer's rating logic.

The renewal offer window is the stretch of days before a policy expires during
which a renewal offer may be issued. By default it opens 45 days before the
expiration date and closes on the last day the policy is in force.

The window never opens before the policy's own effective date, which matters
for short terms or unusually long lead times.
"
Class {
	#name : 'RenewalOfferWindow',
	#superclass : 'Object',
	#instVars : [
		'policyTerm',
		'leadTime'
	],
	#category : 'PersonalLines-Rating',
	#package : 'PersonalLines-Rating'
}

{ #category : 'instance creation' }
RenewalOfferWindow class >> for: aPolicyTerm openingDaysBeforeExpiration: anInteger [

  AssertionChecker
    enforce: [ anInteger > 0 ]
    because: 'The renewal lead time must be a positive number of days'
    raising: InstanceCreationFailed.

  ^ self new initializeFor: aPolicyTerm leadTime: anInteger * GregorianDate day
]

{ #category : 'instance creation' }
RenewalOfferWindow class >> standardFor: aPolicyTerm [

  ^ self for: aPolicyTerm openingDaysBeforeExpiration: self standardLeadTimeInDays
]

{ #category : 'private - accessing' }
RenewalOfferWindow class >> standardLeadTimeInDays [

  ^ 45
]

{ #category : 'accessing' }
RenewalOfferWindow >> closesOn [

  ^ policyTerm lastDateInForce
]

{ #category : 'calculating' }
RenewalOfferWindow >> daysUntilOpeningFrom: aGregorianDate [

  aGregorianDate >= self opensOn then: [ ^ 0 * GregorianDate day ].
  ^ self opensOn - aGregorianDate
]

{ #category : 'initialization' }
RenewalOfferWindow >> initializeFor: aPolicyTerm leadTime: aTimeQuantity [

  policyTerm := aPolicyTerm.
  leadTime := aTimeQuantity
]

{ #category : 'testing' }
RenewalOfferWindow >> isOpenOn: aGregorianDate [

  ^ aGregorianDate between: self opensOn and: self closesOn
]

{ #category : 'accessing' }
RenewalOfferWindow >> leadTime [

  ^ leadTime
]

{ #category : 'accessing' }
RenewalOfferWindow >> opensOn [

  ^ ( policyTerm expirationDate previous: leadTime ) max: policyTerm effectiveDate
]

{ #category : 'accessing' }
RenewalOfferWindow >> policyTerm [

  ^ policyTerm
]
