#!/bin/bash
# uninstall.sh - Remove work system symlinks from Claude Code
#
# This removes symlinks but does NOT delete the repository files.
# After uninstalling, you can delete ~/projects/work-system if desired.

set -e

CLAUDE_DIR="${HOME}/.claude"

# Components to remove (must match install.sh)
COMPONENTS=(agents commands templates docs work-managers session schema)

echo "Uninstalling Claude Code Work System..."
echo ""

# Function to remove symlink and optionally restore backup
remove_symlink() {
    local target="$1"
    local name="$(basename "$target")"

    if [ -L "$target" ]; then
        echo "  Removing symlink: $name"
        rm "$target"

        # Restore backup if exists
        if [ -e "${target}.backup" ]; then
            echo "  Restoring backup: ${name}.backup -> $name"
            mv "${target}.backup" "$target"
        fi
    elif [ -e "$target" ]; then
        echo "  Skipping (not a symlink): $name"
    else
        echo "  Skipping (doesn't exist): $name"
    fi
}

echo "Removing symlinks..."

# Remove symlinks for all components
for component in "${COMPONENTS[@]}"; do
    remove_symlink "${CLAUDE_DIR}/${component}"
done

echo ""
echo "Uninstallation complete!"
echo ""
echo "The repository is still intact."
echo "To fully remove, run: rm -rf $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
