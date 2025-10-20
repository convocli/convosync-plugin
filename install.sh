#!/bin/bash
#
# ConvoSync Plugin Installer
# Installs Claude Code commands for cross-device session sync
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_DIR="$SCRIPT_DIR/commands"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════╗"
echo "║   ConvoSync Plugin Installer              ║"
echo "║   Sync your coding sessions across devices║"
echo "╚═══════════════════════════════════════════╝"
echo -e "${NC}"

# Check if rclone is installed
echo -e "\n${BLUE}[1/4] Checking dependencies...${NC}"
if ! command -v rclone &> /dev/null; then
    echo -e "${YELLOW}⚠ rclone not found${NC}"
    echo ""
    echo "rclone is required for cloud sync. Install it:"
    echo ""
    echo "  Termux:  pkg install rclone"
    echo "  macOS:   brew install rclone"
    echo "  Linux:   sudo apt install rclone"
    echo "  Windows: https://rclone.org/downloads/"
    echo ""
    read -p "Install rclone now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v pkg &> /dev/null; then
            pkg install rclone -y
        elif command -v brew &> /dev/null; then
            brew install rclone
        elif command -v apt &> /dev/null; then
            sudo apt install rclone -y
        elif command -v dnf &> /dev/null; then
            sudo dnf install rclone -y
        else
            echo -e "${RED}✗ Automatic installation not supported on this system${NC}"
            echo "Please install rclone manually and run this script again"
            exit 1
        fi
    else
        echo -e "${YELLOW}Skipping rclone installation. You'll need to install it manually.${NC}"
    fi
else
    echo -e "${GREEN}✓ rclone found${NC}"
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}✗ git not found - ConvoSync requires git${NC}"
    exit 1
else
    echo -e "${GREEN}✓ git found${NC}"
fi

# Ask where to install
echo -e "\n${BLUE}[2/4] Choose installation location...${NC}"
echo ""
echo "1) Current project only (.claude/commands/)"
echo "2) Global (all projects) (~/.claude/global-commands/)"
echo "3) Both"
echo ""
read -p "Enter choice [1-3]: " INSTALL_CHOICE

case $INSTALL_CHOICE in
    1)
        INSTALL_LOCAL=true
        INSTALL_GLOBAL=false
        ;;
    2)
        INSTALL_LOCAL=false
        INSTALL_GLOBAL=true
        ;;
    3)
        INSTALL_LOCAL=true
        INSTALL_GLOBAL=true
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

# Install commands
echo -e "\n${BLUE}[3/4] Installing commands...${NC}"

if [ "$INSTALL_LOCAL" = true ]; then
    echo -e "${YELLOW}Installing to current project...${NC}"
    mkdir -p .claude/commands
    cp "$COMMANDS_DIR"/*.md .claude/commands/
    echo -e "${GREEN}✓ Commands installed to .claude/commands/${NC}"
fi

if [ "$INSTALL_GLOBAL" = true ]; then
    echo -e "${YELLOW}Installing globally...${NC}"
    mkdir -p ~/.claude/global-commands
    cp "$COMMANDS_DIR"/*.md ~/.claude/global-commands/
    echo -e "${GREEN}✓ Commands installed to ~/.claude/global-commands/${NC}"

    if [ "$INSTALL_LOCAL" = false ]; then
        echo ""
        echo "To use global commands in a project, run:"
        echo "  ln -s ~/.claude/global-commands/*.md .claude/commands/"
    fi
fi

# Check rclone configuration
echo -e "\n${BLUE}[4/4] Checking cloud storage...${NC}"

if rclone listremotes | grep -q "gdrive:"; then
    echo -e "${GREEN}✓ Google Drive already configured${NC}"

    # Check if convosync directory exists
    if rclone lsd gdrive:convosync &> /dev/null; then
        echo -e "${GREEN}✓ ConvoSync directories found${NC}"
    else
        echo -e "${YELLOW}⚠ ConvoSync directories not found${NC}"
        read -p "Create them now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rclone mkdir gdrive:convosync
            rclone mkdir gdrive:convosync/conversations
            rclone mkdir gdrive:convosync/sessions
            echo -e "${GREEN}✓ Directories created${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠ Google Drive not configured${NC}"
    echo ""
    echo "You need to configure rclone for cloud storage."
    echo ""
    read -p "Configure now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "Running: rclone config"
        echo ""
        echo "When prompted:"
        echo "  1. Choose 'n' for new remote"
        echo "  2. Name: gdrive"
        echo "  3. Storage: drive (for Google Drive)"
        echo "  4. Follow the prompts"
        echo ""
        read -p "Press Enter to continue..."
        rclone config

        # Create directories
        echo ""
        echo "Creating ConvoSync directories..."
        rclone mkdir gdrive:convosync
        rclone mkdir gdrive:convosync/conversations
        rclone mkdir gdrive:convosync/sessions
        echo -e "${GREEN}✓ Setup complete${NC}"
    else
        echo ""
        echo "You can configure rclone later by running:"
        echo "  rclone config"
        echo ""
        echo "Then create the directory structure:"
        echo "  rclone mkdir gdrive:convosync"
        echo "  rclone mkdir gdrive:convosync/conversations"
        echo "  rclone mkdir gdrive:convosync/sessions"
    fi
fi

# Installation complete
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Installation Complete!                  ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
echo ""
echo "Available commands in Claude Code:"
echo ""
echo -e "  ${BLUE}/save \"message\"${NC}  - Save current session"
echo -e "  ${BLUE}/resume${NC}          - Resume saved session"
echo ""
echo "Example workflow:"
echo ""
echo "  # On desktop"
echo "  $ claude-code"
echo "  > /save \"implementing OAuth\""
echo ""
echo "  # On phone"
echo "  $ claude-code"
echo "  > /resume"
echo ""
echo "For more info, see: https://github.com/convocli/convosync-plugin"
echo ""
echo -e "${GREEN}Happy coding anywhere!${NC}"
echo ""
