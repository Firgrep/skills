#!/usr/bin/env bash
# Run validate_spec.sh against tests/samples/{valid,invalid}.
# valid/*.yaml must exit 0; invalid/*.yaml must exit 1 and print the text in
# their first-line "# expect: <substring>" header.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
validator="${here}/../../.agents/skills/socratic-grill/scripts/validate_spec.sh"
pass=0; fail=0

report() { # ok? label detail
  if [[ $1 == ok ]]; then pass=$((pass+1)); echo "PASS  $2"
  else fail=$((fail+1)); echo "FAIL  $2 -- $3"; fi
}

for f in "${here}"/samples/valid/*.yaml; do
  out="$(bash "$validator" "$f" 2>&1)"; rc=$?
  [[ $rc -eq 0 ]] && report ok "valid/$(basename "$f")" || report no "valid/$(basename "$f")" "exit $rc: $out"
done

for f in "${here}"/samples/invalid/*.yaml; do
  name="invalid/$(basename "$f")"
  expect="$(sed -n '1s/^# expect: //p' "$f")"
  if [[ -z $expect ]]; then report no "$name" "missing '# expect:' header"; continue; fi
  out="$(bash "$validator" "$f" 2>&1)"; rc=$?
  if [[ $rc -ne 1 ]]; then report no "$name" "expected exit 1, got $rc"
  elif [[ $out != *"$expect"* ]]; then report no "$name" "output lacks \"$expect\": $out"
  else report ok "$name"; fi
done

echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
