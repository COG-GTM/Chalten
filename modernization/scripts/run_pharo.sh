#!/usr/bin/env bash
# Deterministic, re-runnable headless Pharo driver for the modernization demo.
#
#   modernization/scripts/run_pharo.sh bootstrap   # download Pharo 12, clone Buoy v8 + Aconcagua v11, load Chalten
#   modernization/scripts/run_pharo.sh tests       # run the Smalltalk SUnit suites headlessly
#   modernization/scripts/run_pharo.sh golden      # regenerate modernization/golden/*.csv from the Smalltalk
#   modernization/scripts/run_pharo.sh all         # bootstrap + tests + golden
#
# Everything lives under modernization/.pharo (git-ignored). Re-running 'bootstrap' rebuilds the image
# from the current working tree, so edits to source/ are picked up.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="$REPO_ROOT/modernization/scripts"
WORK_DIR="${PHARO_WORK_DIR:-$REPO_ROOT/modernization/.pharo}"
DEPS_DIR="$WORK_DIR/deps"
PHARO_URL="${PHARO_URL:-https://get.pharo.org/64/120+vm}"
export CHALTEN_DEPS_DIR="$DEPS_DIR"
export CHALTEN_SOURCE_DIR="$REPO_ROOT/source"
export CHALTEN_GOLDEN_DIR="$REPO_ROOT/modernization/golden"

bootstrap() {
  mkdir -p "$WORK_DIR" "$DEPS_DIR"
  if [ ! -x "$WORK_DIR/pharo" ]; then
    echo ">> downloading Pharo from $PHARO_URL"
    (cd "$WORK_DIR" && curl -fsSL "$PHARO_URL" | bash)
  fi
  [ -d "$DEPS_DIR/Buoy" ] || git clone -q --depth 1 --branch v8 https://github.com/ba-st/Buoy.git "$DEPS_DIR/Buoy"
  [ -d "$DEPS_DIR/Aconcagua" ] || git clone -q --depth 1 --branch v11 https://github.com/ba-st/Aconcagua.git "$DEPS_DIR/Aconcagua"
  cp "$WORK_DIR/Pharo.image" "$WORK_DIR/Chalten.image"
  cp "$WORK_DIR/Pharo.changes" "$WORK_DIR/Chalten.changes"
  echo ">> loading Chalten + PersonalLines-Rating from $CHALTEN_SOURCE_DIR"
  local load_log="$WORK_DIR/load.log"
  (cd "$WORK_DIR" && ./pharo Chalten.image st "$SCRIPT_DIR/load_chalten.st" > "$load_log" 2>&1) || true
  grep -E "Loaded -> |CHALTEN LOADED" "$load_log" || true
  if ! grep -q "CHALTEN LOADED" "$load_log"; then
    echo ">> bootstrap FAILED: the loader did not print CHALTEN LOADED (full log: $load_log)" >&2
    grep -iE "error|fail|not understood" "$load_log" | head -20 >&2 || true
    return 1
  fi
}

versions() {
  (cd "$WORK_DIR" && ./pharo Chalten.image eval "SystemVersion current printString, ' / VM ', Smalltalk vm version")
}

tests() {
  echo ">> $(versions)"
  (cd "$WORK_DIR" && ./pharo Chalten.image st "$SCRIPT_DIR/run_tests.st" 2>&1 | grep -E "Tests: |FAILURE|ERROR|Error" )
}

golden() {
  mkdir -p "$CHALTEN_GOLDEN_DIR"
  echo ">> $(versions)"
  {
    echo "# Golden data generation run"
    echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "command: modernization/scripts/run_pharo.sh golden  (runs: ./pharo Chalten.image st modernization/scripts/generate_golden.st)"
    echo "pharo: $(versions)"
    echo "chalten commit: $(git -C "$REPO_ROOT" rev-parse --short HEAD)"
    echo "---"
    (cd "$WORK_DIR" && ./pharo Chalten.image st "$SCRIPT_DIR/generate_golden.st" 2>&1 | grep -vE "^\s*$")
  } | tee "$CHALTEN_GOLDEN_DIR/GENERATION_LOG.txt"
}

case "${1:-all}" in
  bootstrap) bootstrap ;;
  tests) tests ;;
  golden) golden ;;
  versions) versions ;;
  all) bootstrap; tests; golden ;;
  *) echo "usage: $0 {bootstrap|tests|golden|versions|all}"; exit 2 ;;
esac
