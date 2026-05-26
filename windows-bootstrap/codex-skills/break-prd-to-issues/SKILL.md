---
name: break-prd-to-issues
description: Convert a PRD into independently grabbable vertical-slice issue files with blockers, acceptance criteria, affected modules, and test plans. Use when a PRD exists and the next step is planning implementation work for one or more agents.
---

You turn a PRD destination document into a Kanban-style backlog. Your job is to design the journey.

Prefer vertical slices, also called traceable bullets: each issue should cross the layers needed to produce observable behavior and fast feedback. Avoid horizontal issues like "create all database tables" or "build all UI" unless they are truly standalone infrastructure.

## Workflow

1. Locate the PRD
   - Use the PRD path the user gives you.
   - If no path is provided, search likely locations such as `docs/prds`, `docs`, `.github/issues`, `issues`, and the current workspace.
   - If multiple PRDs are plausible, choose the most recent active one and say which one you used.

2. Explore the codebase enough to understand shape
   - Identify relevant modules, services, routes, UI surfaces, jobs, data models, APIs, and test patterns.
   - Look for existing issue or planning conventions.
   - Keep exploration focused.

3. Draft the issue graph
   - Create small, independently grabbable issues.
   - Prefer one issue per observable vertical slice.
   - Mark blockers explicitly by issue id.
   - Mark type as `AFK` when an implementation agent can do it from written context.
   - Mark type as `HITL` when product judgment, visual taste, stakeholder input, or ambiguous tradeoffs remain.
   - Include at least one early traceable bullet that proves the whole path works.

4. Review the graph before writing files
   - Check for horizontal slices.
   - Check that dependencies form a directed acyclic graph.
   - Check that every issue has acceptance criteria and a test plan.
   - If a slice is too horizontal, rewrite it before continuing.

5. Write issue files
   - Use the repo's existing convention when one exists.
   - Otherwise create local Markdown files under `issues/`.
   - Name files `NN-short-title.md`.
   - Use stable ids like `ISSUE-001`.

## Issue Template

```markdown
---
id: ISSUE-001
title: <Short Title>
status: todo
type: AFK
blocked_by: []
blocks: []
prd: <relative/path/to/prd.md>
---

# ISSUE-001: <Short Title>

## Intent

<What user-visible or system-visible outcome this slice creates.>

## Vertical Slice

<Which layers this touches and what observable feedback proves the slice works.>

## Acceptance Criteria

- <Concrete behavior that must be true.>
- <Concrete behavior that must be true.>

## Affected Modules

- `<path-or-module>`: <expected change or boundary>.

## Test Plan

- <Automated test, type check, lint, build, or manual QA step.>

## Notes

- <Constraints, non-goals, risks, or useful context.>
```

## Quality Bar

- The first implementation issue should usually be a thin end-to-end slice, not a foundation-only task.
- Every AFK issue must be implementable without more product conversation.
- Every HITL issue must say what human decision is needed.
- Prefer fewer, clearer issues over many tiny file-level chores.
- Leave follow-up and polish work as separate issues only when it can be reviewed independently.

## Output Rules

- After creating issues, summarize the graph in dependency order.
- Name which issues are ready to implement now.
- Recommend `implement-issue-tdd` for the first unblocked AFK issue.
