#!/bin/bash
# install.sh - Install work system to Claude Code using symlinks
#
# This script creates symlinks from ~/.claude to the repository,
# allowing Claude Code to read files while git tracks changes.
#
# Usage:
#   ./install.sh          # Install (or update) work system
#   ./install.sh --check  # Check if already installed
#   ./install.sh --status # Same as --check

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

# Components to symlink
COMPONENTS=(agents commands templates docs work-managers session schema)

# Check if a component is correctly linked to this repo
is_linked() {
    local name="$1"
    local target="${CLAUDE_DIR}/${name}"
    local source="${SCRIPT_DIR}/${name}"

    if [ -L "$target" ]; then
        local actual=$(readlink -f "$target" 2>/dev/null || readlink "$target")
        if [ "$actual" = "$source" ]; then
            return 0  # Correctly linked
        fi
    fi
    return 1  # Not linked or wrong target
}

# Check installation status
check_installation() {
    local installed=0
    local total=${#COMPONENTS[@]}

    echo "Work System Installation Status"
    echo "================================"
    echo "Repository: ${SCRIPT_DIR}"
    echo "Target: ${CLAUDE_DIR}"
    echo ""

    for component in "${COMPONENTS[@]}"; do
        if is_linked "$component"; then
            echo "  ✓ $component"
            installed=$((installed + 1))
        elif [ -L "${CLAUDE_DIR}/${component}" ]; then
            echo "  ✗ $component (symlink points elsewhere)"
        elif [ -e "${CLAUDE_DIR}/${component}" ]; then
            echo "  ✗ $component (exists but not a symlink)"
        else
            echo "  ✗ $component (not installed)"
        fi
    done

    echo ""
    if [ $installed -eq $total ]; then
        echo "Status: Fully installed ($installed/$total components)"
        return 0
    elif [ $installed -gt 0 ]; then
        echo "Status: Partially installed ($installed/$total components)"
        echo "Run ./install.sh to complete installation"
        return 1
    else
        echo "Status: Not installed"
        echo "Run ./install.sh to install"
        return 1
    fi
}

# Handle --check or --status flag
if [ "$1" = "--check" ] || [ "$1" = "--status" ]; then
    check_installation
    exit $?
fi

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

# Create symlinks for all components
for component in "${COMPONENTS[@]}"; do
    create_symlink "${SCRIPT_DIR}/${component}" "${CLAUDE_DIR}/${component}"
done

echo ""
echo "Installation complete!"
echo ""
echo "Verify with: ./install.sh --check"
echo ""
echo "Next steps:"
echo "1. Configure work manager (if needed): vim ~/.claude/work-manager.yaml"
echo "2. Verify installation: /work-status in Claude Code"
