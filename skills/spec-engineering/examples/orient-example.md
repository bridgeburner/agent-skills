# ORIENT Mode Example

## User Request
"Help me understand this codebase - it's a Node.js API service."

## Response

**MODE:** ORIENT

**Consulted:**
- `README.md` (router entrypoint)
- `docs/architecture.md` (architecture overview)
- `package.json` (workflows/scripts)

**Answer / Plan:**

### Repo Map
- **src/**: Main application code
  - `server.ts`: Express app entrypoint
  - `routes/`: API route handlers
  - `services/`: Business logic
  - `models/`: Database models (Sequelize)
  - `middleware/`: Auth, validation, error handling
- **tests/**: Jest test suites mirroring src structure
- **migrations/**: Sequelize database migrations

### Key Runtime Flows
1. HTTP request → middleware chain → route handler → service → model → response
2. Background jobs via Bull queue in `src/jobs/`

### Critical Invariants
- All routes require JWT auth except `/health` and `/auth/*`
- Database transactions required for multi-table writes
- Rate limiting: 100 req/min per user

### Pareto Entrypoints
- Architecture: `docs/architecture.md`
- Interfaces: `docs/api.md`, `src/routes/` for route definitions
- Workflows: `package.json` scripts, `docs/contributing.md`

**Verification:**
- Ran: `npm run test -- --listTests` to confirm test structure
- Code locations verified: `src/server.ts:15-40` for middleware chain

**Spec impact:**
- Impact classification: N/A (read-only operation)
- Spec updates required: No

**Confidence:**
- High - router docs exist and are consistent with code structure
