#!/usr/bin/env bash
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${here}/../lib/harness.sh"

suite_begin struct-spec
run_samples "${here}/../../.agents/skills/struct-spec/scripts/validate_spec.sh" "${here}/samples"
suite_end
