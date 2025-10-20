# Resume ConvoSync Session

Restore a synced coding session from another device.

**Process:**

1. **Pull latest code**
   - Pull from remote: `git pull`
   - Handle any merge conflicts if they exist
   - Get current commit hash: `git rev-parse HEAD`
   - Get current branch: `git rev-parse --abbrev-ref HEAD`

2. **Find matching session**
   - Download metadata for current commit: `rclone copy gdrive:convosync/sessions/{commit_hash}.json /tmp/`
   - If not found, list recent sessions: `rclone ls gdrive:convosync/sessions/`
   - Show user available sessions with timestamps and messages

3. **Download conversation**
   - Get conversation_id from metadata
   - Download conversation file: `rclone copy gdrive:convosync/conversations/{conversation_id} /tmp/`
   - Verify file downloaded successfully

4. **Restore conversation**
   - Find current project directory in `~/.claude/projects/`
   - Copy conversation file to project directory
   - Use the same conversation_id from metadata
   - Path: `~/.claude/projects/{project-path}/{conversation_id}`

5. **Verify restoration**
   - Check file exists and has content
   - Display session info:
     ```
     ✓ Code pulled: commit {hash}
     ✓ Branch: {branch}
     ✓ Conversation restored: {conversation_id}
     ✓ Original message: {message}
     ✓ Synced from: {original_device/timestamp}
     ```

6. **Confirm ready**
   - Display: "✓ Session restored successfully"
   - Display: "You can now continue the conversation"

**Fallback behavior:**
- If no session exists for current commit, show list of recent sessions
- Allow user to choose which session to restore
- Warn if restoring a session from a different commit (code mismatch risk)

**Example usage:**
```
User: /resume
Assistant:
✓ Code pulled: commit abc123
✓ Conversation restored
✓ Original: "implementing OAuth login"
✓ Ready to continue!
```

**Important:**
- Always git pull before restoring conversation
- Verify commit hash matches to ensure code/conversation alignment
- Handle case where no session exists gracefully
- Don't overwrite existing conversations - use new ID if needed
