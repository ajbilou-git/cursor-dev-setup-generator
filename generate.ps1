param(
  [switch]$Install
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$TemplatesDir = Join-Path $ScriptDir "templates"
$VariablesFile = Join-Path $ScriptDir "variables.env"
$WorkspaceRoot = Split-Path -Parent $ScriptDir

$vars = @{}
$generatedCount = 0

function Print-Header {
  Write-Host ""
  Write-Host "================================================" -ForegroundColor Cyan
  Write-Host "   Cursor DevOps Workspace Generator" -ForegroundColor Cyan
  Write-Host "================================================" -ForegroundColor Cyan
  Write-Host ""
}

function Load-Variables {
  if (-not (Test-Path $VariablesFile)) {
    Write-Host "ERROR: variables.env not found at $VariablesFile" -ForegroundColor Red
    exit 1
  }

  $lines = Get-Content $VariablesFile -Encoding UTF8
  foreach ($line in $lines) {
    $trimmed = $line.Trim()
    if ([string]::IsNullOrEmpty($trimmed) -or $trimmed.StartsWith("#")) { continue }

    $eqIndex = $trimmed.IndexOf("=")
    if ($eqIndex -lt 1) { continue }

    $key = $trimmed.Substring(0, $eqIndex).Trim()
    $rawValue = $trimmed.Substring($eqIndex + 1)

    $commentIndex = $rawValue.IndexOf("#")
    if ($commentIndex -ge 0) {
      $rawValue = $rawValue.Substring(0, $commentIndex)
    }
    $rawValue = $rawValue.Trim()

    $vars[$key] = $rawValue
  }
}

function Validate-Required {
  $required = @("PROJECT_NAME", "GITHUB_ORG")
  $missing = @()

  foreach ($var in $required) {
    if (-not $vars.ContainsKey($var) -or [string]::IsNullOrEmpty($vars[$var])) {
      $missing += $var
    }
  }

  if ($missing.Count -gt 0) {
    Write-Host "ERROR: The following required variables are empty:" -ForegroundColor Red
    foreach ($var in $missing) {
      Write-Host "  X $var" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Please fill them in variables.env and try again."
    exit 1
  }

  if (-not (Has-Var "REPO_BACK_NAME") -and -not (Has-Var "REPO_FRONT_NAME") -and -not (Has-Var "REPO_DATA_NAME")) {
    Write-Host "ERROR: At least one repo must be defined (REPO_BACK_NAME, REPO_FRONT_NAME, or REPO_DATA_NAME)." -ForegroundColor Red
    exit 1
  }

  Write-Host "OK All required variables validated" -ForegroundColor Green
}

function Has-Var($name) {
  return ($vars.ContainsKey($name) -and -not [string]::IsNullOrEmpty($vars[$name]))
}

function Process-Template {
  param([string]$Src, [string]$Dest)

  $destDir = Split-Path -Parent $Dest
  if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
  }

  $content = Get-Content $Src -Raw -Encoding UTF8
  if ($null -eq $content) { $content = "" }

  foreach ($key in $vars.Keys) {
    $placeholder = "{{$key}}"
    $content = $content.Replace($placeholder, $vars[$key])
  }

  [System.IO.File]::WriteAllText($Dest, $content, [System.Text.UTF8Encoding]::new($false))
  $script:generatedCount++
}

function Generate {
  $projectName = $vars["PROJECT_NAME"]
  $OutDir = Join-Path $ScriptDir "output" $projectName

  if (Test-Path $OutDir) {
    Write-Host "Output directory already exists. Overwriting." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $OutDir
  }

  New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
  Write-Host "Generating workspace for: $projectName" -ForegroundColor Blue
  Write-Host ""

  $T = $TemplatesDir

  Write-Host "  Rules (restrictions)" -ForegroundColor White
  Process-Template "$T/.cursor/rules/restrictions/no-comments.mdc"        "$OutDir/.cursor/rules/restrictions/no-comments.mdc"
  Process-Template "$T/.cursor/rules/restrictions/no-ai-meta-mention.mdc" "$OutDir/.cursor/rules/restrictions/no-ai-meta-mention.mdc"
  Process-Template "$T/.cursor/rules/restrictions/no-modify-existing.mdc" "$OutDir/.cursor/rules/restrictions/no-modify-existing.mdc"
  Process-Template "$T/.cursor/rules/restrictions/git-workflow-branch.mdc" "$OutDir/.cursor/rules/restrictions/git-workflow-branch.mdc"
  Process-Template "$T/.cursor/rules/restrictions/no-github-write.mdc"    "$OutDir/.cursor/rules/restrictions/no-github-write.mdc"

  if ($vars["CLOUD_PROVIDER"] -eq "azure") {
    Process-Template "$T/.cursor/rules/restrictions/azure-read-only.mdc" "$OutDir/.cursor/rules/restrictions/azure-read-only.mdc"
  }

  if ($vars["ISSUE_TRACKER"] -eq "jira") {
    Process-Template "$T/.cursor/rules/restrictions/no-jira-write.mdc" "$OutDir/.cursor/rules/restrictions/no-jira-write.mdc"
  }

  Write-Host "  Rules (competences)" -ForegroundColor White
  Process-Template "$T/.cursor/rules/competences/devops-senior-engineer.mdc" "$OutDir/.cursor/rules/competences/devops-senior-engineer.mdc"
  Process-Template "$T/.cursor/rules/competences/coderabbit-cli.mdc"         "$OutDir/.cursor/rules/competences/coderabbit-cli.mdc"

  $backName = $vars["REPO_BACK_NAME"]
  $frontName = $vars["REPO_FRONT_NAME"]
  $dataName = $vars["REPO_DATA_NAME"]
  $infraName = $vars["REPO_INFRA_NAME"]

  if (Has-Var "REPO_BACK_NAME") {
    Process-Template "$T/.cursor/rules/competences/back-conventions.mdc" "$OutDir/.cursor/rules/competences/$backName-conventions.mdc"
  }

  if (Has-Var "REPO_FRONT_NAME") {
    Process-Template "$T/.cursor/rules/competences/front-conventions.mdc" "$OutDir/.cursor/rules/competences/$frontName-conventions.mdc"
  }

  if (Has-Var "REPO_DATA_NAME") {
    Process-Template "$T/.cursor/rules/competences/data-conventions.mdc" "$OutDir/.cursor/rules/competences/$dataName-conventions.mdc"
  }

  if (Has-Var "REPO_INFRA_NAME") {
    Process-Template "$T/.cursor/rules/competences/terraform-iac-expert.mdc"  "$OutDir/.cursor/rules/competences/terraform-iac-expert.mdc"
    Process-Template "$T/.cursor/rules/competences/infra-general.mdc"         "$OutDir/.cursor/rules/competences/$infraName-general.mdc"
    Process-Template "$T/.cursor/rules/competences/infra-terraform.mdc"       "$OutDir/.cursor/rules/competences/$infraName-terraform.mdc"
    Process-Template "$T/.cursor/rules/competences/infra-workflows.mdc"       "$OutDir/.cursor/rules/competences/$infraName-workflows.mdc"
    Process-Template "$T/.cursor/rules/competences/infra-nsg-yaml.mdc"        "$OutDir/.cursor/rules/competences/$infraName-nsg-yaml.mdc"
    Process-Template "$T/.cursor/rules/competences/infra-sync-versions.mdc"   "$OutDir/.cursor/rules/competences/$infraName-sync-versions.mdc"
  }

  Write-Host "  Skills (dev)" -ForegroundColor White
  if ((Has-Var "REPO_BACK_NAME") -or (Has-Var "REPO_FRONT_NAME") -or (Has-Var "REPO_DATA_NAME")) {
    Process-Template "$T/.cursor/skills/dev/dev-expert/SKILL.md"     "$OutDir/.cursor/skills/dev/dev-expert/SKILL.md"
    Process-Template "$T/.cursor/skills/dev/dev-expert/reference.md"  "$OutDir/.cursor/skills/dev/dev-expert/reference.md"
    Process-Template "$T/.cursor/skills/dev/dev-approval/SKILL.md"   "$OutDir/.cursor/skills/dev/dev-approval/SKILL.md"
    Process-Template "$T/.cursor/skills/dev/security-reviewer/SKILL.md" "$OutDir/.cursor/skills/dev/security-reviewer/SKILL.md"

    if ($vars["ISSUE_TRACKER"] -ne "none") {
      Process-Template "$T/.cursor/skills/dev/dev-pipeline/SKILL.md"     "$OutDir/.cursor/skills/dev/dev-pipeline/SKILL.md"
      Process-Template "$T/.cursor/skills/dev/dev-pipeline/reference.md"  "$OutDir/.cursor/skills/dev/dev-pipeline/reference.md"

      if ($vars["NOTIFICATION_CHANNEL"] -eq "teams" -and (Has-Var "TEAMS_WEBHOOK_URL")) {
        Process-Template "$T/.cursor/skills/dev/dev-pipeline/teams_notify.sh" "$OutDir/.cursor/skills/dev/dev-pipeline/teams_notify.sh"
        Process-Template "$T/.cursor/skills/dev/dev-pipeline/.env" "$OutDir/.cursor/skills/dev/dev-pipeline/.env"
      }

      if (Has-Var "CONFLUENCE_SITE_NAME") {
        Process-Template "$T/.cursor/skills/dev/dev-pipeline/confluence-context.md" "$OutDir/.cursor/skills/dev/dev-pipeline/confluence-context.md"
      }
    }
  }

  Write-Host "  Skills (ops)" -ForegroundColor White
  Process-Template "$T/.cursor/skills/ops/token-optimizer/SKILL.md" "$OutDir/.cursor/skills/ops/token-optimizer/SKILL.md"

  if ($vars["ISSUE_TRACKER"] -ne "none") {
    Process-Template "$T/.cursor/skills/ops/sprint-reporter/SKILL.md" "$OutDir/.cursor/skills/ops/sprint-reporter/SKILL.md"
  }

  if (Has-Var "CONFLUENCE_SITE_NAME") {
    Process-Template "$T/.cursor/skills/ops/doc-sync/SKILL.md" "$OutDir/.cursor/skills/ops/doc-sync/SKILL.md"
  }

  if (Has-Var "REPO_INFRA_NAME") {
    Process-Template "$T/.cursor/skills/ops/infra-bootstrap-workflow/SKILL.md"                              "$OutDir/.cursor/skills/ops/infra-bootstrap-workflow/SKILL.md"
    Process-Template "$T/.cursor/skills/ops/infra-bootstrap-plan-validator/SKILL.md"                        "$OutDir/.cursor/skills/ops/infra-bootstrap-plan-validator/SKILL.md"
    Process-Template "$T/.cursor/skills/ops/infra-bootstrap-plan-validator/scripts/parse-plan-artifacts.sh" "$OutDir/.cursor/skills/ops/infra-bootstrap-plan-validator/scripts/parse-plan-artifacts.sh"
    Process-Template "$T/.cursor/skills/ops/infra-bootstrap-pipeline/SKILL.md" "$OutDir/.cursor/skills/ops/infra-bootstrap-pipeline/SKILL.md"
  }

  if (Has-Var "REPO_BOOTSTRAP_NAME") {
    Write-Host "  Skills (bootstrap)" -ForegroundColor White
    Process-Template "$T/.cursor/skills/bootstrap/bootstrap-devops-expert/SKILL.md"    "$OutDir/.cursor/skills/bootstrap/bootstrap-devops-expert/SKILL.md"
    Process-Template "$T/.cursor/skills/bootstrap/bootstrap-devops-expert/reference.md" "$OutDir/.cursor/skills/bootstrap/bootstrap-devops-expert/reference.md"
    Process-Template "$T/.cursor/bootstrap-devops-reports/README.md" "$OutDir/.cursor/bootstrap-devops-reports/README.md"
    New-Item -ItemType Directory -Path "$OutDir/.cursor/bootstrap-align-reports" -Force | Out-Null
  }

  Write-Host "  Docs" -ForegroundColor White
  Process-Template "$T/.cursor/docs/dev-local-setup.md"                    "$OutDir/.cursor/docs/dev-local-setup.md"
  Process-Template "$T/.cursor/docs/functional-context.md"                 "$OutDir/.cursor/docs/functional-context.md"
  Process-Template "$T/.cursor/docs/setup-new-env.md"                      "$OutDir/.cursor/docs/setup-new-env.md"
  Process-Template "$T/.cursor/docs/setup-new-env-variables.template.md"   "$OutDir/.cursor/docs/setup-new-env-variables.template.md"
  Process-Template "$T/.cursor/dev-reports/README.md"                      "$OutDir/.cursor/dev-reports/README.md"

  if ($vars["ISSUE_TRACKER"] -eq "jira") {
    Write-Host "  Jira templates" -ForegroundColor White
    Process-Template "$T/.cursor/jira-templates/README.md" "$OutDir/.cursor/jira-templates/README.md"
    if (Has-Var "REPO_BACK_NAME") {
      Process-Template "$T/.cursor/jira-templates/jira-ticket-back.md" "$OutDir/.cursor/jira-templates/jira-ticket-back.md"
    }
    if (Has-Var "REPO_FRONT_NAME") {
      Process-Template "$T/.cursor/jira-templates/jira-ticket-front.md" "$OutDir/.cursor/jira-templates/jira-ticket-front.md"
    }
    if (Has-Var "REPO_DATA_NAME") {
      Process-Template "$T/.cursor/jira-templates/jira-ticket-data.md" "$OutDir/.cursor/jira-templates/jira-ticket-data.md"
    }
  }

  Write-Host "  Root files" -ForegroundColor White
  Process-Template "$T/Makefile"   "$OutDir/Makefile"
  Process-Template "$T/.gitignore" "$OutDir/.gitignore"
  Process-Template "$T/mcp.json"   "$OutDir/mcp.json"
}

function Install-ToWorkspace {
  $projectName = $vars["PROJECT_NAME"]
  $OutDir = Join-Path $ScriptDir "output" $projectName

  Write-Host ""
  Write-Host "Installing to workspace: $WorkspaceRoot" -ForegroundColor Blue
  Write-Host ""

  Copy-Item -Path "$OutDir\.cursor" -Destination "$WorkspaceRoot\.cursor" -Recurse -Force
  Write-Host "  OK .cursor\ -> $WorkspaceRoot\.cursor\" -ForegroundColor Green

  Copy-Item -Path "$OutDir\Makefile" -Destination "$WorkspaceRoot\Makefile" -Force
  Write-Host "  OK Makefile -> $WorkspaceRoot\Makefile" -ForegroundColor Green

  Copy-Item -Path "$OutDir\.gitignore" -Destination "$WorkspaceRoot\.gitignore" -Force
  Write-Host "  OK .gitignore -> $WorkspaceRoot\.gitignore" -ForegroundColor Green

  $mcpSrc = Join-Path $OutDir "mcp.json"
  if (Test-Path $mcpSrc) {
    $mcpUserDir = Join-Path $env:USERPROFILE ".cursor"
    if (-not (Test-Path $mcpUserDir)) {
      New-Item -ItemType Directory -Path $mcpUserDir -Force | Out-Null
    }
    $mcpDest = Join-Path $mcpUserDir "mcp.json"
    if (Test-Path $mcpDest) {
      Copy-Item -Path $mcpDest -Destination "$mcpDest.bak" -Force
      Write-Host "  WARNING Existing ~/.cursor/mcp.json backed up to mcp.json.bak" -ForegroundColor Yellow
    }
    Copy-Item -Path $mcpSrc -Destination $mcpDest -Force
    Write-Host "  OK mcp.json -> $mcpDest" -ForegroundColor Green
  }

  Write-Host ""
  Write-Host "OK Workspace installed successfully!" -ForegroundColor Green
}

function Print-Summary {
  $projectName = $vars["PROJECT_NAME"]
  $OutDir = Join-Path $ScriptDir "output" $projectName
  $fileCount = (Get-ChildItem -Path $OutDir -Recurse -File).Count

  Write-Host ""
  Write-Host "OK Workspace generated successfully!" -ForegroundColor Green
  Write-Host ""
  Write-Host "  Location:  $OutDir"
  Write-Host "  Files:     $fileCount files generated"
  Write-Host ""

  if ($Install) {
    Write-Host "  Status:    Installed to workspace root" -ForegroundColor White
  } else {
    Write-Host "  Next steps:" -ForegroundColor White
    Write-Host "    Run again with -Install to auto-copy to workspace root:"
    Write-Host "      .\generate.ps1 -Install" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    Or copy manually:"
    Write-Host "      Copy-Item -Recurse -Force $OutDir\.cursor ."
    Write-Host "      Copy-Item $OutDir\Makefile ."
    Write-Host "      Copy-Item $OutDir\mcp.json ~\.cursor\mcp.json"
  }

  Write-Host ""
  Write-Host "  Generated structure:" -ForegroundColor White
  Get-ChildItem -Path $OutDir -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Replace($OutDir + [IO.Path]::DirectorySeparatorChar, "")
    Write-Host "    $rel"
  }
  Write-Host ""
}

Print-Header
Write-Host "Step 1/3: Loading variables..."
Load-Variables
Write-Host "Step 2/3: Validating..."
Validate-Required
Write-Host "Step 3/3: Generating workspace..."
Write-Host ""
Generate

if ($Install) {
  Install-ToWorkspace
}

Print-Summary
