# Save ConvoSync Session

Sync the current coding session (code + conversation) to enable cross-device continuation.

**Execute the save process:**

```bash
python3 << 'SAVE_SCRIPT'
import json
import subprocess
import sys
from pathlib import Path
from datetime import datetime

# Get commit message from user (passed as argument to /save)
commit_msg = sys.argv[1] if len(sys.argv) > 1 else "WIP: sync session"

print("💾 ConvoSync: Saving session...")
print()

# 1. Git operations
print("→ Committing code...")
subprocess.run(["git", "add", "."], check=False)

try:
    subprocess.run(["git", "commit", "-m", commit_msg], check=True)
except:
    print("  No changes to commit")

subprocess.run(["git", "push"], check=True)

# Get git info
commit_hash = subprocess.check_output(["git", "rev-parse", "HEAD"]).decode().strip()
commit_short = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"]).decode().strip()
branch = subprocess.check_output(["git", "rev-parse", "--abbrev-ref", "HEAD"]).decode().strip()
result = subprocess.run(["git", "config", "--get", "remote.origin.url"], capture_output=True, text=True)
repo_url = result.stdout.strip() or "unknown"
working_dir = subprocess.check_output(["pwd"]).decode().strip()

print(f"✓ Code committed: {commit_short}")
print()

# 2. Find current conversation
project_hash = working_dir.replace('/', '-').lstrip('-')
conv_dir = Path.home() / ".claude" / "projects" / project_hash

if not conv_dir.exists():
    print("✗ No conversation directory found for this project")
    print(f"  Expected: {conv_dir}")
    sys.exit(1)

# Get most recent conversation file
conv_files = list(conv_dir.glob("*.jsonl"))
if not conv_files:
    print("✗ No conversation file found")
    sys.exit(1)

conv_file = max(conv_files, key=lambda p: p.stat().st_mtime)
conv_id = conv_file.stem
conv_size_kb = conv_file.stat().st_size // 1024

print(f"→ Found conversation: {conv_id} ({conv_size_kb}KB)")
print()

# 3. Create metadata
project_name = Path(working_dir).name
metadata = {
    "conversation_id": conv_id,
    "git_commit": commit_hash,
    "git_branch": branch,
    "git_repo": repo_url,
    "working_dir": working_dir,
    "timestamp": int(datetime.now().timestamp()),
    "message": commit_msg
}

# Write to temp file
metadata_file = Path("/tmp") / f"{project_name}-{commit_hash}.json"
with open(metadata_file, 'w') as f:
    json.dump(metadata, f, indent=2)

# 4. Upload to cloud
print("→ Uploading conversation...")
subprocess.run(
    ["rclone", "copy", str(conv_file), "gdrive:convosync/conversations/"],
    check=True
)

print("→ Uploading metadata...")
subprocess.run(
    ["rclone", "copy", str(metadata_file), "gdrive:convosync/sessions/"],
    check=True
)

# Clean up
metadata_file.unlink()

# 5. Confirm
print()
print(f"✅ Session saved to commit {commit_short}")
print(f"✓ Conversation synced ({conv_size_kb}KB)")
print(f"✓ Ready to resume on another device")
print()
print("To resume on another device:")
print("  1. cd to project directory")
print("  2. Run: /resume")

SAVE_SCRIPT
```

**What happens:**
1. ✓ Commits and pushes code changes
2. ✓ Finds current conversation file
3. ✓ Creates session metadata
4. ✓ Uploads conversation to cloud
5. ✓ Uploads metadata linking conversation ↔ commit

**Example:**
```
/save "implementing OAuth login"

💾 ConvoSync: Saving session...
✓ Code committed: abc123
✓ Conversation synced (2.1MB)
✅ Session saved!
```

**Arguments:**
- Commit message (optional, defaults to "WIP: sync session")
- Example: `/save "added user authentication"`
