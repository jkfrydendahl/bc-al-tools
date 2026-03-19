---
name: estimate-task
description: "Interactive BC/AL task estimation. Scores complexity, asks clarifying questions, and produces a calibrated three-point hour estimate."
---

# Task Estimation

Interactive estimation workflow for Business Central (AL) development tasks. Uses a data-driven 6-dimension scoring model calibrated from 170+ historical tasks to produce three-point estimates (optimistic / likely / pessimistic).

> **Note**: This skill produces estimates only. It does not create or modify work items.

## Invocation

| Command | Action |
|---------|--------|
| `/estimate-task` | Start — prompts user for task description |
| `/estimate-task <inline text>` | Start with the provided task description |

## Input

The skill takes a task description as plain text. If the user does not provide text inline, ask for:
1. **Task description** (full requirements text — free-form input)

## Output

The final output is a structured estimate in Markdown:

| Section | Contents |
|---------|----------|
| Complexity Scoring | 6-dimension score table with per-dimension rationale |
| Adjustments | Project, PM, and keyword adjustments (capped at ±25% each, ±40% total) |
| Three-Point Estimate | P20 (optimistic), P50 (likely), P80 (pessimistic) in hours |
| Confidence & Risks | Confidence level, key risks, assumptions made |

## Knowledge Base

This skill requires the **Task Estimation Framework** document as context. The framework contains:

- The 6 complexity dimensions and scoring rubrics
- The composite formula and piecewise score-to-hours mapping
- Adjustment factor tables (project type, PM style, keyword signals)
- Task archetypes with historical hour ranges
- 12 calibrated anti-patterns from blind and live testing

Reference: [Task_Estimation_Framework.md](./Task_Estimation_Framework.md)

## Workflow

### Phase 1: Context Gathering

Collect the task description and initial context. If not already provided, ask for:

1. **Task description** — the full text from DevOps, email, or verbal brief
2. **Project name** — which project/codebase this is in
3. **Developer familiarity** — high / medium / low / first-time with this codebase

If the user provides all three inline, skip directly to Phase 2.

### Phase 2: Clarifying Questions (MANDATORY)

**Never skip this phase.** Validation showed interactive estimation (92% in-range) dramatically outperforms autonomous estimation (67% in-range).

Ask clarifying questions based on what is NOT already clear from the description:

| Question | Why it matters | When to ask |
|----------|---------------|-------------|
| "Is this same-environment or cross-environment?" | Cross-env IC is 3-4× harder | Integration / IC tasks |
| "Does this apply to multiple document types, companies, or environments?" | Scope trap detection | Any task mentioning lists, cards, documents |
| "Are we modifying your own code or patching standard BC / ISV code?" | Std BC bugs need TechComplexity +1 | Bug fixes, corrections |
| "Is this the full spec, or is there more context elsewhere?" | Anti-pattern #9: hidden icebergs | Short/vague descriptions |
| "How many distinct deliverables are involved?" | Multiple deliverables = Scope +1 | Tasks mentioning 2+ outputs |

**Red flag detection** — also ask if any of these apply:
- Vague description + broad-scope PM → likely larger than it reads
- Warehouse/production order document creation → tends to add ~1h
- Testing only possible in production → adds dependency overhead

After receiving answers, proceed to Phase 3.

**If the user says "just estimate it":** Proceed, but explicitly flag which assumptions were made and their risk level.

### Phase 3: Scoring & Estimation

Using the framework's scoring model:

1. **Score all 6 dimensions** (1–5 each) with a brief rationale per dimension:
   - Scope · Uncertainty · Technical Complexity · Dependencies · Testing · Familiarity

2. **Calculate composite score** using the weighted formula:
   ```
   Composite = (Scope × 1.2) + (Uncertainty × 1.0) + (TechComplexity × 1.2)
             + (Dependencies × 0.7) + (Testing × 0.7) + (Familiarity × 1.2)
   ```

3. **Map to hours** using the piecewise curve (see framework §2)

4. **Apply adjustments** (project type, PM style, keyword signals) — capped at ±25% each, ±40% total

5. **Check against anti-patterns** (#1–#12) — adjust scores if any apply

6. **Produce the three-point estimate** (P20 / P50 / P80)

### Phase 4: Delivery

Present the estimate using the output format defined in the framework (§4). Include:

- The full scoring table with rationale
- All adjustments applied with reasoning
- The three-point estimate
- Confidence level and key risks
- Any anti-patterns that were triggered

## Estimation Principles

These principles override gut feel:

- **Anchor to the median (4h), not the mean (7.3h).** Most tasks are smaller than the mean suggests.
- **Familiarity dominates.** In well-known codebases, effort drops ~50%. Score this dimension carefully.
- **Score conservatively.** When in doubt between two scores, pick the lower one. The framework has a slight overestimation bias.
- **Keywords inform, they don't dictate.** Use them as sanity checks, not multipliers.
- **Communicate ranges, not points.** Always present P20–P80, not just P50.

## Argument Detection

| Pattern | Type | Action |
|---------|------|--------|
| `/estimate-task <text>` | Inline text | Start Phase 1 with provided text |
| `/estimate-task` (no argument) | No input | Prompt user for task description, then start Phase 1 |

## Task List Structure

When starting a new estimation:

```
[Phase 1] Context Gathering - Collect task description and project context
[Phase 2] Clarifying Questions - Ask mandatory questions before scoring
[Phase 3] Scoring & Estimation - Score dimensions, calculate hours
[Phase 4] Delivery - Present structured estimate
```

## Multi-Task Mode

If the user provides multiple tasks at once, estimate them **sequentially** — completing all 4 phases for each task before moving to the next. Shared context (project, familiarity) carries forward between tasks in the same session.

## Quality Gate (Required)

- All 6 dimensions are scored with rationale
- At least one clarifying question was asked (or user explicitly declined)
- Composite score matches the formula calculation
- Hour estimate matches the piecewise curve for the computed composite
- Adjustments do not exceed ±40% total
- At least one risk or assumption is documented
- Any triggered anti-patterns are acknowledged in the output
