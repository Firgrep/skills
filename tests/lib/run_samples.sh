#!/usr/bin/env bash
# Shared sample runner.
# Usage: run_samples.sh <validator.sh> <samples-dir> [default-extra-arg]
#
# valid/*.yaml must exit 0; invalid/*.yaml must exit 1 and print the text in
# their "# expect: <substring>" header. A sample may carry a "# spec: <path>"
# header (relative to <samples-dir>) naming the extra argument the validator
# takes; otherwise [default-extra-arg] is used, if given.
set -uo pipefail
validator="$1"; samples="$2"; default_extra="${3:-}"
pass=0; fail=0

report() { # ok|no label detail
  if [[ $1 == ok ]]; then pass=$((pass+1)); echo "PASS  $2"
  else fail=$((fail+1)); echo "FAIL  $2 -- $3"; fi
}

run() { # sample-file -> sets out, rc
  local extra="$default_extra" hdr
  hdr="$(sed -n 's/^# spec: //p' "$1" | head -n1)"
  [[ -n $hdr ]] && extra="${samples}/${hdr}"
  if [[ -n $extra ]]; then out="$(bash "$validator" "$1" "$extra" 2>&1)"; rc=$?
  else out="$(bash "$validator" "$1" 2>&1)"; rc=$?; fi
}

for f in "${samples}"/valid/*.yaml; do
  run "$f"
  [[ $rc -eq 0 ]] && report ok "valid/$(basename "$f")" || report no "valid/$(basename "$f")" "exit $rc: $out"
done

for f in "${samples}"/invalid/*.yaml; do
  name="invalid/$(basename "$f")"
  expect="$(sed -n '1s/^# expect: //p' "$f")"
  if [[ -z $expect ]]; then report no "$name" "missing '# expect:' header"; continue; fi
  run "$f"
  if [[ $rc -ne 1 ]]; then report no "$name" "expected exit 1, got $rc"
  elif [[ $out != *"$expect"* ]]; then report no "$name" "output lacks \"$expect\": $out"
  else report ok "$name"; fi
done

echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
