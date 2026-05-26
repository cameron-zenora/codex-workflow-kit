---
name: run-afk-loop
description: Operate an AFK implementation loop over a prepared issue backlog, selecting unblocked tasks, implementing one slice at a time, running feedback loops, and stopping for review or human decisions. Use when local issue files exist and the user asks an agent to keep working through them.
---

You operate the night-shift workflow. Only run AFK after humans have shaped the work into clear issues.

This skill does not remove review. It queues implementation, then hands work back for fresh-context review and human QA.

## Preconditions

- A PRD or destination document exists.
- Issues exist with ids, status, type, blockers, acceptance criteria, affected modules, and test plans.
- At least one issue is unblocked and marked `AFK`.
- The repo has feedback loops or the issue includes a plan to add them.

## Workflow

1. Load backlog
   - Read local issue files from `issues/` or the repo's issue convention.
   - Ignore completed issues.
   - Treat `blocked_by` as authoritative.

2. Select next work
   - Highest priority critical bug fixes.
   - Then development infrastructure needed by other issues.
   - Then vertical-slice traceable bullets.
   - Then polish or refactor issues.
   - Never pick a `HITL` issue unless the human has resolved the question.

3. Implement one issue
   - Use `implement-issue-tdd`.
   - Keep scope to the selected issue.
   - Run the issue's feedback loops.

4. Review handoff
   - After implementation, recommend or run `review-work` in a fresh context if the user asked for review.
   - Do not let the implementation context review itself as the only review step.

5. Update backlog
   - Mark completed issues appropriately.
   - Create follow-up issues for QA or review findings using `qa-to-issues`.
   - Stop when all AFK issues are complete or the next issue requires human input.

## Stop Conditions

Stop and report when:

- No unblocked `AFK` issues remain.
- Tests, type checks, lint, build, migrations, or app startup fail and cannot be resolved inside the selected issue.
- The selected issue requires product judgment, visual taste, security approval, data migration approval, or stakeholder input.
- The working tree contains unrelated user changes that make the issue unsafe to continue.

## Output Rules

- State which issue was selected and why.
- Report implementation status and feedback loops.
- List remaining unblocked issues.
- If no work remains, output: `NO_MORE_AFK_TASKS`.
