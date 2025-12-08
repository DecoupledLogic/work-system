#!/bin/bash
# install.sh - Install work system to Claude Code using symlinks
#
# This script creates symlinks from ~/.claude to the repository,
# allowing Claude Code to read files while git tracks changes.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

echo "Installing Claude Code Work System..."
echo "Repository: ${SCRIPT_DIR}"
echo "Target: ${CLAUDE_DIR}"
echo ""

# Create ~/.claude if it doesn't exist
mkdir -p "${CLAUDE_DIR}"

# Function to create symlink with backup
create_symlink() {
    local source="$1"
    local target="$2"
    local name="$(basename "$target")"

    if [ -L "$target" ]; then
        # Already a symlink - remove and recreate
        echo "  Updating symlink: $name"
        rm "$target"
    elif [ -e "$target" ]; then
        # Exists but not a symlink - backup
        echo "  Backing up existing: $name -> ${name}.backup"
        mv "$target" "${target}.backup"
    else
        echo "  Creating symlink: $name"
    fi

    ln -s "$source" "$target"
}

echo "Creating symlinks..."

# Directories
create_symlink "${SCRIPT_DIR}/agents" "${CLAUDE_DIR}/agents"
create_symlink "${SCRIPT_DIR}/commands" "${CLAUDE_DIR}/commands"
create_symlink "${SCRIPT_DIR}/templates" "${CLAUDE_DIR}/templates"
create_symlink "${SCRIPT_DIR}/docs" "${CLAUDE_DIR}/docs"
create_symlink "${SCRIPT_DIR}/work-managers" "${CLAUDE_DIR}/work-managers"
create_symlink "${SCRIPT_DIR}/session" "${CLAUDE_DIR}/session"

echo ""
echo "Installation complete!"
echo ""
echo "Verify with: ls -la ~/.claude/ | grep '^l'"
echo ""
echo "Next steps:"
echo "1. Configure work manager (if needed): vim ~/.claude/work-manager.yaml"
echo "2. Verify installation: /work-status in Claude Code"
