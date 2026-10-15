#!/usr/bin/env bash
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${here}/../lib/run_samples.sh" \
  "${here}/../../.agents/skills/socratic-grill/scripts/validate_spec.sh" \
  "${here}/samples"
