#!/usr/bin/env bash
# Validate a kantian-implementation IMPL yaml against the layout in SKILL.md and
# cross-check it against the SPEC it implements.
# Pure bash + POSIX awk: no yq/python needed. The checks live in validate_impl.awk.
#
# Usage: validate_impl.sh <IMPL_name.yaml> <SPEC_name.yaml>
# Exit:  0 valid, 1 validation errors (printed as file:line: message), 2 usage error
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -ne 2 ]]; then
  echo "usage: $(basename "$0") <impl.yaml> <spec.yaml>" >&2
  exit 2
fi
for f in "$1" "$2"; do
  if [[ ! -f "$f" ]]; then
    echo "error: file not found: $f" >&2
    exit 2
  fi
done

awk -v file="$1" -v specfile="$2" -v base="$(basename "$1")" \
  -f "${here}/validate_impl.awk" "$1"
