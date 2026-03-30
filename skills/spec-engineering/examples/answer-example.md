# ANSWER Mode Example

## User Request
"How does authentication work in this service?"

## Response

**MODE:** ANSWER

**Consulted:**
- `docs/architecture.md` (Section: Authentication)
- `src/middleware/auth.ts` (implementation)
- `src/routes/auth.ts` (auth endpoints)

**Answer / Plan:**

### Authentication Flow
1. **Login**: `POST /auth/login` accepts email/password, validates against bcrypt hash in `users` table, returns JWT + refresh token
2. **Token format**: JWT contains `{ userId, role, exp }`, signed with `process.env.JWT_SECRET`, expires in 15 minutes
3. **Refresh**: `POST /auth/refresh` accepts refresh token (stored in Redis with 7-day TTL), issues new JWT
4. **Middleware**: `authMiddleware` in `src/middleware/auth.ts:23` extracts Bearer token, verifies signature, attaches `req.user`

### Trust Boundaries
- JWT verification happens before any route handler executes
- Role-based access uses `requireRole('admin')` middleware
- Refresh tokens are one-time use (deleted from Redis after use)

**Verification:**
- Ran: `grep -r "verifyToken" src/` to confirm single verification point
- Code locations verified: `src/middleware/auth.ts:23-45` for token verification logic

**Spec impact:**
- Impact classification: N/A (read-only operation)
- Spec updates required: No

**Confidence:**
- High - docs match implementation; verified token flow in code
