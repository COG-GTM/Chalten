"
SYNTHETIC - tests for the demonstration RenewalOfferWindow class.
"
Class {
	#name : 'RenewalOfferWindowTest',
	#superclass : 'ChaltenTest',
	#category : 'PersonalLines-Rating-Tests',
	#package : 'PersonalLines-Rating-Tests'
}

{ #category : 'tests' }
RenewalOfferWindowTest >> testDaysUntilOpening [

  | window |

  window := ( PolicyTerm twelveMonthsFrom: january first , 2025 ) renewalOfferWindow.
  self
    assert: ( window daysUntilOpeningFrom: january first , 2025 ) equals: 320 * day;
    assert: ( window daysUntilOpeningFrom: november sixteenth , 2025 ) equals: 1 * day;
    assert: ( window daysUntilOpeningFrom: november seventeenth , 2025 ) equals: 0 * day;
    assert: ( window daysUntilOpeningFrom: december first , 2025 ) equals: 0 * day
]

{ #category : 'tests' }
RenewalOfferWindowTest >> testLeadTimeMustBePositive [

  self
    should: [ RenewalOfferWindow for: ( PolicyTerm sixMonthsFrom: january first , 2025 ) openingDaysBeforeExpiration: 0 ]
    raise: InstanceCreationFailed
]

{ #category : 'tests' }
RenewalOfferWindowTest >> testStandardWindowOpensFortyFiveDaysBeforeExpiration [

  | window |

  window := ( PolicyTerm twelveMonthsFrom: january first , 2025 ) renewalOfferWindow.
  self
    assert: window leadTime equals: 45 * day;
    assert: window opensOn equals: november seventeenth , 2025;
    assert: window closesOn equals: december thirtyFirst , 2025;
    deny: ( window isOpenOn: november sixteenth , 2025 );
    assert: ( window isOpenOn: november seventeenth , 2025 );
    assert: ( window isOpenOn: december thirtyFirst , 2025 );
    deny: ( window isOpenOn: january first , 2026 )
]

{ #category : 'tests' }
RenewalOfferWindowTest >> testWindowCrossingLeapDay [

  | window |

  window := ( PolicyTerm sixMonthsFrom: october first , 2023 ) renewalOfferWindow.
  self
    assert: window policyTerm expirationDate equals: april first , 2024;
    assert: window opensOn equals: february sixteenth , 2024
]

{ #category : 'tests' }
RenewalOfferWindowTest >> testWindowNeverOpensBeforeEffectiveDate [

  | window |

  window := RenewalOfferWindow
              for: ( PolicyTerm sixMonthsFrom: january first , 2025 )
              openingDaysBeforeExpiration: 400.
  self assert: window opensOn equals: january first , 2025
]
