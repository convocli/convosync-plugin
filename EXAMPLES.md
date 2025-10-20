# ConvoSync Plugin - Usage Examples

Real-world scenarios showing how to use ConvoSync to sync coding sessions.

---

## Example 1: Desktop → Mobile Development

### Scenario
You're implementing a new feature on your desktop. You need to leave for a meeting but want to continue thinking about the problem on your commute.

### Workflow

**On Desktop:**
```bash
$ cd ~/projects/myapp
$ claude-code

You: Let's add user authentication with OAuth
Claude: I'll help you implement OAuth. First, let's set up the auth routes...
[Working together, implementing OAuth routes]
You: Great! Now let's add the token refresh logic
Claude: [Implements refresh token logic]

# Time to leave
You: /save "OAuth routes done, starting refresh tokens"
Claude: Saving session...
✓ Code committed: e8f3a9b
✓ Conversation synced (2.1 MB)
✓ Ready to resume on another device
```

**On Mobile (30 minutes later):**
```bash
$ cd ~/storage/code-projects/myapp
$ claude-code

You: /resume
Claude: Resuming session...
✓ Code pulled: commit e8f3a9b
✓ Conversation restored
✓ Original: "OAuth routes done, starting refresh tokens"
✓ Synced 30 minutes ago
✓ Ready to continue!

You: I've been thinking - should we add rate limiting to the refresh endpoint?
Claude: Great idea! Since we're already working on the refresh token logic, let's add rate limiting...
[Continues with full context of the OAuth implementation]
```

**Result:** Seamlessly continued the conversation with complete context, even though you switched devices.

---

## Example 2: Quick Bug Fix On Mobile

### Scenario
You're away from your desk when a user reports a critical bug. You want to quickly investigate and fix it on your phone.

### Workflow

**On Phone:**
```bash
$ cd ~/storage/code-projects/myapp
$ claude-code

You: There's a bug where users can't log out. Can you help debug this?
Claude: Let me check the logout implementation...
[Investigates the issue]
Claude: Found it! The session cookie isn't being cleared. Here's the fix...
[Implements fix in auth.js:145]

You: Perfect! Let's test this works
Claude: [Adds test case]

You: /save "fixed logout bug - session cookie not clearing"
✓ Synced to commit f4d2c1a
```

**Back at Desktop (later):**
```bash
$ cd ~/projects/myapp
$ claude-code

You: /resume
✓ Restored from commit f4d2c1a
✓ Original: "fixed logout bug - session cookie not clearing"

You: Great fix! Now let's deploy this and add better error handling
Claude: [Has full context of the bug fix, continues with deployment]
```

**Result:** Fixed critical bug on mobile, then seamlessly transitioned to desktop for deployment.

---

## Example 3: Collaborative Debugging

### Scenario
You're pair programming remotely. You want to share the exact conversation state so your colleague has full context.

### Workflow

**You (on desktop):**
```bash
$ claude-code

You: I'm stuck on this performance issue in the data processing pipeline
Claude: Let's profile the code and find the bottleneck...
[Working through performance analysis]

You: /save "investigating performance - narrowed down to DB queries"
✓ Synced to commit a7b3e5d

# Send commit hash to colleague
You: "Hey, pull commit a7b3e5d and run /resume - I've been debugging with Claude"
```

**Colleague (on their machine):**
```bash
$ git fetch
$ git checkout a7b3e5d
$ claude-code

Colleague: /resume
✓ Conversation restored
✓ Original: "investigating performance - narrowed down to DB queries"

Colleague: I see you found the N+1 query problem. Let's add eager loading
Claude: [Has full context of the debugging session, continues where you left off]
```

**Result:** Perfect context transfer between team members.

---

## Example 4: Multi-Day Feature Development

### Scenario
You're working on a complex feature over several days, switching between devices based on where you are.

### Day 1 - Desktop Evening

```bash
You: Let's build a new analytics dashboard
Claude: [Starts implementation]
You: /save "analytics dashboard - basic layout done"
```

### Day 2 - Phone Morning Commute

```bash
You: /resume
You: Let's add the chart components
Claude: [Continues with charts]
You: /save "added chart components, need data integration"
```

### Day 2 - Desktop Afternoon

```bash
You: /resume
You: Now let's connect to the analytics API
Claude: [Integrates API with full context of previous work]
You: /save "API integrated, testing remaining"
```

### Day 3 - Tablet (Couch Coding)

```bash
You: /resume
You: Final touches - let's add loading states and error handling
Claude: [Completes the feature with full context of 3 days of work]
You: /save "analytics dashboard complete!"
```

**Result:** Worked on complex feature across 4 different sessions on 3 different devices, maintaining perfect context throughout.

---

## Example 5: Experimental Branch Work

### Scenario
You want to try an experimental approach without losing your current work.

### Workflow

```bash
# Save current work
You: /save "main feature implementation in progress"
✓ Synced to commit main_abc123

# Create experimental branch
$ git checkout -b experiment
You: Let's try a completely different approach using WebSockets instead of polling
Claude: [Implements experimental WebSocket version]
You: /save "experimental WebSocket implementation"
✓ Synced to commit exp_def456

# Compare results
$ git checkout main
You: /resume
✓ Restored original polling implementation

$ git checkout experiment
You: /resume
✓ Restored experimental WebSocket version
```

**Result:** Can easily switch between different approaches while maintaining separate conversation contexts for each.

---

## Example 6: Code Review Preparation

### Scenario
You're preparing a pull request and want to document your implementation decisions.

### Workflow

```bash
You: Let's implement the new payment integration
Claude: [Implements payment system]
You: Why did we choose Stripe over PayPal?
Claude: We chose Stripe because...
[Discussion of architecture decisions]

You: /save "payment integration complete - used Stripe for better API, documented decisions"
✓ Synced to commit payment_feature

# Later, during code review
Reviewer: "Why Stripe?"
You: *pulls up the conversation* "Here's the full discussion we had..."
```

**Result:** Full documentation of implementation decisions preserved in the conversation.

---

## Tips & Best Practices

### Save Often
```bash
# Good practice: Save at logical checkpoints
/save "completed user model"
/save "API routes working"
/save "tests passing"

# Not recommended: Only saving at end of day
/save "did a bunch of stuff"
```

### Use Descriptive Messages
```bash
# Good
/save "fixed race condition in order processing - added transaction lock"

# Less useful
/save "bug fix"
```

### Resume Before Making Changes
```bash
# Always resume first when switching devices
$ claude-code
> /resume  # Get latest context
> [Now start working]
```

### Check Git Status
```bash
# Before /save, make sure you're on the right branch
$ git status
$ git branch
$ /save "feature complete"
```

---

## Troubleshooting Examples

### Forgot to Save Before Switching
```bash
# On Desktop: Forgot to /save
# On Phone: /resume gives old conversation

# Solution: Go back to desktop and /save
# Then /resume on phone will work
```

### Working on Wrong Branch
```bash
# Saved on feature-a branch
# Accidentally resumed on feature-b branch

# Solution:
$ git checkout feature-a
$ /resume  # Now gets the correct conversation
```

### Conversation Too Large to Upload
```bash
# If conversation is very large (>10MB)

# The /save command handles this, but you can check:
$ ls -lh ~/.claude/projects/*/current.jsonl

# Future: Delta compression will reduce this by 96%
```

---

## Advanced Workflows

### Multiple Projects
```bash
# Each project has its own conversations
$ cd ~/project-a
$ /save "working on project A"

$ cd ~/project-b
$ /save "working on project B"

# Conversations are isolated per project
```

### Team Workflow
```bash
# Morning standup
You: /resume  # Get latest from yesterday
You: /save "morning standup - switching to bug fixes"

# Share specific conversation with teammate
You: Send commit hash to team
Teammate: git pull && /resume
```

---

## Next Steps

- See [README.md](README.md) for installation
- See [Troubleshooting](README.md#troubleshooting) for common issues
- Join [Discussions](https://github.com/convocli/convosync-plugin/discussions) to share your workflows!
