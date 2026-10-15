# Test harness, sourced by each tests/<skill>/run.sh.
#
#   suite_begin <name>
#   check_pass <label> / check_fail <label> <detail>
#   run_samples <validator.sh> <samples-dir> [default-extra-arg]
#   suite_end            prints the summary; returns non-zero if anything failed
#
# On a terminal, prints one character per test ("." pass, "F" fail) as progress
# and replaces that line with the summary at the end; failures are listed above
# the summary. Without a terminal (pipes, CI) only failures and the summary are
# printed. Set VERBOSE=1 for one line per test instead.

progress() { [[ -t 1 && -z ${VERBOSE:-} ]] && printf '%s' "$1"; return 0; }

suite_begin() { suite="$1"; passed=0; failed=0; failures=(); }

check_pass() {
  passed=$((passed + 1))
  if [[ -n ${VERBOSE:-} ]]; then echo "PASS  $1"; else progress .; fi
}

check_fail() {
  failed=$((failed + 1))
  failures+=("FAIL  $1 -- $2")
  if [[ -n ${VERBOSE:-} ]]; then echo "FAIL  $1 -- $2"; else progress F; fi
}

suite_end() {
  [[ -t 1 && -z ${VERBOSE:-} ]] && printf '\r\033[K'
  if [[ $failed -gt 0 && -z ${VERBOSE:-} ]]; then printf '%s\n' "${failures[@]}"; fi
  echo "${suite}: ${passed} passed, ${failed} failed"
  [[ $failed -eq 0 ]]
}

# valid/*.yaml must exit 0; invalid/*.yaml must exit 1 and print the text in
# their "# expect: <substring>" header. A sample may carry a "# spec: <path>"
# header (relative to <samples-dir>) naming the extra argument the validator
# takes; otherwise [default-extra-arg] is used, if given.
run_samples() {
  local validator="$1" samples="$2" default_extra="${3:-}" f name expect out rc

  run_one() { # sample-file -> sets out, rc
    local extra="$default_extra" hdr
    hdr="$(sed -n 's/^# spec: //p' "$1" | head -n1)"
    [[ -n $hdr ]] && extra="${samples}/${hdr}"
    if [[ -n $extra ]]; then out="$(bash "$validator" "$1" "$extra" 2>&1)"; rc=$?
    else out="$(bash "$validator" "$1" 2>&1)"; rc=$?; fi
  }

  for f in "${samples}"/valid/*.yaml; do
    name="valid/$(basename "$f")"
    run_one "$f"
    if [[ $rc -eq 0 ]]; then check_pass "$name"; else check_fail "$name" "exit $rc: $out"; fi
  done

  for f in "${samples}"/invalid/*.yaml; do
    name="invalid/$(basename "$f")"
    expect="$(sed -n '1s/^# expect: //p' "$f")"
    if [[ -z $expect ]]; then check_fail "$name" "missing '# expect:' header"; continue; fi
    run_one "$f"
    if [[ $rc -ne 1 ]]; then check_fail "$name" "expected exit 1, got $rc"
    elif [[ $out != *"$expect"* ]]; then check_fail "$name" "output lacks \"$expect\": $out"
    else check_pass "$name"; fi
  done
}
