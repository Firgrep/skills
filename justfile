# Run all skill tests (VERBOSE=1 for one line per test)
test:
    #!/usr/bin/env bash
    rc=0
    for t in tests/*/run.sh; do
        bash "$t" || rc=1
    done
    exit $rc
