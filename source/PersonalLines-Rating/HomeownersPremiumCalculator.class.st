"
SYNTHETIC - demonstration code, not a real insurer's rating logic.

I rate a simple homeowners policy:

  dwelling premium   = dwelling coverage / 1000 * dwelling rate, rounded to cents
  valuable articles  = scheduled value / 1000 * valuable articles rate, rounded to cents,
                       subject to a minimum premium when anything is scheduled
  deductible credit  = dwelling premium * credit percentage for the chosen deductible, rounded to cents
  annual premium     = dwelling premium - deductible credit + valuable articles premium
  term premium       = annual premium * term months / 12, rounded to cents

Each component is rounded before it is combined, as a legacy rating engine would do
when every intermediate figure is printed on the declarations page.
"
Class {
	#name : 'HomeownersPremiumCalculator',
	#superclass : 'Object',
	#instVars : [
		'dwellingRatePerThousand',
		'valuableArticlesRatePerThousand',
		'valuableArticlesMinimumPremium',
		'deductibleCreditPercentages'
	],
	#category : 'PersonalLines-Rating',
	#package : 'PersonalLines-Rating'
}

{ #category : 'instance creation' }
HomeownersPremiumCalculator class >> new [

  ^ super new initialize
]

{ #category : 'instance creation' }
HomeownersPremiumCalculator class >> standard [

  ^ self new
      dwellingRatePerThousand: 7 / 2;
      valuableArticlesRatePerThousand: 25 / 2;
      valuableArticlesMinimumPremium: 25;
      creditPercentage: 0 forDeductible: 500;
      creditPercentage: 5 forDeductible: 1000;
      creditPercentage: 12 forDeductible: 2500;
      creditPercentage: 20 forDeductible: 5000;
      yourself
]

{ #category : 'calculating' }
HomeownersPremiumCalculator >> annualPremiumForDwelling: aDwellingCoverage valuableArticles: aScheduledValue deductible: aDeductible [

  ^ ( self dwellingPremiumFor: aDwellingCoverage )
    - ( self deductibleCreditForDwelling: aDwellingCoverage deductible: aDeductible )
    + ( self valuableArticlesPremiumFor: aScheduledValue )
]

{ #category : 'private - asserting' }
HomeownersPremiumCalculator >> assertIsValidCoverage: anAmount [

  AssertionChecker enforce: [ anAmount >= 0 ] because: 'Coverage amounts cannot be negative'
]

{ #category : 'configuring' }
HomeownersPremiumCalculator >> creditPercentage: aPercentage forDeductible: aDeductible [

  deductibleCreditPercentages at: aDeductible put: aPercentage
]

{ #category : 'calculating' }
HomeownersPremiumCalculator >> deductibleCreditForDwelling: aDwellingCoverage deductible: aDeductible [

  | percentage |

  percentage := deductibleCreditPercentages
                  at: aDeductible
                  ifAbsent: [ ObjectNotFound signal: 'No deductible credit is defined for ' , aDeductible printString ].
  ^ ProRataEarnedPremiumCalculator roundToCents:
      ( self dwellingPremiumFor: aDwellingCoverage ) * percentage / 100
]

{ #category : 'calculating' }
HomeownersPremiumCalculator >> dwellingPremiumFor: aDwellingCoverage [

  self assertIsValidCoverage: aDwellingCoverage.
  ^ ProRataEarnedPremiumCalculator roundToCents: aDwellingCoverage / 1000 * dwellingRatePerThousand
]

{ #category : 'configuring' }
HomeownersPremiumCalculator >> dwellingRatePerThousand: aRate [

  dwellingRatePerThousand := aRate
]

{ #category : 'initialization' }
HomeownersPremiumCalculator >> initialize [

  deductibleCreditPercentages := Dictionary new
]

{ #category : 'calculating' }
HomeownersPremiumCalculator >> termPremiumForDwelling: aDwellingCoverage valuableArticles: aScheduledValue deductible: aDeductible over: aPolicyTerm [

  | annualPremium |

  annualPremium := self
                     annualPremiumForDwelling: aDwellingCoverage
                     valuableArticles: aScheduledValue
                     deductible: aDeductible.
  ^ ProRataEarnedPremiumCalculator roundToCents: annualPremium * aPolicyTerm termInMonths / 12
]

{ #category : 'configuring' }
HomeownersPremiumCalculator >> valuableArticlesMinimumPremium: anAmount [

  valuableArticlesMinimumPremium := anAmount
]

{ #category : 'calculating' }
HomeownersPremiumCalculator >> valuableArticlesPremiumFor: aScheduledValue [

  self assertIsValidCoverage: aScheduledValue.
  aScheduledValue isZero then: [ ^ 0 ].
  ^ ( ProRataEarnedPremiumCalculator roundToCents: aScheduledValue / 1000 * valuableArticlesRatePerThousand )
      max: valuableArticlesMinimumPremium
]

{ #category : 'configuring' }
HomeownersPremiumCalculator >> valuableArticlesRatePerThousand: aRate [

  valuableArticlesRatePerThousand := aRate
]
