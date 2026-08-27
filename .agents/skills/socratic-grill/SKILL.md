---
name: socratic-grill
description: Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill', or 'spec' trigger phrases.
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

Finally, revisit the business problem and ask the user if the plan adequately responds to it. If it does, move over to measureable outcomes and discuss how these can be measured, what validation, strict typing or tests we can have to ensure the quality of the new feature. 

Produce the specification using the following template, populated from the information gathered above. Write it to `.dev/SPEC_{{ spec_name }}.md` — a working file scoped to the current branch, not a committed artifact. Ensure `.dev/` is covered by `.gitignore`; add an entry if it isn't. If the file already exists (e.g. from a prior session), treat it as the current source of truth and update it in place rather than starting over.

```md
# <spec_name>

## 1. Business Case

### 1.1 Summary

<!-- One paragraph summarizing the feature and its business utility.
     Include what is NOT being built if necessary. -->

### 1.2 Falsifiable Outcomes

<!--
- Bullet points with short non-technical descriptions
    - Nested sub-points indicate technical items
-->

## 2. Decisions

### 2.1 Accepted Decisions

<!--
- Bullet points with short or long descriptions. (Include facts in self-standing parenthesis with details if necessary, e.g. `paths/to/life`).
-->

### 2.2 Rejected Decisions

<!--
- Bullet points with descriptions of significant alternatives rejected with a succinct explanation why. (Include facts in self-standing parenthesis with details if necessary, e.g. `paths/to/life`.)
-->

## 3. Requirements

<!--
We emulate Gherkin's Rule keyword (from Cucumber), where one Rule is illustrated by multiple Example/Scenario. Here Rules designate distilled functional behavior that work as checkable acceptance criterion.

Create a table where one column defines user or event scenario, another column defining rule(s) that must necessarily follow from that/those scenarios.

Leave cells with `"` to emulate spans, e.g. if a rule accounts for two scenarios, or one scenario accounts for two rules.
-->

This document defines what and why. Sequencing, estimation, and task breakdown are out of scope here.
```
