"
SYNTHETIC - tests for the demonstration HomeownersPremiumCalculator class.
"
Class {
	#name : 'HomeownersPremiumCalculatorTest',
	#superclass : 'ChaltenTest',
	#category : 'PersonalLines-Rating-Tests',
	#package : 'PersonalLines-Rating-Tests'
}

{ #category : 'tests' }
HomeownersPremiumCalculatorTest >> testAnnualPremiumCombinesComponents [

  "350000 dwelling at 3.50 = 1225.00; 1000 deductible credit 5% = 61.25; 20000 scheduled at 12.50 = 250.00"
  self
    assert: ( HomeownersPremiumCalculator standard
          annualPremiumForDwelling: 350000
          valuableArticles: 20000
          deductible: 1000 )
    equals: 141375 / 100
]

{ #category : 'tests' }
HomeownersPremiumCalculatorTest >> testDeductibleCredit [

  | calculator |

  calculator := HomeownersPremiumCalculator standard.
  self
    assert: ( calculator deductibleCreditForDwelling: 350000 deductible: 500 ) equals: 0;
    assert: ( calculator deductibleCreditForDwelling: 350000 deductible: 1000 ) equals: 6125 / 100;
    assert: ( calculator deductibleCreditForDwelling: 350000 deductible: 2500 ) equals: 147;
    assert: ( calculator deductibleCreditForDwelling: 350000 deductible: 5000 ) equals: 245
]

{ #category : 'tests' }
HomeownersPremiumCalculatorTest >> testDwellingPremium [

  | calculator |

  calculator := HomeownersPremiumCalculator standard.
  self
    assert: ( calculator dwellingPremiumFor: 0 ) equals: 0;
    assert: ( calculator dwellingPremiumFor: 350000 ) equals: 1225;
    assert: ( calculator dwellingPremiumFor: 123456 ) equals: 43210 / 100
]

{ #category : 'tests' }
HomeownersPremiumCalculatorTest >> testNegativeCoverageIsRejected [

  self
    should: [ HomeownersPremiumCalculator standard dwellingPremiumFor: -1 ]
    raise: AssertionFailed
]

{ #category : 'tests' }
HomeownersPremiumCalculatorTest >> testSixMonthTermPremiumIsHalfTheAnnual [

  | calculator |

  calculator := HomeownersPremiumCalculator standard.
  self
    assert: ( calculator
          termPremiumForDwelling: 350000
          valuableArticles: 20000
          deductible: 1000
          over: ( PolicyTerm sixMonthsFrom: january first , 2025 ) )
    equals: 70688 / 100;
    assert: ( calculator
          termPremiumForDwelling: 350000
          valuableArticles: 20000
          deductible: 1000
          over: ( PolicyTerm twelveMonthsFrom: january first , 2025 ) )
    equals: 141375 / 100
]

{ #category : 'tests' }
HomeownersPremiumCalculatorTest >> testUnknownDeductibleIsRejected [

  self
    should: [ HomeownersPremiumCalculator standard deductibleCreditForDwelling: 350000 deductible: 750 ]
    raise: ObjectNotFound
]

{ #category : 'tests' }
HomeownersPremiumCalculatorTest >> testValuableArticlesPremiumHasMinimum [

  | calculator |

  calculator := HomeownersPremiumCalculator standard.
  self
    assert: ( calculator valuableArticlesPremiumFor: 0 ) equals: 0;
    assert: ( calculator valuableArticlesPremiumFor: 1000 ) equals: 25;
    assert: ( calculator valuableArticlesPremiumFor: 2000 ) equals: 25;
    assert: ( calculator valuableArticlesPremiumFor: 2001 ) equals: 2501 / 100;
    assert: ( calculator valuableArticlesPremiumFor: 20000 ) equals: 250
]
