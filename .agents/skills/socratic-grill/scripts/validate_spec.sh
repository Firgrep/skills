#!/usr/bin/env bash
# Validate a socratic-grill SPEC yaml against the layout in SKILL.md.
# Pure bash + POSIX awk: no yq/python needed. The checks live in validate_spec.awk.
#
# Usage: validate_spec.sh <path/to/SPEC_name.yaml>
# Exit:  0 valid, 1 validation errors (printed as file:line: message), 2 usage error
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -ne 1 ]]; then
  echo "usage: $(basename "$0") <spec.yaml>" >&2
  exit 2
fi
if [[ ! -f "$1" ]]; then
  echo "error: file not found: $1" >&2
  exit 2
fi

awk -v file="$1" -v base="$(basename "$1")" \
  -f "${here}/validate_spec.awk" "$1"
