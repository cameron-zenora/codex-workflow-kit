---
name: write-prd
description: Turn an idea, brief, transcript, or completed alignment conversation into a practical product requirements document. Use when the user asks to write a PRD, create product requirements, turn a brief into a destination document, capture decisions, or prepare work for implementation planning.
---

You write PRDs as destination documents for AI-assisted software work. Your goal is shared understanding, not exhaustive bureaucracy.

## When To Use This Skill

Use this skill after the user has an idea, client brief, meeting transcript, rough plan, or a `grill-me` alignment conversation.

Use `grill-me` first when the idea is vague, high-risk, full of hidden product decisions, or likely to need domain input.

Skip extra grilling when the user already supplied enough context and the next useful step is to capture decisions.

## Workflow

1. Gather input
   - Ask for the source material if none was provided.
   - If there is a codebase, briefly explore the relevant architecture before proposing implementation decisions.
   - Keep the current context small. Prefer focused exploration over broad dumps.

2. Resolve important unknowns
   - Ask one question at a time only when the answer changes the PRD meaningfully.
   - For each question, include a recommended answer.
   - If the answer can be discovered from the repo, inspect the repo instead of asking.
   - Stop when the destination is clear enough to plan vertical slices.

3. Identify the code shape
   - List proposed modules, routes, services, data models, APIs, jobs, or UI surfaces that may change.
   - Prefer deep modules with small interfaces and meaningful internal behavior.
   - Call out where tests should wrap the behavior.

4. Write the PRD
   - Save it as Markdown when working in a repo or local workspace.
   - Use the repo's existing issue, docs, or planning location if there is one.
   - If no convention exists, use `docs/prds/YYYY-MM-DD-short-feature-name.md`.
   - Do not keep stale implementation plans in the repo after completion unless the team convention says to. PRDs can rot and mislead future agents.

## PRD Template

```markdown
# PRD: <Feature Name>

## Problem

<Who has the problem, what hurts, and why now.>

## Goals

- <Outcome users or the business should get.>
- <Observable behavior that must be true when done.>

## Non-Goals

- <Explicitly out-of-scope decisions, rejected ideas, or deferred work.>

## Users And Stories

- As a <user>, I want <capability>, so that <benefit>.
- As a <user>, I want <capability>, so that <benefit>.

## Proposed Solution

<Short explanation of the product behavior and user experience.>

## Functional Requirements

- <Requirement with clear acceptance criteria.>
- <Requirement with clear acceptance criteria.>

## Implementation Notes

### Proposed Modules

- `<module-or-file>`: <role, public interface, and behavior boundary.>
- `<module-or-file>`: <role, public interface, and behavior boundary.>

### Data Model

- <Entities, fields, migrations, or persistence changes.>

### Integration Points

- <Routes, APIs, events, jobs, permissions, analytics, third-party services.>

## Testing Strategy

- <Unit or service tests around deep modules.>
- <Integration tests for vertical slices.>
- <Manual QA checks for UI/taste/product fit.>

## Rollout And Risks

- <Migration, flagging, compatibility, support, privacy, security, or performance concerns.>

## Definition Of Done

- <Concrete finish line.>
- <Feedback loops that must pass.>
- <Manual QA expectations.>

## Open Questions

- <Only unresolved questions that genuinely block planning or implementation.>
```

## Output Rules

- Keep the PRD useful for an implementation agent, but readable by humans.
- Preserve negative decisions and rationale in `Non-Goals` or `Rollout And Risks`.
- Do not pretend the PRD is a compiler. The codebase remains the source of truth.
- After writing the PRD, recommend the next step: usually breaking it into independently grabbable vertical-slice issues.
