---
name: socratic-grill
description: Grill the user relentlessly about a plan, decision, or idea — Socratic in that questions, not answers, expose the unexamined assumptions and leave every decision yours. Use when the user wants to stress-test their thinking, or uses any 'grill', or 'spec' trigger phrases.
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it. Begin first with a short discussion to establish a baseline of _what_ business problem or case the requested feature is meant to solve and _what_ are the measurable outcomes. Keep in mind the business problem and outcomes for later.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. Present the frontier as a numbered list in your message, but invoke the question tool once per item, in order (i.e. the round is batched conceptually, but delivery is serial): number each question and give your recommended answer. However, _if you have no strong basis for a recommendation_, **always say so plainly** rather than guessing. Then wait for the user's answers before the next round. Use whatever structured multiple-choice input mechanism is available to present options, and ask _only one question at a time_.

Format a round like so:

```
**Q1** - **<round name>** **<question title>**: 

<question body, might be multiple paragraphs, but input should be multiple choices>

<your recommended answer>
```

Each round the user answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a _faster, lightweight, smaller model_ sub-agent to find it; the sub-agent may use tools and read the environment, but must never contact the user directly. Never ask the user for anything you could look up yourself. Never block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. The _decisions_ are the user's: put each to them and wait.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Do not act on it until the user confirms you have reached a shared understanding.

Finally, revisit the business problem and ask the user if the plan adequately responds to it. If it does, move over to measurable outcomes and discuss how these can be measured, what validation, strict typing or tests we can have to ensure the quality of the new feature.

Produce the specification as YAML, populated from the information gathered above. Write it to `.localdev/SPEC_{{ spec_name }}.yaml`, a working file scoped to the current branch, not a committed artifact. Ensure `.localdev/` is covered by `.gitignore`; add an entry if it isn't. If the file already exists (e.g. from a prior session), treat it as the current source of truth and update it in place rather than starting over.

A requirements entry is a ruleset: a cluster of one or more scenarios and one or more rules, where every rule in the cluster applies to every scenario in it. Give each ruleset a stable id (RULESET-1, RULESET-2, ...). If kantian-implementation or the user needs to reference a single rule within a multi-rule ruleset, address it as RULESET-<n>.<rule-index> (1-based index into that ruleset's rules list).

```yaml
spec_name: <feature-name>
status: DRAFT   # DRAFT | CONFIRMED | SUPERSEDED

business_case:
  summary: >-
    <One paragraph summarizing the feature and its business utility.>
  not_building: >-
    <OPTIONAL: what is explicitly NOT being built, if relevant.>
  outcomes:
    - id: OUT-1
      description: "<short non-technical description>"
      metric: <what is measured>
      validation: <how it's checked, e.g. analytics_event, load_test, type_check>
      # add OUT-2, OUT-3... one per falsifiable outcome. Add an empty line between outcome objects.

decisions:
  accepted:
    - id: DEC-1
      summary: "<short or long description>"
      facts: []   # OPTIONAL: self-standing facts, e.g. paths, e.g. ["uploads/avatars/"]
      # add DEC-2, DEC-3... Add an empty line between accepted decisions.
  rejected:
    - id: DEC-R1
      summary: "<significant alternative that was rejected>"
      reason: "<succinct explanation why>"
      facts: []   # OPTIONAL
      # add DEC-R2, DEC-R3... Add an empty line between rejected decisions.

requirements:
  - id: RULESET-1
    scenarios:
      - "<user or event scenario>"
      # multiple scenarios if the same rules apply to all of them
    rules:
      - "<rule that must hold given the scenario(s) above>"
      # multiple rules if this scenario-cluster implies more than one rule;
      # reference an individual one later as RULESET-1.1, RULESET-1.2, etc.
    # add RULESET-2, RULESET-3... Add an empty line between rulesets.
```

After writing or updating the file, validate it:

```sh
bash ${CLAUDE_SKILL_DIR}/scripts/validate_spec.sh .localdev/SPEC_{{ spec_name }}.yaml
```

The script prints `file:line: message` for each problem and exits non-zero. Fix every reported error in the file and re-run until it exits 0. Never tell the user the spec is ready before it passes.

This document defines what and why. Sequencing, estimation, and task breakdown are out of scope here.