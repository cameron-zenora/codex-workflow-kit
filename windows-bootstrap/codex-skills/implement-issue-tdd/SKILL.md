---
name: implement-issue-tdd
description: Implement one clear issue using test-driven development, existing codebase patterns, small scoped edits, and feedback loops. Use when an issue file or ticket is ready for implementation.
---

You implement exactly one issue at a time. Stay in the smart zone by keeping scope small.

Use red-green-refactor whenever the repo has a practical automated test surface. If TDD is impossible, explain why and create the closest useful feedback loop before implementing.

## Workflow

1. Pick the issue
   - Use the issue specified by the user.
   - If the user asks you to pick, choose the first unblocked `AFK` issue from `issues/`.
   - Do not work on blocked issues unless the user explicitly asks.

2. Understand context
   - Read the issue, PRD, blockers, and any linked notes.
   - Inspect the relevant modules and existing tests.
   - Check current git status before editing.

3. Plan the slice
   - Identify the smallest behavior that satisfies the issue.
   - Identify the test boundary.
   - Prefer deep-module or integration tests that exercise meaningful behavior.

4. Red
   - Add or update a failing test first.
   - Run the narrowest relevant test command.
   - Confirm the failure is for the expected reason.

5. Green
   - Implement the smallest code change that passes the test.
   - Follow local architecture, naming, and helper patterns.
   - Avoid unrelated refactors.

6. Refactor
   - Clean up only what the slice needs.
   - Preserve a simple interface around deep modules.
   - Avoid scattering shallow helper modules unless they reduce real complexity.

7. Feedback loops
   - Run the issue's test plan.
   - Run relevant type checks, lint, build, and focused test suites when available.
   - For UI work, run the app and verify with browser screenshots when feasible.

8. Finish
   - Update the issue status to `done` only if the implementation and checks are complete.
   - If the work reveals new tasks, create follow-up issues instead of expanding scope.
   - Create a commit only when the user or local workflow asks for commits; keep it one issue per commit.

## Implementation Rules

- Do not use a vague PRD as permission to change everything.
- Do not implement more than the selected issue.
- Do not write tests after the entire implementation unless TDD is genuinely impractical.
- Do not mock away the behavior that matters.
- Do not mark an issue done if manual QA or review is still required; mark it `review` or note the remaining checks.

## Output Rules

- State the issue implemented.
- Summarize changed behavior.
- Report exact feedback loops run and their results.
- Mention any follow-up issues created or residual risk.
- Recommend `review-work` in a fresh context after implementation.
