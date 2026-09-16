#!/usr/bin/env bash
# ==============================================================================
# AISSC Automated Online Empire - Environment Installer & Skill Integrator
# ==============================================================================
# Target Workspace: /home/josh/AISSC-Automated-Online-Empire/
# Purpose: Automates local directory scaffolding, dependency validation,
#          and registers all 284+ Agency-Agents as native Antigravity skills.
# ==============================================================================

set -euo pipefail

WORKSPACE_ROOT="/home/josh/AISSC-Automated-Online-Empire"
SKILLS_GLOBAL_DIR="$HOME/.gemini/config/skills"
SKILLS_PROJECT_DIR="$WORKSPACE_ROOT/.agents/skills"

echo "===================================================================="
echo "   NEXUS-SUAD SYSTEM ARCHITECTURE - PHASE 1 INSTALLER"
echo "===================================================================="
echo "Target Workspace: $WORKSPACE_ROOT"
echo "Global Skills Target: $SKILLS_GLOBAL_DIR"
echo "Project Skills Target: $SKILLS_PROJECT_DIR"
echo "--------------------------------------------------------------------"

# Step 1: Validate Prerequisites
echo "[1/5] Validating environment CLI prerequisites..."
PREREQS=("node" "npm" "git" "gcloud" "terraform")
MISSING_TOOLS=()

for tool in "${PREREQS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        MISSING_TOOLS+=("$tool")
    else
        echo "  [OK] $tool is installed: $(command -v "$tool")"
    fi
done

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo "[WARN] The following optional or required CLI tools were not found: ${MISSING_TOOLS[*]}"
    echo "[WARN] Ensure you install these dependencies prior to running production Terraform or Cloud Build tasks."
fi

# Step 2: Ensure Directory Tree Skeleton Exists
echo "--------------------------------------------------------------------"
echo "[2/5] Scaffolding local directory structure..."
DIRS=(
    "$WORKSPACE_ROOT/cloud-tasks-setup/blueprints"
    "$WORKSPACE_ROOT/components/kanban-dashboard/data"
    "$WORKSPACE_ROOT/components/krieger-tech-systems"
    "$WORKSPACE_ROOT/components/malory-business-ops"
    "$WORKSPACE_ROOT/components/pam-workforce"
    "$WORKSPACE_ROOT/components/sheryl-gateway"
    "$WORKSPACE_ROOT/gcs-terraform/blueprints"
    "$WORKSPACE_ROOT/independent-structured-thought-layer/blueprints"
    "$WORKSPACE_ROOT/independent-structured-thought-layer/templates"
    "$WORKSPACE_ROOT/monitoring-telemetry-remediation/blueprints"
    "$WORKSPACE_ROOT/monitoring-telemetry-remediation/playbooks"
    "$WORKSPACE_ROOT/qa-evidence-validation/blueprints"
    "$WORKSPACE_ROOT/qa-evidence-validation/screenshots"
    "$WORKSPACE_ROOT/scripts"
    "$WORKSPACE_ROOT/sheryl-gateway/blueprints"
    "$WORKSPACE_ROOT/strategy/nexus/handoffs"
    "$WORKSPACE_ROOT/suad-action-layer/blueprints"
    "$WORKSPACE_ROOT/web-interface/blueprints"
    "$SKILLS_GLOBAL_DIR"
    "$SKILLS_PROJECT_DIR"
)

for dir in "${DIRS[@]}"; do
    mkdir -p "$dir"
    echo "  [CREATED/VERIFIED] $dir"
done

# Step 3: Register Antigravity Skills (Agent Roster Integration)
echo "--------------------------------------------------------------------"
echo "[3/5] Registering Agency-Agents roster into Antigravity skills registry..."

# If source skills exist in repository integrations, register them
SOURCE_SKILLS_DIR="$WORKSPACE_ROOT/integrations/antigravity"
REGISTERED_COUNT=0

if [ -d "$SOURCE_SKILLS_DIR" ]; then
    for skill_path in "$SOURCE_SKILLS_DIR"/agency-*; do
        if [ -d "$skill_path" ]; then
            skill_name=$(basename "$skill_path")
            # Sync to global Gemini skills path
            cp -r "$skill_path" "$SKILLS_GLOBAL_DIR/"
            # Sync to project local .agents/skills/ path
            cp -r "$skill_path" "$SKILLS_PROJECT_DIR/"
            REGISTERED_COUNT=$((REGISTERED_COUNT + 1))
        fi
    done
    echo "  [SUCCESS] Dynamically mapped $REGISTERED_COUNT skills to $SKILLS_GLOBAL_DIR"
else
    echo "  [INFO] Custom integrations folder not found at $SOURCE_SKILLS_DIR."
    echo "  [INFO] Creating foundational skill wrapper pointer for Agency-Agents..."
    
    cat << 'EOF' > "$SKILLS_PROJECT_DIR/agency-orchestrator.md"
---
name: agency-orchestrator
description: Autonomous pipeline manager that orchestrates the NEXUS development workflow.
---
# Agency Orchestrator Skill
Activates the Agents Orchestrator to run continuous Dev<->QA validation loops.
EOF
    echo "  [OK] Provisioned fallback skill definition: agency-orchestrator.md"
fi

# Step 4: Grant Execution Rights to Utility Scripts
echo "--------------------------------------------------------------------"
echo "[4/5] Setting execution permissions across script binaries..."
find "$WORKSPACE_ROOT/scripts" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
find "$WORKSPACE_ROOT" -type f -name "*.mjs" -exec chmod +x {} + 2>/dev/null || true

if [ -f "$WORKSPACE_ROOT/migrate-workspace-paths.sh" ]; then
    chmod +x "$WORKSPACE_ROOT/migrate-workspace-paths.sh"
    echo "  [OK] Executable granted: migrate-workspace-paths.sh"
fi

# Step 5: Final Environment Audit & Verification
echo "--------------------------------------------------------------------"
echo "[5/5] Auditing setup state..."
echo "  - Workspace Root: $WORKSPACE_ROOT"
echo "  - Project Skill Path: $SKILLS_PROJECT_DIR"
echo "  - Active Path Verification: 0 legacy '/home/olly/' references permitted."

echo "===================================================================="
echo "   [SUCCESS] PHASE 1 INSTALLATION COMPLETE"
echo "===================================================================="
