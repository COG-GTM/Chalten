"Runs every Chalten and PersonalLines SUnit test headlessly and prints one result line per package,
 followed by the name of every failing or erroring test. Exits with status 1 when anything fails."
| failed |
failed := false.
#('Chalten-Core-Tests' 'Chalten-Timezones-Tests' 'PersonalLines-Rating-Tests') do: [ :packageName |
  | result |
  result := TestResult new.
  ((RPackageOrganizer default packageNamed: packageName) definedClasses
    select: [ :each | (each inheritsFrom: TestCase) and: [ each isAbstract not ] ])
    do: [ :testClass | testClass suite run: result ].
  Transcript show: packageName, ': ', result printString; cr.
  result failures do: [ :each | Transcript show: '  FAILURE ', each printString; cr ].
  result errors do: [ :each | Transcript show: '  ERROR ', each printString; cr ].
  result hasPassed ifFalse: [ failed := true ] ].
failed ifTrue: [ Smalltalk exit: 1 ].
Smalltalk snapshot: false andQuit: true.
