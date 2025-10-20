# Save ConvoSync Session

Sync the current coding session to enable cross-device continuation.

**Process:**

1. **Stage and commit changes**
   - Add all changes: `git add .`
   - Commit with message from user (or default "WIP: sync session")
   - Push to remote: `git push`

2. **Capture session state**
   - Get current git commit hash: `git rev-parse HEAD`
   - Get current branch: `git rev-parse --abbrev-ref HEAD`
   - Get repository URL: `git config --get remote.origin.url`
   - Get current working directory: `pwd`

3. **Find and sync conversation**
   - Find the current conversation file (most recently modified .jsonl in current project)
   - Path pattern: `~/.claude/projects/{project-path}/*.jsonl`
   - Create metadata file with session info:
     ```json
     {
       "conversation_id": "{filename}",
       "git_commit": "{commit_hash}",
       "git_branch": "{branch}",
       "git_repo": "{repo_url}",
       "working_dir": "{cwd}",
       "timestamp": {unix_timestamp},
       "message": "{user's message}"
     }
     ```

4. **Upload to Google Drive**
   - Upload conversation file: `rclone copy {conversation_file} gdrive:convosync/conversations/`
   - Upload metadata: `rclone copy {metadata_file} gdrive:convosync/sessions/`
   - Name metadata file: `{commit_hash}.json`

5. **Confirm sync**
   - Display: "✓ Session saved to commit {hash}"
   - Display: "✓ Conversation synced ({file_size})"
   - Display: "✓ Ready to resume on another device"

**Arguments:**
- User provides optional commit message (default: "WIP: sync session")

**Example usage:**
```
User: /save "implementing OAuth login"
```

**Important:**
- Always push to git before uploading conversation
- Link conversation to exact commit hash
- Handle git errors gracefully (unstaged changes, push failures, etc.)
