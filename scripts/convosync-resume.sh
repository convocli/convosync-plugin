#!/bin/bash
#
# ConvoSync Resume Script
# Restores a synced coding session from cloud
#

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}ConvoSync: Resuming session...${NC}"

# 1. Git pull
echo "→ Pulling latest code..."
git pull

# Get git info
COMMIT_HASH=$(git rev-parse HEAD)
COMMIT_SHORT=$(git rev-parse --short HEAD)
BRANCH=$(git rev-parse --abbrev-ref HEAD)
WORKING_DIR=$(pwd)

echo -e "${GREEN}✓ Code pulled: $COMMIT_SHORT${NC}"

# 2. Find matching session
PROJECT_NAME=$(basename "$WORKING_DIR")
METADATA_FILE="$PROJECT_NAME-$COMMIT_HASH.json"

echo "→ Looking for session metadata..."
rclone copy "gdrive:convosync/sessions/$METADATA_FILE" /tmp/ 2>/dev/null || {
    echo -e "${YELLOW}⚠ No session found for current commit${NC}"
    echo ""
    echo "Available sessions:"
    rclone ls gdrive:convosync/sessions/ | grep "$PROJECT_NAME" || echo "None found"
    echo ""
    echo "Tip: Make sure you're on the same commit as when you ran /save"
    exit 1
}

# 3. Read metadata
METADATA_PATH="/tmp/$METADATA_FILE"
CONV_ID=$(grep -o '"conversation_id": "[^"]*"' "$METADATA_PATH" | cut -d'"' -f4)
ORIG_MSG=$(grep -o '"message": "[^"]*"' "$METADATA_PATH" | cut -d'"' -f4)
TIMESTAMP=$(grep -o '"timestamp": [0-9]*' "$METADATA_PATH" | cut -d' ' -f2)

echo -e "${GREEN}✓ Found session: $ORIG_MSG${NC}"

# 4. Download conversation
echo "→ Downloading conversation..."
rclone copy "gdrive:convosync/conversations/$CONV_ID.jsonl" /tmp/

CONV_FILE="/tmp/$CONV_ID.jsonl"
CONV_SIZE=$(ls -lh "$CONV_FILE" | awk '{print $5}')

echo -e "${GREEN}✓ Conversation downloaded ($CONV_SIZE)${NC}"

# 5. Restore conversation
PROJECT_HASH=$(echo "$WORKING_DIR" | sed 's/\//-/g' | sed 's/^-//')
CONV_DIR="$HOME/.claude/projects/$PROJECT_HASH"

# Create directory if it doesn't exist
mkdir -p "$CONV_DIR"

# Copy conversation to Claude directory
cp "$CONV_FILE" "$CONV_DIR/$CONV_ID.jsonl"

echo -e "${GREEN}✓ Conversation restored${NC}"

# Clean up
rm "$METADATA_PATH" "$CONV_FILE"

# 6. Instructions
echo ""
echo -e "${GREEN}╔════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Session Restored Successfully!    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════╝${NC}"
echo ""
echo "Original message: \"$ORIG_MSG\""
echo "Commit: $COMMIT_SHORT"
echo "Branch: $BRANCH"
echo ""
echo -e "${YELLOW}IMPORTANT: To continue the conversation:${NC}"
echo ""
echo "Claude Code needs to load the restored conversation."
echo "The conversation file has been restored to:"
echo "  $CONV_DIR/$CONV_ID.jsonl"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Exit Claude Code (Ctrl+D or 'exit')"
echo "  2. Restart: claude-code"
echo "  3. Claude should detect and load the conversation"
echo ""
echo "Or manually specify the conversation:"
echo "  claude-code --conversation $CONV_ID"
echo ""
