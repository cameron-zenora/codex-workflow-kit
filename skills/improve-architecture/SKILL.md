---
name: improve-architecture
description: Inspect a codebase for shallow modules, weak feedback loops, hard-to-test behavior, and architecture changes that would make AI-assisted implementation safer. Use when agents struggle, tests are poor, or the codebase feels hard to reason about.
---

You look for architecture improvements that make humans and agents more effective.

The target is deep modules: small, clear public interfaces with meaningful internal behavior and useful test boundaries. Avoid shallow-module sprawl where every helper is tiny, coupled, and hard to test in isolation.

## Workflow

1. Map the current shape
   - Identify major domains, services, routes, UI surfaces, jobs, data stores, and shared utilities.
   - Find dependency clusters and places where logic is scattered.
   - Locate existing tests and feedback loops.

2. Find friction
   - Look for modules that are difficult to test without excessive mocks.
   - Look for features spread across many shallow files with unclear ownership.
   - Look for repeated logic, hidden coupling, unstable interfaces, and high-churn areas.
   - Look for missing integration or service-level tests around important behavior.

3. Propose deepening moves
   - Define a deeper module boundary.
   - Name the public interface.
   - Explain what behavior moves inside.
   - Explain how to test it from the outside.
   - Keep proposals incremental and safe.

4. Prioritize candidates
   - Prefer changes that improve feedback loops for upcoming work.
   - Prefer changes that let future issues be implemented as clean vertical slices.
   - Avoid large abstract rewrites with unclear payoff.

5. Create issues when useful
   - If the user wants implementation-ready work, create local issues under `issues/`.
   - Mark architecture issues `AFK` only when they have clear acceptance criteria and tests.

## Candidate Format

```markdown
## Candidate: <Name>

### Current Pain

<Why the current code shape is hard for humans or agents.>

### Proposed Deep Module

- Public interface: `<function-or-class-or-route>`
- Owns: <behavior/data/rules inside the module>
- Depends on: <dependencies>
- Used by: <callers>

### Test Boundary

<How to test meaningful behavior from outside the module.>

### Migration Plan

1. <Small safe step.>
2. <Small safe step.>
3. <Small safe step.>

### Risks

- <Potential regression or migration concern.>
```

## Output Rules

- Start with the highest-leverage candidates.
- Explain how each candidate improves AI-assisted work.
- Include tests or feedback loops for each proposal.
- Recommend `break-prd-to-issues` if the architecture work should be queued.
