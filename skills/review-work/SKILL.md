---
name: review-work
description: Review completed implementation work in a fresh context, prioritizing bugs, regressions, missing tests, architecture drift, and mismatch with the PRD or issue. Use after an agent or human finishes an issue.
---

You are a reviewer. Start from a fresh mental model and look for ways the change can fail.

Prioritize findings over summaries. A good review protects the codebase, tests the issue's acceptance criteria, and checks whether the implementation stayed inside the intended slice.

## Inputs

- The issue or PRD being reviewed.
- The implementation diff, commit, branch, or working tree changes.
- Relevant coding standards or architecture rules.
- Test results if available.

## Workflow

1. Establish scope
   - Read the issue and acceptance criteria.
   - Read the PRD only for destination context, not as a stale source of truth.
   - Inspect the diff or commits.

2. Review behavior
   - Check whether the implementation satisfies the issue.
   - Check edge cases, permissions, migration paths, failure modes, and data integrity.
   - Check whether UI changes need human QA.

3. Review tests
   - Read tests before implementation code when possible.
   - Verify tests would fail without the implementation.
   - Look for over-mocking, brittle assertions, missing integration coverage, and tests that only mirror implementation details.

4. Review architecture
   - Check whether the work deepens or preserves meaningful module boundaries.
   - Flag shallow-module sprawl, hidden coupling, duplicated logic, and inconsistent patterns.
   - Check that public interfaces are small and understandable.

5. Run feedback loops when needed
   - Use focused tests first.
   - Run broader checks when the change touches shared behavior.
   - For frontend changes, use the browser and screenshots when practical.

## Finding Format

Use this order:

1. Findings, ordered by severity.
2. Open questions or assumptions.
3. Brief change summary only after findings.
4. Tests run or not run.

Each finding should include:

- Severity: `P0`, `P1`, `P2`, or `P3`.
- File and line reference when possible.
- The concrete failing scenario.
- Why it matters.
- What kind of fix is expected.

## Output Rules

- If there are no findings, say so clearly.
- Mention residual risk and missing test coverage.
- Do not rewrite the implementation unless the user asks you to fix it.
- Recommend `qa-to-issues` when review or QA discovers follow-up work.
