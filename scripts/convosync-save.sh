#!/bin/bash
#
# ConvoSync Save Script
# Saves current coding session (code + conversation) to cloud
#

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Get commit message from argument
COMMIT_MSG="${1:-WIP: sync session}"

echo -e "${BLUE}ConvoSync: Saving session...${NC}"

# 1. Git operations
echo "→ Committing code..."
git add .
git commit -m "$COMMIT_MSG" || echo "No changes to commit"
git push

# Get git info
COMMIT_HASH=$(git rev-parse HEAD)
COMMIT_SHORT=$(git rev-parse --short HEAD)
BRANCH=$(git rev-parse --abbrev-ref HEAD)
REPO_URL=$(git config --get remote.origin.url || echo "unknown")
WORKING_DIR=$(pwd)

echo -e "${GREEN}✓ Code committed: $COMMIT_SHORT${NC}"

# 2. Find current conversation
# Get the most recently modified conversation file for current project
PROJECT_HASH=$(echo "$WORKING_DIR" | sed 's/\//-/g' | sed 's/^-//')
CONV_DIR="$HOME/.claude/projects/$PROJECT_HASH"

if [ ! -d "$CONV_DIR" ]; then
    echo -e "${RED}✗ No conversation directory found for this project${NC}"
    echo "Expected: $CONV_DIR"
    exit 1
fi

CONV_FILE=$(ls -t "$CONV_DIR"/*.jsonl 2>/dev/null | head -1)

if [ -z "$CONV_FILE" ]; then
    echo -e "${RED}✗ No conversation file found${NC}"
    exit 1
fi

CONV_ID=$(basename "$CONV_FILE" .jsonl)
CONV_SIZE=$(ls -lh "$CONV_FILE" | awk '{print $5}')

echo "→ Found conversation: $CONV_ID ($CONV_SIZE)"

# 3. Create metadata
METADATA_FILE="/tmp/convosync-$COMMIT_SHORT.json"
cat > "$METADATA_FILE" << EOF
{
  "conversation_id": "$CONV_ID",
  "git_commit": "$COMMIT_HASH",
  "git_branch": "$BRANCH",
  "git_repo": "$REPO_URL",
  "working_dir": "$WORKING_DIR",
  "timestamp": $(date +%s),
  "message": "$COMMIT_MSG"
}
EOF

# 4. Upload to cloud
echo "→ Uploading conversation..."
rclone copy "$CONV_FILE" gdrive:convosync/conversations/

echo "→ Uploading metadata..."
rclone copy "$METADATA_FILE" gdrive:convosync/sessions/

# Clean up temp file
rm "$METADATA_FILE"

# 5. Confirm
echo ""
echo -e "${GREEN}✓ Session saved to commit $COMMIT_SHORT${NC}"
echo -e "${GREEN}✓ Conversation synced ($CONV_SIZE)${NC}"
echo -e "${GREEN}✓ Ready to resume on another device${NC}"
echo ""
echo "To resume on another device:"
echo "  1. cd to project directory"
echo "  2. Run: convosync-resume.sh"
