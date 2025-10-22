# Resume ConvoSync Session

Resume work on another device by viewing session handoffs from other devices.

**What this does:**
1. Pulls latest code and handoff file from git
2. Parses handoffs from all devices
3. Cleans up old handoffs from THIS device (keeps latest only)
4. Displays handoffs from OTHER devices in current conversation
5. Commits cleaned handoff file back to git

**Prerequisites:**
- Another device must have run `/convosync:generate-handoff` and `/convosync:save`
- Git repository must be configured

**Usage:**
```
/convosync:resume
```

**Execute the resume process:**

```bash
python3 << 'RESUME_SCRIPT'
import subprocess
import sys
from pathlib import Path
from datetime import datetime, timezone
import re

print("🔄 ConvoSync: Resuming session...")
print()

# ============================================================================
# 1. Git pull
# ============================================================================

print("→ Pulling latest code and handoffs...")
try:
    subprocess.run(["git", "pull"], check=True, capture_output=True)
    commit_short = subprocess.run(['git', 'rev-parse', '--short', 'HEAD'], capture_output=True, text=True).stdout.strip()
    print(f"✓ Code pulled: {commit_short}")
except subprocess.CalledProcessError as e:
    print(f"⚠️  Git pull failed: {e.stderr}")
    print("  Continuing with local version...")

print()

# ============================================================================
# 2. Get device ID
# ============================================================================

def get_or_create_device_id():
    """Get unique device identifier, create if doesn't exist."""
    device_file = Path('.convosync/device-id')

    if device_file.exists():
        return device_file.read_text().strip()

    # Generate device ID from hostname
    try:
        hostname = subprocess.run(['hostname'], capture_output=True, text=True).stdout.strip()
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
# 3. Check for handoff file
# ============================================================================

handoff_file = Path('.convosync/session-handoff.md')

if not handoff_file.exists():
    print("┌────────────────────────────────────────────────────────────────┐")
    print("│ ℹ️  NO HANDOFFS FOUND                                          │")
    print("└────────────────────────────────────────────────────────────────┘")
    print()
    print("No session handoffs found in this repository.")
    print()
    print("This is normal for:")
    print("  • First time using ConvoSync on this project")
    print("  • No other devices have saved sessions yet")
    print()
    print("To create a handoff:")
    print("  1. Run: /convosync:generate-handoff")
    print("  2. Ask Claude to generate the handoff")
    print("  3. Run: /convosync:save \"your message\"")
    print()
    sys.exit(0)

# ============================================================================
# 4. Parse handoff file
# ============================================================================

def parse_handoffs(content):
    """Parse handoff markdown file into structured data."""
    handoffs = []

    # Split on handoff headers (## Handoff from {device})
    sections = re.split(r'^---\s*$', content, flags=re.MULTILINE)

    for section in sections:
        section = section.strip()
        if not section or section.startswith('# ConvoSync'):
            continue

        # Extract device from header
        device_match = re.search(r'^## Handoff from (.+?)$', section, re.MULTILINE)
        if not device_match:
            continue

        device = device_match.group(1).strip()

        # Extract metadata
        timestamp_match = re.search(r'\*\*Timestamp:\*\* (.+?)$', section, re.MULTILINE)
        commit_match = re.search(r'\*\*Commit:\*\* (.+?)$', section, re.MULTILINE)
        branch_match = re.search(r'\*\*Branch:\*\* (.+?)$', section, re.MULTILINE)

        timestamp = timestamp_match.group(1).strip() if timestamp_match else None
        commit = commit_match.group(1).strip() if commit_match else None
        branch = branch_match.group(1).strip() if branch_match else None

        # Extract content (everything after metadata)
        content_start = section.find('**Branch:**')
        if content_start == -1:
            content_start = section.find('**Commit:**')
        if content_start == -1:
            content_start = section.find('**Timestamp:**')

        if content_start != -1:
            # Find end of metadata line
            content_start = section.find('\n', content_start)
            if content_start != -1:
                handoff_content = section[content_start:].strip()
            else:
                handoff_content = ''
        else:
            handoff_content = section

        handoffs.append({
            'device': device,
            'timestamp': timestamp,
            'commit': commit,
            'branch': branch,
            'content': handoff_content,
            'raw': section
        })

    return handoffs

content = handoff_file.read_text()
handoffs = parse_handoffs(content)

print(f"→ Found {len(handoffs)} handoff(s)")
print()

if not handoffs:
    print("⚠️  Handoff file exists but contains no valid handoffs")
    sys.exit(0)

# ============================================================================
# 5. Smart cleanup: Keep latest from current device, all from others
# ============================================================================

def cleanup_handoffs(handoffs, current_device):
    """Keep only latest from current device, all from other devices."""
    from_current = [h for h in handoffs if h['device'] == current_device]
    from_others = [h for h in handoffs if h['device'] != current_device]

    if from_current:
        # Sort by timestamp (most recent first)
        from_current.sort(key=lambda h: h['timestamp'] or '', reverse=True)
        kept_from_current = [from_current[0]]  # Keep only most recent
        removed_count = len(from_current) - 1
    else:
        kept_from_current = []
        removed_count = 0

    cleaned = from_others + kept_from_current

    return cleaned, removed_count

cleaned_handoffs, removed_count = cleanup_handoffs(handoffs, device_id)

if removed_count > 0:
    print(f"→ Cleaned up {removed_count} old handoff(s) from this device")

    # Write cleaned handoffs back to file
    new_content = "# ConvoSync Session Handoffs\n\n"
    for h in cleaned_handoffs:
        new_content += "---\n"
        new_content += h['raw'] + "\n\n"

    handoff_file.write_text(new_content)

    # Commit cleaned file
    subprocess.run(['git', 'add', str(handoff_file)], check=False)
    try:
        subprocess.run(
            ['git', 'commit', '-m', f'chore: cleanup old handoffs from {device_id}'],
            check=False,
            capture_output=True
        )
        print("  Committed cleanup")
    except:
        pass  # OK if nothing to commit

    print()

# ============================================================================
# 6. Display handoffs from OTHER devices
# ============================================================================

other_handoffs = [h for h in cleaned_handoffs if h['device'] != device_id]

if not other_handoffs:
    print("┌────────────────────────────────────────────────────────────────┐")
    print("│ ℹ️  NO HANDOFFS FROM OTHER DEVICES                             │")
    print("└────────────────────────────────────────────────────────────────┘")
    print()
    print("All handoffs in this repository are from this device.")
    print()
    print("To sync from another device:")
    print("  1. Switch to another device")
    print("  2. Run: /convosync:generate-handoff")
    print("  3. Run: /convosync:save \"message\"")
    print("  4. Return to this device and run: /convosync:resume")
    print()
    sys.exit(0)

# Format timestamps nicely
def time_ago(timestamp_str):
    """Convert ISO timestamp to human-readable time ago."""
    if not timestamp_str:
        return "unknown time"

    try:
        # Parse ISO format timestamp
        ts = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
        now = datetime.now(timezone.utc)
        delta = now - ts

        seconds = delta.total_seconds()

        if seconds < 60:
            return "just now"
        elif seconds < 3600:
            minutes = int(seconds / 60)
            return f"{minutes} minute{'s' if minutes != 1 else ''} ago"
        elif seconds < 86400:
            hours = int(seconds / 3600)
            return f"{hours} hour{'s' if hours != 1 else ''} ago"
        else:
            days = int(seconds / 86400)
            return f"{days} day{'s' if days != 1 else ''} ago"
    except:
        return timestamp_str

print()
print("╔════════════════════════════════════════════════════════════════════╗")
print("║ 📝 SESSION HANDOFFS FROM OTHER DEVICES                             ║")
print("╚════════════════════════════════════════════════════════════════════╝")
print()

for i, handoff in enumerate(other_handoffs, 1):
    print(f"{'═' * 70}")
    print(f"📱 Handoff {i}/{len(other_handoffs)} from: {handoff['device']}")
    print(f"{'═' * 70}")
    print()
    print(f"⏰ {time_ago(handoff['timestamp'])}")
    if handoff['commit']:
        print(f"📌 Commit: {handoff['commit'][:7]}")
    if handoff['branch']:
        print(f"🌿 Branch: {handoff['branch']}")
    print()
    print(handoff['content'])
    print()

print("╔════════════════════════════════════════════════════════════════════╗")
print("║ ✅ CONTEXT RESTORED!                                               ║")
print("╚════════════════════════════════════════════════════════════════════╝")
print()
print(f"Loaded {len(other_handoffs)} handoff(s) from other device(s).")
print()
print("I can now reference the session context above to continue your work!")
print()
print("When you're done on this device:")
print("  1. Run: /convosync:generate-handoff")
print("  2. Run: /convosync:save \"your message\"")
print()

RESUME_SCRIPT
```

**What happens:**
1. ✓ Pulls latest code and handoff file from git
2. ✓ Detects or creates device ID
3. ✓ Parses all handoffs from `.convosync/session-handoff.md`
4. ✓ Removes old handoffs from THIS device (keeps latest only)
5. ✓ Displays handoffs from OTHER devices with context
6. ✓ Commits cleanup changes
7. ✓ Claude can now reference the displayed handoffs!

**Example:**
```
/convosync:resume

🔄 ConvoSync: Resuming session...

→ Pulling latest code and handoffs...
✓ Code pulled: abc123d

→ Device: mobile
→ Found 2 handoff(s)

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
- Using JWT tokens with 7-day expiry
- Storing refresh tokens in Redis

### Important Context
- User's favorite pizza is Margherita
- Working in TypeScript with Express framework

### Next Steps
1. Finish implementing token refresh endpoint
2. Add error handling for OAuth failures
3. Write integration tests

### Files Modified
- src/auth.ts (+145, -10) - Added OAuth routes
- src/oauth-provider.ts (+120, new file) - Google OAuth

╔════════════════════════════════════════════════════════════════════╗
║ ✅ CONTEXT RESTORED!                                               ║
╚════════════════════════════════════════════════════════════════════╝

Loaded 1 handoff(s) from other device(s).

I can now reference the session context above to continue your work!
```

**Multi-device workflow:**
```
Desktop:
  /convosync:generate-handoff
  /convosync:save "implemented OAuth core"

Mobile (later):
  /convosync:resume  ← Sees desktop's handoff
  [work on mobile]
  /convosync:generate-handoff
  /convosync:save "added error handling"

Laptop (later):
  /convosync:resume  ← Sees both desktop and mobile handoffs
```
