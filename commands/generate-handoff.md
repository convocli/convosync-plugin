# Generate Session Handoff

Generate a comprehensive session handoff document to sync context across devices.

**What this does:**
Prompts Claude to generate a structured summary of the current work session, including:
- What you're working on
- Progress made
- Key decisions
- Important context (including non-code details!)
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
