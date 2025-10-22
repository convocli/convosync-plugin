# Save ConvoSync Session

Save current coding session with AI-generated handoff for cross-device sync.

**What this does:**
1. Checks if handoff draft exists - if not, automatically prompts Claude to generate one
2. Reads the session handoff draft
3. Appends it to .convosync/session-handoff.md with metadata
4. Commits code changes and handoff to git
5. Pushes to remote repository

**Usage:**
```
/convosync:save "your commit message"
```

Or omit the message to auto-generate from handoff:
```
/convosync:save
```

**Notes:**
- **Commit message is optional** - If omitted, ConvoSync extracts the "Current Task" from the handoff to create a meaningful commit message
- If no handoff draft exists, Claude will generate one automatically
- You can also pre-generate a handoff using `/convosync:generate-handoff` to review it first
- The handoff captures both code AND conversation context

**Execute the save process:**

```bash
python3 << 'SAVE_SCRIPT'
import subprocess
import sys
from pathlib import Path
from datetime import datetime
import re

# Get commit message from arguments (None if not provided - will auto-generate from handoff)
commit_msg = ' '.join(sys.argv[1:]) if len(sys.argv) > 1 else None

print("💾 ConvoSync: Saving session...")
print()

# ============================================================================
# 1. Get or create device ID
# ============================================================================

def get_or_create_device_id():
    """Get unique device identifier, create if doesn't exist."""
    device_file = Path('.convosync/device-id')

    if device_file.exists():
        return device_file.read_text().strip()

    # Generate device ID from hostname
    try:
        hostname = subprocess.run(['hostname'], capture_output=True, text=True).stdout.strip()
        # Sanitize hostname (remove special chars)
        device_id = re.sub(r'[^a-zA-Z0-9-]', '-', hostname)
    except:
        device_id = 'unknown-device'

    # Prompt if generic hostname
    if device_id.lower() in ['localhost', 'android', 'termux', 'pc', 'unknown-device', '']:
        print("┌────────────────────────────────────────────────────────────────┐")
        print("│ DEVICE IDENTIFICATION                                          │")
        print("└────────────────────────────────────────────────────────────────┘")
        print()
        print(f"Detected hostname: '{device_id}'")
        print()
        print("Please give this device a friendly name")
        print("(e.g., 'desktop', 'mobile', 'laptop', 'work-laptop'):")
        print()
        try:
            user_input = input("Device name: ").strip()
            if user_input:
                device_id = re.sub(r'[^a-zA-Z0-9-]', '-', user_input)
        except:
            pass  # Keep default if input fails
        print()

    # Save device ID
    device_file.parent.mkdir(exist_ok=True)
    device_file.write_text(device_id)
    subprocess.run(['git', 'add', str(device_file)], check=False)

    return device_id

device_id = get_or_create_device_id()
print(f"→ Device: {device_id}")
print()

# ============================================================================
# 2. Check for handoff draft
# ============================================================================

draft_file = Path('.convosync/session-handoff-draft.md')

if not draft_file.exists():
    print("┌────────────────────────────────────────────────────────────────┐")
    print("│ ⚠️  NO HANDOFF DRAFT FOUND - GENERATING NOW                    │")
    print("└────────────────────────────────────────────────────────────────┘")
    print()
    print("No handoff draft found. I'll generate one for you now.")
    print()
    print("=" * 70)
    print("SESSION HANDOFF GENERATION")
    print("=" * 70)
    print()
    print("Please generate a comprehensive session handoff with these sections:")
    print()
    print("### Current Task")
    print("Brief description of what we're currently working on.")
    print()
    print("### Progress So Far")
    print("List of accomplishments:")
    print("- ✅ Use checkmark for completed items")
    print("- ⏳ Use hourglass for in-progress items")
    print()
    print("### Key Decisions Made")
    print("Important technical or design decisions:")
    print("- What was decided")
    print("- Why it was decided that way")
    print()
    print("### Important Context")
    print("Non-code context to preserve:")
    print("- User preferences or facts mentioned")
    print("- Constraints or requirements")
    print("- Assumptions made")
    print()
    print("### Blockers/Waiting On")
    print("What's blocking progress:")
    print("- External dependencies or waiting on others")
    print("- If nothing blocking, write 'None - ready to proceed'")
    print()
    print("### Environment/Setup")
    print("Environment or setup changes:")
    print("- New dependencies installed")
    print("- Env vars added or changed")
    print("- Services that need to be running")
    print("- If no changes, write 'No environment changes'")
    print()
    print("### Known Issues/Debt")
    print("Technical debt or shortcuts:")
    print("- Shortcuts with file:line refs")
    print("- TODOs added to code")
    print("- Known bugs or workarounds")
    print("- If none, write 'No known issues'")
    print()
    print("### Debug/Error Context")
    print("If debugging:")
    print("- Error messages or stack traces")
    print("- Steps to reproduce")
    print("- What's been tried")
    print("- If not debugging, write 'No active debugging'")
    print()
    print("### Next Steps")
    print("What should be done next:")
    print("1. Specific next action")
    print("2. Another action")
    print()
    print("### Files Modified")
    print("List of changed files:")
    print("- filename.ts (+50, -10) - description of changes")
    print()
    print("### Open Questions")
    print("Unresolved questions or pending decisions")
    print()
    print("=" * 70)
    print()
    print("After generating the handoff above, save it to:")
    print("  .convosync/session-handoff-draft.md")
    print()
    print("Then re-run: /convosync:save \"your message\"")
    print()
    sys.exit(0)

handoff_content = draft_file.read_text().strip()
print("✓ Found handoff draft")
print()

# Auto-generate commit message from handoff if not provided
if commit_msg is None:
    try:
        # Extract Current Task section from handoff
        task_match = re.search(r'### Current Task\n(.+?)(?:\n\n|\n###|$)', handoff_content, re.DOTALL)
        if task_match:
            current_task = task_match.group(1).strip()
            # Truncate to 72 chars (git best practice for commit messages)
            if len(current_task) > 72:
                commit_msg = current_task[:69] + "..."
            else:
                commit_msg = current_task
            print(f"→ Auto-generated commit message from handoff")
        else:
            commit_msg = "WIP: sync session"
    except:
        commit_msg = "WIP: sync session"

print()

# ============================================================================
# 3. Get git info
# ============================================================================

try:
    commit_hash = subprocess.run(['git', 'rev-parse', 'HEAD'], capture_output=True, text=True, check=True).stdout.strip()
    branch = subprocess.run(['git', 'rev-parse', '--abbrev-ref', 'HEAD'], capture_output=True, text=True, check=True).stdout.strip()
except subprocess.CalledProcessError:
    print("❌ Not in a git repository")
    print("   ConvoSync requires the project to be in a git repository.")
    sys.exit(1)

timestamp = datetime.utcnow().isoformat() + 'Z'

# ============================================================================
# 4. Format handoff with metadata
# ============================================================================

formatted_handoff = f"""---
## Handoff from {device_id}
**Timestamp:** {timestamp}
**Commit:** {commit_hash}
**Branch:** {branch}

{handoff_content}

"""

# ============================================================================
# 5. Append to main handoff file
# ============================================================================

handoff_file = Path('.convosync/session-handoff.md')
handoff_file.parent.mkdir(exist_ok=True)

# Create file with header if it doesn't exist
if not handoff_file.exists():
    handoff_file.write_text("# ConvoSync Session Handoffs\n\n")

# Append new handoff
with open(handoff_file, 'a') as f:
    f.write(formatted_handoff)

print("✓ Handoff appended to .convosync/session-handoff.md")
print()

# ============================================================================
# 6. Git operations
# ============================================================================

print("→ Committing code and handoff...")
subprocess.run(['git', 'add', '.'], check=False)

try:
    result = subprocess.run(['git', 'commit', '-m', commit_msg], check=True, capture_output=True, text=True)
    # Print first line of commit output
    first_line = result.stdout.split('\n')[0] if result.stdout else ''
    if first_line:
        print(f"  {first_line}")
except subprocess.CalledProcessError as e:
    if 'nothing to commit' in e.stderr.lower():
        print("  No changes to commit")
    else:
        print(f"  Commit failed: {e.stderr}")

print()
print("→ Pushing to remote...")
try:
    subprocess.run(['git', 'push'], check=True, capture_output=True)
    print("  Pushed successfully")
except subprocess.CalledProcessError as e:
    print(f"  ⚠️  Push failed: {e.stderr}")
    print("  You may need to push manually later")

print()

commit_short = subprocess.run(['git', 'rev-parse', '--short', 'HEAD'], capture_output=True, text=True).stdout.strip()

print(f"✓ Code committed: {commit_short}")
print(f"✓ Handoff saved from device: {device_id}")
print()

# ============================================================================
# 7. Cleanup draft
# ============================================================================

try:
    draft_file.unlink()
    print("✓ Draft handoff cleaned up")
except:
    pass

print()
print("╔════════════════════════════════════════════════════════════════════╗")
print("║ ✅ SESSION SAVED SUCCESSFULLY!                                     ║")
print("╚════════════════════════════════════════════════════════════════════╝")
print()
print("To resume on another device:")
print("  1. cd to project directory")
print("  2. git pull")
print("  3. Run: /convosync:resume")
print()
print("The handoff from this device will be visible on other devices,")
print("providing full context of what you worked on.")

SAVE_SCRIPT
```

**What happens:**
1. ✓ Detects or creates device ID
2. ✓ Checks for handoff draft - generates one if missing
3. ✓ Reads handoff draft
4. ✓ Appends handoff to .convosync/session-handoff.md with metadata
5. ✓ Commits code changes and handoff
6. ✓ Pushes to remote repository
7. ✓ Cleans up draft file

**Example (with existing handoff draft):**
```
/convosync:save "implemented OAuth refresh tokens"

💾 ConvoSync: Saving session...

→ Device: desktop
✓ Found handoff draft
✓ Handoff appended to .convosync/session-handoff.md
→ Committing code and handoff...
  [main abc123d] implemented OAuth refresh tokens
→ Pushing to remote...
  Pushed successfully

✓ Code committed: abc123d
✓ Handoff saved from device: desktop
✓ Draft handoff cleaned up

╔════════════════════════════════════════════════════════════════════╗
║ ✅ SESSION SAVED SUCCESSFULLY!                                     ║
╚════════════════════════════════════════════════════════════════════╝
```

**Example (no handoff draft - auto-generates):**
```
/convosync:save "implemented OAuth"

💾 ConvoSync: Saving session...

→ Device: desktop

┌────────────────────────────────────────────────────────────────┐
│ ⚠️  NO HANDOFF DRAFT FOUND - GENERATING NOW                    │
└────────────────────────────────────────────────────────────────┘

No handoff draft found. I'll generate one for you now.

======================================================================
SESSION HANDOFF GENERATION
======================================================================

Please generate a comprehensive session handoff with these sections:
[instructions displayed...]

After generating the handoff above, save it to:
  .convosync/session-handoff-draft.md

Then re-run: /convosync:save "your message"
```

Then after Claude generates the handoff, running `/convosync:save` again will proceed with the commit.
