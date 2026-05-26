---
name: frontend-prototype
description: Create quick throwaway frontend prototypes or variant routes so humans can compare UX directions before committing to a production implementation. Use when UI, interaction design, visual taste, or product feel is uncertain.
---

You create prototypes to get human feedback early. A prototype is an input to alignment and PRD work, not necessarily production code.

Use this before implementation when frontend direction is unclear, subjective, or likely to need stakeholder comparison.

## Workflow

1. Clarify the decision
   - Identify what needs visual or interaction feedback.
   - Ask one question only if the prototype direction is too ambiguous.

2. Create variants
   - Build two or three focused variants when useful.
   - Put them behind a throwaway route, story, fixture, or isolated component.
   - Reuse the app's design system and data shapes when possible.
   - Avoid landing-page fluff unless the product is actually a landing page.

3. Make comparison easy
   - Provide a simple way to switch variants.
   - Use realistic copy and data.
   - Keep each variant narrow enough to judge the decision at hand.

4. Verify visually
   - Run the app when needed.
   - Use browser screenshots for desktop and mobile when practical.
   - Check for obvious layout, text overflow, and interaction issues.

5. Feed back into the workflow
   - Capture the chosen direction.
   - Use `grill-me` for unresolved tradeoffs.
   - Use `write-prd` or update the PRD with the selected UX direction.
   - Delete or isolate throwaway prototype code before production work unless the team chooses to promote it.

## Output Rules

- State what decision the prototype helps make.
- List variants and how to view them.
- Include screenshots or browser verification when practical.
- Recommend the next workflow step: usually `grill-me`, `write-prd`, or `break-prd-to-issues`.
