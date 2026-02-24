#!/usr/bin/env bash
set -euo pipefail

ARTIFACTS_DIR="${1:-}"
OUTPUT_FILE="${2:-}"
PR_NUMBER="${3:-}"
BRANCH="${4:-}"
RUN_URL="${5:-}"

if [ -z "$ARTIFACTS_DIR" ] || [ -z "$OUTPUT_FILE" ]; then
  echo "Usage: $0 <artifacts_dir> <output_file> [pr_number] [branch] [run_url]"
  exit 1
fi

describe() {
  local action="$1"
  local address="$2"
  case "$action" in
    replace)
      [[ "$address" == *"AzureMonitorLinuxAgent"* ]] && echo "Extension version upgrade (1.0 → 1.29)" && return
      [[ "$address" == *"grafana_firewall_rule"* ]] && [[ "$address" != *"["* ]] && echo "Replaced by for_each rules (one per IP)" && return
      [[ "$address" == *"key_vault_secret"* ]] && echo "Secret recreated (value or metadata change)" && return
      [[ "$address" == *"random_password"* ]] || [[ "$address" == *"time_rotating"* ]] && echo "Recreate (dependent resource)" && return
      [[ "$address" == *"null_resource"* ]] && echo "Trigger logic updated (new keys)" && return
      [[ "$address" == *"mysql_flexible_server"* ]] && echo "Cascade from firewall rules change" && return
      echo "Recreate (in-place not supported)" ;;
    create)
      [[ "$address" == *"grafana_firewall_rule"* ]] && [[ "$address" == *"["* ]] && echo "New firewall rule per Grafana outbound IP" && return
      [[ "$address" == *"time_rotating"* ]] && echo "Rotation trigger" && return
      echo "New resource" ;;
    update)
      [[ "$address" == *"key_vault_secret"* ]] && echo "Secret value rotation" && return
      echo "Attribute change" ;;
    delete)
      [[ "$address" == *"grafana_firewall_rule"* ]] && [[ "$address" != *"["* ]] && echo "Replaced by for_each rules" && return
      [[ "$address" == *"null_resource"* ]] && echo "Trigger logic updated" && return
      echo "Resource removed" ;;
    no-op) echo "No change" ;;
    *) echo "-" ;;
  esac
}

DATE=$(date +%Y-%m-%d)

{
  echo "# Terraform Plan Summary — PR #${PR_NUMBER:-N/A}"
  echo ""
  echo "**Branch**: ${BRANCH:-N/A}"
  echo "**Workflow run**: ${RUN_URL:-N/A}"
  echo "**Date**: $DATE"
  echo ""
  echo "## Summary"
  echo ""
  echo "| Environment | Layer | Create | Update | Delete | Replace |"
  echo "|-------------|-------|--------|--------|--------|--------|"
} > "$OUTPUT_FILE"

for artifact_dir in "$ARTIFACTS_DIR"/json-files-*; do
  [ -d "$artifact_dir" ] || continue
  name=$(basename "$artifact_dir")
  env=$(echo "$name" | sed 's/json-files-\([^-]*\)-.*/\1/')
  for file in "$artifact_dir"/*.json; do
    [ -f "$file" ] || continue
    layer=$(basename "$file" .json)
    create=$(jq '[.resource_changes[]? | select(.change.actions==["create"])] | length' "$file" 2>/dev/null || echo 0)
    update=$(jq '[.resource_changes[]? | select(.change.actions[0]=="update")] | length' "$file" 2>/dev/null || echo 0)
    delete=$(jq '[.resource_changes[]? | select(.change.actions==["delete"])] | length' "$file" 2>/dev/null || echo 0)
    replace=$(jq '[.resource_changes[]? | select((.change.actions | index("delete")) and (.change.actions | index("create")))] | length' "$file" 2>/dev/null || echo 0)
    echo "| $env | $layer | $create | $update | $delete | $replace |" >> "$OUTPUT_FILE"
  done
done

{
  echo ""
  echo "## Detailed changes"
  echo ""
  echo "| Action | Resource | Description |"
  echo "|--------|----------|-------------|"
} >> "$OUTPUT_FILE"

for artifact_dir in "$ARTIFACTS_DIR"/json-files-*; do
  [ -d "$artifact_dir" ] || continue
  for file in "$artifact_dir"/*.json; do
    [ -f "$file" ] || continue
    while IFS= read -r obj; do
      [ -z "$obj" ] && continue
      action_first=$(echo "$obj" | jq -r '.change.actions[0]')
      [ "$action_first" = "no-op" ] && continue
      address=$(echo "$obj" | jq -r '.address')
      actions=$(echo "$obj" | jq -r '.change.actions | join(",")')
      if echo "$actions" | grep -q "delete" && echo "$actions" | grep -q "create"; then
        action="replace"
      else
        action=$(echo "$obj" | jq -r '.change.actions[0]')
      fi
      desc=$(describe "$action" "$address")
      echo "| $action | $address | $desc |" >> "$OUTPUT_FILE"
    done < <(jq -c '.resource_changes[]?' "$file" 2>/dev/null)
  done
done
