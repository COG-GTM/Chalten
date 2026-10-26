#!/usr/bin/env bash
# Replays every golden case through the Java port (JUnit 5 parameterized tests) and prints
# pass/fail counts per rule from the surefire XML reports. Re-runnable; exit status is Maven's.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODULE="$REPO_ROOT/java/policy-term-service"
# The port targets Java 17; prefer a local JDK 17 when present so the run matches the report.
if [ -d /usr/lib/jvm/java-17-openjdk-amd64 ]; then
  export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
fi
export JAVA_HOME="${JAVA_HOME:?set JAVA_HOME to a JDK 17 installation}"
echo "# Parity run $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "java: $("$JAVA_HOME/bin/java" -version 2>&1 | head -1)"
echo "golden: $(cat "$REPO_ROOT"/modernization/golden/*.csv | grep -c . ) lines in $(ls "$REPO_ROOT"/modernization/golden/*.csv | wc -l) files (headers included)"
echo "command: (cd java/policy-term-service && mvn -B test)"
echo "---"
(cd "$MODULE" && mvn -B test 2>&1 | grep -E "Tests run|BUILD|ERROR|FAIL" | grep -v "^\[INFO\] *$")
status=${PIPESTATUS[0]}
echo "---"
printf "%-32s %6s %6s %6s %6s\n" "rule (test class)" total pass fail error
for xml in "$MODULE"/target/surefire-reports/TEST-*.xml; do
  cls=$(basename "$xml" .xml | sed 's/TEST-com.example.policyterm.//')
  read -r t f e s <<<"$(python3 - "$xml" <<'PY'
import sys,xml.etree.ElementTree as ET
r=ET.parse(sys.argv[1]).getroot()
print(r.get('tests'),r.get('failures'),r.get('errors'),r.get('skipped'))
PY
)"
  printf "%-32s %6s %6s %6s %6s\n" "$cls" "$t" "$((t-f-e-s))" "$f" "$e"
done
exit "$status"
