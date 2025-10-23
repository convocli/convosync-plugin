# ConvoSync Plugin for Claude Code

**Sync your coding sessions across devices with AI-generated handoffs**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blue.svg)](https://claude.ai/code)
[![Version](https://img.shields.io/badge/version-1.0.0-brightgreen.svg)](https://github.com/convocli/convosync-plugin/blob/main/CHANGELOG.md)

> Switch devices seamlessly - Claude remembers your work context across desktop, laptop, and mobile.

---

## What It Does

ConvoSync lets you work with Claude Code on one device, then continue exactly where you left off on another device. Claude generates a structured handoff document that captures:

- What you're working on
- Progress made and key decisions
- Environment setup (dependencies, env vars, services)
- Blockers and known issues
- Debug context if troubleshooting
- Next steps

Everything syncs through git - no cloud storage setup needed.

---

## Features

- **AI-Generated Handoffs** - Claude creates structured session summaries
- **Git-Based Sync** - Uses your existing repository, no external services
- **Multi-Device Support** - Works with unlimited devices, automatic cleanup
- **Complete Context** - Captures code AND conversation context
- **Privacy First** - Everything stays in your git repository

---

## Installation

### Prerequisites

- Claude Code installed
- Git repository

### Install via Plugin Marketplace

The easiest way to install ConvoSync:

```bash
# Add the ConvoCLI marketplace
/plugin marketplace add convocli/convosync-plugin

# Install ConvoSync
/plugin install convosync@convocli-marketplace
```

Or use the interactive browser:

```bash
/plugin
# Navigate to "Browse plugins" → "convocli-marketplace" → "convosync" → "Install"
```

That's it! The commands are now available in Claude Code.

### Alternative: Manual Installation

For plugin development or if you prefer manual installation:

```bash
git clone https://github.com/convocli/convosync-plugin
cd convosync-plugin
mkdir -p .claude/commands
cp commands/*.md .claude/commands/
```

---

## Usage

### Simple Workflow (2 Commands)

**1. Save your work:**

```bash
/convosync:save "your commit message"
```

Or simply:

```bash
/convosync:save
```

If you omit the message, ConvoSync auto-generates a commit message from your handoff's "Current Task". On first run, Claude will generate a handoff automatically. Then run the command again to commit.

**2. Resume on another device:**

```bash
/convosync:resume
```

Claude displays the handoff from your other device - full context restored!

### Example Workflow

```bash
# On desktop
$ claude-code
You: Let's implement user authentication
Claude: I'll help you with that...
[working together...]

You: /convosync:save "added OAuth login"
[Claude generates handoff]
You: /convosync:save "added OAuth login"
✓ Saved to git

# Later on mobile
$ claude-code
You: /convosync:resume
✓ Handoff loaded from desktop

You: What were we working on?
Claude: We were implementing OAuth authentication.
        You completed the login routes and are working
        on refresh token support. I can continue from here!
```

### Optional: Pre-Generate Handoff

Want to review the handoff before committing?

```bash
/convosync:generate-handoff
[Review .convosync/session-handoff-draft.md]
/convosync:save "your message"
```

---

## What Gets Synced

Each handoff includes:

- **Current Task** - What you're working on
- **Progress** - Completed (✅) and in-progress (⏳) items
- **Key Decisions** - Technical choices and why
- **Important Context** - User preferences, requirements, assumptions
- **Blockers** - What's blocking progress
- **Environment** - Dependencies, env vars, services needed
- **Known Issues** - Shortcuts, TODOs, workarounds
- **Debug Context** - Errors, reproduction steps, attempts
- **Next Steps** - What to do next
- **Files Modified** - Changed files with descriptions
- **Open Questions** - Unresolved issues

---

## How It Works

**Simple architecture:**

1. Claude analyzes your conversation and code
2. Claude generates a structured markdown handoff
3. Handoff saved to `.convosync/session-handoff.md` in your git repo
4. Commit and push to remote
5. On another device, pull and run `/convosync:resume`
6. Claude displays the handoff in the conversation
7. Claude can now reference the handoff to continue your work

**Smart cleanup:**
- Each device keeps one handoff
- Old handoffs from the same device are automatically removed
- All handoffs from other devices are preserved
- Result: 1 handoff per device, scales to unlimited devices

**File size:**
- Full conversation: 2-5 MB
- Handoff: 2-4 KB
- **99.9% compression** through AI summarization

---

## Troubleshooting

**"No handoff draft found"**

This is normal on first run. The command will prompt Claude to generate one. Run `/convosync:save` again after Claude creates it.

**"No handoffs from other devices"**

You haven't saved from another device yet. Save a handoff on one device, push to git, then resume on another.

**Git conflicts**

If two devices save simultaneously:
1. `git pull` to see conflicts
2. Manually resolve (keep both handoffs)
3. Commit and continue

**Missing environment setup**

Check the "Environment/Setup" section of the handoff - it lists all dependencies, env vars, and services needed.

---

## File Structure

```
your-project/
├── .convosync/
│   ├── device-id                    # Your device name
│   ├── session-handoff.md          # All handoffs (git-tracked)
│   └── session-handoff-draft.md    # Temporary (gitignored)
├── .claude/
│   └── commands/
│       ├── generate-handoff.md
│       ├── save.md
│       └── resume.md
```

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

## Support

- **Issues:** [GitHub Issues](https://github.com/convocli/convosync-plugin/issues)
- **Documentation:** [CHANGELOG.md](CHANGELOG.md)
- **Repository:** [https://github.com/convocli/convosync-plugin](https://github.com/convocli/convosync-plugin)

---

<div align="center">

**Code anywhere, anytime - with ConvoSync**

Part of the [ConvoCLI](https://github.com/convocli) ecosystem

</div>
