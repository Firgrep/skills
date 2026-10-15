#!/usr/bin/env bash
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${here}/../lib/harness.sh"

suite_begin socratic-grill
run_samples "${here}/../../.agents/skills/socratic-grill/scripts/validate_spec.sh" "${here}/samples"
suite_end
