#!/bin/bash
#
# Claude Code Cross-Machine Sync - Linux/macOS Setup Script
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/robertogogoni/claude-cross-machine-sync/master/scripts/linux-setup.sh | bash
#
# Or clone and run:
#   ./scripts/linux-setup.sh
#

set -e

# Configuration
REPO_URL="https://github.com/robertogogoni/claude-cross-machine-sync.git"
INSTALL_PATH="$HOME/claude-cross-machine-sync"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

step() { echo -e "\n${CYAN}[→] $1${NC}"; }
success() { echo -e "    ${GREEN}[OK]${NC} $1"; }
warn() { echo -e "    ${YELLOW}[!]${NC} $1"; }
error() { echo -e "    ${RED}[X]${NC} $1"; }
info() { echo -e "    $1"; }

# Banner
echo -e "${MAGENTA}"
cat << 'EOF'
  ╔═══════════════════════════════════════════════════════════╗
  ║       Claude Code Cross-Machine Sync - Linux Setup        ║
  ║                                                           ║
  ║  This script will:                                        ║
  ║  1. Install prerequisites (Git LFS)                       ║
  ║  2. Clone the sync repository                             ║
  ║  3. Copy settings and skills to Claude Code               ║
  ║  4. Verify the installation                               ║
  ╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

#region Prerequisites
step "Checking prerequisites..."

# Check Git
if ! command -v git &> /dev/null; then
    error "Git not found. Please install git first."
    exit 1
fi
success "Git installed: $(git --version)"

# Check/Install Git LFS
if ! git lfs version &> /dev/null; then
    warn "Git LFS not found. Installing..."

    # Detect package manager
    if command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm git-lfs
    elif command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y git-lfs
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y git-lfs
    elif command -v brew &> /dev/null; then
        brew install git-lfs
    else
        error "Could not detect package manager. Please install git-lfs manually."
        exit 1
    fi

    git lfs install
fi
success "Git LFS installed: $(git lfs version | head -1)"

# Check Claude Code
if command -v claude &> /dev/null; then
    success "Claude Code installed: $(claude --version 2>&1 | head -1)"
else
    warn "Claude Code not found in PATH"
    info "Please ensure Claude Code is installed"
fi
#endregion

#region Clone Repository
step "Setting up repository..."

if [ -d "$INSTALL_PATH" ]; then
    info "Repository exists. Pulling latest..."
    cd "$INSTALL_PATH"
    git pull
else
    info "Cloning repository..."
    git clone "$REPO_URL" "$INSTALL_PATH"
fi
success "Repository ready at $INSTALL_PATH"

# Fetch LFS content
info "Fetching Git LFS content..."
cd "$INSTALL_PATH"
git lfs pull
success "LFS content downloaded"
#endregion

#region Copy Configuration
step "Configuring Claude Code..."

CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"

# Create directories
mkdir -p "$CLAUDE_DIR"
mkdir -p "$SKILLS_DIR"

# Copy settings
if [ -f "$INSTALL_PATH/.claude/settings.json" ]; then
    # Backup existing
    if [ -f "$CLAUDE_DIR/settings.json" ]; then
        BACKUP="$CLAUDE_DIR/settings.json.backup.$(date +%Y%m%d-%H%M%S)"
        cp "$CLAUDE_DIR/settings.json" "$BACKUP"
        info "Backed up existing settings to $BACKUP"
    fi
    cp "$INSTALL_PATH/.claude/settings.json" "$CLAUDE_DIR/"
    success "Copied settings.json"
else
    warn "settings.json not found in repository"
fi

# Copy skills
if [ -d "$INSTALL_PATH/skills" ]; then
    cp -r "$INSTALL_PATH/skills/"* "$SKILLS_DIR/" 2>/dev/null || true
    SKILL_COUNT=$(find "$SKILLS_DIR" -name "*.md" | wc -l)
    success "Copied $SKILL_COUNT skill files"
else
    warn "Skills directory not found"
fi
#endregion

#region Verification
step "Verifying installation..."

# Check settings
if [ -f "$CLAUDE_DIR/settings.json" ]; then
    if python3 -c "import json; json.load(open('$CLAUDE_DIR/settings.json'))" 2>/dev/null; then
        success "Settings file is valid JSON"
    else
        warn "Settings file may be invalid JSON"
    fi
fi

# Check episodic memory
if [ -d "$INSTALL_PATH/episodic-memory" ]; then
    SIZE=$(du -sh "$INSTALL_PATH/episodic-memory" 2>/dev/null | cut -f1)
    success "Episodic memory: $SIZE"
fi

# Check Warp history
if [ -d "$INSTALL_PATH/warp-ai" ]; then
    QUERY_COUNT=$(wc -l < "$INSTALL_PATH/warp-ai/queries/all-queries.csv" 2>/dev/null || echo "0")
    PREVIEW_COUNT=$(wc -l < "$INSTALL_PATH/warp-ai/preview-queries/all-queries.csv" 2>/dev/null || echo "0")
    TOTAL=$((QUERY_COUNT + PREVIEW_COUNT - 2))
    success "Warp AI history: $TOTAL queries available"
fi
#endregion

#region Summary
echo -e "${GREEN}"
cat << 'EOF'

  ╔═══════════════════════════════════════════════════════════╗
  ║                    Setup Complete!                        ║
  ╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "  Repository:  ${WHITE}$INSTALL_PATH${NC}"
echo -e "  Settings:    ${WHITE}$CLAUDE_DIR/settings.json${NC}"
echo -e "  Skills:      ${WHITE}$SKILLS_DIR${NC}"
echo ""
echo -e "  ${YELLOW}Next Steps (run inside Claude Code):${NC}"
echo ""
echo "    1. Install plugins:"
echo "       /plugin marketplace add obra/superpowers-marketplace"
echo "       /plugin install episodic-memory@superpowers-marketplace"
echo "       /plugin install superpowers@superpowers-marketplace"
echo ""
echo "    2. Verify setup:"
echo "       /config"
echo "       /help"
echo ""
echo "    3. Test episodic memory:"
echo '       "What was the solution to the Warp extraction?"'
echo ""
echo -e "  ${CYAN}Documentation:${NC} $INSTALL_PATH/docs/WINDOWS-SETUP.md"
echo -e "  ${CYAN}Project Memory:${NC} $INSTALL_PATH/CLAUDE.md"
echo ""
echo -e "${GREEN}Setup complete! Start Claude Code to begin.${NC}"
#endregion
