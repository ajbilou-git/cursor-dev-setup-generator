#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"
VARIABLES_FILE="${SCRIPT_DIR}/variables.env"
FEATURES_FILE="${SCRIPT_DIR}/features.conf"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_MODE=false

for arg in "$@"; do
  case "$arg" in
    --install) INSTALL_MODE=true ;;
  esac
done

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

generated_count=0

print_header() {
  printf "\n"
  printf "${BOLD}╔══════════════════════════════════════════════╗${NC}\n"
  printf "${BOLD}║   Cursor DevOps Workspace Generator          ║${NC}\n"
  printf "${BOLD}╚══════════════════════════════════════════════╝${NC}\n"
  printf "\n"
}

load_env_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    local key="${line%%=*}"
    key="$(printf '%s' "$key" | tr -d '[:space:]')"
    [[ -z "$key" ]] && continue
    local raw_value="${line#*=}"
    raw_value="${raw_value%%#*}"
    raw_value="$(printf '%s' "$raw_value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    export "$key=$raw_value"
    ALL_VARS+=("$key")
  done < "$file"
}

load_variables() {
  if [[ ! -f "$VARIABLES_FILE" ]]; then
    printf "${RED}ERROR: variables.env not found at %s${NC}\n" "$VARIABLES_FILE"
    exit 1
  fi

  ALL_VARS=()
  load_env_file "$VARIABLES_FILE"

  if [[ -f "$FEATURES_FILE" ]]; then
    printf "${GREEN}✓${NC} Loading features.conf\n"
    load_env_file "$FEATURES_FILE"
  fi
}

validate_required() {
  local required=(PROJECT_NAME GITHUB_ORG)
  local missing=()

  for var in "${required[@]}"; do
    if [[ -z "${!var:-}" ]]; then
      missing+=("$var")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    printf "${RED}ERROR: The following required variables are empty:${NC}\n"
    for var in "${missing[@]}"; do
      printf "  ${RED}✗${NC} %s\n" "$var"
    done
    printf "\nPlease fill them in variables.env and try again.\n"
    exit 1
  fi

  if ! has_var REPO_BACK_NAME && ! has_var REPO_FRONT_NAME && ! has_var REPO_DATA_NAME; then
    printf "${RED}ERROR: At least one repo must be defined (REPO_BACK_NAME, REPO_FRONT_NAME, or REPO_DATA_NAME).${NC}\n"
    exit 1
  fi

  printf "${GREEN}✓${NC} All required variables validated\n"
}

process_template() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"

  local content
  content="$(<"$src")"

  for var_name in "${ALL_VARS[@]}"; do
    local var_value="${!var_name:-}"
    content="${content//\{\{${var_name}\}\}/${var_value}}"
  done

  printf '%s\n' "$content" > "$dest"
  generated_count=$((generated_count + 1))
}

has_var() {
  [[ -n "${!1:-}" ]]
}

generate() {
  local OUT="${SCRIPT_DIR}/output/${PROJECT_NAME}"

  if [[ -d "$OUT" ]]; then
    printf "${YELLOW}Output directory already exists. Overwriting.${NC}\n"
    rm -rf "$OUT"
  fi

  mkdir -p "$OUT"
  printf "${BLUE}Generating workspace for: ${BOLD}%s${NC}\n\n" "$PROJECT_NAME"

  local T="$TEMPLATES_DIR"

  printf "  ${BOLD}Rules (restrictions)${NC}\n"
  process_template "$T/.cursor/rules/restrictions/no-comments.mdc"        "$OUT/.cursor/rules/restrictions/no-comments.mdc"
  process_template "$T/.cursor/rules/restrictions/no-ai-meta-mention.mdc" "$OUT/.cursor/rules/restrictions/no-ai-meta-mention.mdc"
  process_template "$T/.cursor/rules/restrictions/no-modify-existing.mdc" "$OUT/.cursor/rules/restrictions/no-modify-existing.mdc"
  process_template "$T/.cursor/rules/restrictions/git-workflow-branch.mdc" "$OUT/.cursor/rules/restrictions/git-workflow-branch.mdc"
  process_template "$T/.cursor/rules/restrictions/no-github-write.mdc"    "$OUT/.cursor/rules/restrictions/no-github-write.mdc"

  if [[ "${CLOUD_PROVIDER:-}" == "azure" ]]; then
    process_template "$T/.cursor/rules/restrictions/azure-read-only.mdc" "$OUT/.cursor/rules/restrictions/azure-read-only.mdc"
  fi

  if [[ "${ISSUE_TRACKER:-}" == "jira" ]]; then
    process_template "$T/.cursor/rules/restrictions/no-jira-write.mdc" "$OUT/.cursor/rules/restrictions/no-jira-write.mdc"
  fi

  printf "  ${BOLD}Rules (competences)${NC}\n"
  process_template "$T/.cursor/rules/competences/devops-senior-engineer.mdc" "$OUT/.cursor/rules/competences/devops-senior-engineer.mdc"
  process_template "$T/.cursor/rules/competences/coderabbit-cli.mdc"         "$OUT/.cursor/rules/competences/coderabbit-cli.mdc"

  if has_var REPO_BACK_NAME; then
    process_template "$T/.cursor/rules/competences/back-conventions.mdc" "$OUT/.cursor/rules/competences/${REPO_BACK_NAME}-conventions.mdc"
  fi

  if has_var REPO_FRONT_NAME; then
    process_template "$T/.cursor/rules/competences/front-conventions.mdc" "$OUT/.cursor/rules/competences/${REPO_FRONT_NAME}-conventions.mdc"
  fi

  if has_var REPO_DATA_NAME; then
    process_template "$T/.cursor/rules/competences/data-conventions.mdc" "$OUT/.cursor/rules/competences/${REPO_DATA_NAME}-conventions.mdc"
  fi

  if has_var REPO_INFRA_NAME; then
    process_template "$T/.cursor/rules/competences/terraform-iac-expert.mdc"  "$OUT/.cursor/rules/competences/terraform-iac-expert.mdc"
    process_template "$T/.cursor/rules/competences/infra-general.mdc"         "$OUT/.cursor/rules/competences/${REPO_INFRA_NAME}-general.mdc"
    process_template "$T/.cursor/rules/competences/infra-terraform.mdc"       "$OUT/.cursor/rules/competences/${REPO_INFRA_NAME}-terraform.mdc"
    process_template "$T/.cursor/rules/competences/infra-workflows.mdc"       "$OUT/.cursor/rules/competences/${REPO_INFRA_NAME}-workflows.mdc"
    process_template "$T/.cursor/rules/competences/infra-nsg-yaml.mdc"        "$OUT/.cursor/rules/competences/${REPO_INFRA_NAME}-nsg-yaml.mdc"
    process_template "$T/.cursor/rules/competences/infra-sync-versions.mdc"   "$OUT/.cursor/rules/competences/${REPO_INFRA_NAME}-sync-versions.mdc"
  fi

  printf "  ${BOLD}Skills (dev)${NC}\n"
  if has_var REPO_BACK_NAME || has_var REPO_FRONT_NAME || has_var REPO_DATA_NAME; then
    process_template "$T/.cursor/skills/dev/dev-expert/SKILL.md"     "$OUT/.cursor/skills/dev/dev-expert/SKILL.md"
    process_template "$T/.cursor/skills/dev/dev-expert/reference.md"  "$OUT/.cursor/skills/dev/dev-expert/reference.md"
    process_template "$T/.cursor/skills/dev/dev-approval/SKILL.md"   "$OUT/.cursor/skills/dev/dev-approval/SKILL.md"
    process_template "$T/.cursor/skills/dev/security-reviewer/SKILL.md" "$OUT/.cursor/skills/dev/security-reviewer/SKILL.md"

    if [[ "${ISSUE_TRACKER:-}" != "none" ]]; then
      process_template "$T/.cursor/skills/dev/dev-pipeline/SKILL.md"     "$OUT/.cursor/skills/dev/dev-pipeline/SKILL.md"
      process_template "$T/.cursor/skills/dev/dev-pipeline/reference.md"  "$OUT/.cursor/skills/dev/dev-pipeline/reference.md"

      local teams_enabled="${TEAMS_NOTIFICATIONS:-false}"
      if [[ "${NOTIFICATION_CHANNEL:-}" == "teams" ]] && { has_var TEAMS_WEBHOOK_URL || [[ "$teams_enabled" == "true" ]]; }; then
        process_template "$T/.cursor/skills/dev/dev-pipeline/teams_notify.sh" "$OUT/.cursor/skills/dev/dev-pipeline/teams_notify.sh"
        chmod +x "$OUT/.cursor/skills/dev/dev-pipeline/teams_notify.sh"
        process_template "$T/.cursor/skills/dev/dev-pipeline/.env" "$OUT/.cursor/skills/dev/dev-pipeline/.env"
      fi

      if has_var CONFLUENCE_SITE_NAME; then
        process_template "$T/.cursor/skills/dev/dev-pipeline/confluence-context.md" "$OUT/.cursor/skills/dev/dev-pipeline/confluence-context.md"
      fi
    fi
  fi

  printf "  ${BOLD}Skills (ops)${NC}\n"
  process_template "$T/.cursor/skills/ops/token-optimizer/SKILL.md" "$OUT/.cursor/skills/ops/token-optimizer/SKILL.md"

  if [[ "${ISSUE_TRACKER:-}" != "none" ]]; then
    process_template "$T/.cursor/skills/ops/sprint-reporter/SKILL.md" "$OUT/.cursor/skills/ops/sprint-reporter/SKILL.md"
  fi

  if has_var CONFLUENCE_SITE_NAME; then
    process_template "$T/.cursor/skills/ops/doc-sync/SKILL.md" "$OUT/.cursor/skills/ops/doc-sync/SKILL.md"
  fi

  if has_var REPO_INFRA_NAME; then
    process_template "$T/.cursor/skills/ops/infra-bootstrap-workflow/SKILL.md"                              "$OUT/.cursor/skills/ops/infra-bootstrap-workflow/SKILL.md"
    process_template "$T/.cursor/skills/ops/infra-bootstrap-plan-validator/SKILL.md"                        "$OUT/.cursor/skills/ops/infra-bootstrap-plan-validator/SKILL.md"
    process_template "$T/.cursor/skills/ops/infra-bootstrap-plan-validator/scripts/parse-plan-artifacts.sh" "$OUT/.cursor/skills/ops/infra-bootstrap-plan-validator/scripts/parse-plan-artifacts.sh"
    chmod +x "$OUT/.cursor/skills/ops/infra-bootstrap-plan-validator/scripts/parse-plan-artifacts.sh"
    process_template "$T/.cursor/skills/ops/infra-bootstrap-pipeline/SKILL.md" "$OUT/.cursor/skills/ops/infra-bootstrap-pipeline/SKILL.md"
  fi

  if has_var REPO_BOOTSTRAP_NAME; then
    printf "  ${BOLD}Skills (bootstrap)${NC}\n"
    process_template "$T/.cursor/skills/bootstrap/bootstrap-devops-expert/SKILL.md"    "$OUT/.cursor/skills/bootstrap/bootstrap-devops-expert/SKILL.md"
    process_template "$T/.cursor/skills/bootstrap/bootstrap-devops-expert/reference.md" "$OUT/.cursor/skills/bootstrap/bootstrap-devops-expert/reference.md"
    process_template "$T/.cursor/bootstrap-devops-reports/README.md" "$OUT/.cursor/bootstrap-devops-reports/README.md"
    mkdir -p "$OUT/.cursor/bootstrap-align-reports"
  fi

  printf "  ${BOLD}Docs${NC}\n"
  process_template "$T/.cursor/docs/dev-local-setup.md"                    "$OUT/.cursor/docs/dev-local-setup.md"
  process_template "$T/.cursor/docs/functional-context.md"                 "$OUT/.cursor/docs/functional-context.md"
  process_template "$T/.cursor/docs/setup-new-env.md"                      "$OUT/.cursor/docs/setup-new-env.md"
  process_template "$T/.cursor/docs/setup-new-env-variables.template.md"   "$OUT/.cursor/docs/setup-new-env-variables.template.md"
  process_template "$T/.cursor/dev-reports/README.md"                      "$OUT/.cursor/dev-reports/README.md"

  if [[ "${ISSUE_TRACKER:-}" == "jira" ]]; then
    printf "  ${BOLD}Jira templates${NC}\n"
    process_template "$T/.cursor/jira-templates/README.md"             "$OUT/.cursor/jira-templates/README.md"
    if has_var REPO_BACK_NAME; then
      process_template "$T/.cursor/jira-templates/jira-ticket-back.md" "$OUT/.cursor/jira-templates/jira-ticket-back.md"
    fi
    if has_var REPO_FRONT_NAME; then
      process_template "$T/.cursor/jira-templates/jira-ticket-front.md" "$OUT/.cursor/jira-templates/jira-ticket-front.md"
    fi
    if has_var REPO_DATA_NAME; then
      process_template "$T/.cursor/jira-templates/jira-ticket-data.md" "$OUT/.cursor/jira-templates/jira-ticket-data.md"
    fi
  fi

  printf "  ${BOLD}Root files${NC}\n"
  process_template "$T/Makefile"   "$OUT/Makefile"
  process_template "$T/.gitignore" "$OUT/.gitignore"
  process_template "$T/mcp.json"   "$OUT/mcp.json"

  if [[ -f "$FEATURES_FILE" ]]; then
    cp -f "$FEATURES_FILE" "$OUT/.cursor/features.conf"
    generated_count=$((generated_count + 1))
  fi
}

install_to_workspace() {
  local OUT="${SCRIPT_DIR}/output/${PROJECT_NAME}"

  printf "\n${BLUE}${BOLD}Installing to workspace: %s${NC}\n\n" "$WORKSPACE_ROOT"

  cp -rf "$OUT/.cursor" "$WORKSPACE_ROOT/"
  printf "  ${GREEN}✓${NC} .cursor/ → %s/.cursor/\n" "$WORKSPACE_ROOT"

  cp -f "$OUT/Makefile" "$WORKSPACE_ROOT/"
  printf "  ${GREEN}✓${NC} Makefile → %s/Makefile\n" "$WORKSPACE_ROOT"

  cp -f "$OUT/.gitignore" "$WORKSPACE_ROOT/"
  printf "  ${GREEN}✓${NC} .gitignore → %s/.gitignore\n" "$WORKSPACE_ROOT"

  local MCP_SRC="$OUT/mcp.json"
  if [[ -f "$MCP_SRC" ]]; then
    local MCP_USER_DIR="$HOME/.cursor"
    mkdir -p "$MCP_USER_DIR"
    if [[ -f "$MCP_USER_DIR/mcp.json" ]]; then
      cp -f "$MCP_USER_DIR/mcp.json" "$MCP_USER_DIR/mcp.json.bak"
      printf "  ${YELLOW}⚠${NC} Existing ~/.cursor/mcp.json backed up to mcp.json.bak\n"
    fi
    cp -f "$MCP_SRC" "$MCP_USER_DIR/mcp.json"
    printf "  ${GREEN}✓${NC} mcp.json → %s/mcp.json\n" "$MCP_USER_DIR"
  fi

  printf "\n${GREEN}${BOLD}✓ Workspace installed successfully!${NC}\n"
}

print_summary() {
  local OUT="${SCRIPT_DIR}/output/${PROJECT_NAME}"
  local file_count
  file_count=$(find "$OUT" -type f | wc -l | tr -d '[:space:]')

  printf "\n"
  printf "${GREEN}${BOLD}✓ Workspace generated successfully!${NC}\n\n"
  printf "  ${BOLD}Location:${NC}  %s\n" "$OUT"
  printf "  ${BOLD}Files:${NC}     %s files generated\n\n" "$file_count"

  if [[ "$INSTALL_MODE" == true ]]; then
    printf "  ${BOLD}Status:${NC}    Installed to workspace root\n\n"
  else
    printf "  ${BOLD}Next steps:${NC}\n"
    printf "    Run again with --install to auto-copy to workspace root:\n"
    printf "      ${BOLD}bash generate.sh --install${NC}\n\n"
    printf "    Or copy manually:\n"
    printf "      cp -rf %s/.cursor .\n" "$OUT"
    printf "      cp %s/Makefile .\n" "$OUT"
    printf "      cp %s/mcp.json ~/.cursor/mcp.json\n\n" "$OUT"
  fi

  printf "  ${BOLD}Generated structure:${NC}\n"
  if command -v tree &>/dev/null; then
    tree "$OUT" --noreport 2>/dev/null | tail -n +2
  else
    find "$OUT" -type f | sed "s|$OUT/||" | sort | while read -r f; do
      printf "    %s\n" "$f"
    done
  fi
  printf "\n"
}

print_header
printf "Step 1/3: Loading variables...\n"
load_variables
printf "Step 2/3: Validating...\n"
validate_required
printf "Step 3/3: Generating workspace...\n\n"
generate

if [[ "$INSTALL_MODE" == true ]]; then
  install_to_workspace
fi

print_summary
