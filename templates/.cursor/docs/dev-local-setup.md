# Configuration environnement local

Guide pour configurer votre machine afin que les agents dev-expert, dev-approval et dev-pipeline puissent exécuter les tests end-to-end.

## 1. Prérequis globaux

Les outils nécessaires dépendent des repos présents dans votre workspace. Seuls les outils correspondant à vos repos sont requis.

| Outil | Requis si | Version | Installation |
|-------|-----------|---------|--------------|
| **{{BACK_LANGUAGE}}** | Backend | {{BACK_LANGUAGE_VERSION}}+ | Voir la documentation officielle de {{BACK_LANGUAGE}} |
| **{{BACK_BUILD_TOOL}}** | Backend | Via wrapper ou système | Inclus dans le repo ou à installer séparément |
| **Node.js** | Frontend | Compatible {{FRONT_FRAMEWORK}} {{FRONT_FRAMEWORK_VERSION}} | `brew install node` / [nvm](https://github.com/nvm-sh/nvm) / nodejs.org |
| **{{DATA_PACKAGE_MANAGER}}** | Data | Compatible Python {{DATA_LANGUAGE_VERSION}} | Voir la documentation officielle |
| **Docker** | Si docker-compose.yml | Latest | `brew install --cask docker` / docker.com |
| **Git** | Toujours | 2.x+ | `brew install git` / git-scm.com |

## 2. Configuration shell ({{SHELL_CONFIG_FILE}})

Ajouter à la fin de `{{SHELL_CONFIG_FILE}}` les exports nécessaires pour que les outils soient dans le PATH. Adapter selon votre OS et votre gestionnaire de versions.

Recharger : `source {{SHELL_CONFIG_FILE}}`

## 3. {{REPO_BACK_NAME}}

### Prérequis

- {{BACK_LANGUAGE}} {{BACK_LANGUAGE_VERSION}}
- {{BACK_BUILD_TOOL}}
- Docker Desktop (si le repo utilise docker-compose pour {{BACK_DB_TYPE}} ou d'autres services)

### Installation

```bash
make setup-back
```

Ou manuellement :

```bash
cd {{REPO_BACK_NAME}}
{{BACK_SETUP_CMD}}
```

### Commandes de test (alignées sur les agents)

```bash
cd {{REPO_BACK_NAME}}

{{BACK_LINT_CMD}}
{{BACK_BUILD_CMD}}
{{BACK_START_CMD}}
```

Vérification health (attendre le start_period) :

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:{{BACK_PORT}}{{BACK_HEALTH_PATH}}
```

Attendre `200`.

### Connexion au registre de conteneurs (si nécessaire)

```bash
az login
az acr login -n {{ACR_NAME}}
```

### Arrêt

```bash
cd {{REPO_BACK_NAME}}
make down
```

---

## 4. {{REPO_FRONT_NAME}}

### Prérequis

- Node.js (compatible {{FRONT_FRAMEWORK}} {{FRONT_FRAMEWORK_VERSION}})
- {{FRONT_BUILD_TOOL}}

### Installation

```bash
make setup-front
```

Ou manuellement :

```bash
cd {{REPO_FRONT_NAME}}
{{FRONT_INSTALL_CMD}}
```

### Commandes de test (alignées sur les agents)

```bash
cd {{REPO_FRONT_NAME}}

{{FRONT_INSTALL_CMD}}
{{FRONT_LINT_CMD}}
{{FRONT_BUILD_CMD}}
```

Smoke test (optionnel) :

```bash
{{FRONT_START_CMD}}
```

Vérifier `http://localhost:{{FRONT_PORT}}/`.

---

## 5. {{REPO_DATA_NAME}}

### Prérequis

- Python {{DATA_LANGUAGE_VERSION}}
- {{DATA_PACKAGE_MANAGER}}

### Installation

```bash
make setup-data
```

Ou manuellement :

```bash
cd {{REPO_DATA_NAME}}
{{DATA_SETUP_CMD}}
```

### Commandes de test (alignées sur les agents)

```bash
cd {{REPO_DATA_NAME}}

{{DATA_SETUP_CMD}}
{{DATA_TEST_CMD}}
```

Lint :

```bash
{{DATA_LINT_CMD}}
```

---

## 6. Récapitulatif Makefile (racine du projet)

| Commande | Description |
|----------|-------------|
| `make setup-back` | Installer {{REPO_BACK_NAME}} |
| `make setup-front` | Installer {{REPO_FRONT_NAME}} |
| `make setup-data` | Installer {{REPO_DATA_NAME}} |
| `make setup-all` | Installer tous les repos |
| `make test-back` | Lint + build ({{REPO_BACK_NAME}}) |
| `make test-front` | Lint + build ({{REPO_FRONT_NAME}}) |
| `make test-data` | Tests ({{REPO_DATA_NAME}}) |
| `make test-all` | Exécuter tous les tests |
| `make smoke-back` | Démarrer + vérifier health {{BACK_PORT}} |
| `make smoke-front` | {{FRONT_START_CMD}} |
| `make lint-back` | {{BACK_LINT_CMD}} |
| `make lint-front` | {{FRONT_LINT_CMD}} |
| `make lint-data` | {{DATA_LINT_CMD}} |

---

## 7. Récapitulatif des commandes par repo

| Repo | Lint | Build/Test | Smoke |
|------|------|-----------|-------|
| **{{REPO_BACK_NAME}}** | `{{BACK_LINT_CMD}}` | `{{BACK_BUILD_CMD}}` | `{{BACK_START_CMD}}` puis `curl localhost:{{BACK_PORT}}{{BACK_HEALTH_PATH}}` |
| **{{REPO_FRONT_NAME}}** | `{{FRONT_LINT_CMD}}` | `{{FRONT_BUILD_CMD}}` | `{{FRONT_START_CMD}}` |
| **{{REPO_DATA_NAME}}** | `{{DATA_LINT_CMD}}` | `{{DATA_TEST_CMD}}` | — |

---

## 8. Vérification post-installation

```bash
source {{SHELL_CONFIG_FILE}}
make test-back
make test-data
make test-front
```

---

## 9. Workflow de test manuel

1. **Après une modification par dev-expert** : aller dans le repo cible et exécuter les commandes ci-dessus.
2. **Simuler dev-approval** : checkout de la branche, puis exécuter lint → build → smoke dans l'ordre.
3. **Rapports** : les rapports du pipeline sont dans `.cursor/dev-reports/`.

---

## 10. Dépannage

### Outils introuvables dans le terminal

Utiliser un shell de login (les agents utilisent `{{LOGIN_SHELL_CMD}}` pour charger le profil) :

```bash
{{LOGIN_SHELL_CMD}} "cd {{REPO_BACK_NAME}} && {{BACK_BUILD_CMD}}"
```

### Docker non démarré

Ouvrir **Docker Desktop** depuis les Applications (Mac) ou le menu Démarrer (Windows). Vérifier : `docker info`.

### git push échoue (Permission denied - publickey)

L'agent dev-pipeline/dev-approval pousse la branche vers GitHub. Si `git push` échoue avec `Permission denied (publickey)` :

**Cause fréquente** : l'agent SSH n'a aucune clé chargée (`ssh-add -l` → "The agent has no identities"). Cursor exécute dans un shell non interactif où les clés ne sont pas chargées.

1. **Charger la clé dans l'agent** (à faire dans un terminal, avant de lancer Cursor ou le pipeline) :
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/{{SSH_KEY_FILE}}
   ```
   Si tu as une passphrase, saisis-la. Vérifier : `ssh-add -l` doit lister la clé.

2. **Persistance macOS** : créer `~/.ssh/config` pour charger la clé automatiquement :
   ```
   Host github.com
     HostName github.com
     User git
     IdentityFile ~/.ssh/{{SSH_KEY_FILE}}
     AddKeysToAgent yes
     UseKeychain yes
   ```
   Puis une fois : `ssh-add --apple-use-keychain ~/.ssh/{{SSH_KEY_FILE}}` (saisir la passphrase une fois, elle sera stockée dans le trousseau).

3. **Vérifier que la clé est sur GitHub** : GitHub → Settings → SSH and GPG keys. Your public key must be listed. If not: `cat ~/.ssh/{{SSH_KEY_FILE}}.pub` puis "New SSH key" sur GitHub.

4. **Tester** : `ssh -T git@github.com` → doit afficher "Hi username! You've successfully authenticated...".

5. **Alternative HTTPS** (si SSH impossible) :
   ```bash
   cd {{REPO_DATA_NAME}}
   git remote set-url origin https://github.com/{{GITHUB_ORG}}/{{REPO_DATA_NAME}}.git
   ```
   Utiliser un [Personal Access Token](https://github.com/settings/tokens) comme mot de passe si demandé.

### Pipeline bloqué à chaque étape (approbation manuelle)

Pour un flux entièrement automatique, configurer **Cursor** : **Settings → Cursor Settings → Agents → Auto-Run** sur **"Run Everything"**. Sinon, l'agent demandera une approbation pour chaque commande.

### "and Cursor" affiché comme co-auteur sur GitHub

Si les commits affichent "your name **and Cursor**" sur GitHub, désactiver l'attribution automatique :

1. **Cursor** : Settings (Ctrl+, ou Cmd+,)
2. Rechercher **"co-author"** ou **"Commit Attribution"**
3. Désactiver toutes les options sous **Commit Attribution**
4. Redémarrer Cursor (important)
