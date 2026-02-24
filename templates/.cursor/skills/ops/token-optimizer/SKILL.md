---
name: token-optimizer
description: Analyzes workspace code for patterns that waste LLM context tokens. Scans skills, rules, source code, and config for verbosity, dead code, duplication, and bloat. Proposes and applies optimizations automatically. Use after running agent skills, when the user asks to optimize tokens, reduce context size, or improve prompt efficiency.
---

# Token Optimizer (Agent)

Workflow: scan workspace → detect token-waste patterns → score severity → display findings in chat → apply fixes automatically.

## Trigger

- *"Optimize tokens"*
- *"Detect token waste"*
- *"Run token-optimizer"*
- *"Reduce context size"*
- After any skill execution (dev-expert, dev-pipeline, security-reviewer, etc.) as a post-run optimization pass

**Input**: Optional — specific path or file to analyze. Default: full workspace scan.

## Rules

- **Non-blocking**: Never interrupt running pipelines or other skills
- **Safe rewrites**: Preserve semantics — only remove what is provably unused or redundant
- **No comments rule**: Workspace enforces no-comments; flag any surviving comments as waste
- **Signed commits**: If changes are committed, use `git commit -S -m "..."`
- **Language**: English for all outputs

## Token Waste Categories

| ID | Category | Target Files | Severity Weight |
|----|----------|-------------|-----------------|
| W1 | Verbose LLM instructions | `.cursor/skills/**`, `.cursor/rules/**` | HIGH |
| W2 | Redundant/duplicate content | Cross-file (skills, rules) | HIGH |
| W3 | Dead code & unused imports | `*.java`, `*.ts`, `*.py`, `*.tf` | MEDIUM |
| W4 | Commented-out code blocks | All source files | HIGH |
| W5 | Oversized files (>500 lines) | All files | MEDIUM |
| W6 | Excessive examples in prompts | `.cursor/skills/**` | MEDIUM |
| W7 | Explanations LLM already knows | `.cursor/skills/**`, `.cursor/rules/**` | HIGH |
| W8 | Unused variables/functions | All source files | MEDIUM |
| W9 | Duplicated code blocks | Within and across files | LOW |
| W10 | Binary/generated files in context | Workspace root | HIGH |
| W11 | Verbose logging strings | All source files | LOW |
| W12 | Redundant type annotations | `*.ts`, `*.py` | LOW |

## Workflow Steps

### 1. Inventory workspace

List all files that contribute to context. Build a file manifest with line counts:

```
find . -type f \( -name "*.md" -o -name "*.mdc" -o -name "*.java" -o -name "*.ts" \
  -o -name "*.py" -o -name "*.tf" -o -name "*.yaml" -o -name "*.yml" \
  -o -name "*.json" -o -name "*.sh" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/build/*" \
  -not -path "*/dist/*" -not -path "*/__pycache__/*" \
  | xargs wc -l | sort -rn | head -40
```

Flag files > 500 lines as W5 candidates.

### 2. Scan .cursor/ for prompt bloat (W1, W2, W6, W7)

For each file in `.cursor/skills/` and `.cursor/rules/`:

**W1 — Verbose instructions**: Detect paragraphs that explain concepts an LLM inherently knows (HTTP methods, git basics, what JSON is, standard library usage). Flag text that could be replaced by a one-liner.

**W2 — Duplicate content**: Compare rule/skill files pairwise. Flag identical or near-identical paragraphs (>3 lines matching) across files. Suggest extracting to a shared reference.

**W6 — Excessive examples**: Count examples per skill. If >3 examples illustrate the same pattern, flag for reduction.

**W7 — Known-to-LLM explanations**: Flag definitions of widely known terms, tutorials on standard tools, boilerplate disclaimers. Example patterns:
- "JSON (JavaScript Object Notation) is a format..."
- "Git is a version control system..."
- "Docker containers are lightweight..."

### 3. Scan source code (W3, W4, W5, W8, W9, W11, W12)

**W3 — Dead code & unused imports**:
- Java: `grep -rn "^import " --include="*.java"` then verify each import is used
- TypeScript: look for `import` statements where the symbol never appears elsewhere in file
- Python: `import` statements with unused symbols

**W4 — Commented-out code**:
- Detect `//`, `/* */`, `#` blocks that contain code patterns (assignments, function calls, control flow)
- Exclude license headers and TODOs

**W8 — Unused variables/functions**:
- Private methods/functions never called within the file or project
- Variables assigned but never read

**W9 — Duplicated blocks**:
- Detect >=5 consecutive lines identical across files

**W11 — Verbose logging**:
- Log statements with string concatenation or long template literals that inflate token count at runtime AND in context

**W12 — Redundant type annotations**:
- TypeScript: explicit types where inference is obvious (`const x: number = 5`)
- Python: redundant type hints on simple assignments

### 4. Detect binary/generated files (W10)

Flag:
- `*.min.js`, `*.min.css`, `*.map` in tracked files
- `package-lock.json`, `poetry.lock` if >5000 lines (suggest .cursorignore)
- Image/font files tracked in git
- Auto-generated code (swagger, protobuf stubs) without `.cursorignore` entry

### 5. Score and rank findings

Calculate a token-waste score per finding:

```
score = estimated_tokens_saved × severity_weight
```

Severity weights: HIGH=3, MEDIUM=2, LOW=1

Estimate tokens: ~4 chars per token for English/code.

Sort findings by score descending.

### 6. Display results in chat

Present a summary table:

```markdown
## Token Optimization Report

**Total estimated waste**: ~{N} tokens ({pct}% of workspace context)

| # | Category | File | Lines | Est. Tokens | Action |
|---|----------|------|-------|-------------|--------|
| 1 | W1 Verbose | .cursor/skills/foo/SKILL.md | 45-60 | ~800 | Rewrite |
| 2 | W4 Commented | src/main/Service.java | 112-130 | ~450 | Remove |
| ... | | | | | |

### Top 5 Quick Wins
1. ...
2. ...
```

### 7. Apply fixes automatically

For each finding, apply the appropriate fix:

| Category | Fix Strategy |
|----------|-------------|
| W1 | Rewrite verbose paragraphs into concise directives |
| W2 | Extract duplicate content to shared reference file |
| W3 | Remove unused imports |
| W4 | Delete commented-out code blocks |
| W5 | Suggest file splits (do not auto-split, flag only) |
| W6 | Reduce to 2 examples max per pattern |
| W7 | Replace explanations with one-line directives |
| W8 | Remove unused private functions/variables |
| W9 | Flag only (requires refactoring decision) |
| W10 | Add entries to `.cursorignore` |
| W11 | Simplify to structured logging |
| W12 | Remove redundant annotations |

After applying fixes, show a before/after token count comparison.

### 8. Post-execution summary

```markdown
## Optimization Applied

| Metric | Before | After | Saved |
|--------|--------|-------|-------|
| Total files | X | Y | -Z |
| Total lines | X | Y | -Z |
| Est. tokens | X | Y | -Z ({pct}%) |

### Changes Applied
- [file1]: removed N lines (W3, W4)
- [file2]: rewritten (W1) — saved ~X tokens
- .cursorignore: added N entries (W10)
```

## Post-Skill Integration

When running after another skill (dev-expert, dev-pipeline, etc.):

1. Wait for the skill to complete fully
2. Identify files modified by the skill (from git diff)
3. Run token-optimizer scoped to those files only
4. Apply fixes on the same branch (before push/PR if possible)
5. Include token savings in chat summary

## Scope Control

| Mode | Command | Scope |
|------|---------|-------|
| Full | `"Run token-optimizer"` | Entire workspace |
| Scoped | `"Optimize tokens in {{REPO_BACK_NAME}}"` | Single repo |
| Post-skill | Automatic after skill run | Modified files only |
| File | `"Optimize tokens in path/to/file"` | Single file |

## Error Handling

| Situation | Action |
|-----------|--------|
| File is read-only | Skip, flag in report |
| Fix would break semantics | Skip, flag as manual review needed |
| No waste detected | Report clean state, no changes |
| Large workspace (>1000 files) | Sample top 100 by size, scan .cursor/ fully |
