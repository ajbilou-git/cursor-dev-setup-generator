#!/usr/bin/env bash
set -euo pipefail

TICKET="${1:-}"
STATUS="${2:-APPROVED}"
REPO="${3:-}"
BRANCH="${4:-}"
PR_URL="${5:-}"
SUMMARY="${6:-}"

if [[ -z "$TICKET" || -z "$REPO" || -z "$BRANCH" ]]; then
  echo "Usage: $0 TICKET STATUS REPO BRANCH PR_URL SUMMARY"
  exit 1
fi

if [[ -z "${TEAMS_WEBHOOK_URL:-}" ]]; then
  echo "TEAMS_WEBHOOK_URL not set"
  exit 1
fi

if [[ "$STATUS" == "APPROVED" ]]; then
  THEME_COLOR="{{TEAMS_COLOR_APPROVED}}"
else
  THEME_COLOR="{{TEAMS_COLOR_REJECTED}}"
fi

OWNER="{{GITHUB_ORG}}"
COMPARE_URL="https://github.com/${OWNER}/${REPO}/compare/{{PROTECTED_BRANCH}}...${BRANCH}"
PR_VALUE="${PR_URL:-$COMPARE_URL}"
[[ -z "$PR_VALUE" ]] && PR_VALUE="$COMPARE_URL"

PAYLOAD=$(export _TEAMS_TICKET="$TICKET" _TEAMS_STATUS="$STATUS" _TEAMS_REPO="$REPO" _TEAMS_BRANCH="$BRANCH" _TEAMS_PR="$PR_VALUE" _TEAMS_SUMMARY="$SUMMARY" _TEAMS_COLOR="$THEME_COLOR" && python3 -c "
import json, os
d = {
    '@type': 'MessageCard',
    '@context': 'https://schema.org/extensions',
    'themeColor': os.environ['_TEAMS_COLOR'],
    'summary': 'Dev Pipeline ' + os.environ['_TEAMS_TICKET'],
    'sections': [{
        'activityTitle': 'Dev Pipeline — ' + os.environ['_TEAMS_TICKET'],
        'activitySubtitle': 'Status: ' + os.environ['_TEAMS_STATUS'],
        'facts': [
            {'name': 'Ticket', 'value': os.environ['_TEAMS_TICKET']},
            {'name': 'Repo', 'value': os.environ['_TEAMS_REPO']},
            {'name': 'Branch', 'value': os.environ['_TEAMS_BRANCH']},
            {'name': 'PR', 'value': os.environ['_TEAMS_PR']},
            {'name': 'Résumé', 'value': os.environ['_TEAMS_SUMMARY']}
        ]
    }]
}
print(json.dumps(d))
")

curl -s -X POST -H "Content-Type: application/json" -d "$PAYLOAD" "$TEAMS_WEBHOOK_URL"
