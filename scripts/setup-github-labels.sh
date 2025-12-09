#!/bin/bash
#
# Setup GitHub Labels for Work System
#
# This script creates GitHub labels aligned with the WorkItem schema
# defined in docs/core/work-system.md
#
# Usage:
#   ./setup-github-labels.sh [owner/repo]
#
# If no repo is specified, uses the current repository.
#
# Prerequisites:
#   - GitHub CLI (gh) installed and authenticated
#   - Repository access (owner or collaborator)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get repo from argument or detect from git remote
if [ -n "$1" ]; then
    REPO="$1"
else
    REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
    if [ -z "$REPO" ]; then
        echo -e "${RED}Error: Could not detect repository. Please specify owner/repo as argument.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Setting up labels for: ${REPO}${NC}"
echo ""

# Function to create a label (skips if exists)
create_label() {
    local name="$1"
    local description="$2"
    local color="$3"

    if gh label create "$name" --description "$description" --color "$color" --repo "$REPO" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Created: $name"
    else
        echo -e "${YELLOW}○${NC} Exists:  $name"
    fi
}

echo "=== Type Labels (Work Item Hierarchy) ==="
create_label "type:epic" "Large strategic initiative spanning cycles" "0052CC"
create_label "type:feature" "Deliverable capability spanning weeks" "0066FF"
create_label "type:story" "User-facing requirement spanning days" "4D94FF"
create_label "type:task" "Atomic work unit spanning hours" "80B3FF"
create_label "type:client_request" "External client request" "B3D1FF"
echo ""

echo "=== WorkType Labels (Nature of Work) ==="
create_label "worktype:product_delivery" "New product development work" "2DA44E"
create_label "worktype:support" "Customer support request" "3FB950"
create_label "worktype:maintenance" "System maintenance and upkeep" "56D364"
create_label "worktype:bug_fix" "Defect correction" "7EE787"
create_label "worktype:research" "Investigation and exploration" "A7F3D0"
echo ""

echo "=== Urgency Labels (Priority) ==="
create_label "urgency:critical" "Same-day action required" "CF222E"
create_label "urgency:now" "Current work queue" "FA7A18"
create_label "urgency:next" "Next cycle planning" "FBCA04"
create_label "urgency:future" "Long-term backlog" "D4A72C"
echo ""

echo "=== Impact Labels ==="
create_label "impact:high" "Significant business or user impact" "8250DF"
create_label "impact:medium" "Moderate impact" "A371F7"
create_label "impact:low" "Minor impact" "C297FF"
echo ""

echo "=== Stage Labels (Workflow Stages) ==="
create_label "stage:triage" "Being categorized and routed" "EDEDED"
create_label "stage:plan" "Being decomposed and sized" "D4C5F9"
create_label "stage:design" "Solution being designed" "C2E0C6"
create_label "stage:deliver" "Being implemented and tested" "BFD4F2"
echo ""

echo "=== Capability Labels ==="
create_label "capability:development" "Software development work" "1D76DB"
create_label "capability:design" "UX/UI design work" "E99695"
create_label "capability:qa" "Quality assurance and testing" "5319E7"
create_label "capability:devops" "Infrastructure and deployment" "006B75"
create_label "capability:accessibility" "Accessibility improvements" "0E8A16"
create_label "capability:marketing" "Marketing-related work" "D93F0B"
create_label "capability:ux" "User experience research" "FBCA04"
echo ""

echo -e "${GREEN}Label setup complete!${NC}"
echo ""
echo "Label categories align with WorkItem schema from docs/core/work-system.md:"
echo "  - Type: epic, feature, story, task, client_request"
echo "  - WorkType: product_delivery, support, maintenance, bug_fix, research"
echo "  - Urgency: critical, now, next, future"
echo "  - Impact: high, medium, low"
echo "  - Stage: triage, plan, design, deliver"
echo "  - Capability: development, design, qa, devops, accessibility, marketing, ux"
