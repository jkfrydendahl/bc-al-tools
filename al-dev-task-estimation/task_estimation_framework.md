# Task Estimation Framework for Business Central (AL) Development
## Based on 170+ historical tasks (2024–2026) · v3.3

*Calibrated for BC/AL development tasks — page extensions, codeunit logic, integrations, reports, operations, and ERP customization.*

---

## How to Use This Document

Provide this document as context to an AI assistant alongside a **task description** (from Azure DevOps, email, or verbal brief). The AI will:

1. **Ask clarifying questions** before scoring (see protocol below)
2. Score the task on 6 complexity dimensions
3. Map the composite score to a calibrated hour range
4. Apply relevant adjustments (project, familiarity, keywords)
5. Return a **three-point estimate** (optimistic / likely / pessimistic)

**Prompt template:**
> Using the estimation framework below, analyze this task and provide an estimate:
> 
> **Project:** [project name]
> **Consultant/PM:** [name]
> **Developer familiarity with this codebase:** [high/medium/low/first-time]
> **Task description:** [paste description]

### Clarifying Questions Protocol (MANDATORY)

**Before scoring any task, the AI MUST ask clarifying questions.** Validation showed that interactive estimation (92% in-range) dramatically outperforms autonomous estimation (67% in-range) because critical context is often missing from task descriptions.

**Always ask these if not already clear from the description:**

1. **Project & Familiarity:** "Which project/codebase is this in, and how familiar are you with it?"
2. **Environment topology:** "Is this same-environment or cross-environment?" *(especially for IC/integration tasks — effort difference is 3-4×)*
3. **Scope boundaries:** "Does this apply to multiple document types, companies, or environments?" *(scope trap detection)*
4. **Standard vs custom code:** "Are we modifying your own code or patching standard BC / ISV code?" *(standard BC bugs need TechComplexity +1)*
5. **Description completeness:** "Is this the full spec, or is there additional context in emails, meetings, or diagrams?" *(anti-pattern #9 detection)*

**Additionally, ask if any of these red flags are present:**
- Vague description + senior PM who tends to assign broad-scope tasks → likely larger than it reads
- Multiple distinct deliverables mentioned → confirm count
- Warehouse/production order document creation involved → tends to add ~1h over estimate
- Testing only possible in production → adds dependency overhead

**After receiving answers, proceed with scoring. If the developer says "just estimate it", provide the estimate but flag which assumptions you made and their risk.**

### Estimation Principles
- **Anchor to the median, not the mean.** The typical task takes 4h (median). Most tasks are smaller than the mean (7.3h) suggests — outliers skew upward.
- **Familiarity dominates.** In well-known codebases, effort drops ~50% vs early work. Always ask: "Have I done something similar here before?"
- **Score conservatively.** When in doubt between two scores, pick the lower one. The framework already has a slight overestimation bias.
- **Keywords inform, they don't dictate.** A "rapport" task is typically 4h (median), not the 10.8h that mean-based analysis suggests. Don't let a single keyword override the full scoring.

---

## 1. Complexity Scoring Model

Score each dimension from 1 (minimal) to 5 (maximum):

### Dimension 1: Scope
*How many BC objects/components are touched?*

| Score | Description | Examples |
|-------|------------|---------|
| 1 | Single field, property, or config change | Add field to page, change caption |
| 2 | Single object modification (page, table, codeunit) | New FactBox, column addition |
| 3 | Multiple related objects (2–4) | New page + table extension + logic |
| 4 | Cross-functional feature (5+ objects) | New workflow spanning multiple areas |
| 5 | New module or major subsystem | Full module, data migration suite |

**Scope scoring trap:** When a task applies the same change across **multiple document types** (e.g., both quote AND order, both list AND card, both company DK AND SE), score Scope **one level higher** than the individual change suggests. The per-location effort for testing, edge cases, and subtle differences adds up.

### Dimension 2: Uncertainty
*How clearly defined is the requirement?*

| Score | Description | Examples |
|-------|------------|---------|
| 1 | Crystal clear spec with test criteria | Templated task, exact field mapping provided |
| 2 | Well described, minor clarification needed | Løsningsbeskrivelse with clear goal |
| 3 | Goal is clear, approach needs investigation | "Make X work like Y" without details |
| 4 | Vague requirement, needs discovery | Customer email with rough idea |
| 5 | Exploratory / unknown scope | "Debug this intermittent issue", "Look into feasibility" |

### Dimension 3: Technical Complexity
*How difficult is the implementation?*

| Score | Description | Examples |
|-------|------------|---------|
| 1 | Standard BC configuration or simple field addition | Cockpit modifications (median 1.5h) |
| 2 | Straightforward AL code, known patterns | Page extensions, simple validations |
| 3 | Moderate logic, data transformations, reports | Reports (median 4h), automations (median 5h) |
| 4 | Complex algorithms, multi-table operations | Import scripts (median 8h), planning logic |
| 5 | Architecture-level, upgrades, system integration | NAV→BC migration (80h), webservice integration |

### Dimension 4: Dependencies
*What external factors affect completion?*

| Score | Description | Examples |
|-------|------------|---------|
| 1 | Fully standalone, no external input needed | Internal tooling, isolated fix |
| 2 | Needs minor input (one question to PM/customer) | Clarification on a field mapping |
| 3 | Depends on customer testing or data | Customer test environment needed, data validation |
| 4 | Multi-party coordination (customer + other devs) | Integration with external system, shared branches |
| 5 | Blocked by external deliverables or infrastructure | Waiting on 3rd party, environment setup, GDAP access |

### Dimension 5: Testing & Validation
*How much testing/QA is required?*

| Score | Description | Examples |
|-------|------------|---------|
| 1 | Quick visual/smoke test | Field displays correctly |
| 2 | Targeted functional test | Feature works as described |
| 3 | Multi-scenario testing | Multiple data paths, edge cases |
| 4 | Regression testing + customer validation | Changes may affect existing logic, needs sign-off |
| 5 | Full system test / go-live validation | Upgrades, driftstart, data migration verification |

### Dimension 6: Familiarity (strongest predictor)
*How well do you know this codebase and domain?*

| Score | Description | Impact |
|-------|------------|--------|
| 1 | Expert — built or maintained this code extensively | Effort drops ~50% vs unfamiliar. Well-known projects average 4h |
| 2 | Experienced — worked on this project multiple times | Comfortable navigating, minor discovery needed |
| 3 | Moderate — done a few tasks here, know the basics | Some exploration required for each task |
| 4 | Low — first few tasks in this codebase | Expect 30% overhead for orientation and code discovery |
| 5 | None — brand new project, never seen the code | Expect 50-80% overhead. Historical: early tasks in a new project averaged 9.9h vs 4.0h later |

*This dimension was added after blind testing revealed familiarity as the dominant factor. In one high-volume project, effort dropped 59% from first-half to second-half tasks. In another, it dropped 74%.*

---

## 2. Score-to-Hours Mapping

### Composite Score Calculation
```
Composite = (Scope × 1.2) + (Uncertainty × 1.0) + (TechComplexity × 1.2) + (Dependencies × 0.7) + (Testing × 0.7) + (Familiarity × 1.2)
```
*Weights reflect v2 calibration: Scope, Technical Complexity, and Familiarity are the strongest effort predictors. Dependencies and Testing contribute less to pure development time. Uncertainty is weighted neutrally.*

**Maximum possible: 30.0 | Minimum: 6.0**

### Hour Mapping (v3 — non-linear piecewise with asymmetric bands)

The mapping uses a **non-linear curve** that scales gently for small tasks but accelerates for complex ones. Bands are **asymmetric** — P80 is proportionally wider than P20 because complex tasks have more upside risk than downside.

| Composite | P20 (Optimistic) | P50 (Likely) | P80 (Pessimistic) | Category |
|-----------|------------------|-------------|-------------------|----------|
| 7 | 0.5h | 1h | 2h | Trivial |
| 8 | 0.5h | 1h | 2.5h | Trivial |
| 9 | 0.5h | 1.5h | 3h | Trivial |
| 10 | 0.5h | 1.5h | 3h | Trivial |
| 11 | 1h | 2h | 4.5h | Small |
| 12 | 1.5h | 3h | 6h | Small |
| 13 | 2h | 4h | 8h | Small |
| 14 | 2h | 4.5h | 10h | Small |
| 15 | 3h | 6.5h | 14h | Medium |
| 16 | 4h | 8.5h | 19h | Medium |
| 17 | 5h | 10.5h | 26h | Medium |
| 18 | 6h | 12.5h | 31h | Medium |
| 19 | 8h | 16.5h | 40h | Large |
| 20 | 10h | 20h | 50h | Large |
| 22 | 14h | 28.5h | 70h | Large |
| 24+ | 20h+ | 40h+ | 80h+ | XL |

**Underlying formula (for interpolation):**
```
Composite 6–10:   P50 = 0.15 × composite               (trivial: ~1–1.5h)
Composite 10–14:  P50 = 1.5 + 0.75 × (composite − 10)  (small: ~1.5–4.5h)
Composite 14–18:  P50 = 4.5 + 2.0 × (composite − 14)   (medium: ~4.5–12.5h)
Composite 18–22:  P50 = 12.5 + 4.0 × (composite − 18)  (large: ~12.5–28.5h)
Composite 22+:    P50 = 28.5 + 7.0 × (composite − 22)  (XL: accelerating)

Bands:
  Trivial/Small (≤14):  P20 = P50 × 0.45,  P80 = P50 × 2.0
  Medium (14–18):        P20 = P50 × 0.50,  P80 = P50 × 2.2
  Large+ (18+):          P20 = P50 × 0.50,  P80 = P50 × 2.5
```

*v3 changes: Non-linear mapping replaces flat buckets. This fixes v1's overestimation of small tasks AND v2's underestimation of large tasks. Bands are wider and asymmetric — honest about upside risk on complex work.*

### Non-Development Tasks
Tasks like conference attendance, placeholder time-tracking, or administrative work **cannot be estimated by this framework**. Flag them explicitly and estimate based on calendar time (e.g., "3-day conference = 24h").

### Quick Reference Percentiles (all tasks)
- **P10:** 1h — the simplest tasks you do
- **P25:** 2h — a quick modification
- **P50:** 4h — your typical task (half-day)
- **P75:** 7h — a solid day's work
- **P90:** 16h — multi-day feature (2+ days)
- **P95:** 30h — major feature (week)

### Irreducible Variance Warning
Even among tasks that look similar (medium-length description, familiar project), effort has a **coefficient of variation of 113%** and a standard deviation of ±5h. This means:
- A task scored as "Small" (P50 = 3-4h) will land at **1–12h** in 80% of cases
- **~10% of Small-looking tasks will exceed 12h** — triple the P50
- This isn't a flaw in the framework. It's the fundamental nature of software estimation.

**Practical guidance:** When a task falls in the Small-Medium range (composite 11-16), always communicate the **full P20-P80 range** to stakeholders — not just the P50. The likely estimate is your planning target; the pessimistic is your commitment.

---

## 3. Adjustment Factors

Apply these as **soft adjustments** (±15-25% max) to the base estimate. In v1, multipliers were too aggressive and caused overestimation. **Never let adjustments more than double or halve the base estimate.**

### Project Adjustments
*Based on recent historical medians. Note: familiarity is already captured in Dimension 6, so these adjustments are smaller.*

| Project Type | Adjustment | Notes |
|-------------|-----------|-------|
| Primary/high-volume project | −10% | Well-known codebase, many prior tasks |
| Internal tools | −15% | Familiar patterns, full control |
| Small-scope client projects | −20% | Consistently small, well-scoped tasks |
| Upgrade-heavy / infrastructure projects | +25% | Complex infrastructure, less predictable |
| *New/unfamiliar project* | *Handled via Dimension 6 (Familiarity)* | *Don't double-count* |

### Consultant/PM Adjustments
*These reflect task scoping tendencies, not effort. Cap at ±20%.*

| PM Style | Adjustment | Rationale |
|----------|-----------|-----------|
| Broad-scope / architectural PM | +15% to +20% | Tends to assign cross-functional or architecturally significant tasks |
| Balanced / average-scope PM | 0% | Standard scoping, no adjustment needed |
| Self-assigned tasks | −10% | Accurate self-scoping, knows own velocity |
| Well-scoping / targeted PM | −15% | Consistently delivers focused, well-defined task briefs |
| Small-fix / focused PM | −15% | Assigns targeted, isolated fixes |

### Keyword-Based Signals
*Use as directional hints, NOT multipliers. All values are medians (v1 used means, which were inflated by outliers).*

| Keyword/Pattern | Median effort | vs Baseline (4h) | Interpretation |
|----------------|--------------|-------------------|----------------|
| "import" / "eksport" / "migration" | 8h | ↑ Above | Data handling adds effort, but rarely extreme |
| "rapport" (report) | 4h | → At baseline | Reports aren't inherently large; mean (10.8h) is inflated by outliers |
| "rettelse" (correction) | 5h | → Slightly above | Debugging adds mild overhead |
| "konvertering" (conversion) | 5h | → Slightly above | Manageable with known patterns |
| "automatisk" (automatic) | 5h | → Slightly above | Automation logic is moderate |
| "integration" / "api" | 3.5h | ↓ Below baseline | Surprisingly efficient — known patterns |
| "udvidelse" (extension) | 2h | ↓ Well below | Incremental, low-risk |
| "cockpit" / dashboard UI | 1.5h | ↓ Well below | UI-only, display changes in familiar areas |
| "fejl"/"bug" | 4.5h | → At baseline | Usually isolated issues |
| "tilpasning" (customization) | 4h | → At baseline | Standard work |

---

## 4. Estimation Output Format

When producing an estimate, use this format:

```
## Task Estimate: [Task Title]

### Complexity Scoring
| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Scope | X/5 | [brief reason] |
| Uncertainty | X/5 | [brief reason] |
| Technical Complexity | X/5 | [brief reason] |
| Dependencies | X/5 | [brief reason] |
| Testing | X/5 | [brief reason] |
| Familiarity | X/5 | [brief reason] |

**Composite Score:** XX.X → [Category]

### Adjustments (capped at ±25%)
- Project: [±X%] — [reason]
- PM: [±X%] — [reason]
- Keyword signals: [directional note, not a multiplier]
- **Combined adjustment: [±X%]** (never exceed ±40% total)

### Estimate
| | Hours |
|---|------|
| **Optimistic (P20)** | Xh |
| **Likely (P50)** | Xh |
| **Pessimistic (P80)** | Xh |

### Confidence & Risks
- Confidence: [High/Medium/Low] — based on description clarity and familiarity
- [Key risk or assumption]
- [Similar historical task if applicable]
```

---

## 5. Historical Reference: Task Archetypes

### Trivial (1–2h)
- Adding/exposing fields on existing pages
- Simple validation or caption changes
- Config changes, property modifications
- Cockpit UI adjustments
- Single-object fixes with clear instructions

### Small (3–5h)
- New FactBox or page extension with logic
- API endpoint extensions with known patterns
- Dialogue/workflow tweaks
- Small report modifications
- Well-defined bug fixes

### Medium (6–10h)
- Multi-object features (page + table + codeunit)
- Data synchronization logic
- Status field implementations with business rules
- Report building with moderate complexity
- Error handling improvements for existing features

### Large (11–20h)
- Data import/load scripts (vareindlæsning, ruteindlæsning)
- Planning/scheduling features (planlægningskladde)
- Module refactoring/modernization (tech debt cleanup)
- Multi-scenario features requiring customer test cycles

### XL (20–50h)
- Major new features (CAD integration, resource capacity)
- Webshop module installation + customization
- Complex label/printing systems
- Features spanning multiple functional areas

### XXL (50h+)
- Go-live support with hotfixes (driftstart)
- BC version upgrades (NAV→BC migration)
- Full module implementations
- Major architecture changes

---

## 6. Estimation Anti-Patterns (Lessons from Blind Testing)

Based on the historical data, four rounds of blind validation (v1→v2→v3→v3.1), AND 12 live forward-validation tasks:

1. **Don't let keywords override scoring.** v1 used mean-based keyword signals that inflated estimates (e.g., "rapport" → 10.8h mean, but actual median is 4h). Always score dimensions first, use keywords as a sanity check only.
2. **Familiarity is king.** The biggest estimation errors in blind testing were on well-known codebases. In high-volume projects, recent tasks average 4h — down from 9.9h early on. If you've done 10+ tasks in a project, score Familiarity at 1.
3. **PM adjustments should be gentle (±15-20%).** Early versions had PM multipliers up to 2.4× — these caused massive distortion. The PM influence on effort is real but modest.
4. **Beware the "complex-sounding" description.** Tasks like "IC styring" or "Intercompany" sound architecturally heavy but may resolve to a simple filter/flag addition (6h actual vs 14h estimated in v1). Read the *solution approach*, not just the problem statement.
5. **New table/object creation pushes Scope up.** If a task requires creating a brand new table or module (not just extending), score Scope at least one level higher.
6. **Low familiarity × multiple deliverables = explosive effort.** When Familiarity score is high (4-5, meaning the codebase is unfamiliar) AND Scope is high (3+), the real effort will often land near P80 or beyond. One validated example: 5 label types in an unfamiliar project = 37h.
7. **Non-dev tasks break the model.** Conference attendance, placeholder tracking, administrative time — these simply can't be scored. Flag them and estimate based on calendar duration.
8. **Accept irreducible variance.** Analysis of 170+ tasks shows 113% coefficient of variation for similar-looking tasks. Even with perfect scoring, ~20-25% of tasks will fall outside P20-P80. This is **normal** — don't over-tune the model. Instead, communicate ranges rather than point estimates.
9. **"See diagram" / vague descriptions = hidden icebergs.** When a task description is intentionally brief ("see attached diagram", "several fields needed"), it usually means scope lives outside the ticket — in emails, meetings, or the PM's head. These tasks are systematically underestimated because the scoring dimensions can't capture what isn't written. **Rule of thumb:** If the description is under ~100 chars and the PM tends toward broad-scope assignments, assume the task is at least Large (P50 ≥ 12h) regardless of what the scoring produces. Ask for a fuller brief before committing to an estimate.
10. **Cross-environment IC ≠ same-environment IC.** Intercompany tasks between separate BC environments (e.g., DK→LT, SE→DK across tenants) are 3-4× harder than same-environment IC. Data must survive IC document serialization, debugging spans two environments, and event hooks are more limited. Always clarify which type before scoring. Cross-environment IC with multiple field mappings should score Scope ≥ 4 and Dependencies ≥ 3.
11. **Multiple distinct deliverables = Scope +1.** When a task has 2+ independent pieces of work (e.g., "event subscriber + new API page" or "field mapping + line creation"), score Scope at least one higher than each individual piece suggests. Each deliverable carries its own testing and edge cases.
12. **Standard BC bug fixes land at P80, not P50.** Patching standard BC behavior (not your own code) requires navigating unfamiliar base app code. Discovery time is real even when the fix is clear. Score TechComplexity one level higher than the fix itself suggests.

---

## 7. Continuous Calibration

### Validated Accuracy

| Version | In-range (P20-P80) | MAPE | Key change |
|---------|-------------------|------|------------|
| v1 | 5/10 (50%) | 75% | Baseline: 5 dimensions, flat buckets |
| v2 | 6/10 (60%) | 44% | + Familiarity, median keywords, capped adjustments |
| v3 | 9/10 (90%) | 40% | + Non-linear piecewise, asymmetric bands |
| v3.1 | 12/14 (86%) | 41% | + Vague-description rule (anti-pattern #9) |
| **v3.3** | **11/12 (92%)** | **33%** | **Anonymized, clarifying questions protocol, anti-patterns #10-12** |

*v3.1 tested on expanded 14-task blind set (16 total, 2 non-dev correctly flagged).*
*v3.2 validated on 12 live tasks estimated in real-time (not retrospective). 1 non-dev correctly flagged.*
*v3.3 anonymized and re-validated — no accuracy degradation (80% in-range on 5-task subset).*

### Observations from Live Validation (v3.2)

- **P50 accuracy is strong:** 4 out of 12 dev tasks landed within 0.5h of P50 ("dead on")
- **Slight low bias on warehouse/production tasks:** BC warehouse document APIs consistently add ~1h over the framework's P50. Consider scoring TechComplexity +1 when warehouse put-away/pick creation is involved.
- **Unfamiliar projects:** Familiarity=3 is the sweet spot for "known patterns, unknown codebase". The framework handles moderately familiar projects well at this level.
- **Cross-environment context is critical:** An IC task jumped from P50=8h to P50=11h once cross-environment was clarified. Always ask about the deployment topology.

### Forward Validation Tracker

After completing each task, record results here. Review monthly for systematic drift.

```
| Date | Task Title | Project | PM | P20 | P50 | P80 | Actual | In Range? | Notes |
|------|------------|---------|-----|-----|-----|-----|--------|-----------|-------|
|      |            |         |     |     |     |     |        |           |       |
```

**What to track:**
- **Systematic bias:** If >3 consecutive tasks overrun P50, increase Uncertainty scoring by 1 across the board
- **New project patterns:** After 5+ tasks in a new project, add it to the Project Adjustments table (§3)
- **PM calibration:** If a PM's tasks consistently land outside range, adjust their modifier by ±5%
- **Keyword discoveries:** If a new keyword appears in 3+ tasks with consistent effort, add it to the signals table

**When to recalibrate the piecewise curve:**
- After 20+ forward-validated tasks, re-run the composite→actual regression
- If MAPE exceeds 50% over a rolling 10-task window, investigate root cause before adjusting

---

*Framework version: 3.3 — Anonymized and live-validated 2026-03-19*
*Based on: 170 calibrated tasks + 12 live forward-validation tasks*
*Blind test accuracy (v3.1): 86% in-range on 14 dev tasks*
*Live test accuracy (v3.2): 92% in-range on 12 dev tasks (MAPE 33%)*
*Progression: v1 50% → v2 60% → v3 90% → v3.1 86% (expanded) → v3.2 92% (live)*
*Key features: Non-linear piecewise mapping, asymmetric bands, familiarity dimension, 12 anti-patterns, mandatory clarifying questions*
*Developer profile: BC/AL developer — web, integrations, ERP customization*
