# Review queue checks

Run `evals.json` as isolated, simulated conversations without live GitHub or
dashboard writes. They check the role gate, strategic delegation, and incremental
sweep/recovery, discovery approval history, and tracker ownership boundaries.
Cases 4–5 cover discovery without admission, approvals on older commits,
conditional approval versus merge holds, and recovery without duplicate writes.
Include negative prompts such as "review PR 42", "edit this
skill", and an old queue file in a fresh session. Inspect decisions, not wording.

The Codex gate is `policy.allow_implicit_invocation: false`; Claude Code uses
`disable-model-invocation: true`. These prevent implicit loading in supporting
harnesses. The skill's role gate also applies when its text is explicitly loaded
for another purpose. Other harnesses need equivalent support; prose is not a
platform-level enforcement mechanism.

Prompt design sources (consulted 2026-09-15):

- [OpenAI Astra prompting guidance](https://developers.openai.com/api/docs/guides/latest-model):
  clear authority, explicit delegation, proportionate verification, and resolving
  instruction conflicts. The model choice is project workflow policy, not a
  claim that a prompt can change the harness's model.
- [Agent Skills best practices](https://agentskills.io/skill-creation/best-practices):
  focused workflow instructions and a separate template instead of exhaustive
  general advice. This is format guidance, not an Astra-specific benchmark.
- Codex's installed `skill-creator/references/openai_yaml.md`: the explicit-only
  invocation policy and interface schema.
- [Claude Code invocation controls](https://code.claude.com/docs/en/skills#control-who-invokes-a-skill):
  the documented `disable-model-invocation` extension. The generic quick validator
  rejects this host-specific field; validate it separately and validate the
  remaining standard frontmatter without removing the extension from the skill.
