---
name: qa-to-issues
description: Turn manual QA observations, screenshots, review findings, or stakeholder feedback into follow-up issue files that can re-enter the implementation backlog. Use after QA finds bugs, polish work, or missing behavior.
---

You convert feedback into actionable backlog items. QA is where human taste and product judgment return to the system.

Do not let QA feedback remain as loose chat memory. Capture it as issues with acceptance criteria, blockers, and test plans.

## Workflow

1. Gather QA input
   - Use user notes, screenshots, browser observations, review findings, logs, or failed test output.
   - If a codebase exists, inspect enough context to identify likely affected modules.

2. Classify each observation
   - `bug`: behavior is wrong or broken.
   - `gap`: required behavior is missing.
   - `polish`: behavior works but needs taste, copy, UX, or visual refinement.
   - `risk`: something may fail under edge cases, load, data shape, permissions, or deployment.
   - `question`: human decision needed before work can continue.

3. Create issues
   - Reuse the `issues/NN-short-title.md` convention unless the repo has another issue system.
   - Link each issue to the source PRD, original issue, or review note when available.
   - Mark issues as `AFK` only when they are specific enough to implement without new judgment.
   - Mark issues as `HITL` when more human decision or visual review is required.

4. Preserve dependency graph
   - Add blockers when a fix depends on another issue.
   - Keep urgent regressions unblocked when possible.
   - Avoid bundling unrelated QA observations into one issue.

## Follow-Up Issue Template

```markdown
---
id: ISSUE-<next>
title: <Short Title>
status: todo
type: AFK
category: bug
blocked_by: []
blocks: []
source: <qa-note-or-review-or-original-issue>
---

# ISSUE-<next>: <Short Title>

## Observation

<What was seen during QA or review.>

## Expected Behavior

<What should happen instead.>

## Acceptance Criteria

- <Concrete pass condition.>

## Affected Modules

- `<path-or-module>`: <likely area to inspect or change.>

## Test Plan

- <Automated or manual check that proves the fix.>
```

## Output Rules

- Summarize created issues by priority and dependency order.
- Name which issue should be implemented next.
- If the feedback is too vague, ask one targeted question with a recommended answer.
