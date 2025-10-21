# ConvoSync Plugin for Claude Code

> **⚠️ DEVELOPMENT PAUSED - PROJECT NOT WORKING YET**
>
> **Status:** With the recent launch of **Claude Code Web** (web interface for Claude Code with direct GitHub integration), this project's development is **on hold** pending evaluation of Claude Code Web's native conversation sync capabilities.
>
> **Why paused:**
> - Claude Code Web may provide native cross-device conversation sync
> - This could make ConvoSync redundant
> - Waiting to see what Claude Code Web offers before continuing development
>
> **Current state:**
> - Code sync: ✅ Works (via git)
> - Conversation sync: ❌ **Not working** (context display has parsing issues)
> - Not recommended for production use
>
> **For developers/contributors:** See [CHANGELOG.md](CHANGELOG.md) for technical details on what was attempted (v0.1.1 file merge, v0.2.0 context display, v0.2.1 parsing fix) and why it's still not fully functional.

**Sync your coding sessions across devices - continue exactly where you left off**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blue.svg)](https://claude.ai/code)
[![Version](https://img.shields.io/badge/version-0.2.1-brightgreen.svg)](CHANGELOG.md)

> Part of the [ConvoCLI](https://github.com/convocli/convocli) ecosystem

> **🔧 Latest Update (v0.2.1):** Critical bugfix - context display now parses messages correctly! Previous version showed empty output. [See CHANGELOG](CHANGELOG.md) for details.

---

## The Problem

You're working with Claude Code on your desktop. You have to leave, but get an idea on the subway. You pull out your phone - but the code state doesn't match, and the conversation context is lost.

**ConvoSync solves this.**

---

## What is ConvoSync Plugin?

A **minimal Claude Code plugin** that syncs your coding sessions (code + conversation) across devices in seconds.

- Desktop → Mobile workflow
- Atomic sync (code and conversation stay linked)
- Works with any cloud storage (Google Drive, Dropbox, etc.)
- Zero backend required
- Simple slash commands

## Quick Example

```bash
# On desktop
$ claude-code
> Working on OAuth feature...
> /save "implementing login"
✓ Synced to commit abc123

# On phone (5 minutes later)
$ claude-code
> /resume
✓ Restored from commit abc123
✓ Ready to continue!
```

---

## Features

**Atomic Session Sync**
- Code and conversation linked by git commit
- Prevents state mismatches
- Safety checks ensure everything matches

**Lightning Fast**
- Syncs in 5-10 seconds
- Delta compression ready (future)
- Mobile-friendly bandwidth

**Privacy First**
- Your data, your cloud
- Self-hosted option
- No third-party servers required

**Works Everywhere**
- Desktop ↔ Phone ↔ Tablet
- Any git repository
- Any cloud storage

---

## Installation

### Prerequisites

1. **Claude Code** installed ([download](https://claude.ai/code))
2. **Git** repository
3. **Cloud storage** (Google Drive, Dropbox, etc.)
4. **rclone** ([install guide](#setup))

### Option 1: Plugin Command (Recommended)

**Easiest way** - Install directly from Claude Code:

```bash
# In Claude Code
/plugin marketplace add convocli/convosync-plugin

# Then browse and install
/plugin

# Select "Browse Plugins" → "convosync" → "Install"
```

That's it! The `/save` and `/resume` commands are now available.

**Note:** You still need to [configure rclone](#setup) for cloud storage after installing the plugin.

### Option 2: Automated Install Script

```bash
# Clone this repo
git clone https://github.com/convocli/convosync-plugin
cd convosync-plugin

# Run installer
./install.sh

# Follow prompts to:
# 1. Install rclone (if needed)
# 2. Configure cloud storage
# 3. Install commands
```

### Option 3: Manual Install

```bash
# Copy commands to your project
mkdir -p .claude/commands
cp convosync-plugin/commands/*.md .claude/commands/

# Or install globally (for all projects)
mkdir -p ~/.claude/global-commands
cp convosync-plugin/commands/*.md ~/.claude/global-commands/

# Symlink in each project
ln -s ~/.claude/global-commands/*.md .claude/commands/
```

---

## Setup

### 1. Install rclone

**Termux (Android):**
```bash
pkg install rclone
```

**macOS:**
```bash
brew install rclone
```

**Linux:**
```bash
sudo apt install rclone  # Debian/Ubuntu
sudo dnf install rclone  # Fedora
```

**Windows:**
Download from [rclone.org](https://rclone.org/downloads/)

### 2. Configure Cloud Storage

We'll use Google Drive as an example:

```bash
rclone config
```

**Follow the prompts:**

1. `n` - New remote
2. Name: `gdrive`
3. Storage: `drive` (Google Drive)
4. Leave Client ID/Secret blank
5. Scope: `1` (full access)
6. Leave Root folder blank
7. Leave Service account blank
8. Advanced config: `n`
9. Auto config: `n` (on Termux/remote)
10. On another device with browser, run:
    ```bash
    rclone authorize "drive" "eyJzY29wZSI6ImRyaXZlIn0"
    ```
11. Copy the token back to original device
12. Configure as Shared Drive: `n`
13. Confirm: `y`

**Create directory structure:**
```bash
rclone mkdir gdrive:convosync
rclone mkdir gdrive:convosync/conversations
rclone mkdir gdrive:convosync/sessions
```

**Test:**
```bash
rclone lsd gdrive:convosync
# Should show: conversations, sessions
```

### 3. Use the Commands

You're ready! The `/save` and `/resume` commands are now available in Claude Code.

---

## Usage

### `/save` - Save Current Session

Commits your code, uploads the conversation, and links them together.

**Basic usage:**
```
/save "implementing OAuth login"
```

**What it does:**
1. `git add .` - Stage changes
2. `git commit -m "WIP: implementing OAuth login"` - Commit
3. `git push` - Push to remote
4. Get commit hash (e.g., `abc123`)
5. Find current conversation file
6. Upload conversation to cloud
7. Create metadata linking conversation ↔ commit
8. Confirm sync complete

**Output:**
```
✓ Code committed: abc123
✓ Conversation synced (3.2 MB)
✓ Ready to resume on another device
```

### `/resume` - Resume Session

Pulls the latest code and restores the conversation.

**Basic usage:**
```
/resume
```

**What it does:**
1. `git pull` - Get latest code
2. Get current commit hash
3. Download session metadata for this commit
4. Download the saved conversation
5. **Display conversation history in current session** (so Claude can see it!)
6. **Also merge files on disk** (for future reference)
7. Continue seamlessly with full context!

**Output:**
```
🔄 ConvoSync: Resuming session...
✓ Code pulled: commit abc123
✓ Found session: "implementing OAuth login"
✓ Downloaded (2.1MB)
✓ Merged: 850 old + 5 current = 855 total

======================================================================
📝 RESTORED CONVERSATION CONTEXT
======================================================================

Session: "implementing OAuth login"
Messages: 850 restored from cloud
Timestamp: 2025-10-20 12:30

RECENT CONVERSATION HISTORY (last 30 messages):
----------------------------------------------------------------------

[1] USER:
    Let's add refresh token logic

[2] ASSISTANT:
    I'll implement refresh tokens...

...

[25] USER:
    By the way, my favorite pizza is Margherita

[26] ASSISTANT:
    Good to know! Margherita is a classic...

...

======================================================================
✅ Context restored! I can now reference the conversation above.
======================================================================

✅ Session restored successfully!
```

**The Magic: Context Display + File Merge (v0.2.0)**

Instead of just merging files on disk (which Claude can't access), `/resume` now uses a **hybrid approach**:

1. **Displays conversation in current session**
   - Shows last 30 messages as formatted output
   - Claude sees the history and can reference it immediately
   - No restart needed!

2. **Also merges conversation files**
   - Old messages + current messages merged on disk
   - Session IDs unified
   - Parent UUID chain linked
   - Ready for future sessions

**Result:** You get immediate context (from display) AND persistent record (from file merge)!

---

## How It Works

### Atomic Session Sync

```
Session = {
  git_commit: "abc123",
  git_branch: "main",
  git_repo: "https://github.com/user/project",
  conversation_id: "conv_xyz",
  working_dir: "/path/to/project",
  timestamp: 1234567890
}
```

**The key:** Conversation and code are **always linked by commit hash**.

### Cloud Storage Structure

```
gdrive:convosync/
├── conversations/
│   └── conv_xyz.jsonl         # Your conversation
└── sessions/
    └── abc123.json            # Metadata for commit abc123
```

### Safety Guarantees

✅ Can't restore conversation without matching code
✅ Automatic verification on resume
✅ Warns if code/conversation mismatch
✅ Never overwrites without confirmation

---

## Workflow Examples

### Desktop → Mobile

```bash
# Desktop: Working on a feature
$ claude-code
You: Add user authentication
Claude: I'll implement OAuth login...
[working together...]

# Time to catch the train
You: /save "OAuth halfway done, need to add refresh tokens"
✓ Synced to commit abc123

# On the train (phone)
$ claude-code
You: /resume
✓ Restored! Continue from where you left off
You: Now add the refresh token logic
Claude: [continues with full context]
```

### Mobile → Desktop

```bash
# Phone: Quick idea on the go
$ claude-code
You: Quick fix for the login bug
Claude: Here's the fix...
You: /save "fixed login redirect bug"
✓ Synced

# Later at desktop
$ claude-code
You: /resume
✓ Restored
You: Great! Now let's add tests for this fix
Claude: [has full context of the fix]
```

---

## Troubleshooting

### "rclone: command not found"
Install rclone - see [Setup](#setup) section.

### "Failed to create file system for 'gdrive:'"
Run `rclone config` to set up your cloud storage.

### "No session found for current commit"
You haven't run `/save` from this commit yet. Options:
- Run `/save` to create a new session
- Checkout the commit you saved from
- View available sessions: `rclone ls gdrive:convosync/sessions/`

### Conversation not restoring
Check that:
1. You ran `git pull` first
2. Cloud storage is accessible: `rclone lsd gdrive:`
3. Session metadata exists: `rclone ls gdrive:convosync/sessions/`

### Code and conversation out of sync
Always use `/save` before switching devices. The commands ensure atomicity, but only if you save before switching!

---

## Advanced

### Use Different Cloud Storage

**Dropbox:**
```bash
rclone config
# Choose 'dropbox' instead of 'drive'
# Update commands to use 'dropbox:' instead of 'gdrive:'
```

**Self-hosted S3:**
```bash
rclone config
# Choose 's3'
# Enter your S3 endpoint and credentials
```

### Multiple Projects

Install commands per-project or globally:

**Per-project** (default):
```bash
cd your-project
cp convosync-plugin/commands/*.md .claude/commands/
```

**Global** (all projects):
```bash
mkdir -p ~/.claude/global-commands
cp convosync-plugin/commands/*.md ~/.claude/global-commands/

# In each project:
ln -s ~/.claude/global-commands/*.md .claude/commands/
```

### Customize Commands

Edit `commands/save.md` or `commands/resume.md` to:
- Change cloud path (e.g., `gdrive:convosync` → `dropbox:sync`)
- Add custom git hooks
- Modify commit message format
- Add notifications

---

## Roadmap

**v0.1 (Current)** - MVP
- [x] Basic `/save` and `/resume` commands
- [x] rclone integration
- [x] Manual sync workflow

**v0.2** - Improvements
- [ ] Auto-detect cloud provider
- [ ] Better error messages
- [ ] Session listing (`/sessions`)
- [ ] Conflict resolution

**v0.3** - Advanced
- [ ] Delta compression (96% size reduction)
- [ ] Multi-device orchestration
- [ ] Automatic background sync
- [ ] Team collaboration

**v1.0** - Full ConvoSync
- [ ] Integrated backend service
- [ ] Real-time sync
- [ ] Web dashboard
- [ ] Mobile app (ConvoCLI)

---

## Related Projects

- **[ConvoCLI](https://github.com/convocli/convocli)** - Mobile terminal for Android with sync built-in
- **[ConvoSync](https://github.com/convocli/convosync)** - Backend service for production sync
- **[Docs](https://github.com/convocli/docs)** - Documentation and guides

---

## Contributing

Contributions welcome! This is a minimal MVP - lots of room for improvement.

**Ideas for contributions:**
- Support for more cloud providers
- Better error handling
- Session management UI
- Delta compression
- Tests

See [CONTRIBUTING.md](CONTRIBUTING.md) (coming soon) for guidelines.

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

## Acknowledgments

- **Claude Code** - Amazing AI coding assistant
- **rclone** - Swiss Army knife of cloud storage
- **ConvoCLI Project** - Vision of coding anywhere, anytime

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

</div>
