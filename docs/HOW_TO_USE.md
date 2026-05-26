# How To Use The Workflow

This kit is for turning fuzzy work into small, reviewable agent tasks.

The loop is:

```text
grill-me
-> write-prd
-> break-prd-to-issues
-> implement one issue
-> review in fresh context
-> fix review findings
-> review again
-> manual QA
-> mark done
-> next issue
```

## 1. Start With An Idea

Use this when you have a rough feature, bug, refactor, client request, or product thought.

In Codex GUI:

```text
Use grill-me.

Here is the idea:
<paste the idea>

Ask me one question at a time. For each question, give your recommended answer. Continue until we have shared understanding.
```

Use this phase for decisions and alignment. Do not implement yet.

## 2. Write The PRD

After the grill session:

```text
Use write-prd.

Turn the grill-me conversation into a PRD.
Save it under docs/prds/YYYY-MM-DD-short-feature-name.md.
```

The PRD is the destination document. It should explain the problem, goals, non-goals, user stories, implementation notes, testing strategy, risks, and definition of done.

## 3. Split The PRD Into Kanban Issues

```text
Use break-prd-to-issues on docs/prds/YYYY-MM-DD-short-feature-name.md.

Create local issue files in issues/.
Prefer vertical slices over horizontal phases.
Mark each issue AFK or HITL.
Include blockers, acceptance criteria, affected modules, and test plan.
```

This creates the Kanban board. Each Markdown issue is one card.

## 4. Read The Board

From a terminal in the project:

```bash
aiwf status
aiwf next
aiwf afk
```

Or inspect the `issues/` folder manually.

Issue meanings:

- `AFK`: agent can implement from written context.
- `HITL`: human decision needed.
- `blocked_by`: issue ids that must be done first.
- `status: todo`: not started.
- `status: review`: implemented but not accepted.
- `status: done`: review and QA passed.

## 5. Run AFK Overnight

Use this only after the board has clear `AFK` issues with acceptance criteria and test plans.

```bash
aiwf afk
```

`aiwf afk` repeatedly picks the next unblocked `todo` + `AFK` issue, launches Codex with `run-afk-loop` and `implement-issue-tdd`, then refreshes the board before selecting the next issue.

On Windows, the helper defaults Codex to `danger-full-access` because the Codex CLI Windows sandbox can fail before commands start with `CreateProcessAsUserW failed: 5`. On macOS/Linux, the helper defaults to `workspace-write`.

Override the sandbox if needed:

```powershell
$env:CODEX_FLOW_SANDBOX = "workspace-write"
aiwf afk
```

Valid values are `read-only`, `workspace-write`, and `danger-full-access`.

It stops when:

- No unblocked `AFK` issues remain.
- The next ready issue is `HITL`.
- Codex exits with a failure.
- An issue stays `todo` after Codex returns.

Before leaving it overnight, make sure review issues that should unblock later work are either accepted and marked `done`, or intentionally left in `review` to keep dependent work blocked.

If you want a deeper implementation-only night run, let AFK treat `review` blockers as complete:

```powershell
aiwf afk --through-review
```

Use this when you plan to review the full stack later. It still skips issues whose own status is `review` or `done`, and it still stops at `HITL` issues.

## 6. Resolve HITL Issues

When an issue is `HITL`, do not let the agent guess.

```text
Resolve this HITL issue:
issues/003-example.md

Ask me the decisions one at a time. For each decision, give your recommended default and tradeoff. Once I approve, update the issue with the decision table and set status to done.
```

## 7. Implement One Issue

Pick one unblocked AFK issue.

```text
Use implement-issue-tdd on issues/001-example.md.

Implement only this issue.
Read the linked PRD and relevant code first.
Use TDD where practical.
Run the issue test plan and relevant checks.
Do not expand into other issues.
Keep the issue in review when implementation is complete.
```

## 8. Review In A Fresh Context

Use a new Codex thread/session.

```text
Use review-work.

Review the current uncommitted changes against:
issues/001-example.md

Do not modify files.
Inspect the issue, linked PRD, git status, and git diff.
Findings first, ordered by severity.
Do not paste the full diff.
```

Severity rule:

- `P0` or `P1`: must fix.
- `P2`: usually fix before done unless explicitly accepted.
- `P3`: can become a follow-up issue.

## 9. Fix Findings

Send the review findings back to the implementation thread:

```text
Use implement-issue-tdd.

Fix only these review findings for:
issues/001-example.md

<paste findings>

Do not expand scope.
Run relevant tests and checks.
Keep the issue in review.
```

Then review again in a fresh context.

Repeat:

```text
implement fix
-> review
-> implement fix
-> review
```

Stop when there are no blocking findings.

## 10. Manual QA

For user-facing work:

```text
Use the browser to QA:
issues/001-example.md

Check the acceptance criteria and likely user paths.
Capture any failures as follow-up issues.
```

Manual QA is where human taste, UX, product fit, and “does this feel right?” come back into the process.

## 11. Mark Done

When review and QA pass:

```text
Update issues/001-example.md:
- set status to done
- add review notes
- add QA notes
- add checks run
```

Then pick the next unblocked issue.

## 12. Continue The Board

```bash
aiwf status
aiwf next
aiwf afk
```

If the next item is AFK, implement it.

If the next item is HITL, resolve decisions.

If everything is blocked, resolve the blocker.

## Good Defaults

Use Codex GUI for:

- grill-me
- PRD writing
- issue splitting
- implementation
- review
- HITL decisions
- browser QA

Use terminal for:

- setup
- `aiwf status`
- `aiwf next`
- `aiwf afk`
- package tests and checks

The GUI is the cockpit. The terminal is the dashboard.
