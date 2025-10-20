# Changelog

All notable changes to ConvoSync Plugin will be documented in this file.

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
