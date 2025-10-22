# ConvoSync Plugin for Claude Code

**Sync your coding sessions across devices with AI-generated session handoffs**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blue.svg)](https://claude.ai/code)
[![Version](https://img.shields.io/badge/version-1.0.0-brightgreen.svg)](CHANGELOG.md)

> Part of the [ConvoCLI](https://github.com/convocli/convocli) ecosystem

> **🎉 v1.0.0 Release:** Complete architectural redesign! Now uses AI-generated session handoffs stored in git (no cloud storage needed). [See CHANGELOG](CHANGELOG.md) for details.

---

## The Problem

You're working with Claude Code on your desktop. You have to leave, but get an idea on the subway. You pull out your phone - but Claude doesn't know what you were working on.

**ConvoSync solves this.**

---

## What is ConvoSync Plugin?

A **minimal Claude Code plugin** that syncs your coding sessions across devices using AI-generated handoffs.

- Desktop → Mobile → Laptop workflow
- Claude writes session summaries for you
- Stored in your git repository (no cloud setup!)
- Simple two-command workflow (or optionally three)
- Captures code AND conversation context

## Quick Example

```bash
# On desktop
$ claude-code
> Working on OAuth feature...
> /convosync:save "implementing login"
[Claude auto-generates handoff if needed]
> /convosync:save "implementing login"
✓ Handoff saved to git

# On phone (5 minutes later)
$ claude-code
> /convosync:resume
✓ Loaded handoff from desktop!
> [Continue with full context]
```

---

## Features

**AI-Generated Session Handoffs**
- Claude creates structured summaries of your work
- Captures what you're doing, progress, decisions, and context
- Human-readable markdown format
- Includes non-code context (like user preferences!)

**Git-Based Sync**
- No cloud storage setup required
- Uses your existing git repository
- Fast and reliable
- Complete privacy (stays in your repo)

**Smart Multi-Device Support**
- Works with unlimited devices
- Automatic cleanup prevents file bloat
- Each device keeps one handoff
- See context from all other devices

**Context Preservation**
- **THE PIZZA TEST WORKS!** If you mention your favorite pizza on desktop, Claude will remember it on mobile
- Structured sections: Current Task, Progress, Key Decisions, Important Context, Next Steps, Files Modified, Open Questions
- Time ago formatting ("3 hours ago")

---

## Installation

### Prerequisites

1. **Claude Code** installed ([download](https://claude.ai/code))
2. **Git** repository

That's it! No cloud storage configuration needed.

### Install from Claude Code Marketplace

```bash
# In Claude Code
/plugin marketplace add convocli/convosync-plugin

# Browse and install
/plugin
# Select "Browse Plugins" → "convosync" → "Install"
```

### Manual Install

```bash
# Clone this repo
git clone https://github.com/convocli/convosync-plugin
cd convosync-plugin

# Copy commands to your project
mkdir -p .claude/commands
cp commands/*.md .claude/commands/

# Or install globally (for all projects)
mkdir -p ~/.claude/global-commands
cp commands/*.md ~/.claude/global-commands/

# In each project, create symlinks:
ln -s ~/.claude/global-commands/*.md .claude/commands/
```

---

## Usage

### Primary Workflow (2 Commands)

#### Step 1: `/convosync:save` - Save Session

Save your work with an AI-generated handoff:

```
/convosync:save "your commit message"
```

What happens:
1. **Auto-generates handoff if needed** - If no draft exists, Claude will generate one automatically
2. Reads the handoff draft
3. Appends to `.convosync/session-handoff.md` with metadata (device, timestamp, commit, branch)
4. Commits code changes and handoff to git
5. Pushes to remote repository
6. Cleans up draft file

**First run (no handoff):**
```
/convosync:save "implementing OAuth"
→ No draft found, generating handoff...
→ Please generate handoff (instructions shown)
[Claude generates and saves handoff]
/convosync:save "implementing OAuth"
✓ Handoff saved!
```

**Subsequent runs (handoff exists):**
```
/convosync:save "added error handling"
✓ Using existing handoff
✓ Saved to git!
```

#### Step 2: `/convosync:resume` - Resume on Another Device

On your other device, restore the context:

```
/convosync:resume
```

What happens:
1. Pulls latest code and handoff file from git
2. Detects your device ID
3. Parses all handoffs
4. **Removes your old handoffs** (keeps only latest from this device)
5. **Displays handoffs from OTHER devices** in the current conversation
6. Claude can now reference the handoffs!

### Optional: Pre-Generate Handoff

Want to review the handoff before committing? Use the generate command first:

```
/convosync:generate-handoff
```

Claude will create a handoff with:
- **Current Task:** What you're working on
- **Progress So Far:** What's been completed (✅) and in-progress (⏳)
- **Key Decisions Made:** Important technical/design decisions
- **Important Context:** Non-code context (user preferences, requirements, assumptions)
- **Next Steps:** What to do next
- **Files Modified:** Changed files with descriptions
- **Open Questions:** Unresolved issues

Then review `.convosync/session-handoff-draft.md` and run `/convosync:save` when ready.

**Output:**
```
💾 ConvoSync: Saving session...

→ Device: desktop
✓ Found handoff draft
✓ Handoff appended to .convosync/session-handoff.md
→ Committing code and handoff...
  [main abc123d] implementing OAuth login
→ Pushing to remote...
  Pushed successfully

✓ Code committed: abc123d
✓ Handoff saved from device: desktop

╔════════════════════════════════════════════════════════════════════╗
║ ✅ SESSION SAVED SUCCESSFULLY!                                     ║
╚════════════════════════════════════════════════════════════════════╝
```

#### Step 3: `/convosync:resume` - Resume on Another Device

On your other device, restore the context:

```
/convosync:resume
```

What happens:
1. Pulls latest code and handoff file from git
2. Detects your device ID
3. Parses all handoffs
4. **Removes your old handoffs** (keeps only latest from this device)
5. **Displays handoffs from OTHER devices** in the current conversation
6. Claude can now reference the handoffs!

**Output:**
```
🔄 ConvoSync: Resuming session...

→ Pulling latest code and handoffs...
✓ Code pulled: abc123d

→ Device: mobile
→ Found 1 handoff(s)

╔════════════════════════════════════════════════════════════════════╗
║ 📝 SESSION HANDOFFS FROM OTHER DEVICES                             ║
╚════════════════════════════════════════════════════════════════════╝

══════════════════════════════════════════════════════════════════
📱 Handoff 1/1 from: desktop
══════════════════════════════════════════════════════════════════

⏰ 3 hours ago
📌 Commit: abc123d
🌿 Branch: main

### Current Task
Implementing OAuth 2.0 authentication with refresh token support

### Progress So Far
- ✅ Created auth.ts with login/logout/callback routes
- ✅ Implemented OAuth provider integration
- ⏳ Currently implementing refresh token storage

### Key Decisions Made
- Using JWT tokens with 7-day expiry (balanced security vs UX)
- Storing refresh tokens in Redis (faster lookup)

### Important Context
- User's favorite pizza is Margherita (mentioned in conversation)
- Working in TypeScript with Express framework
- Tests will be added after core implementation

### Next Steps
1. Finish implementing token refresh endpoint
2. Add error handling for OAuth failures
3. Write integration tests

### Files Modified
- src/auth.ts (+145, -10) - Added OAuth routes
- src/oauth-provider.ts (+120, new file) - Google OAuth integration

╔════════════════════════════════════════════════════════════════════╗
║ ✅ CONTEXT RESTORED!                                               ║
╚════════════════════════════════════════════════════════════════════╝

Loaded 1 handoff(s) from other device(s).

I can now reference the session context above to continue your work!
```

Now you can ask Claude questions about the previous session:
```
You: What were we working on?
Claude: We were implementing OAuth 2.0 authentication with refresh token support.
       Based on the handoff from your desktop, you completed the auth routes
       and provider integration, and were in the middle of implementing refresh
       token storage in Redis.

You: What is my favorite pizza?
Claude: Your favorite pizza is Margherita - that was mentioned in the Important
       Context section of the handoff! 🍕
```

---

## How It Works

### AI-Generated Handoffs

Instead of trying to sync raw conversation files (which don't work due to Claude's architecture), ConvoSync uses AI-generated summaries:

1. **Claude analyzes** your conversation and code changes
2. **Claude writes** a structured handoff document
3. **Handoff stored** in git repository as markdown
4. **Handoff displayed** as text in next session
5. **Claude reads** the handoff from conversation history

This works because handoffs are just text displayed in the conversation - Claude can see them immediately!

### Smart Multi-Device Cleanup

ConvoSync prevents file bloat with intelligent cleanup:

```
Before Resume (3 handoffs in file):
- Desktop (old) ← will be removed
- Desktop (older) ← will be removed
- Mobile (latest) ← will be kept

After Resume on Desktop:
- Mobile (latest) ← kept (from other device)
- Desktop (new) ← kept (latest from this device)

Result: Always 1 handoff per device in steady state
```

### File Structure

```
.convosync/
├── device-id                    # Your device identifier (e.g., "desktop")
├── session-handoff.md          # All handoffs from all devices
└── session-handoff-draft.md    # Temporary draft (not in git)
```

### The Handoff Format

```markdown
---
## Handoff from desktop
**Timestamp:** 2025-10-22T14:30:00Z
**Commit:** abc123d
**Branch:** main

### Current Task
Brief description of what you're working on

### Progress So Far
- ✅ Completed item
- ⏳ In-progress item

### Key Decisions Made
- Important decision and why

### Important Context
- User preferences
- Requirements
- Assumptions
- Background info

### Next Steps
1. Specific next action
2. Another action

### Files Modified
- file.ts (+50, -10) - description

### Open Questions
- Unresolved question
```

---

## Workflow Examples

### Desktop → Mobile

```bash
# Desktop: Working on a feature
$ claude-code
You: Let's implement user authentication with OAuth
Claude: I'll help you implement OAuth. Let me start by...
[working together...]
You: I need to catch my train. Let's save this.

# Save to git (auto-generates handoff)
You: /convosync:save "OAuth halfway done, need refresh tokens"
[No draft found - Claude generates handoff automatically]
You: /convosync:save "OAuth halfway done, need refresh tokens"
✓ Handoff saved from device: desktop

# On the train (phone)
$ claude-code
You: /convosync:resume
✓ Loaded handoff from desktop!
✓ Context restored!

You: Let's continue with the refresh token logic
Claude: Based on the handoff from your desktop, you implemented
        the basic OAuth flow and were about to add refresh token
        support. Let me help you with that...
```

### Mobile → Laptop

```bash
# Phone: Quick bug fix
$ claude-code
You: There's a bug in the login redirect
Claude: Let me fix that...
[fix applied]

You: /convosync:save "fixed login redirect bug"
[Claude generates handoff automatically]
You: /convosync:save "fixed login redirect bug"
✓ Handoff saved

# Later on laptop
$ claude-code
You: /convosync:resume
✓ Restored handoff from mobile!

You: Great! Now let's add tests for this fix
Claude: [Has full context of the bug fix from mobile]
        Let me write comprehensive tests...
```

### 3-Device Workflow

```bash
Desktop:
  /convosync:save "implemented core OAuth"
  [Handoff auto-generated]
  /convosync:save "implemented core OAuth"
  ✓ Saved

Mobile (later):
  /convosync:resume  ← Sees desktop's handoff
  [work on mobile]
  /convosync:save "added error handling"
  [Handoff auto-generated]
  /convosync:save "added error handling"
  ✓ Saved

Laptop (even later):
  /convosync:resume  ← Sees both desktop AND mobile handoffs
  [Has complete context from both devices]
```

---

## Troubleshooting

### First Time Setup

**Q: Which device should I run this on first?**

A: Start on whichever device you're currently working on. The first `/convosync:save` will create the `.convosync/` directory and handoff file.

**Q: Do I need to configure anything?**

A: No! If you have git configured, you're ready to go. The plugin will auto-detect your device hostname and prompt for a friendly name if needed.

### Common Issues

**"No handoffs found"**

This is normal on first run. Create one:
1. `/convosync:generate-handoff`
2. Ask Claude to generate the handoff
3. `/convosync:save "your message"`

**"No handoffs from other devices"**

You haven't saved from another device yet. The resume command is working, but there's nothing to restore yet.

**Git conflicts in session-handoff.md**

Rare but possible if you save simultaneously from two devices:
1. `git pull` to get conflicts
2. Manually resolve (keep both handoffs)
3. Commit the merge
4. Continue normally

**Device ID prompt every time**

The device ID file isn't being committed to git. Make sure `.convosync/device-id` is committed:
```bash
git add .convosync/device-id
git commit -m "add device id"
git push
```

### The Pizza Test

Want to verify ConvoSync is working? Try the pizza test:

```bash
# Device 1
You: By the way, my favorite pizza is Margherita
Claude: Good to know!
You: /convosync:generate-handoff
Claude: [Includes "favorite pizza is Margherita" in Important Context]
You: /convosync:save "added auth feature"

# Device 2
You: /convosync:resume
[Handoff displays with "favorite pizza is Margherita"]
You: What is my favorite pizza?
Claude: Your favorite pizza is Margherita! ✅
```

If Claude can answer the pizza question, ConvoSync is working perfectly!

---

## Advanced Usage

### Customizing Handoff Sections

Edit `commands/generate-handoff.md` to modify what Claude includes:
- Add custom sections
- Change formatting
- Adjust instructions

### Installing Globally

```bash
# Install once globally
mkdir -p ~/.claude/global-commands
cp commands/*.md ~/.claude/global-commands/

# In each project, create symlinks
cd your-project
mkdir -p .claude/commands
ln -s ~/.claude/global-commands/*.md .claude/commands/
```

### Ignoring the Draft File

Add to `.gitignore`:
```
.convosync/session-handoff-draft.md
```

This prevents the temporary draft from cluttering git.

---

## Comparison with v0.2.x

### What Changed?

**v0.2.1 (Old Approach):**
- ❌ Tried to sync raw conversation files
- ❌ Required rclone + cloud storage setup
- ❌ Context didn't actually restore (RAM vs Disk problem)
- ❌ Pizza test failed
- ❌ Complex architecture

**v1.0.0 (New Approach):**
- ✅ AI-generated session handoffs
- ✅ Uses git only (no cloud setup!)
- ✅ Context actually works
- ✅ Pizza test passes
- ✅ Simple architecture

### Migration from v0.2.x

There is no migration path. v1.0.0 is a complete redesign:

1. Update to v1.0.0
2. Old cloud-stored sessions are abandoned
3. Start fresh with the new workflow

The breaking change is worth it - v1.0.0 actually works!

---

## FAQ

**Q: How big do handoff files get?**

A: Each handoff is ~1-3 KB of markdown. With smart cleanup, you'll have exactly one handoff per device. Three devices = ~3-9 KB total.

**Q: Can I use this with private repositories?**

A: Yes! Handoffs are stored in your git repository alongside your code. If your repo is private, handoffs are private too.

**Q: What if I forget to run /convosync:save?**

A: Your code changes are still safe (git handles that). You just won't have a handoff for the next device. Run `/convosync:generate-handoff` and `/convosync:save` before switching.

**Q: Can Claude generate handoffs in other languages?**

A: Yes! Ask Claude to generate the handoff in your preferred language. The structure is the same, just translated.

**Q: How does this compare to Claude Code Web?**

A: Claude Code Web doesn't sync conversation context across devices either. ConvoSync solves this with AI-generated handoffs.

**Q: Do I need to commit the handoffs?**

A: Yes! The `/convosync:save` command automatically commits handoffs to git. That's how they sync across devices.

---

## Roadmap

**v1.0 (Current)** - AI Handoffs
- [x] AI-generated session summaries
- [x] Git-based sync
- [x] Smart multi-device cleanup
- [x] Context preservation (pizza test!)

**v1.1** - Enhancements
- [ ] Handoff history viewer (`/convosync:history`)
- [ ] Device management (`/convosync:devices`)
- [ ] Custom handoff templates
- [ ] Handoff search/filter

**v1.2** - Advanced
- [ ] Automatic handoff generation on save
- [ ] Diff view between handoffs
- [ ] Handoff export (PDF, markdown)
- [ ] Team collaboration features

**v2.0** - Real-time Sync
- [ ] Live session sharing
- [ ] Collaborative coding with shared handoffs
- [ ] Web dashboard
- [ ] Mobile app integration

---

## Related Projects

- **[ConvoCLI](https://github.com/convocli/convocli)** - Mobile terminal for Android
- **[ConvoSync](https://github.com/convocli/convosync)** - Backend service for production
- **[Docs](https://github.com/convocli/docs)** - Documentation and guides

---

## Contributing

Contributions welcome! Areas for improvement:

- Better handoff templates
- Additional metadata tracking
- Conflict resolution UI
- Tests and documentation
- Translation support

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

## Acknowledgments

- **Claude Code** - Amazing AI coding assistant that makes this possible
- **Git** - Reliable sync foundation
- **ConvoCLI Project** - Vision of coding anywhere, anytime
- **The User** - Who persistently tested the "pizza test" and helped discover the solution!

---

## Creator

Created by the [ConvoCLI team](https://github.com/convocli)

Part of the mission to enable developers to code anywhere, on any device.

---

## Support

- **Issues:** [Report bugs](https://github.com/convocli/convosync-plugin/issues)
- **Discussions:** [Ask questions](https://github.com/convocli/convosync-plugin/discussions)
- **Docs:** [ConvoCLI Documentation](https://github.com/convocli/docs)

---

<div align="center">

**[⬆ Back to Top](#convosync-plugin-for-claude-code)**

Code anywhere, anytime - with ConvoSync

*Now with AI-generated handoffs that actually work!*

</div>
