# Save ConvoSync Session

Save current coding session with AI-generated handoff for cross-device sync.

**What this does:**
1. Reads the session handoff draft (created by /convosync:generate-handoff)
2. Appends it to .convosync/session-handoff.md with metadata
3. Commits code changes and handoff to git
4. Pushes to remote repository

**Prerequisites:**
- Run `/convosync:generate-handoff` first to create the handoff draft
- Claude should have saved the handoff to `.convosync/session-handoff-draft.md`

**Usage:**
```
/convosync:save "your commit message"
```

**Execute the save process:**

```bash
python3 << 'SAVE_SCRIPT'
import subprocess
import sys
from pathlib import Path
from datetime import datetime
import re

# Get commit message from arguments
commit_msg = ' '.join(sys.argv[1:]) if len(sys.argv) > 1 else "WIP: sync session"

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
    print("│ ❌ NO HANDOFF DRAFT FOUND                                      │")
    print("└────────────────────────────────────────────────────────────────┘")
    print()
    print("Please run /convosync:generate-handoff first to create a handoff.")
    print()
    print("Steps:")
    print("  1. Run: /convosync:generate-handoff")
    print("  2. Ask Claude to generate the handoff")
    print("  3. Claude will save it to .convosync/session-handoff-draft.md")
    print("  4. Run: /convosync:save \"your message\"")
    print()
    sys.exit(1)

handoff_content = draft_file.read_text().strip()
print("✓ Found handoff draft")
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
2. ✓ Reads handoff draft created by generate-handoff
3. ✓ Appends handoff to .convosync/session-handoff.md with metadata
4. ✓ Commits code changes and handoff
5. ✓ Pushes to remote repository
6. ✓ Cleans up draft file

**Example:**
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
