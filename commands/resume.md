# Resume ConvoSync Session

Restore a synced coding session and **merge it into the current conversation**.

**What this does:**
1. Downloads the conversation from the cloud
2. Merges it with your current conversation
3. You can continue exactly where you left off - all messages visible!

**Execute the resume process:**

```bash
# Get the plugin scripts directory
PLUGIN_DIR="$HOME/storage/code-projects/convosync-plugin"

# If plugin was installed via /plugin, find it
if [ ! -d "$PLUGIN_DIR" ]; then
    PLUGIN_DIR="$HOME/.claude/plugins/marketplaces/convocli-marketplace"
fi

# Run the enhanced resume script
python3 << 'RESUME_SCRIPT'
import json
import subprocess
import sys
from pathlib import Path
from datetime import datetime

print("🔄 ConvoSync: Resuming session...")
print()

# 1. Git pull
print("→ Pulling latest code...")
subprocess.run(["git", "pull"], check=False)

# Get git info
commit_hash = subprocess.check_output(["git", "rev-parse", "HEAD"]).decode().strip()
commit_short = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"]).decode().strip()
branch = subprocess.check_output(["git", "rev-parse", "--abbrev-ref", "HEAD"]).decode().strip()
working_dir = subprocess.check_output(["pwd"]).decode().strip()

print(f"✓ Code pulled: {commit_short}")
print()

# 2. Find session metadata
project_name = Path(working_dir).name
metadata_file = f"{project_name}-{commit_hash}.json"

print("→ Looking for session...")
try:
    subprocess.run(
        ["rclone", "copy", f"gdrive:convosync/sessions/{metadata_file}", "/tmp/"],
        check=True,
        capture_output=True
    )
except:
    print("⚠ No session found for current commit")
    print()
    print("Available sessions:")
    result = subprocess.run(
        ["rclone", "ls", "gdrive:convosync/sessions/"],
        capture_output=True,
        text=True
    )
    for line in result.stdout.splitlines():
        if project_name in line:
            print(f"  {line}")
    sys.exit(1)

# 3. Read metadata
with open(f"/tmp/{metadata_file}") as f:
    metadata = json.load(f)

conv_id = metadata['conversation_id']
orig_msg = metadata['message']

print(f"✓ Found session: \"{orig_msg}\"")
print()

# 4. Download old conversation
print("→ Downloading conversation...")
subprocess.run(
    ["rclone", "copy", f"gdrive:convosync/conversations/{conv_id}.jsonl", "/tmp/"],
    check=True
)

old_conv_file = f"/tmp/{conv_id}.jsonl"
print(f"✓ Downloaded ({Path(old_conv_file).stat().st_size // 1024}KB)")
print()

# 5. Find current conversation
project_hash = working_dir.replace('/', '-').lstrip('-')
conv_dir = Path.home() / ".claude" / "projects" / project_hash

if not conv_dir.exists():
    print(f"⚠ No active conversation in this project")
    print(f"  Starting new conversation with restored context")
    conv_dir.mkdir(parents=True, exist_ok=True)
    # Just copy the old conversation
    import shutil
    shutil.copy(old_conv_file, conv_dir / f"{conv_id}.jsonl")
    print("✓ Conversation restored")
else:
    # Find most recent conversation
    conv_files = list(conv_dir.glob("*.jsonl"))
    if not conv_files:
        # No current conversation, just copy old one
        import shutil
        shutil.copy(old_conv_file, conv_dir / f"{conv_id}.jsonl")
        print("✓ Conversation restored")
    else:
        current_conv = max(conv_files, key=lambda p: p.stat().st_mtime)

        print(f"→ Merging conversations...")
        print(f"  Old: {old_conv_file}")
        print(f"  Current: {current_conv}")

        # Load and merge
        with open(old_conv_file) as f:
            old_messages = [json.loads(line) for line in f if line.strip()]

        with open(current_conv) as f:
            new_messages = [json.loads(line) for line in f if line.strip()]

        # Merge: old messages + new messages
        target_session_id = new_messages[0]['sessionId']

        # Update old messages to use new session ID
        for msg in old_messages:
            msg['sessionId'] = target_session_id

        # Link new conversation to old
        if new_messages and new_messages[0].get('parentUuid') is None:
            new_messages[0]['parentUuid'] = old_messages[-1]['uuid']

        merged = old_messages + new_messages

        # Save merged conversation
        with open(current_conv, 'w') as f:
            for msg in merged:
                f.write(json.dumps(msg) + '\n')

        print(f"✓ Merged: {len(old_messages)} old + {len(new_messages)} current = {len(merged)} total")

print()
print("✅ Session restored successfully!")
print()
print(f"  Original: \"{orig_msg}\"")
print(f"  Commit: {commit_short}")
print(f"  Branch: {branch}")
print()
print("You can now continue the conversation with full context!")

RESUME_SCRIPT
```

**What happens:**
1. ✓ Pulls latest code
2. ✓ Downloads conversation from cloud
3. ✓ **Merges with current conversation**
4. ✓ All old messages now visible!
5. ✓ Continue exactly where you left off

**Example:**
```
/resume

🔄 ConvoSync: Resuming session...
✓ Code pulled: abc123
✓ Found session: "implementing OAuth"
✓ Downloaded (2.1MB)
✓ Merged: 850 old + 5 current = 855 total
✅ Session restored!
```
