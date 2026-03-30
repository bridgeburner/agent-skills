# Agent-Consumed Document Principles

Principles for writing specs, design docs, and execution plans when the primary consumer is an AI coding agent. These apply across all three document types and all skill modes.

---

## P1. Number everything referenceable

Requirements get `R1`, goals get `G1`, non-goals get `NG1`, constraints get `C1`/`N1`/`A1`, design decisions get `D1`, tasks get `T1.1`. Cross-document references use these IDs ("implements R3", "respects C2", "blocked by T1.3"). Agents cannot point at "the third bullet under that heading" -- they need stable identifiers.

## P2. One concept per section, one concern per file

Each heading covers exactly one topic. Never mix "Data Model" with "API" in one section. Each spec file should be loadable independently for a single implementation session. Interleaved topics cause agents to conflate separate ideas.

## P3. Tables over prose for structured data

State machines, field descriptions, constraint lists, task status, schemas, and design decisions belong in markdown tables. Tables are mechanically parseable; paragraph prose requires inference.

## P4. Declare desired end state, not step-by-step instructions

Specs and designs describe WHAT the system should do: "DrawingRequest has status enum {creating, processing, complete, failed}". Not HOW to code it: "first add the status column, then create the enum type..." Agents reason better about end states than imperative sequences. (Exception: execution plans describe ordering, but task descriptions are still declarative.)

## P5. Include verification inline with every claim

Every requirement, constraint, and task states how to mechanically verify compliance. "R3: one active request per part" is incomplete. "R3: one active request per part -- verify: `INSERT` a second row with same part_id and status='creating'; expect unique constraint violation" is actionable.

## P6. Explicit file paths in design/plan, not in behavioral requirements

Design docs and plans say "Implement in `app/drawing/service.py`" -- agents need to know where to write code. But product spec requirements should NOT embed file paths -- those go stale when code moves. Specs describe behavior; designs and plans describe where it lives.

## P7. Cross-reference by link, never by restating

Duplication across documents creates contradictions as documents evolve independently. A design doc references `[R3](spec.md#r3-single-active-request)`, it does not re-explain the requirement. The plan references "Implements R3" and "Respects C2", never restating what those mean.

## P8. Consistent terminology enforced by glossary

If the spec says "DrawingRequest" in one place and "drawing request record" in another, the agent may treat them as different entities. The glossary in the product spec is the canonical definition. All documents use glossary terms exactly as defined.

## P9. Three-tier constraint boundaries (MUST / ASK FIRST / NEVER)

Flat rule lists are less effective than tiered boundaries. MUST maps to "agent verifies after every change." ASK FIRST maps to "agent stops and asks." NEVER maps to "agent must not generate code that violates, and the Correct Approach column tells it what to do instead." See SKILL.md Section 5.3 for full guidance.

## P10. Context-efficient writing

Every unnecessary word consumes tokens from the agent's working context. Bullet points over paragraphs. Short sentences. No preamble, no "In this section we will discuss..." Tables over prose. Numbered lists over narrative. The spec is not a blog post.

## P11. Machine-parseable structure

Use consistent, parseable formats: metadata tables for story fields, checkbox lists for acceptance criteria, structured headings for phases and streams. Execution tools (beads, terminal-velocity) consume these documents programmatically. Ambiguous prose structures ("mostly done", "see above") are unparseable.

## P12. Spec quality is the primary lever for agent reliability

When an agent produces wrong output, fix the spec first, code second. Every agent failure should trigger: "What was wrong with the spec that allowed this?" A single contradiction in a spec can cause mysterious errors across many agent iterations. Investment in spec quality pays compound dividends.

## P13. Silent success, verbose failure

Verification output sent to agents should be minimal on success (just "PASS" or exit code 0) and detailed on failure (full error, stack trace, context). Verbose success output wastes context budget and can trigger hallucination.

---

## Quick Reference

| # | Principle | Spec | Design | Plan |
|---|-----------|:----:|:------:|:----:|
| P1 | Number everything referenceable | R#, G#, NG# | C#, N#, A#, D# | T#.# |
| P2 | One concept per section | Yes | Yes | Yes |
| P3 | Tables over prose | Yes | Yes | Yes |
| P4 | Declare end state, not steps | Yes | Yes | Task descriptions |
| P5 | Inline verification | Given/When/Then | Constraint checks | Per-task commands |
| P6 | File paths in design/plan only | No paths | Yes | Yes |
| P7 | Cross-reference by link | Upstream (no refs out) | Refs spec R# | Refs R#, C#, N# |
| P8 | Glossary-enforced terminology | Defines glossary | Uses glossary | Uses glossary |
| P9 | Three-tier constraints | -- | Defines C#/A#/N# | Respects C#/N# |
| P10 | Context-efficient writing | Yes | Yes | Yes |
| P11 | Machine-parseable structure | Status field | Status field | Metadata tables, checkboxes |
| P12 | Spec quality as primary lever | Primary target | Secondary | Downstream |
| P13 | Silent success, verbose failure | -- | -- | Verification output |

---

## Sources

- Huntley (ghuntley.com/ralph/): P4, P11, P12 (CURSED spec contradiction discovery)
- Osmani (addyosmani.com/blog/good-spec/): P3, P9, P10
- Pocock (aihero.dev): P6, P10
- HumanLayer RPI (humanlayer.dev): P13, context utilization targets
- Fowler/Boeckeler (martinfowler.com): P2, P7 (observed agents conflating interleaved topics)
- Kiro (kiro.dev/docs/specs/): P1, P3, P5 (EARS notation for machine parseability)
- Google design doc culture (industrialempathy.com): P7 (cross-reference, never restate)
