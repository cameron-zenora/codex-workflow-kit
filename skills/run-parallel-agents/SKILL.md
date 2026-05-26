---
name: run-parallel-agents
description: Plan and operate multiple implementation agents across independent issue branches or worktrees, then review and merge their work safely. Use when a prepared issue backlog has multiple unblocked AFK issues that can be worked in parallel.
---

You coordinate parallel implementation. Parallelism is only safe after the backlog has explicit blockers and small vertical slices.

Do not parallelize vague issues, HITL issues, broad refactors, or multiple tasks likely to edit the same fragile module.

## Preconditions

- Local or GitHub issues exist with ids, status, type, blockers, acceptance criteria, affected modules, and test plans.
- At least two unblocked `AFK` issues exist.
- The repo can run feedback loops locally.
- The working tree is clean enough to create branches or worktrees safely.

## Workflow

1. Build the dependency graph
   - Read all open issues.
   - Exclude blocked, done, review, and HITL issues.
   - Group ready issues into a parallel batch.
   - Avoid batching issues that touch the same high-risk files unless conflicts are unlikely.

2. Create isolated work areas
   - Prefer one branch or worktree per issue.
   - Name branches with the issue id and short title.
   - Keep one issue per implementation context.

3. Implement in parallel
   - Each agent uses `implement-issue-tdd`.
   - Each agent runs the issue's feedback loops.
   - Each agent produces a small summary and, when appropriate, one commit.

4. Review independently
   - Review each branch or diff with `review-work` in a fresh context.
   - Push coding standards into the reviewer prompt.
   - Convert review findings into fixes or follow-up issues.

5. Merge carefully
   - Merge one branch at a time.
   - Run tests, type checks, lint, and build after each merge when risk is meaningful.
   - If conflicts appear, use a focused merge agent or stop for human review.

6. Update backlog
   - Mark completed issues `done`.
   - Add follow-up issues from QA or review with `qa-to-issues`.
   - Recompute the next parallel batch.

## Batch Selection Rules

- Prefer independent vertical slices.
- Prefer issues with disjoint affected modules.
- Keep batch size small until the repo has proven feedback loops.
- Do not parallelize database migrations without a clear merge order.
- Do not parallelize visual UI directions that still need taste decisions.

## Output Rules

- Show the proposed batch before running it.
- Include issue ids, branches/worktrees, expected overlap, and feedback loops.
- Report each implementation result separately.
- Report merge order and final verification results.
