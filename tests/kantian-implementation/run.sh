#!/usr/bin/env bash
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${here}/../lib/harness.sh"
validator="${here}/../../.agents/skills/kantian-implementation/scripts/validate_impl.sh"
spec="${here}/samples/specs/SPEC_avatar.yaml"

usage() { # label expected-exit args...
  local label="$1" want="$2" got; shift 2
  bash "$validator" "$@" >/dev/null 2>&1; got=$?
  if [[ $got -eq $want ]]; then check_pass "usage/$label"
  else check_fail "usage/$label" "expected exit $want, got $got"; fi
}

suite_begin kantian-implementation
usage no-args 2
usage one-arg 2 "${here}/samples/valid/full.yaml"
usage missing-impl 2 "${here}/samples/valid/nope.yaml" "$spec"
usage missing-spec 2 "${here}/samples/valid/full.yaml" "${here}/samples/specs/nope.yaml"
run_samples "$validator" "${here}/samples" "$spec"
suite_end
