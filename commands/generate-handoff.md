# Generate Session Handoff

Generate a comprehensive session handoff document to sync context across devices.

**What this does:**
Prompts Claude to generate a structured summary of the current work session, including:
- What you're working on
- Progress made
- Key decisions
- Important context (including non-code details!)
- Blockers and dependencies
- Environment setup changes
- Known issues and technical debt
- Debug/error context
- Next steps

**Usage:**
```
/convosync:generate-handoff
```

**Execute:**

```bash
cat << 'HANDOFF_INSTRUCTIONS'
╔══════════════════════════════════════════════════════════════════════╗
║                   SESSION HANDOFF GENERATION                          ║
╚══════════════════════════════════════════════════════════════════════╝

Please generate a comprehensive session handoff document with the following
sections. This will be used to sync context when switching to another device.

────────────────────────────────────────────────────────────────────────

### Current Task
Brief description of what we're currently working on.

### Progress So Far
List of accomplishments in this session:
- ✅ Use checkmark for completed items
- ⏳ Use hourglass for in-progress items
- Be specific about what was done

### Key Decisions Made
Important technical or design decisions that were made:
- What was decided
- Why it was decided that way
- Any trade-offs considered

### Important Context
Any non-code context that's important to preserve:
- User preferences or facts mentioned in conversation
- Constraints or requirements discussed
- Assumptions made
- Background information
- Anything I said that isn't in the code but is important

### Blockers/Waiting On
What's blocking progress or what we're waiting for:
- External dependencies (API keys, permissions, etc.)
- Waiting on other teams or people
- Third-party service issues
- Missing requirements or unclear specifications
- If nothing is blocking, write "None - ready to proceed"

### Environment/Setup
Changes to development environment or setup:
- New dependencies installed (npm packages, system libraries, etc.)
- Environment variables added or changed
- Configuration file changes
- Database migrations run
- Services that need to be running (Redis, PostgreSQL, etc.)
- If no changes, write "No environment changes"

### Known Issues/Debt
Technical debt, shortcuts, or known issues:
- Shortcuts taken with file:line references (e.g., "Hardcoded timeout in auth.ts:45")
- TODOs added to code
- Known bugs or issues introduced
- Workarounds implemented
- Things that work but need improvement
- If none, write "No known issues"

### Debug/Error Context
If debugging, include error details:
- Error messages or stack traces
- Steps to reproduce the issue
- What's been tried (failed attempts)
- Current hypothesis about the cause
- If not debugging, write "No active debugging"

### Next Steps
What should be done next (numbered list):
1. Specific next action
2. Another action
3. ...

### Files Modified
List of files changed with brief description:
- filename.ts (+50, -10) - description of changes
- newfile.ts (new file) - description

### Open Questions
Any unresolved questions or pending decisions:
- Question or decision that needs to be made
- Options being considered

────────────────────────────────────────────────────────────────────────

After generating the handoff above, please save it using the Write tool to:

  .convosync/session-handoff-draft.md

Then I'll run /convosync:save to commit it to the repository.

────────────────────────────────────────────────────────────────────────

HANDOFF_INSTRUCTIONS
```

**Example handoff:**
```markdown
### Current Task
Implementing OAuth 2.0 authentication with Google provider and refresh token support

### Progress So Far
- ✅ Created auth.ts with login/logout/callback routes
- ✅ Implemented OAuth provider integration with Google API
- ✅ Added session management using JWT tokens
- ⏳ Currently implementing refresh token storage with Redis

### Key Decisions Made
- Using JWT tokens with 7-day expiry (balanced security vs user experience)
- Storing refresh tokens in Redis instead of PostgreSQL (faster lookup, automatic expiry)
- Google OAuth as initial provider (can add GitHub/Facebook later)
- Session cookies are httpOnly and secure (prevent XSS attacks)

### Important Context
- User mentioned their favorite pizza is Margherita (in passing conversation)
- Working in TypeScript with Express framework
- Tests will be added after core OAuth implementation is complete
- Redis must be running on localhost:6379 for development

### Blockers/Waiting On
- Waiting on production OAuth credentials from DevOps team (ETA: tomorrow)
- Need Redis Cloud account approved for staging environment

### Environment/Setup
- Installed packages: `redis@4.6.0`, `jsonwebtoken@9.0.2`, `@types/jsonwebtoken@9.0.5`
- Added env vars: `REDIS_URL`, `JWT_SECRET`, `OAUTH_CLIENT_ID`, `OAUTH_CLIENT_SECRET`
- Run `npm install` and copy `.env.example` to `.env` on new device
- Redis must be running: `docker run -p 6379:6379 redis` or use local install

### Known Issues/Debt
- Session timeout hardcoded to 7 days in auth.ts:67 (TODO: move to config)
- Error handling is basic - needs proper error types and messages
- No token rotation yet (security enhancement for later)
- Refresh token endpoint returns 200 even on partial failures (needs fix)

### Debug/Error Context
No active debugging

### Next Steps
1. Finish implementing token refresh endpoint in auth.ts
2. Add comprehensive error handling for OAuth provider failures
3. Write integration tests for the complete OAuth flow
4. Update API documentation with new endpoints

### Files Modified
- src/auth.ts (+145, -10) - Added OAuth routes and token management
- src/oauth-provider.ts (+120, new file) - Google OAuth integration
- src/session-manager.ts (+85, new file) - JWT session handling
- src/types/session.ts (+45, new file) - TypeScript types for sessions

### Open Questions
- Should we implement token rotation for enhanced security? (leaning yes)
- Maximum number of concurrent sessions per user? (suggested 5)
- Should we log OAuth events for security auditing? (probably yes)
```

**Next:**
After Claude saves the handoff to `.convosync/session-handoff-draft.md`, run:
```
/convosync:save "your commit message"
```
