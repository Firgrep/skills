# Run all skill tests
test:
    #!/usr/bin/env bash
    set -euo pipefail
    for t in tests/*/run.sh; do
        echo "==> $t"
        bash "$t"
    done

