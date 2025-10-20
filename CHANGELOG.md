# Changelog

All notable changes to ConvoSync Plugin will be documented in this file.

## [0.2.0] - 2025-10-20

### Added

#### Context Display in Resume Command (MAJOR FEATURE)
**The game-changing feature that makes cross-device conversation continuation actually work!**

**Problem Solved:** In v0.1.1, the resume command successfully merged conversation files on disk, but Claude couldn't access them because:
- Conversation context lives in RAM, not on disk
- No API to reload conversation mid-session
- File changes don't affect active Claude context
- User had to manually restart Claude Code (poor UX)

**Solution:** Display the old conversation IN the current conversation so Claude can see it immediately.

**What's New:**
- `/convosync:resume` now displays the last 30 messages from the restored conversation
- Messages appear as formatted output in the current session
- Claude can read and reference the conversation history
- No restart required - context available immediately!

**User Experience:**

Before (v0.1.1):
```
/resume
✓ Merged: 809 old + 521 current = 1330 messages
✓ Session restored!

User: "What is my favorite pizza?"
Claude: "I don't know" ❌  (context in file, not in RAM)
```

After (v0.2.0):
```
/resume
✓ Merged: 809 old + 521 current = 1330 messages

======================================================================
📝 RESTORED CONVERSATION CONTEXT
======================================================================

Session: "implementing OAuth login"
Messages: 809 restored from cloud
Timestamp: 2025-10-20 12:30

RECENT CONVERSATION HISTORY (last 30 messages):
----------------------------------------------------------------------

[1] USER:
    Let's add refresh token logic

...

[15] USER:
    By the way, my favorite pizza is Margherita

[16] ASSISTANT:
    Good to know! Margherita is a classic choice...

...

======================================================================
✅ Context restored! I can now reference the conversation above.
======================================================================

User: "What is my favorite pizza?"
Claude: "Your favorite pizza is Margherita! I can see from
        message [15] in the restored context above." ✅
```

**Technical Details:**
- Hybrid approach: Displays context + maintains file merge
- Shows last 30 messages (configurable)
- Truncates long messages for readability (300 char limit)
- Skips empty messages
- Preserves message roles (USER/ASSISTANT)
- Formatted for easy reading

**Impact:**
- ✅ Cross-device workflow actually works now!
- ✅ No manual restart needed
- ✅ Context immediately accessible
- ✅ Automated single-command operation
- ✅ Supports high-frequency device switching
- ✅ Perfect for desktop ↔ mobile workflows

**Requirements Met:**
- Automated: Single `/resume` command ✅
- Bidirectional: Works both ways ✅
- Preserves code + conversation ✅
- Fast and reliable ✅
- No manual steps ✅

This is the feature that makes ConvoSync fulfill its original promise!

## [0.1.1] - 2025-10-20

### Fixed

#### Critical: Resume command not executing (conversation merge failed)
**Problem:** The `/convosync:resume` command was not actually executing the merge script. Instead, Claude Code interpreted the markdown as instructions and implemented a simplified version that only copied files without merging conversations.

**Root Cause:** The `commands/resume.md` file had bash commands before the Python heredoc in the same code block:
```bash
# Bad structure (OLD):
```bash
# Get the plugin scripts directory
PLUGIN_DIR="..."
python3 << 'RESUME_SCRIPT'
[Python code]
RESUME_SCRIPT
```

This caused Claude Code to execute commands separately instead of running the complete script.

**Fix:** Restructured `commands/resume.md` to match `commands/save.md` pattern - start immediately with Python heredoc:
```bash
# Good structure (NEW):
```bash
python3 << 'RESUME_SCRIPT'
[Python code]
RESUME_SCRIPT
```

**Impact:**
- ✅ Resume script now executes as a single atomic operation
- ✅ Conversation merge logic actually runs
- ✅ Old conversation messages properly merged into current session
- ✅ Context is fully restored (e.g., remembers previous discussions)

**User-Visible Symptoms (Before Fix):**
- Resume command appeared to work (showed "✓ Session restored")
- But asking questions about previous conversation returned "I don't know"
- Old conversation file was downloaded but not merged
- User stayed in new conversation instead of restored one

**User-Visible Behavior (After Fix):**
- Resume command executes merge script
- Old messages prepended to current conversation
- Session IDs unified
- Parent UUID chain linked
- Full context available - Claude remembers previous discussions

#### Subprocess bug in save command
**Problem:** The `/convosync:save` command crashed when getting git remote URL with error:
```
ValueError: check argument not allowed, it will be overridden.
```

**Root Cause:** Line 36 in `commands/save.md` used invalid Python:
```python
# Bad (crashed):
repo_url = subprocess.check_output(["git", "config", "--get", "remote.origin.url"], check=False).decode().strip()
```

The `subprocess.check_output()` function does not accept a `check` parameter - it always checks by design.

**Fix:** Replaced with `subprocess.run()` which properly supports error handling:
```python
# Good (works):
result = subprocess.run(["git", "config", "--get", "remote.origin.url"], capture_output=True, text=True)
repo_url = result.stdout.strip() or "unknown"
```

**Impact:**
- ✅ Save command no longer crashes when git remote is missing/invalid
- ✅ Gracefully falls back to "unknown" for repo URL
- ✅ Conversation upload completes successfully

**User-Visible Symptoms (Before Fix):**
- Save command partially worked (code committed and pushed)
- Then crashed with ValueError
- Conversation never uploaded to cloud
- Had to re-run save command to complete sync

**User-Visible Behavior (After Fix):**
- Save command completes in single execution
- Handles missing git remote gracefully
- All steps complete: commit → push → upload conversation → upload metadata

## [0.1.0] - 2025-10-19

### Added
- Initial release
- `/convosync:save` command to save code + conversation
- `/convosync:resume` command to restore session
- Conversation merge logic for seamless context restoration
- rclone integration for cloud storage
- Support for Google Drive, Dropbox, and other cloud providers
- Session metadata linking conversation ↔ git commit
- Cross-device sync (desktop ↔ mobile)

### Documentation
- README with installation instructions
- EXAMPLES with workflow demonstrations
- Inline command documentation
