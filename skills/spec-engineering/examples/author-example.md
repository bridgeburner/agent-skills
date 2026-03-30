# AUTHOR Mode Example

## User Request
"Write specs for a notification preferences feature."

## Response

**MODE:** AUTHOR

**Consulted:**
- `specs/INDEX.md` (existing spec layout)
- `app/users/models.py` (existing user model)
- `specs/user_management/spec.md` (related spec)

**Answer / Plan:**

### Documents Created

**1. Product Spec** (`specs/notifications/spec.md`)
- Summary: user-configurable notification preferences per channel
- 4 requirements (R1-R4) with Given/When/Then
- 3 goals (G1-G3), 2 non-goals (NG1-NG2)
- API contracts for GET/PUT /users/{id}/preferences with error code tables
- State machine for notification delivery: pending -> sent / failed / suppressed
- Glossary: 5 terms (NotificationChannel, PreferenceSet, DeliveryWindow, etc.)

**2. Design Doc** (`specs/notifications/design.md`)
- Context: triggered by user feedback on notification fatigue
- `notification_preferences` table + `notification_channels` enum
- 5 MUST constraints (C1-C5), 2 ASK FIRST (A1-A2), 3 NEVER (N1-N3)
- 4 design decisions with rationale (D1-D4)
- Alternatives Considered: per-notification toggles vs channel-level preferences (rejected: UI complexity for marginal benefit)
- Cross-cutting concerns: no PII in logs, latency budget P95 < 100ms
- File organization: `app/notifications/` with models, schemas, service, router

**3. Spec Index Updated** (`specs/INDEX.md`)
- Added row: `| Notifications | In Progress | [spec](notifications/spec.md) | [design](notifications/design.md) | -- |`

**Verification:**
- All R# independently testable via Given/When/Then
- All C#/N# include rationale; N# include Correct Approach
- Cross-references verified between spec and design
- Glossary terms used consistently across both documents

**Spec impact:**
- Impact classification: N/A (new feature, new specs)
- Spec updates: INDEX.md updated with new feature row

**Confidence:**
- High -- follows existing patterns in the codebase; related user management spec consulted
