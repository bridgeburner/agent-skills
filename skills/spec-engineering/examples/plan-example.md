# PLAN Mode Example

## User Request
"Break the notification preferences feature into implementation stories."

## Response

**MODE:** PLAN

**Consulted:**
- `specs/notifications/spec.md` (requirements R1-R4, API contracts)
- `specs/notifications/design.md` (constraints C1-C5, N1-N3, data model, file organization)

**Answer / Plan:**

### Stories Created (`specs/notifications/stories.md`)

**Phase Structure:**

| Phase | Name | Goal |
|-------|------|------|
| 1 | Data Layer + Service | Models, migrations, RLS, core business logic |
| 2 | API + Integration | Endpoints, integration tests, deployment |

**Phase 1 — Data Layer + Service**

*Stream 1: Database Foundation*

#### P1-S01: Create notification_preferences table and migration

| Field | Value |
|-------|-------|
| **Type** | task |
| **Priority** | P1 |
| **Dependencies** | None |

**Description**: Add the `notification_preferences` table. Foundation for all preference management. Includes SQLAlchemy model, Alembic migration, and RLS policy following existing org-scoped table patterns.

**Acceptance Criteria**:
- [ ] Table created with all columns from design doc (user_id, channel, enabled, quiet_hours_start, quiet_hours_end, organization_id, created_at, updated_at)
- [ ] RLS policy enforces org-scoped access
- [ ] Alembic migration created, single head verified
- [ ] Unique constraint on (user_id, channel)
- [ ] `DateTime(timezone=True)` with `utc_now` defaults

#### P1-S02: Implement NotificationPreferenceService

| Field | Value |
|-------|-------|
| **Type** | feature |
| **Priority** | P1 |
| **Dependencies** | P1-S01 |

**Description**: Core business logic for CRUD operations on notification preferences. Includes default preference creation on first access and bulk update support. Service layer follows no-commit policy (flush only).

**Acceptance Criteria**:
- [ ] `get_or_create_defaults(user_id)` returns preferences, creating defaults if none exist
- [ ] `update_preferences(user_id, updates)` bulk-updates channel settings
- [ ] Service methods use flush only, never commit (respects N1)
- [ ] Unit tests cover CRUD, default creation, and concurrent access

*Stream 2: API*

#### P1-S03: Implement GET/PUT /users/{id}/preferences endpoints

| Field | Value |
|-------|-------|
| **Type** | feature |
| **Priority** | P1 |
| **Dependencies** | P1-S02 |

**Description**: REST endpoints for reading and updating notification preferences. GET returns current preferences (creating defaults if needed). PUT accepts bulk update.

**Acceptance Criteria**:
- [ ] `GET /api/v1/users/{id}/preferences` returns preferences with standard response format
- [ ] `PUT /api/v1/users/{id}/preferences` accepts channel update array
- [ ] 422 on invalid channel names, 403 on accessing another user's preferences
- [ ] Endpoints use `get_rls_db` dependency
- [ ] Unit tests cover happy path, validation errors, auth boundaries

**Quality Check:**
- [x] All 4 requirements (R1-R4) covered across story acceptance criteria
- [x] Acceptance criteria are agent-verifiable
- [x] Dependencies form a DAG
- [x] Stories are agent-sized (1-3 files each)
- [x] Format compatible with `bd create -f`

**Verification:**
- R# coverage: 4/4 requirements mapped across stories
- C#/N# coverage: all constraints addressed in acceptance criteria
- Story sizing: all stories touch 1-3 files

**Spec impact:**
- Impact classification: N/A (story decomposition, not code change)
- Spec updates: None

**Confidence:**
- High -- follows existing codebase patterns; all requirements traceable to stories
