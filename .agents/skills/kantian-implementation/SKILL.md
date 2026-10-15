---
name: kantian-implementation
description: Implement a feature from a settled spec, requirement by requirement, verifying each is implemented, tested, and enforced. Use after socratic-grill has produced a SPEC file, or when the user says 'build the spec' / 'implement the spec'.
---

Read `.localdev/SPEC_{{ spec_name }}.yaml`. This is the settled source of truth for *what* and *why*. Never re-litigate Decisions or Business Case; if something there seems wrong, always flag it to the user rather than silently overriding it.

Never edit the `.localdev/SPEC_{{ spec_name }}.yaml`; your job is to implement an existing spec, never to change one. The specs are immutable. If facts surface during investigation or implementation that contest or contradict what is written in the spec, flag it to the user and ask for clarification. Put this clarification as an amendment in the implementation.

If `.localdev/SPEC_{{ spec_name }}.yaml` does not exist, stop and tell the user to run `socratic-grill` first — there is no settled spec to implement against.

If `.localdev/IMPL_{{ spec_name }}.yaml` does not exist, create it from the spec's Requirements table. If it already exists, resume from it rather than starting over.

You now formulate an implementation report of how to implement the spec. Always dispatch one or several _faster, lightweight, smaller model_ sub-agents to explore and find facts about the codebase and any tools. Work the report **one task at a time**, in the order the spec's `requirements` list them, unless a requirement depends on scaffolding another one produces (e.g. shared types, a migration), in that case, do the dependency first and note the reorder as `context` in the implementation file.

Each task must minimally cover one ruleset (or a specific rule within one, e.g. `RULESET-2.1`) and should:
1. **Implement** the behavior the referenced rule(s) describe.
2. **Verify** it: write a test asserting each scenario (Given/When/Then) tied to that ruleset, then *run* it — don't set `status: VERIFIED` until it actually passes. Dispatch a lightweight sub-agent to run the test suite and report results; don't assume a pass. Alternatively, check whether the guarantee is structural (types, validation, constraints) and not just behavior that happens to pass today. If it's only incidentally true, say so and either strengthen it or flag it as an accepted risk in a `verification` entry — never silently mark `VERIFIED` on a hope.

If implementing a task surfaces a gap, ambiguity, or conflict the spec didn't anticipate, never resolve it by assumption. Stop and put it to the user as a new question, the same way `socratic-grill` surfaces decisions. Log the resolution as an entry in that task's `amendments`.

`.localdev/IMPL_{{ spec_name }}.yaml` is a working file, git-ignored, scoped to the branch — same lifecycle as the spec. It is not a committed artifact.

Set a task's `status` to `VERIFIED` only once `impl` has at least one entry **and** `verification` has at least one entry with `result: pass` — never on the basis of code being written, or a test merely existing.

Amendments are recorded only in the IMPL file; the spec remains the frozen record of original intent even where implementation revealed it to be wrong.

Template (one task shape; `impl`, `verification`, and `amendments` start empty and are filled in only after empirical work — never from intention or memory of what should have happened):

```yaml
impl_name: IMPL_<feature-name>

context: ""   # OPTIONAL: brief note only, e.g. an ordering change and why. Never lengthy prose.

tasks:
  - id: TASK-1
    name: "<short title>"
    plan: "<short plan description and prediction of work>"
    rulesets: [RULESET-1]   # ids from the spec; use RULESET-2.1 to target a single rule in a multi-rule cluster
    status: PENDING          # PENDING | IMPLEMENTED | VERIFIED
    impl: []
    verification: []
    amendments: []
  # add TASK-2, TASK-3... one per ruleset, or split further if a ruleset needs multiple tasks. Add an empty line between tasks.
```

Populated shape, after work (a task may have multiple `impl` locations and multiple `verification` entries — unit, integration, e2e, type-check, etc. — and a task may cover multiple rulesets):

```yaml
impl_name: IMPL_user-avatar-upload

context: ""

tasks:
  - id: TASK-1
    name: "Reject oversized uploads"
    plan: "Add size check in upload handler, return 413 with error body"
    rulesets: [RULESET-1]
    status: VERIFIED
    impl:
      - location: "src/upload/validate.ts"
    verification:
      - method: unit_test
        location: "tests/upload/validate.test.ts"
        result: pass
    amendments:
      - note: "Spec assumed client sends MIME type; observed some clients omit it — added sniffing fallback."

  - id: TASK-2
    name: "Clamp out-of-bounds crop coordinates"
    plan: "Clamp crop box to image bounds; log a telemetry warning when clamped"
    rulesets: [RULESET-2]
    status: IMPLEMENTED
    impl:
      - location: "src/upload/crop.ts"
    verification: []
    amendments: []
```

Every time you create or update the IMPL file, validate it against its spec:

```sh
bash ${CLAUDE_SKILL_DIR}/scripts/validate_impl.sh .localdev/IMPL_{{ spec_name }}.yaml .localdev/SPEC_{{ spec_name }}.yaml
```

The script prints `file:line: message` for each problem and exits non-zero. Besides the layout, it enforces the `VERIFIED`/`IMPLEMENTED` evidence rules above and that every spec ruleset (or every rule within it) is covered by a task. Fix every reported error and re-run until it exits 0, and never set a task to `VERIFIED` on the strength of a file that does not validate.

When every task's `status` is `VERIFIED`, report a summary to the user. Ask for confirmation before considering the feature done.