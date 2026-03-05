# Cursor DEV  Workspace Generator

Generate a ready-to-use Cursor IDE workspace with rules, skills, and integrations — in one command.

## Quick Start

### 1. Clone this repo inside your project workspace

Clone `cursor-dev-setup-generator` **at the root level** of your workspace, next to your existing repos.

Your workspace should look like this (you may have 1 repo or many):

```
my-workspace/              ← you are here
├── my-api/                ← your backend repo (if any)
├── my-web/                ← your frontend repo (if any)
├── my-data/               ← your data repo (if any)
├── my-infra/              ← your infra repo (if any)
└── cursor-dev-setup-generator/   ← clone here
```

> **Single repo?** This works perfectly with just one repo (e.g. only `my-data/`). The generator detects what you have and only generates rules, skills, and Makefile targets for it.

```bash
cd /path/to/my-workspace
git clone <cursor-dev-setup-generator-url>
```

### 2. Generate the required tokens

Before running the generator, you need to create tokens for the MCP integrations. Only generate the tokens you plan to use.

#### GitHub Personal Access Token (PAT)

The GitHub MCP needs a token with broad permissions to manage branches, commits, PRs, issues, and repo content.

**Create a Fine-grained token** (recommended): [github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new)

Follow these steps:

1. **Resource owner**: Select your **organization** (not your personal account). If your organization doesn't appear, an admin must enable fine-grained tokens in the org settings (Settings → Personal access tokens → Allow fine-grained tokens).

2. **Repository access**: Choose **"Only select repositories"** and pick the repos the agent will work on (e.g. your backend, frontend, data, infra repos). You can add more repos later.

3. **Permissions**: Set the following **Repository permissions**:

| Permission | Access | Why |
|-----------|--------|-----|
| **Contents** | Read and Write | Push branches, read files, create commits |
| **Pull requests** | Read and Write | Create, read, and update PRs |
| **Issues** | Read and Write | Read issues linked to PRs |
| **Metadata** | Read | Required for all API calls |
| **Workflows** | Read and Write | Trigger and monitor CI/CD workflows |
| **Actions** | Read | Download workflow artifacts (plan validator) |

4. Click **"Generate token"** and copy the token immediately (it won't be shown again).

> **Classic token alternative**: [github.com/settings/tokens/new](https://github.com/settings/tokens/new) — select scope `repo` (full control). Classic tokens apply to all repos, no need to select specific ones.

#### Atlassian API Token (Jira + Confluence)

A single token works for both Jira and Confluence MCP. No specific scopes are needed — Atlassian Cloud API tokens inherit the permissions of the account that created them.

**Create token**: [id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens)

Follow these steps:

1. Go to the link above and click **"Create API token"**
2. Give it a label (e.g. "Cursor MCP") and click **"Create"**
3. Copy the token immediately (it won't be shown again)

You will also need:
- **Your Atlassian email**: the email address you use to log in to Jira/Confluence
- **Your site name**: the `xxx` part of `https://xxx.atlassian.net`

> **Atlassian Data Center / Server**: If you use an on-premise instance (not Cloud), use a [personal access token](https://confluence.atlassian.com/enterprise/using-personal-access-tokens-1026032365.html) instead. These tokens may have scope restrictions depending on your admin configuration.

#### Where to paste your tokens

After generating your tokens, open `cursor-dev-setup-generator/variables.env` and fill in:

```
MCP_GITHUB_PAT=ghp_xxxxxxxxxxxxxxxxxxxx
MCP_ATLASSIAN_EMAIL=your.name@company.com
MCP_ATLASSIAN_API_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxx
```

The generator will use these values to configure the MCP connectors (`mcp.json`) so the agent can communicate with GitHub, Jira, and Confluence.

#### Teams Webhook URL (optional — for dev-pipeline notifications)

Follow the official guide to create an Incoming Webhook in your Teams channel:

[learn.microsoft.com — Create Incoming Webhooks](https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook)

> Slack alternative: [api.slack.com — Incoming Webhooks](https://api.slack.com/messaging/webhooks)

#### Docker Desktop (required if you have a backend repo)

If you have a backend repo that uses a database via `docker-compose`, Docker Desktop **must be installed and running** before the agent can execute backend tests. Skip this if you only have a frontend or data repo without Docker dependencies.

**macOS**:

```bash
brew install --cask docker
```

Then open **Docker Desktop** from Applications. On first launch, accept the license and wait for the Docker engine to start (whale icon in menu bar = running).

> If you don't have Homebrew: [brew.sh](https://brew.sh) — or download Docker Desktop directly from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/)

**Windows**:

1. Download Docker Desktop from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/)
2. Run the installer (requires admin privileges)
3. During installation, enable **WSL 2** backend (recommended) or Hyper-V
4. Restart your computer when prompted
5. Open Docker Desktop — wait for the engine to start (green icon in system tray = running)

> WSL 2 is required. If not installed, follow [learn.microsoft.com — Install WSL](https://learn.microsoft.com/en-us/windows/wsl/install): run `wsl --install` in PowerShell as admin, then restart.

**Verify Docker is running**:

```bash
docker info
```

If this prints system info, Docker is ready. If it says "Cannot connect to the Docker daemon", open Docker Desktop and wait for it to start.

#### Cursor sandbox permissions (auto-approve)

For a fully automated experience, the agent needs to run shell commands without asking for manual approval at each step. **Configure this BEFORE running the setup prompt**:

**Option A — Manual (recommended before first run):**

1. Open Cursor **Settings** (Cmd+, on Mac, Ctrl+, on Windows)
2. Search for **"auto"** in the settings search bar
3. Set **"Cursor > Agent: Auto Approve"** to **enabled**
4. Search for **"co-author"** or **"attribution"**
5. Disable **"Cursor > General: Enable Attribution Header"** (removes "Co-authored-by: cursor" from commits)
6. **Restart Cursor** for settings to take effect

**Option B — Automatic (the setup prompt does it for you):**

The setup prompt (Phase 0) will automatically update `settings.json` to enable auto-approve and disable co-author attribution. However, a **Cursor restart** is still required for the changes to take effect. If you want a seamless first run, configure Option A before pasting the prompt.

> **Why is this needed?** Without auto-approve, Cursor will pause and ask for confirmation at every shell command (git, npm, gradle, poetry, etc.), turning a 5-minute setup into 30+ minutes of clicking "Approve".

---

### 3. Open your workspace in Cursor and paste the configuration prompt

Open the **parent workspace folder** (the one containing all your repos + cursor-dev-setup-generator) in Cursor, then paste the prompt below into the Cursor chat.

Cursor will **automatically scan your repos**, detect your tech stack, fill `variables.env`, generate the workspace, and show you what still needs manual input.

---

#### Prompt to paste in Cursor

```
You are a DevOps workspace configurator. Your job is to scan my project repos,
fill the file cursor-dev-setup-generator/variables.env with the correct values,
generate the workspace, and help me finalize the setup.

All commands MUST use required_permissions: ["all"] to avoid sandbox prompts.
Execute everything automatically without asking for confirmation unless you
genuinely cannot determine a value and need the developer's input.

## Phase 0 — Configure Cursor auto-approve

Before anything else, configure Cursor so all subsequent commands run without
manual approval.

0a. Locate the Cursor settings file:
    - Mac: ~/Library/Application Support/Cursor/User/settings.json
    - Windows: %APPDATA%\Cursor\User\settings.json
    - Linux: ~/.config/Cursor/User/settings.json

0b. Read the file (create it if missing). Merge these keys into the existing
    JSON (preserve all other settings, only add/overwrite these keys):

    {
      "cursor.general.enableAttributionHeader": false,
      "cursor.agent.autoApprove": true,
      "cursor.agent.autoFix": true
    }

0c. Write the updated file back.

0d. Tell me: "Cursor settings updated. RESTART Cursor now, then say CONTINUE."
    Wait for the user to confirm before proceeding.

## Phase 1 — Detect and fill variables

IMPORTANT: The workspace may contain 1 repo or many. A single repo is perfectly
valid. Only fill variables for repos that actually exist. Leave all variables
empty for repo types that are absent. NEVER rely on repo names to determine their
role. A repo named "pluto-engine" could be a backend API, a data pipeline, or
anything else. Always analyze the ACTUAL CODE CONTENT to determine each repo's role.

### Step 1 — Discover repos

1. List all directories at the workspace root. For each directory, check if it
   contains a Git repo (has .git/) or source code. Ignore cursor-dev-setup-generator
   itself, .cursor/, node_modules/, .git/, and other tool directories.

### Step 2 — Classify each repo by analyzing its code

2. For EACH repo found, open and read its source files to determine its role.
   Do NOT guess from the repo name. Use these heuristics based on code content:

   **Backend API** — assign to REPO_BACK_NAME if the repo contains:
   - HTTP server/controller code: classes annotated with @RestController, @Controller,
     @RequestMapping (Java/Kotlin), files importing express/fastify/koa/hono (Node.js),
     files importing flask/fastapi/django (Python), files with http.ListenAndServe (Go)
   - API route definitions: files under controllers/, routes/, endpoints/, handlers/
   - Database/ORM code: JPA entities, Hibernate, SQLAlchemy, Prisma, TypeORM, GORM
   - Application config with server port: application.yml, application.properties,
     .env with PORT, config.yaml with server.port
   - OpenAPI/Swagger definitions

   **Frontend** — assign to REPO_FRONT_NAME if the repo contains:
   - UI component files: .jsx, .tsx, .vue, .svelte, .angular component.ts
   - index.html with <div id="root"> or <app-root> or similar mount point
   - CSS/SCSS/Tailwind configuration
   - Client-side routing: angular.module routes, react-router, vue-router, next/router
   - Browser-specific APIs: document., window., localStorage, fetch to external API
   - package.json with framework: angular, react, vue, next, nuxt, svelte

   **Data pipeline** — assign to REPO_DATA_NAME if the repo contains:
   - Data processing imports: pandas, polars, pyspark, dbt, airflow, prefect, dagster
   - ETL/transformation scripts: files under pipelines/, dags/, transformations/, etl/
   - Data models/schemas WITHOUT HTTP server code
   - Jupyter notebooks (.ipynb) with data analysis
   - SQL files for data warehouse queries
   - pyproject.toml or setup.py with data-focused dependencies and NO web framework

   **Infrastructure** — assign to REPO_INFRA_NAME if the repo contains:
   - Terraform files (.tf) with resource/module definitions
   - Bicep files (.bicep), ARM templates (.json with $schema)
   - Pulumi code, CDK constructs, CloudFormation templates
   - Ansible playbooks (.yml with tasks/hosts)
   - Kubernetes manifests, Helm charts (Chart.yaml)

   **Bootstrap/reference** — assign to REPO_BOOTSTRAP_NAME if the repo:
   - Is a template or reference repo used by other projects
   - Contains reusable modules/templates but is not deployed directly
   - Has releases/tags that other repos track

   **Ambiguous cases**: If a Python repo has BOTH web framework imports AND data
   processing libraries, check the main entry point (main.py, app.py, manage.py).
   If it starts an HTTP server → backend. If it runs scripts/pipelines → data.
   If truly hybrid, prefer classifying as backend (the skills will still work).
   If a Node.js repo has BOTH a server AND React/Vue pages (fullstack monorepo),
   classify it as backend and mention in Phase 4 that the dev may want to split.

### Step 3 — Extract stack details AND build commands from code

3. For each classified repo, extract its stack by reading actual files (NOT from
   the repo name, NOT from defaults):
   - Language and version: read build.gradle (sourceCompatibility), pom.xml
     (java.version), .python-version, .nvmrc, .tool-versions, go.mod, rust-toolchain
   - Framework and version: read dependency files (build.gradle dependencies,
     package.json dependencies, pyproject.toml dependencies, go.mod require)
   - Build tool: determined by which build file exists (build.gradle→Gradle,
     pom.xml→Maven, package.json→check for npm/pnpm/yarn lock files,
     pyproject.toml→check for poetry.lock/pdm.lock/uv.lock)
   - Linter: check for config files (.eslintrc*, .prettierrc*, checkstyle.xml,
     spotbugs, ruff.toml, pyproject.toml [tool.ruff], .flake8, tflint.hcl)
   - Test framework: check test directories and test config (jest.config,
     vitest.config, pytest.ini, pyproject.toml [tool.pytest], build.gradle
     test dependencies, *_test.go files)
   - Ports: read docker-compose.yml ports, Dockerfile EXPOSE, application.yml
     server.port, .env PORT=, config files
   - Health check: read actuator config, /health route definitions, readiness probes
   - Base package: read main source files package declarations (Java), module names
   - Migration tool: check dependencies for Flyway, Liquibase, Alembic, etc.

   For each repo, also determine the EXACT commands to run locally. Read the
   existing Makefile, scripts, README, package.json scripts, or CI/CD configs
   to find the real commands. Fill these command variables:

   Backend (BACK_*_CMD):
   - BACK_SETUP_CMD: install/compile without tests (e.g. ./gradlew build -x test,
     mvn install -DskipTests, go build ./..., dotnet build)
   - BACK_BUILD_CMD: full build with tests (e.g. ./gradlew build, mvn package)
   - BACK_LINT_CMD: lint only (e.g. ./gradlew checkstyleMain checkstyleTest,
     golangci-lint run, dotnet format --verify-no-changes)
   - BACK_TEST_CMD: tests only (e.g. ./gradlew test, go test ./..., dotnet test)
   - BACK_START_CMD: start locally (e.g. make daemon, docker compose up -d)

   Frontend (FRONT_*_CMD):
   - FRONT_INSTALL_CMD: install deps (e.g. npm ci, pnpm install, yarn install)
   - FRONT_BUILD_CMD: build (e.g. npm run build, pnpm build)
   - FRONT_LINT_CMD: lint (e.g. npm run lint, pnpm lint)
   - FRONT_TEST_CMD: test (e.g. npm run test, pnpm test)
   - FRONT_START_CMD: dev server (e.g. npm run start, pnpm dev)

   Data (DATA_*_CMD):
   - DATA_SETUP_CMD: install deps (e.g. poetry install, pip install -r requirements.txt)
   - DATA_LINT_CMD: lint (e.g. poetry run ruff check ., flake8)
   - DATA_TEST_CMD: test (e.g. poetry run pytest, python -m pytest)

### Step 3b — Detect local environment details

   Detect the developer's shell and environment:
   - Shell config: check $SHELL → set SHELL_CONFIG_FILE (~/.zshrc if zsh,
     ~/.bashrc if bash, ~/.config/fish/config.fish if fish)
   - Login shell command: set LOGIN_SHELL_CMD (zsh -l -c, bash -l -c, fish -c)
   - NPM auth token variable: if a frontend repo uses private packages, check
     .npmrc for the env var name used (e.g. NPM_TOKEN, GITHUB_TOKEN,
     TOTAL_NPM_AUTH_TOKEN). Set NPM_AUTH_TOKEN_VAR to that name. Leave empty
     if no private packages.

### Step 4 — Detect integrations

4. Detect integrations by reading actual config files:
   - GitHub org: parse .git/config remote URL in any repo (extract org from
     github.com/ORG/repo or github.com:ORG/repo)
   - Jira: search for .cursor/ config, look for ticket prefixes in recent git log
     messages (e.g. PROJ-123), check CI/CD configs for Jira references
   - Confluence: search .cursor/ config, docs/ references, CI/CD configs
   - Cloud provider: read Terraform provider blocks, Dockerfile base images,
     CI/CD configs (azure-pipelines.yml, .github/workflows/)
   - Container registry: read docker-compose image fields, CI/CD push targets
   - Notification webhooks: search .env files, CI/CD notification steps
   - SSH key: list ~/.ssh/ and find the developer's private key file. Look for
     files like id_ed25519, id_rsa, id_ecdsa, or any custom-named key (check
     which key is used for github.com in ~/.ssh/config, or pick the one that
     `ssh-add -l` lists, or the most recently modified private key). Set
     SSH_KEY_FILE to the filename (without path, e.g. "id_ed25519").

### Step 5 — Fill variables

5. Read cursor-dev-setup-generator/variables.env to see all available variables.

6. Fill EVERY variable based on what you actually found in the code. Rules:
   - For repo types that do NOT exist: leave ALL their variables completely empty
   - For variables you cannot detect (tokens, Jira IDs, etc.): leave them empty
   - NEVER copy default/example values from variables.env comments — only use
     values you actually detected in the code
   - If you detected a value that differs from the comment example, use YOUR
     detected value (e.g. if the comment says "e.g. Spring Boot" but you found
     FastAPI, write FastAPI)

7. Write the filled variables.env file.

## Phase 1b — MCP-first: auto-fetch Jira and Confluence variables

The MCP connectors (GitHub, Jira, Confluence) need tokens to work. Once tokens
are provided, we use them to auto-discover Jira and Confluence configuration
instead of asking the developer to find these values manually.

8. Check if MCP_GITHUB_PAT, MCP_ATLASSIAN_EMAIL, and MCP_ATLASSIAN_API_TOKEN
   are filled in variables.env. If any are empty, ask the developer for them
   in a SINGLE prompt (not one by one):
   "I need your MCP tokens to auto-configure Jira and Confluence. Please provide:
    - GitHub PAT (see README section 2 for how to generate)
    - Atlassian email (your login email)
    - Atlassian API token (see README section 2 for how to generate)"

9. Run: cd cursor-dev-setup-generator && bash generate.sh --install
   (or on Windows: cd cursor-dev-setup-generator; .\generate.ps1 -Install)
   This deploys mcp.json to ~/.cursor/ so the MCP connectors become available.

10. Use the Jira MCP to auto-fetch project configuration:

   a. If JIRA_PROJECT_KEY is known (from git log analysis in Step 4):
      - Fetch boards: GET /rest/agile/1.0/board?projectKeyOrId={JIRA_PROJECT_KEY}
        → Extract the first board ID → set JIRA_BOARD_ID
      - Fetch transitions: GET /rest/api/3/search with jql=project={JIRA_PROJECT_KEY}
        → take first issue key → GET /rest/api/3/issue/{key}/transitions
        → Find "In Progress" transition → set JIRA_TRANSITION_IN_PROGRESS
        → Find "To Review" transition → set JIRA_TRANSITION_TO_REVIEW
      - Set JIRA_BASE_URL from CONFLUENCE_SITE_NAME (https://{site}.atlassian.net)
      - Detect JIRA_ISSUE_TYPE from the most common issue type in recent tickets

   b. If CONFLUENCE_SITE_NAME is known:
      - Fetch spaces: use Confluence MCP to list spaces
        → Match likely space → set CONFLUENCE_SPACE_KEY
      - Search for project pages: search by project name in that space
        → Auto-fill CONFLUENCE_PAGE_EP, CONFLUENCE_PAGE_GDD if found

   c. If any Jira/Confluence value could not be auto-detected, log it for
      Phase 4 (manual fill). Do NOT ask the developer interactively.

11. Update variables.env with the fetched values and re-run the generator:
    cd cursor-dev-setup-generator && bash generate.sh --install

## Phase 2 — Load features configuration

12. Read cursor-dev-setup-generator/features.conf to determine which optional
    features are enabled or disabled. Respect these settings throughout setup.
    If the file does not exist, treat all optional features as disabled.

## Phase 3 — Configure local environment

The agents (dev-expert, dev-approval, dev-pipeline) need a working local environment
to build, test, and push code. Check and configure everything now.

IMPORTANT: Only check/install tools that are relevant to the repos detected in
Phase 1. If only a data repo was found, skip JDK, Node.js, and Docker. If only a
frontend repo, skip JDK, Python, Poetry, and Docker. Adapt to what was detected.

IMPORTANT: This phase is fully automated. Do NOT ask for confirmation before
installing missing tools or running configuration commands. Install everything
that is missing automatically. The only exception: if a tool requires a manual
download (e.g. Docker Desktop GUI), tell the developer and wait.

### 3a. Check and auto-install tools

13. Based on the repos detected AND the stack detected in Phase 1, check ONLY
    the relevant tools. Build the check list dynamically:

   For the backend repo (based on BACK_LANGUAGE detected):
   - Java → check: `java -version`
   - Go → check: `go version`
   - Python → check: `python3 --version`
   - C# → check: `dotnet --version`
   - Kotlin → check: `java -version` (runs on JVM)
   - TypeScript/Node → check: `node -v`

   For the backend repo (based on BACK_BUILD_TOOL detected):
   - Gradle → check: `gradle -v` or `./gradlew -v`
   - Maven → check: `mvn -v`
   - Docker in docker-compose → check: `docker info`

   For the frontend repo (based on FRONT_BUILD_TOOL detected):
   - npm → check: `node -v`, `npm -v`
   - pnpm → check: `node -v`, `pnpm -v`
   - yarn → check: `node -v`, `yarn -v`
   - bun → check: `bun -v`

   For the data repo (based on DATA_PACKAGE_MANAGER detected):
   - Poetry → check: `python3 --version`, `poetry --version`
   - pip → check: `python3 --version`, `pip --version`
   - conda → check: `conda --version`
   - uv → check: `python3 --version`, `uv --version`

   For the infra repo (based on INFRA_TOOL detected):
   - Terraform → check: `terraform -v`
   - Pulumi → check: `pulumi version`

   Always check: `git --version`

14. Show a status table (only include rows for tools actually needed):

   | Tool | Required for | Status | Action |
   |------|-------------|--------|--------|
   | (only tools relevant to detected stack) | ... | OK / MISSING | Installed / Skipped |

   For MISSING tools, auto-install them using the platform package manager:
   - macOS: `brew install <package>` (for CLI tools) or `brew install --cask <package>` (for GUI apps)
   - Linux: `sudo apt-get install -y <package>` or equivalent
   - Windows: `winget install <package>` or `choco install <package>`

   Install mapping (macOS examples):
   - Java: `brew install openjdk@21` (or version detected)
   - Node.js: `brew install node` or `nvm install <version>` if nvm is present
   - Python: `brew install python@3.x`
   - Poetry: `pipx install poetry` or `pip install poetry`
   - Terraform: `brew install terraform`
   - pnpm: `npm install -g pnpm`
   - yarn: `npm install -g yarn`

   After installing, verify each tool works. If installation fails (e.g.
   Homebrew not found), fall back to direct download instructions and tell
   the developer. For Docker Desktop (GUI app), tell the developer to install
   it manually and wait.

   If all tools are present or were successfully installed, continue
   automatically without waiting.

### 3b. Docker Desktop (only if a detected repo uses docker-compose)

15. SKIP this step if no detected repo has a docker-compose.yml file.
    Check if Docker is running: `docker info`
    - If running: confirm and continue.
    - If NOT running but installed: try `open -a Docker` (Mac) and wait 15s.
      Re-check `docker info`. If still not running, tell the developer to
      start Docker Desktop manually and wait.
    - If NOT installed: tell the developer:
      "Docker Desktop must be installed (a repo uses docker-compose).
       - Mac: `brew install --cask docker` then open Docker Desktop
       - Windows: download from docker.com/products/docker-desktop
       Say CONTINUE when Docker is running."

### 3c. Git configuration

16. Check git identity:
    ```
    git config --global user.name
    git config --global user.email
    ```
    If user.name or user.email is empty, ask the developer for name and email,
    then configure automatically:
    ```
    git config --global user.name "Their Name"
    git config --global user.email "their.email@company.com"
    ```

17. Detect the developer's SSH key:
    ```
    ls ~/.ssh/
    ssh-add -l 2>&1
    cat ~/.ssh/config 2>/dev/null
    ```
    Identify the actual SSH private key file used for github.com. Priority:
    - If ~/.ssh/config has a "Host github.com" block with IdentityFile → use that
    - If ssh-add -l lists a key → use that filename
    - If multiple keys exist, pick the most likely one (ed25519 > ecdsa > rsa)
    Update SSH_KEY_FILE in variables.env with the detected filename (without path).

18. Check SSH access to GitHub:
    ```
    ssh -T git@github.com 2>&1
    ```
    - If "Hi username!": SSH works, continue automatically.
    - If "Permission denied" but an SSH key exists: auto-add it:
      ```
      eval "$(ssh-agent -s)"
      ssh-add ~/.ssh/<detected-key>
      ```
      Re-test SSH. If still fails, tell the developer to add the public key
      on GitHub (Settings > SSH and GPG keys > New SSH key) with the content of
      `~/.ssh/<detected-key>.pub`.
    - If no SSH key exists at all: generate one automatically:
      ```
      ssh-keygen -t ed25519 -C "developer-email" -f ~/.ssh/id_ed25519 -N ""
      eval "$(ssh-agent -s)"
      ssh-add ~/.ssh/id_ed25519
      ```
      Update SSH_KEY_FILE=id_ed25519 in variables.env.
      Show the public key content and tell the developer to add it on GitHub.
    - If SSH cannot work (corporate proxy, etc.): switch remotes to HTTPS
      and use the GitHub PAT token as credential.

19. Check GPG signing (for `git commit -S`):

    IMPORTANT: First CHECK if GPG is already configured before proposing to
    generate anything. Many developers already have GPG keys.

    Step 1 — Check if GPG keys exist:
    ```
    gpg --list-secret-keys --keyid-format=long 2>&1
    ```

    Step 2 — If GPG keys EXIST:
      a) Extract the key ID from the output (the hex string after "sec rsa4096/"
         or "sec ed25519/" on the sec line)
      b) Check if git is already configured:
         ```
         git config --global user.signingkey
         git config --global commit.gpgsign
         ```
      c) If signingkey is already set and gpgsign is true: GPG is fully
         configured. Log "GPG signing: already configured" and continue.
      d) If signingkey is NOT set: auto-configure with the detected key:
         ```
         git config --global user.signingkey <KEY_ID>
         git config --global commit.gpgsign true
         ```
         Log "GPG signing: configured with existing key <KEY_ID>" and continue.

    Step 3 — If NO GPG keys exist AND SIGNED_COMMITS=true in variables.env:
      Generate a GPG key automatically (non-interactive):
      ```
      gpg --batch --gen-key <<GPGEOF
      Key-Type: eddsa
      Key-Curve: ed25519
      Subkey-Type: ecdh
      Subkey-Curve: cv25519
      Name-Real: <git user.name>
      Name-Email: <git user.email>
      Expire-Date: 2y
      %no-protection
      %commit
      GPGEOF
      ```
      Then configure git:
      ```
      KEY_ID=$(gpg --list-secret-keys --keyid-format=long | grep -A1 "^sec" | tail -1 | awk '{print $1}')
      git config --global user.signingkey $KEY_ID
      git config --global commit.gpgsign true
      ```
      Export the public key and tell the developer to add it on GitHub:
      ```
      gpg --armor --export $KEY_ID
      ```
      "Add this GPG public key to GitHub: Settings > SSH and GPG keys > New GPG key"

    Step 4 — If NO GPG keys exist AND SIGNED_COMMITS=false:
      Skip GPG setup entirely. Continue without GPG signing.

### 3d. Install project dependencies

20. Run the Makefile setup for all detected repos:
    ```
    make setup-all
    ```
    If a specific repo setup fails, show the error and auto-fix if possible.
    If `make` is not installed, auto-install it:
    - Mac: `xcode-select --install` (or `brew install make`)
    - Linux: `sudo apt-get install -y make`
    Then retry.

### 3e. Run tests to verify environment

21. Run all tests:
    ```
    make test-all
    ```
    Show a status table (only include rows for repos that exist):

    | Repo | Lint | Build/Test | Status |
    |------|------|-----------|--------|
    | (only detected repos) | ... | ... | PASS / FAIL |

    If any test fails, show the error and attempt to fix automatically.
    If all pass: "Local environment is fully configured. All agents can now run
    tests autonomously."

## Phase 4 — Report and missing variables

22. Show a summary table of detected repos:

   | Repo | Role | Language | Framework | Build tool |
   |------|------|----------|-----------|------------|
   | ...  | ...  | ...      | ...       | ...        |

23. Show a table of ALL variables that are still empty and need manual input.
   Group by category and explain where to find each value.

   IMPORTANT: Do NOT list the following variables as missing (they are optional
   or auto-determined):
   - ENV_DEV_URL, ENV_PROD_URL: only used in documentation markdown, not required
   - JIRA_BOARD_ID, JIRA_TRANSITION_IN_PROGRESS, JIRA_TRANSITION_TO_REVIEW:
     should have been auto-fetched via MCP in Phase 1b. Only list if MCP fetch failed.
   - CONFLUENCE_SPACE_KEY, CONFLUENCE_PAGE_EP: should have been auto-fetched.
     Only list if MCP fetch failed.
   - TEAMS_WEBHOOK_URL: only list if features.conf has TEAMS_NOTIFICATIONS=true
   - TEAMS_COLOR_APPROVED, TEAMS_COLOR_REJECTED: use defaults (0078D4, FF0000)

   Example format for remaining missing variables:

   | Variable | Category | Where to find it |
   |----------|----------|-----------------|
   | JIRA_DEFAULT_PARENT_TICKET | Jira | Epic or parent ticket key (e.g. PROJ-100) — optional |
   | CONFLUENCE_PAGE_GDD | Confluence | GDD page URL → numeric ID — optional |
   | ... | ... | ... |

   Only include variables that are ACTUALLY empty AND required or useful.

24. Tell me: "Fill the missing variables in cursor-dev-setup-generator/variables.env
    then say RE-RUN and I will regenerate and reinstall the workspace."
    If no variables are missing: "All variables are filled. Your workspace is
    fully configured and ready to use."

## Phase 5 — RE-RUN (when the user says "RE-RUN")

When the user says "RE-RUN" or "re-run":
1. Run: cd cursor-dev-setup-generator && bash generate.sh --install
   (or on Windows: cd cursor-dev-setup-generator; .\generate.ps1 -Install)
2. Confirm: "Workspace regenerated and installed. All files updated."
3. Show again the table of variables still empty (if any).
   If all filled: "All variables are filled. Your workspace is fully configured."

EXECUTION RULES:
- Do NOT ask questions unless you genuinely cannot determine a value.
- Scan everything, fill what you can, auto-install what is missing, flag what
  you cannot resolve.
- Use required_permissions: ["all"] for ALL commands.
- Execute end-to-end without manual approval gates.
Start now.
```

---

### 4. Review and complete

After Cursor runs, you get:
- **Auto-filled variables**: repos, versions, ports, cloud provider — nothing to do
- **Missing variables table**: a precise list of what you need to fill manually with instructions on where to find each value
- **Workspace installed**: `.cursor/`, `Makefile`, `.gitignore`, and `mcp.json` are already copied to the right places

Fill the missing values in `cursor-dev-setup-generator/variables.env`, then type **RE-RUN** in the Cursor chat to regenerate and reinstall automatically.

Or re-run manually:

```bash
cd cursor-dev-setup-generator && bash generate.sh --install
```

### 5. Start coding

The rules, skills, docs, and integrations are all configured. Your workspace is ready.

---

## What gets generated

| Folder | Content |
|--------|---------|
| `.cursor/rules/competences/` | Coding conventions per repo (back, front, data, infra) |
| `.cursor/rules/restrictions/` | Safety policies (no push to main, read-only cloud, etc.) |
| `.cursor/skills/dev/` | Agent workflows (implement ticket, review, pipeline) |
| `.cursor/skills/ops/` | Ops workflows (infra alignment, sprint reports, doc sync) |
| `.cursor/docs/` | Local setup guide, functional context |
| `.cursor/jira-templates/` | Ticket templates per repo |
| `.cursor/features.conf` | Optional features toggle (Teams notifications, CodeRabbit, etc.) |
| `Makefile` | Dev commands: setup, test, lint, smoke |
| `mcp.json` | MCP connector config (GitHub, Jira, Confluence, Azure) |

## How to Use Each Skill

Once the workspace is generated, you have access to agent skills in Cursor. Type the trigger phrase in Cursor chat to activate each one.

### Dev Skills

#### dev-expert — Implement a Jira ticket automatically

Takes a Jira ticket, reads the description, implements the code changes, runs tests, creates a branch and a PR.

| | |
|---|---|
| **Trigger** | `"Pick an unassigned ticket"` or `"Implement ticket PROJ-1234"` (use your Jira project key) |
| **Input** | A Jira ticket key, or let the agent pick the next unassigned ticket from the active sprint |
| **What it does** | 1. Fetches the ticket from Jira → 2. Assigns it and moves to "In Progress" → 3. Creates a feature branch → 4. Implements the changes following repo conventions → 5. Runs linter + build + tests → 6. Commits, pushes, opens a PR → 7. Moves ticket to "To Review" |
| **Output** | A ready-to-review PR on GitHub |
| **Requires** | Jira MCP + GitHub MCP configured, local build tools installed |

#### dev-approval — Review and approve a PR

Re-runs all tests, performs code review with CodeRabbit, and validates the changes as a senior expert.

| | |
|---|---|
| **Trigger** | `"Review the PR from dev-expert"` or `"Approve changes on branch feat/PROJ-1234"` |
| **Input** | A branch name or PR number |
| **What it does** | 1. Checks out the branch → 2. Re-runs full test suite → 3. Runs CodeRabbit review → 4. Expert assessment (code quality, patterns, conventions) → 5. If approved: pushes and updates PR |
| **Output** | Approved PR ready to merge, or list of fixes needed |
| **Requires** | CodeRabbit CLI installed, local build tools |

#### dev-pipeline — Full automated flow (expert + approval + notification)

Orchestrates dev-expert then dev-approval in sequence. Sends a Teams/Slack notification when done.

| | |
|---|---|
| **Trigger** | `"Run dev-pipeline on PROJ-1234"` or `"Run dev-pipeline"` (picks next ticket) |
| **Input** | A Jira ticket key or automatic selection |
| **What it does** | 1. Runs dev-expert (implement + PR) → 2. Runs dev-approval (review + approve) → 3. Generates a report in `.cursor/dev-reports/` → 4. Sends notification (Teams/Slack) |
| **Output** | Report in `.cursor/dev-reports/`, Teams notification, approved PR |
| **Requires** | Jira MCP + GitHub MCP, local build tools, Teams webhook (optional) |

#### security-reviewer — Security audit on a PR or codebase

Combines CodeRabbit, Trivy SARIF, static analysis, and expert review to find security vulnerabilities.

| | |
|---|---|
| **Trigger** | `"Run security review on PR #42"` or `"Security audit on my-api"` (use your repo name) |
| **Input** | A PR number, branch name, or repo name for full audit |
| **What it does** | 1. Runs CodeRabbit security scan → 2. Fetches Trivy SARIF results → 3. Static analysis (SQL injection, XSS, secrets, auth) → 4. Expert assessment → 5. Generates severity report |
| **Output** | Security report in `.cursor/security-reports/` with CRITICAL/HIGH/MEDIUM/LOW findings |
| **Requires** | GitHub MCP, CodeRabbit CLI (optional), Trivy (optional) |

---

### Ops Skills

#### sprint-reporter — Sprint progress report

Generates a summary of the current sprint from Jira and GitHub data.

| | |
|---|---|
| **Trigger** | `"Generate sprint report"` or `"Sprint status"` |
| **Input** | None (uses active sprint automatically) |
| **What it does** | 1. Fetches active sprint from Jira → 2. Collects ticket statuses → 3. Fetches recent PRs from GitHub → 4. Calculates velocity and metrics → 5. Identifies blockers |
| **Output** | Sprint report in `.cursor/sprint-reports/` with ticket breakdown, PR stats, and velocity |
| **Requires** | Jira MCP + GitHub MCP |

#### doc-sync — Sync documentation from Confluence

Fetches pages from Confluence, converts to Markdown, stores locally for Cursor indexing.

| | |
|---|---|
| **Trigger** | `"Sync docs"` or `"Run doc-sync"` |
| **Input** | None (uses configured Confluence page IDs) |
| **What it does** | 1. Fetches configured Confluence pages → 2. Converts HTML to Markdown → 3. Saves to `.cursor/docs/confluence/` → 4. Updates sync metadata |
| **Output** | Markdown files in `.cursor/docs/` searchable via Cursor's `@Codebase` |
| **Requires** | Confluence MCP configured, Confluence page IDs in `variables.env` |

#### token-optimizer — Reduce LLM context waste

Scans the workspace for patterns that waste tokens (verbose prompts, dead code, duplicated content, oversized files).

| | |
|---|---|
| **Trigger** | `"Optimize tokens"` or `"Detect token waste"` |
| **Input** | Optional: specific path or file. Default: full workspace scan |
| **What it does** | 1. Scans skills, rules, and source code → 2. Detects 12 categories of waste (verbose instructions, dead code, comments, duplicates) → 3. Scores severity → 4. Proposes and applies fixes |
| **Output** | Summary of findings with estimated token savings |
| **Requires** | Nothing — works on any workspace |

---

### Infra Skills

> These skills are only generated if you have an infra repo configured.

#### infra-bootstrap-workflow — Align infra with bootstrap releases

Compares your infra repo against the bootstrap reference repo and creates a PR to align.

| | |
|---|---|
| **Trigger** | `"Align infra with bootstrap"` or `"Check bootstrap releases"` |
| **Input** | None (auto-detects latest bootstrap release) |
| **What it does** | 1. Lists bootstrap releases → 2. Compares changes with your infra repo → 3. Creates a Jira ticket → 4. Applies changes on a branch → 5. Opens a PR |
| **Output** | PR aligning your infra with the latest bootstrap release |
| **Requires** | GitHub MCP, Jira MCP, bootstrap repo configured |

#### infra-bootstrap-plan-validator — Validate Terraform plan

Waits for the Terraform plan workflow to complete, downloads artifacts, and generates a human-readable summary.

| | |
|---|---|
| **Trigger** | `"Validate plan for PR #X"` or `"Check Terraform plan"` |
| **Input** | A PR number or branch name |
| **What it does** | 1. Waits for the plan workflow to finish → 2. Downloads plan artifacts → 3. Parses JSON plan → 4. Generates summary table with changes per layer |
| **Output** | Plan summary in `.cursor/bootstrap-align-reports/` |
| **Requires** | GitHub MCP, infra repo with Terraform plan workflow |

#### infra-bootstrap-pipeline — Full infra alignment (workflow + plan validation)

Runs infra-bootstrap-workflow then infra-bootstrap-plan-validator in sequence.

| | |
|---|---|
| **Trigger** | `"Run infra bootstrap pipeline"` |
| **Input** | None |
| **What it does** | 1. Runs infra-bootstrap-workflow (align + PR) → 2. Runs infra-bootstrap-plan-validator (validate plan) → 3. Generates combined report |
| **Output** | Aligned PR + plan validation report in `.cursor/bootstrap-align-reports/` |
| **Requires** | GitHub MCP, Jira MCP, bootstrap repo configured |

---

### Bootstrap Skills

> These skills are only generated if you have a bootstrap reference repo configured.

#### bootstrap-devops-expert — Tech watch and best practices analysis

Fetches provider changelogs, analyzes your infra code against deprecations and breaking changes, proposes improvements.

| | |
|---|---|
| **Trigger** | `"Run bootstrap devops analysis"` or `"Check for provider updates"` |
| **Input** | None |
| **What it does** | 1. Fetches changelogs (Terraform, azurerm, azapi, grafana) → 2. Identifies deprecations and breaking changes affecting your code → 3. Proposes version upgrades and fixes → 4. Generates report with a ready-to-use Cursor prompt for applying changes |
| **Output** | Analysis report in `.cursor/bootstrap-devops-reports/` |
| **Requires** | Internet access for changelog fetching |

---

### Quick Reference

| Skill | Trigger phrase | Category |
|-------|---------------|----------|
| dev-expert | `"Implement ticket XX-1234"` | Dev |
| dev-approval | `"Review the PR"` | Dev |
| dev-pipeline | `"Run dev-pipeline on XX-1234"` | Dev |
| security-reviewer | `"Run security review"` | Dev |
| sprint-reporter | `"Generate sprint report"` | Ops |
| doc-sync | `"Sync docs"` | Ops |
| token-optimizer | `"Optimize tokens"` | Ops |
| infra-bootstrap-workflow | `"Align infra with bootstrap"` | Infra |
| infra-bootstrap-plan-validator | `"Validate plan for PR #X"` | Infra |
| infra-bootstrap-pipeline | `"Run infra bootstrap pipeline"` | Infra |
| bootstrap-devops-expert | `"Run bootstrap devops analysis"` | Bootstrap |

---

## Manual fallback

If you prefer filling variables manually instead of using the Cursor prompt:

1. Open `cursor-dev-setup-generator/variables.env`
2. Fill in your values (each variable has a comment explaining what it expects)
3. Leave optional variables empty — the generator skips related files
4. Run `bash generate.sh` or `.\generate.ps1`

## Requirements

- Bash (Mac/Linux) or PowerShell (Windows)
- No other dependencies needed
