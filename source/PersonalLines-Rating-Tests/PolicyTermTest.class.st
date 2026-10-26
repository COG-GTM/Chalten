"
SYNTHETIC - tests for the demonstration PolicyTerm class.
"
Class {
	#name : 'PolicyTermTest',
	#superclass : 'ChaltenTest',
	#category : 'PersonalLines-Rating-Tests',
	#package : 'PersonalLines-Rating-Tests'
}

{ #category : 'tests' }
PolicyTermTest >> testDaysInForceIsClampedToTheTerm [

  | term |

  term := PolicyTerm twelveMonthsFrom: march first , 2025.
  self
    assert: ( term daysInForceAt: january first , 2025 ) equals: 0 * day;
    assert: ( term daysInForceAt: march first , 2025 ) equals: 0 * day;
    assert: ( term daysInForceAt: march second , 2025 ) equals: 1 * day;
    assert: ( term daysInForceAt: april first , 2025 ) equals: 31 * day;
    assert: ( term daysInForceAt: march first , 2026 ) equals: 365 * day;
    assert: ( term daysInForceAt: december thirtyFirst , 2030 ) equals: 365 * day
]

{ #category : 'tests' }
PolicyTermTest >> testExpirationClampsToShorterAnniversaryMonth [

  self
    assert: ( PolicyTerm sixMonthsFrom: august thirtyFirst , 2023 ) expirationDate
    equals: february twentyNinth , 2024;
    assert: ( PolicyTerm sixMonthsFrom: august thirtyFirst , 2024 ) expirationDate
    equals: february twentyEighth , 2025;
    assert: ( PolicyTerm twelveMonthsFrom: february twentyNinth , 2024 ) expirationDate
    equals: february twentyEighth , 2025;
    assert: ( PolicyTerm sixMonthsFrom: may thirtyFirst , 2025 ) expirationDate
    equals: november thirtieth , 2025
]

{ #category : 'tests' }
PolicyTermTest >> testIncludes [

  | term |

  term := PolicyTerm sixMonthsFrom: january first , 2025.
  self
    deny: ( term includes: december thirtyFirst , 2024 );
    assert: ( term includes: january first , 2025 );
    assert: ( term includes: june thirtieth , 2025 );
    deny: ( term includes: july first , 2025 )
]

{ #category : 'tests' }
PolicyTermTest >> testNumberOfDaysAcrossLeapDay [

  self
    assert: ( PolicyTerm twelveMonthsFrom: january first , 2024 ) numberOfDays equals: 366 * day;
    assert: ( PolicyTerm twelveMonthsFrom: january first , 2025 ) numberOfDays equals: 365 * day;
    assert: ( PolicyTerm sixMonthsFrom: december first , 2023 ) numberOfDays equals: 183 * day;
    assert: ( PolicyTerm sixMonthsFrom: december first , 2024 ) numberOfDays equals: 182 * day
]

{ #category : 'tests' }
PolicyTermTest >> testOnlySixOrTwelveMonthTermsAreAllowed [

  self
    should: [ PolicyTerm effectiveOn: january first , 2025 lastingMonths: 7 ]
    raise: InstanceCreationFailed.
  self
    should: [ PolicyTerm effectiveOn: january first , 2025 lastingMonths: 0 ]
    raise: InstanceCreationFailed
]

{ #category : 'tests' }
PolicyTermTest >> testTwelveMonthTermExpiresOnAnniversary [

  | term |

  term := PolicyTerm twelveMonthsFrom: march fifteenth , 2025.
  self
    assert: term effectiveDate equals: march fifteenth , 2025;
    assert: term expirationDate equals: march fifteenth , 2026;
    assert: term lastDateInForce equals: march fourteenth , 2026;
    assert: term termInMonths equals: 12;
    assert: term isAnnual
]
