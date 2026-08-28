---
name: kantian-implementation
description: Implement a feature from a settled spec, requirement by requirement, verifying each is implemented, tested, and enforced. Use after socratic-grill has produced a SPEC file, or when the user says 'build the spec' / 'implement the spec'.
---

Read `.dev/SPEC_{{ spec_name }}.md`. This is the settled source of truth for *what* and *why*. Never re-litigate Decisions or Business Case; if something there seems wrong, always flag it to the user rather than silently overriding it.

Never edit the `.dev/SPEC_{{ spec_name }}.md`; your job is to implement an existing spec, never to change one. The specs are immutable. If facts surface during investigation or implementation that contest or contradict what is written in the spec, flag it to the user and ask for clarification. Put this clarification as an amendment in the implementation.

If `.dev/SPEC_{{ spec_name }}.md` does not exist, stop and tell the user to run `socratic-grill` first — there is no settled spec to implement against.

If `.dev/IMPL_{{ spec_name }}.md` does not exist, create it from the spec's Requirements table. If it already exists, resume from it rather than starting over.

You now formulate an implementation report of how to implement the spec. Always dispatch one or several _faster, lightweight, smaller model_ sub-agents to explore and find facts about the codebase and any tools. Work the report **one task at a time**, according to Rules found in the Requirements table in order unless a Requirement depends on scaffolding another one produces (e.g. shared types, a migration) — in that case, do the dependency first and note the reorder in the report.

Each Task must minimally adhere to one Requirement and should:
1. **Implement** the behavior the Rule(s) describes.
2. **Verify** it: write a test asserting each Scenario (Given/When/Then) tied to
   that Rule(s), then *run* the test — don't mark Tested until it actually passes.
   Dispatch a lightweight sub-agent to run the test suite and report results;
   don't assume a pass. Alternatively, check whether the guarantee is structural (types, validation,
   constraints) and not just behavior that happens to pass today. If it's only
   incidentally true, say so and either strengthen it or flag it as an accepted
   risk — never silently mark Enforced on a hope.

If implementing a Requirement surfaces a gap, ambiguity, or conflict the spec didn't anticipate, never resolve it by assumption. Stop and put it to the user as a new question, the same way socratic-grill surfaces decisions. Log the resolution as an amendment to the requirement.

`.dev/IMPL_{{ spec_name }}.md` is a working file, git-ignored, scoped to the branch — same lifecycle as the SPEC. It is not a committed artifact.

Check off a task's box only once it has an [IMPL] and a [VERI] entry showing the test was actually run and passed — not once code is written, and not once a test is merely present.

Amendments are recorded only in the IMPL report; the SPEC remains the frozen record of original intent even where implementation revealed it to be wrong.

```md

# {{ spec_name }} Implementation

<!-- Compile a list of actionable tasks reasoned out from the spec alone, before any code is written or run.
     This is a prediction, not yet a fact — nothing here has been observed to be true. 
     
It must be in the following form:

- [ ] _Task name_. Short plan description and prediction of work.
     - [RULE] {{ the rule this implements}}

A task may include multiple rules.

As you implement, fill in a posteriori points only after empirical verification —
never from intention or memory of what should have happened. Altered shape:
     
- [ ] _Task name_. Short plan description and prediction of work.
     - [RULE] {{ the rule this implements}}
          - [AMND] {{ OPTIONAL: the amendmend due to factual inconsistencies }}
     - [IMPL] {{ implemented in (file/location) }}
          - [VERI] {{ tested by, enforced by, etc.}}

Omit [AMND] where the rule needed no correction.
A task may include multiple rules, and a rule may include multiple amendments. 
A task may also include multiple implementations, and an implementation may include
multiple modes of verification (tests, integration tests, etc.).

-->

```

When every task's checkbox is checked, report a summary to the user. Ask for confirmation before considering the feature done.