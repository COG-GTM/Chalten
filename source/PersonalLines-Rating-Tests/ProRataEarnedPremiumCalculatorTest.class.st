"
SYNTHETIC - tests for the demonstration ProRataEarnedPremiumCalculator class.
"
Class {
	#name : 'ProRataEarnedPremiumCalculatorTest',
	#superclass : 'ChaltenTest',
	#category : 'PersonalLines-Rating-Tests',
	#package : 'PersonalLines-Rating-Tests'
}

{ #category : 'tests' }
ProRataEarnedPremiumCalculatorTest >> testCancellationAfterExpirationEarnsEverything [

  | calculator |

  calculator := ProRataEarnedPremiumCalculator for: ( PolicyTerm twelveMonthsFrom: january first , 2025 ).
  self
    assert: ( calculator earnedPremiumOf: 1200 cancelledOn: january first , 2026 ) equals: 1200;
    assert: ( calculator earnedPremiumOf: 1200 cancelledOn: june first , 2030 ) equals: 1200;
    assert: ( calculator unearnedPremiumOf: 1200 cancelledOn: june first , 2030 ) equals: 0
]

{ #category : 'tests' }
ProRataEarnedPremiumCalculatorTest >> testFlatCancellationEarnsNothing [

  | calculator |

  calculator := ProRataEarnedPremiumCalculator for: ( PolicyTerm twelveMonthsFrom: january first , 2025 ).
  self
    assert: ( calculator earnedPremiumOf: 1200 cancelledOn: january first , 2025 ) equals: 0;
    assert: ( calculator earnedPremiumOf: 1200 cancelledOn: december first , 2024 ) equals: 0;
    assert: ( calculator unearnedPremiumOf: 1200 cancelledOn: january first , 2025 ) equals: 1200
]

{ #category : 'tests' }
ProRataEarnedPremiumCalculatorTest >> testMidTermCancellationIsProRatedByDays [

  | calculator |

  calculator := ProRataEarnedPremiumCalculator for: ( PolicyTerm twelveMonthsFrom: january first , 2025 ).
  "100 days of a 365 day term"
  self
    assert: ( calculator earnedPremiumOf: 1000 cancelledOn: april eleventh , 2025 ) equals: 27397 / 100;
    assert: ( calculator unearnedPremiumOf: 1000 cancelledOn: april eleventh , 2025 ) equals: 72603 / 100
]

{ #category : 'tests' }
ProRataEarnedPremiumCalculatorTest >> testNegativePremiumIsRejected [

  | calculator |

  calculator := ProRataEarnedPremiumCalculator for: ( PolicyTerm twelveMonthsFrom: january first , 2025 ).
  self should: [ calculator earnedPremiumOf: -1 cancelledOn: june first , 2025 ] raise: AssertionFailed
]

{ #category : 'tests' }
ProRataEarnedPremiumCalculatorTest >> testRoundingIsHalfAwayFromZero [

  self
    assert: ( ProRataEarnedPremiumCalculator roundToCents: 1 / 8 ) equals: 13 / 100;
    assert: ( ProRataEarnedPremiumCalculator roundToCents: 1 / 400 ) equals: 0;
    assert: ( ProRataEarnedPremiumCalculator roundToCents: 1 / 200 ) equals: 1 / 100;
    assert: ( ProRataEarnedPremiumCalculator roundToCents: -1 / 200 ) equals: -1 / 100
]

{ #category : 'tests' }
ProRataEarnedPremiumCalculatorTest >> testZeroPremiumEarnsZero [

  | calculator |

  calculator := ProRataEarnedPremiumCalculator for: ( PolicyTerm sixMonthsFrom: february twentyNinth , 2024 ).
  self assert: ( calculator earnedPremiumOf: 0 cancelledOn: may first , 2024 ) equals: 0
]
