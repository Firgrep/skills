#!/usr/bin/env bash
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
validator="${here}/../../.agents/skills/kantian-implementation/scripts/validate_impl.sh"
rc=0

usage() { # label expected-exit args...
  local label="$1" want="$2"; shift 2
  bash "$validator" "$@" >/dev/null 2>&1; local got=$?
  if [[ $got -eq $want ]]; then echo "PASS  usage/$label"
  else echo "FAIL  usage/$label -- expected exit $want, got $got"; rc=1; fi
}
usage no-args 2
usage one-arg 2 "${here}/samples/valid/full.yaml"
usage missing-impl 2 "${here}/samples/valid/nope.yaml" "${here}/samples/specs/SPEC_avatar.yaml"
usage missing-spec 2 "${here}/samples/valid/full.yaml" "${here}/samples/specs/nope.yaml"

"${here}/../lib/run_samples.sh" "$validator" "${here}/samples" "${here}/samples/specs/SPEC_avatar.yaml" || rc=1
exit $rc
