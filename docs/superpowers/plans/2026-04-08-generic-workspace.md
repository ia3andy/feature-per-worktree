# Generic Feature Workspace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the feature-per-worktree workspace reusable across projects by extracting project-specific config into `workspace.yml`, replacing rsync/hardlink `.m2` seeding with Maven's tail local repository, and making all skills/scripts generic.

**Architecture:** A single `workspace.yml` defines repos and build flags. CLAUDE.md, skills, and scripts all reference this file instead of hardcoding project-specific values. Bash scripts use `yq` to parse YAML; Claude skills read it as text.

**Tech Stack:** Bash, YAML, yq, Maven (mvnd), git worktrees, Claude Code skills

---

### Task 1: Create workspace.yml for Roq

**Files:**
- Create: `workspace.yml`

- [ ] **Step 1: Create workspace.yml**

```yaml
project: roq
github_username: ia3andy

repos:
  quarkus-roq:
    upstream: quarkiverse/quarkus-roq
    build_on_init: true
    build_on_refresh: true
  quarkus-web-bundler:
    upstream: quarkiverse/quarkus-web-bundler
    build_on_init: false
    build_on_refresh: false
  quarkus:
    upstream: quarkusio/quarkus
    build_on_init: false
    build_on_refresh: false
```

- [ ] **Step 2: Add workspace.yml to .gitignore allowlist**

Replace the entire `.gitignore` with an allowlist approach:

```
# Ignore everything
*

# Allow orchestration files
!CLAUDE.md
!README.md
!workspace.yml
!.gitignore
!scripts/
!scripts/**
!journal/
!journal/**
!docs/
!docs/**
!.claude/
!.claude/**
```

- [ ] **Step 3: Commit**

```bash
git add workspace.yml .gitignore
git commit -m "Add workspace.yml config, switch .gitignore to allowlist"
```

---

### Task 2: Rewrite CLAUDE.md

**Files:**
- Modify: `CLAUDE.md` (full rewrite)

- [ ] **Step 1: Replace CLAUDE.md with generic version**

```markdown
# Feature Workspace

This is the root directory for daily work. Claude is run from here and has access to all repos and feature branches.
This root folder is a git repository itself, but contains no source code, only orchestration, scripts, and Claude config.

## Project Configuration

All project-specific settings live in `workspace.yml`. Read it at the start of every session to know which repos are configured, their upstream URLs, and build flags.

## Directory Structure

```
<workspace-root>/
├── CLAUDE.md
├── workspace.yml                # project config (repos, usernames, build flags)
├── scripts/
├── main/                        # real clones, always at upstream/main
│   ├── <repo-1>/
│   ├── <repo-2>/
│   └── ...
├── <feature-name>/              # feature directory (named freely)
│   ├── <repo>/                  # worktree from main/<repo>
│   ├── .m2/                     # isolated local repo, falls back to ~/.m2
│   └── journal/
├── journal/                     # archived journals from completed features
```

## Repositories

Defined in `workspace.yml`. All repos follow the same remote convention:
- `origin` = fork (`https://github.com/<github_username>/<repo>.git`)
- `upstream` = upstream (`https://github.com/<upstream-org>/<repo>.git`)

## The main/ Folder

- Contains the real clones of all repos (not worktrees).
- Always tracks upstream/main, reset via the refresh script.
- Uses the global ~/.m2/repository directly (no -Dmaven.repo.local override).

## Feature Directories

- Named freely (e.g., fix-frontmatter, new-plugin, roq-42).
- The name is used for both the directory and the branch name in each worktree.
- Created on demand with a skill. The skill asks which repos to include.
- Each feature has its own .m2 directory for Maven isolation.

## Maven Isolation via Tail Local Repository

Each feature worktree's .mvn/maven.config contains:

```
-Dmaven.repo.local=<absolute-path-to-feature>/.m2
-Daether.enhancedLocalRepository.localPath.tail=$HOME/.m2/repository
```

- Maven reads from the feature .m2 first, then falls back to ~/.m2/repository (read-only tail).
- Maven writes all new artifacts to the feature .m2 only.
- The feature .m2 starts empty; no seeding step required.
- ~/.m2/repository is never polluted by feature builds.

main/ repos use ~/.m2/repository directly (no override).

## IntelliJ IDEA

- Each repo in a feature is opened as a separate IntelliJ project (no multi-module).
- Both main/ and feature dirs must be openable in IDEA and able to run tests directly.
- IntelliJ local repository override: Settings > Build > Build Tools > Maven > check "Override" on "Local repository" and set it to <feature>/.m2. IntelliJ does not respect -Dmaven.repo.local from .mvn/maven.config for plugin resolution during import.

## A/B Comparison Workflow

When in doubt about how something worked before a change:
1. Open main/<repo> in IDEA (or run Maven there), it has pre-built upstream SNAPSHOTs ready.
2. Open <feature>/<repo> in IDEA, it has the feature branch with its own SNAPSHOTs.
3. Both are independently buildable and testable without interfering with each other.

## Skills

1. init-workspace: Clone all repos from workspace.yml into main/, set up remotes, build repos with build_on_init: true.
2. create-feature: Create a feature directory, ask which repos to include, set up worktrees and Maven config.
3. add-repo-to-feature: Add another repo's worktree to an existing feature.
4. delete-feature: Clean up worktrees and delete a feature directory. Archives the journal.
5. refresh-main: Reset all repos to upstream/main, rebuild repos with build_on_refresh: true.
6. write-journal: Append a daily journal entry for the current feature.
7. today-journal: Quick summary of today's work from journal entries.

## Shell Aliases

```bash
alias build-fast="<workspace-root>/scripts/build-fast.sh"
alias build-docs="<workspace-root>/scripts/build-docs.sh"
alias format="<workspace-root>/scripts/format.sh"
```

- build-fast: full build skipping tests, docs, and non-essential steps
- build-docs: build with docs but skip tests
- format: run source formatting only

## Git Structure of This Repo

This root directory is its own git repo containing:
- CLAUDE.md, workspace.yml
- Scripts (refresh loop, snapshot timestamps, etc.)
- .gitignore (allowlist approach, ignores everything except orchestration files)
- No source code
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "Rewrite CLAUDE.md for generic workspace"
```

---

### Task 3: Rewrite init-workspace skill

**Files:**
- Modify: `.claude/skills/init-workspace/SKILL.md` (full rewrite)

- [ ] **Step 1: Replace init-workspace skill**

```markdown
---
name: init-workspace
description: Clone all repos into main/, set up remotes, build all projects into ~/.m2
user_invocable: true
---

# Init Workspace

Initialize the main/ directory with all repositories defined in workspace.yml. Builds install SNAPSHOTs into ~/.m2/repository.

## Steps

1. Read workspace.yml to get the repo list and github_username.

2. Create main/ directory if it doesn't exist.

3. For each repo in workspace.yml, clone the fork into main/:
   ```
   git clone https://github.com/<github_username>/<repo>.git main/<repo>
   ```

4. For each cloned repo, add the upstream remote:
   ```
   cd main/<repo>
   git remote add upstream https://github.com/<upstream>.git
   ```

5. Fetch upstream and reset to upstream/main for each repo:
   ```
   git fetch upstream
   git reset --hard upstream/main
   ```

6. For each repo, if the local default branch is called master, rename it to main, set it to track origin/main, push it, and update the GitHub fork's default branch to main.

7. main/ repos use ~/.m2/repository directly. Do not set -Dmaven.repo.local in any main/ worktree. Do not create a main/.m2/ directory.

8. Build SNAPSHOTs for each repo with build_on_init: true:
   ```
   cd main/<repo>
   <workspace-root>/scripts/build-fast.sh
   ```

9. Verify the builds succeeded by checking ~/.m2/repository for SNAPSHOT artifacts from the built repos.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/init-workspace/SKILL.md
git commit -m "Rewrite init-workspace skill for generic workspace"
```

---

### Task 4: Rewrite create-feature skill

**Files:**
- Modify: `.claude/skills/create-feature/SKILL.md` (full rewrite)

- [ ] **Step 1: Replace create-feature skill**

```markdown
---
name: create-feature
description: Create a new feature directory with worktrees and isolated .m2
user_invocable: true
---

# Create Feature

Usage: /create-feature <name> (e.g., /create-feature fix-frontmatter)

Creates a feature directory with git worktrees and an isolated .m2 using Maven's tail local repository.

- <name>: Feature name (used for directory and branch naming).

## Prerequisites

- main/ must be initialized (run /init-workspace first).
- ~/.m2/repository must contain built artifacts.

## Steps

1. Read workspace.yml to get the repo list.

2. Validate: Check that main/ exists and contains at least one repo. Fail with a clear message if not.

3. Ask the user which repos to include as worktrees. List all repos from workspace.yml and let them pick. At least one repo must be selected.

4. Create feature directory:
   ```
   mkdir -p <workspace-root>/<name>/journal
   ```

5. Create the feature .m2 directory:
   ```
   mkdir -p <workspace-root>/<name>/.m2
   ```

6. For each selected repo, create a worktree from main/<repo>:
   ```
   cd <workspace-root>/main/<repo>
   git fetch upstream
   git worktree add -b <name> <workspace-root>/<name>/<repo> upstream/main
   ```
   If branch <name> already exists:
   ```
   git worktree add <workspace-root>/<name>/<repo> <name>
   ```

7. For each worktree, set up Maven config. Create or prepend to <workspace-root>/<name>/<repo>/.mvn/maven.config:
   ```
   -Dmaven.repo.local=<absolute-path-to-feature>/.m2
   -Daether.enhancedLocalRepository.localPath.tail=$HOME/.m2/repository
   ```
   If .mvn/maven.config already exists (from the repo), prepend these lines.

8. For each selected repo, ask whether to build its SNAPSHOTs into the feature .m2:
   - Repos with build_on_init: true in workspace.yml: suggest yes by default.
   - Repos with build_on_init: false: suggest no by default (the user is adding them for source-level changes, but may not need to build yet).
   ```
   cd <workspace-root>/<name>/<repo>
   <workspace-root>/scripts/build-fast.sh
   ```

9. Confirm: Print the feature directory contents and remind the user to configure IntelliJ IDEA before opening any repo:

   IntelliJ setup (required):
   - Local repository override: Settings > Build > Build Tools > Maven > check "Override" on "Local repository" and set it to <workspace-root>/<name>/.m2. IntelliJ does not respect -Dmaven.repo.local from .mvn/maven.config for plugin resolution during import.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/create-feature/SKILL.md
git commit -m "Rewrite create-feature skill for generic workspace"
```

---

### Task 5: Rewrite add-repo-to-feature skill

**Files:**
- Modify: `.claude/skills/add-repo-to-feature/SKILL.md` (full rewrite)

- [ ] **Step 1: Replace add-repo-to-feature skill**

```markdown
---
name: add-repo-to-feature
description: Add a repository worktree to an existing feature directory
user_invocable: true
---

# Add Repo to Feature

Usage: /add-repo-to-feature <repo> <feature-name> (e.g., /add-repo-to-feature quarkus-web-bundler fix-frontmatter)

Adds a worktree of the specified repository to an existing feature directory.

## Supported repos

Read workspace.yml for the list. Any repo defined there can be added.

## Prerequisites

- Feature directory <feature-name>/ must exist (run /create-feature first).
- The repo must be cloned in main/ (run /init-workspace first).

## Steps

1. Read workspace.yml to get the repo list and validate the repo name.

2. Validate: Check that <workspace-root>/<feature-name>/ exists and main/<repo> exists. Fail with a clear message if not.

3. Create worktree from main/<repo>:
   ```
   cd <workspace-root>/main/<repo>
   git fetch upstream
   git worktree add -b <feature-name> <workspace-root>/<feature-name>/<repo> upstream/main
   ```
   If branch <feature-name> already exists:
   ```
   git worktree add <workspace-root>/<feature-name>/<repo> <feature-name>
   ```

4. Set up Maven config in the worktree. Create or prepend to <workspace-root>/<feature-name>/<repo>/.mvn/maven.config:
   ```
   -Dmaven.repo.local=<absolute-path-to-feature>/.m2
   -Daether.enhancedLocalRepository.localPath.tail=$HOME/.m2/repository
   ```
   If .mvn/maven.config already exists (from the repo), prepend these lines.

5. Ask whether to build SNAPSHOTs for this repo into the feature .m2.

6. Confirm: Print the updated feature directory contents.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/add-repo-to-feature/SKILL.md
git commit -m "Rewrite add-repo-to-feature skill for generic workspace"
```

---

### Task 6: Rewrite delete-feature skill

**Files:**
- Modify: `.claude/skills/delete-feature/SKILL.md` (full rewrite)

- [ ] **Step 1: Replace delete-feature skill**

```markdown
---
name: delete-feature
description: Remove a feature directory, its worktrees, and its .m2
user_invocable: true
---

# Delete Feature

Usage: /delete-feature <name> (e.g., /delete-feature fix-frontmatter)

Cleans up a feature directory completely: removes git worktrees and deletes the directory.

## Steps

1. Read workspace.yml to get the repo list.

2. Validate: Check that <workspace-root>/<name>/ exists. Fail with a clear message if not.

3. List worktrees in the feature directory to identify which repos are present:
   ```bash
   ls <workspace-root>/<name>/
   ```

4. Remove each worktree via git:
   ```bash
   # For each repo dir found:
   cd <workspace-root>/main/<repo>
   git worktree remove <workspace-root>/<name>/<repo> --force
   ```

5. Archive journal: move daily journal files to the workspace archive:
   ```bash
   mkdir -p <workspace-root>/journal/<name>/events
   mv <workspace-root>/<name>/journal/*.md <workspace-root>/journal/<name>/events/
   ```

6. Generate summary: read all day files in chronological order and write <workspace-root>/journal/<name>/summary-<name>.md:
   - A short narrative intro: what the feature was about, when work started and ended
   - A condensed milestone list: key decisions, breakthroughs, final outcome
   - Aim for under 20 bullets regardless of how long the feature lasted
   - Formatting: headings and bullet lists only, no bold, no italics, no code blocks, no emoji

7. Commit the archived journal:
   ```bash
   git add <workspace-root>/journal/<name>/
   git commit -m "Archive journal for feature <name>"
   ```

8. Delete the feature directory and its .m2:
   ```bash
   rm -rf <workspace-root>/<name>/
   ```

9. Prune worktree references in each parent repo:
   ```bash
   # For each repo in workspace.yml:
   cd <workspace-root>/main/<repo> && git worktree prune
   ```

10. Confirm: Print that the feature has been deleted and list remaining feature directories.

## Safety

- Ask for confirmation before deleting. Show the user what will be removed (worktrees, branches, .m2 size).
- Ask whether to also delete the local branches or keep them.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/delete-feature/SKILL.md
git commit -m "Rewrite delete-feature skill for generic workspace"
```

---

### Task 7: Rewrite refresh-main skill

**Files:**
- Modify: `.claude/skills/refresh-main/SKILL.md` (full rewrite)

- [ ] **Step 1: Replace refresh-main skill**

```markdown
---
name: refresh-main
description: Long-running script that resets main/ to upstream and rebuilds configured repos
user_invocable: true
---

# Refresh Main

Usage: /refresh-main

Runs the refresh-main.sh script that keeps main/ in sync with upstream. The script loops forever: fetch, reset, build, sleep 1 hour.

## What the script does (each iteration)

1. Read workspace.yml for repo list and build flags.

2. Fetch and reset all repos to upstream/main:
   ```bash
   for each repo in workspace.yml:
     cd <workspace-root>/main/<repo>
     git fetch upstream
     git reset --hard upstream/main
   ```

3. Build SNAPSHOTs for repos with build_on_refresh: true:
   ```bash
   cd <workspace-root>/main/<repo>
   <workspace-root>/scripts/build-fast.sh
   ```

4. Log the timestamp and build result.

5. Sleep 1 hour, then repeat.

## Script location

The script is at <workspace-root>/scripts/refresh-main.sh.

## Running

Run the script in the background or in a dedicated terminal tab:
```bash
<workspace-root>/scripts/refresh-main.sh
```

The user can stop it with Ctrl+C at any time. The script handles SIGINT gracefully.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/refresh-main/SKILL.md
git commit -m "Rewrite refresh-main skill for generic workspace"
```

---

### Task 8: Update write-journal and today-journal skills

**Files:**
- Modify: `.claude/skills/write-journal/SKILL.md`
- Modify: `.claude/skills/today-journal/SKILL.md`

- [ ] **Step 1: Update write-journal paths**

In `.claude/skills/write-journal/SKILL.md`, replace all instances of `~/git/hibernate` with `<workspace-root>` (the actual workspace root directory, auto-detected from the current working directory). Specifically:

Replace the Feature Detection section:
```
## Feature Detection

Auto-detect which feature is active:

1. Check the current working directory for a feature path (e.g., ~/git/hibernate/3223/...)
2. Check conversation context for recent commands or file reads in a feature directory
3. If ambiguous or no feature context is found, ask the user which feature to journal
```
With:
```
## Feature Detection

Auto-detect which feature is active:

1. Determine the workspace root (the directory containing workspace.yml and CLAUDE.md).
2. Check the current working directory for a feature path within the workspace root.
3. Check conversation context for recent commands or file reads in a feature directory.
4. If ambiguous or no feature context is found, ask the user which feature to journal.
```

Replace all remaining `~/git/hibernate/<feature>` with `<workspace-root>/<feature>` and `~/git/hibernate/` with `<workspace-root>/` throughout the file.

- [ ] **Step 2: Update today-journal paths**

In `.claude/skills/today-journal/SKILL.md`, replace all path references:

Replace:
```bash
find ~/git/hibernate -maxdepth 2 -path '*/journal/*.md' -name "$(date +%Y-%m-%d).md"
find ~/git/hibernate/journal -maxdepth 3 -path '*/events/*.md' -name "$(date +%Y-%m-%d).md"
```
With:
```bash
find <workspace-root> -maxdepth 2 -path '*/journal/*.md' -name "$(date +%Y-%m-%d).md"
find <workspace-root>/journal -maxdepth 3 -path '*/events/*.md' -name "$(date +%Y-%m-%d).md"
```

Where `<workspace-root>` is the directory containing workspace.yml (auto-detected).

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/write-journal/SKILL.md .claude/skills/today-journal/SKILL.md
git commit -m "Update journal skills to use workspace root path"
```

---

### Task 9: Remove hibernate-micro-update skill

**Files:**
- Delete: `.claude/skills/hibernate-micro-update/SKILL.md`

- [ ] **Step 1: Delete the skill directory**

```bash
rm -rf .claude/skills/hibernate-micro-update/
```

- [ ] **Step 2: Commit**

```bash
git add -A .claude/skills/hibernate-micro-update/
git commit -m "Remove hibernate-micro-update skill"
```

---

### Task 10: Rewrite refresh-main.sh script

**Files:**
- Modify: `scripts/refresh-main.sh` (full rewrite)

- [ ] **Step 1: Replace refresh-main.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_YML="$WORKSPACE/workspace.yml"
MAIN_DIR="$WORKSPACE/main"
M2_DIR="$HOME/.m2/repository"

log() { echo "[$(date '+%H:%M:%S')] $*"; }
fail() { log "ERROR: $1"; exit 1; }

trap 'echo ""; log "Interrupted (Ctrl+C). Exiting."; exit 130' INT
trap 'log "Terminated (SIGHUP/Ctrl+D or terminal closed). Exiting."; exit 143' HUP

# Verify workspace exists
[[ -f "$WORKSPACE_YML" ]] || fail "workspace.yml not found at $WORKSPACE_YML"
[[ -d "$MAIN_DIR" ]] || fail "main/ directory not found at $MAIN_DIR"

# Read config
ALL_REPOS=$(yq '.repos | keys | .[]' "$WORKSPACE_YML")
BUILD_REPOS=$(yq '.repos | to_entries | .[] | select(.value.build_on_refresh == true) | .key' "$WORKSPACE_YML")

reset_repo() {
    local repo="$1"
    local dir="$MAIN_DIR/$repo"

    [[ -d "$dir" ]] || { log "SKIP $repo — not cloned"; return 0; }

    log "Resetting $repo to upstream/main..."
    cd "$dir"
    git fetch upstream
    git reset --hard upstream/main
    git clean -fd
    log "$repo reset to $(git rev-parse --short HEAD)"
}

build_repo() {
    local repo="$1"
    local dir="$MAIN_DIR/$repo"

    [[ -d "$dir" ]] || { log "SKIP $repo — not cloned"; return 0; }

    log "Building $repo (build-fast)..."
    cd "$dir"
    "$SCRIPT_DIR/build-fast.sh"
    log "$repo installed to ~/.m2/repository"
}

record_snapshot_timestamps() {
    local label="$1"
    "$SCRIPT_DIR/print-snapshot-timestamps.sh" "$M2_DIR" "$label" "$MAIN_DIR"
}

refresh_cycle() {
    local cycle="$1"
    log "========== Refresh cycle #$cycle starting =========="

    # Record pre-build timestamps
    record_snapshot_timestamps "before"

    # 1. Reset all repos to upstream/main
    for repo in $ALL_REPOS; do
        reset_repo "$repo"
    done

    # 2. Build repos with build_on_refresh: true
    for repo in $BUILD_REPOS; do
        build_repo "$repo"
    done

    # Record post-build timestamps
    record_snapshot_timestamps "after"

    log "========== Refresh cycle #$cycle complete =========="

    local before="$MAIN_DIR/.snapshot-timestamps-before"
    local after="$MAIN_DIR/.snapshot-timestamps-after"
    local before_count after_count
    before_count=$(wc -l < "$before")
    after_count=$(wc -l < "$after")
    log "SNAPSHOT jars: before=$before_count, after=$after_count"

    if [[ -s "$before" && -s "$after" ]]; then
        local changed
        changed=$(diff "$before" "$after" | grep -c '^[><]' || true)
        log "Changed/new jars: $changed"
        log "Sample updated jars:"
        diff "$before" "$after" | grep '^>' | head -5 | while read -r line; do
            log "  ${line#> }"
        done || true
    fi
    log ""
}

# --- Main loop ---
cycle=1
while true; do
    refresh_cycle "$cycle"
    cycle=$((cycle + 1))
    log "Sleeping 1 hour until next refresh..."
    sleep 3600
done
```

- [ ] **Step 2: Commit**

```bash
git add scripts/refresh-main.sh
git commit -m "Rewrite refresh-main.sh to read from workspace.yml"
```

---

### Task 11: Update print-snapshot-timestamps.sh

**Files:**
- Modify: `scripts/print-snapshot-timestamps.sh`

- [ ] **Step 1: Remove hardcoded artifact path filters**

Replace the `find` command that filters by `io/quarkus/*` and `org/hibernate/*` with a generic search for all SNAPSHOT jars:

Replace lines 13-17:
```bash
find "$M2_DIR" \( -path "*/io/quarkus/*" -o -path "*/org/hibernate/*" \) \
    -name "*SNAPSHOT*.jar" \
    ! -name "*-sources.jar" ! -name "*-javadoc.jar" ! -name "*-tests.jar" \
    -exec stat -f '%Sm|%N' -t '%Y-%m-%d %H:%M:%S' {} \; 2>/dev/null \
    | sort > "$OUTFILE"
```

With:
```bash
find "$M2_DIR" \
    -name "*SNAPSHOT*.jar" \
    ! -name "*-sources.jar" ! -name "*-javadoc.jar" ! -name "*-tests.jar" \
    -exec stat -f '%Sm|%N' -t '%Y-%m-%d %H:%M:%S' {} \; 2>/dev/null \
    | sort > "$OUTFILE"
```

- [ ] **Step 2: Commit**

```bash
git add scripts/print-snapshot-timestamps.sh
git commit -m "Remove hardcoded artifact path filters from snapshot timestamps"
```

---

### Task 12: Remove test-hibernate-update.sh

**Files:**
- Delete: `scripts/test-hibernate-update.sh`

- [ ] **Step 1: Delete the script**

```bash
rm scripts/test-hibernate-update.sh
```

- [ ] **Step 2: Commit**

```bash
git add -A scripts/test-hibernate-update.sh
git commit -m "Remove hibernate-specific test script"
```

---

### Task 13: Rewrite README.md

**Files:**
- Modify: `README.md` (full rewrite)

- [ ] **Step 1: Replace README.md**

```markdown
# feature-per-worktree

Orchestrate multi-repo feature branches with isolated git worktrees and dependency isolation for Java/Maven projects.

Each feature gets its own directory with git worktrees and an isolated Maven local repository, so builds never interfere with each other or pollute ~/.m2.

## How It Works

A single workspace.yml file defines your repos. Skills and scripts read from it to clone, build, and manage feature branches.

### Maven Isolation via Tail Local Repository

Feature builds use Maven's tail local repository feature:
- Each feature has its own .m2 directory (starts empty)
- Maven reads from the feature .m2 first, then falls back to ~/.m2/repository
- Maven writes only to the feature .m2
- No rsync, no hardlinks, no seeding step

### A/B Comparison

1. Open main/<repo> in your IDE, pre-built upstream SNAPSHOTs ready
2. Open <feature>/<repo> in your IDE, your feature branch with its own SNAPSHOTs
3. Both are independently buildable and testable, no interference

## Getting Started

1. Clone this repo and cd into it
2. Edit workspace.yml with your repos and GitHub username
3. Run /init-workspace to clone repos and build SNAPSHOTs

## workspace.yml Format

```yaml
project: my-project
github_username: my-username

repos:
  my-repo:
    upstream: org/my-repo
    build_on_init: true
    build_on_refresh: true
  dependency-repo:
    upstream: org/dependency-repo
    build_on_init: false
    build_on_refresh: false
```

### Fields

- project: Short name for log messages and journal references.
- github_username: GitHub username. origin = https://github.com/<username>/<repo>.git.
- repos: Map of repo name to config:
  - upstream: org/repo on GitHub (upstream remote).
  - build_on_init: Build SNAPSHOTs during /init-workspace. Default false.
  - build_on_refresh: Rebuild SNAPSHOTs during /refresh-main. Default false.

## Prerequisites

- Java (JDK 17+)
- mvnd (Maven Daemon)
- Git
- yq (brew install yq)
- Forks of the upstream repositories under your GitHub account

## Usage with Claude Code

This repo is designed to be used with Claude Code. The .claude/skills/ directory contains skills that automate the workflow:

| Skill                                  | Description                                              |
|----------------------------------------|----------------------------------------------------------|
| /init-workspace                        | Clone all repos into main/, set up remotes, do builds    |
| /create-feature <name>                 | Create a feature directory with worktrees and isolated .m2 |
| /add-repo-to-feature <repo> <feature>  | Add another repo's worktree to a feature                 |
| /delete-feature <name>                 | Clean up worktrees and delete a feature directory        |
| /refresh-main                          | Start the hourly upstream refresh loop                   |
| /write-journal                         | Write a daily work journal entry for the current feature |
| /today-journal                         | Quick summary of today's work                            |

## Example: Roq Workspace

```yaml
project: roq
github_username: ia3andy

repos:
  quarkus-roq:
    upstream: quarkiverse/quarkus-roq
    build_on_init: true
    build_on_refresh: true
  quarkus-web-bundler:
    upstream: quarkiverse/quarkus-web-bundler
    build_on_init: false
    build_on_refresh: false
  quarkus:
    upstream: quarkusio/quarkus
    build_on_init: false
    build_on_refresh: false
```
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "Rewrite README for generic workspace"
```

---

### Task 14: Final verification

- [ ] **Step 1: Verify all files are consistent**

Check that no Hibernate-specific references remain:
```bash
grep -ri "hibernate" CLAUDE.md README.md workspace.yml scripts/ .claude/skills/ --include="*.md" --include="*.sh" --include="*.yml"
```
Expected: no output (no matches).

Check that no `~/git/hibernate` paths remain:
```bash
grep -ri "~/git/hibernate" CLAUDE.md README.md workspace.yml scripts/ .claude/skills/ --include="*.md" --include="*.sh" --include="*.yml"
```
Expected: no output.

Check that no rsync/hardlink references remain:
```bash
grep -ri "rsync\|hardlink\|link-dest" CLAUDE.md README.md scripts/ .claude/skills/ --include="*.md" --include="*.sh"
```
Expected: no output.

- [ ] **Step 2: Verify workspace.yml is parseable**

```bash
yq '.' workspace.yml
```
Expected: pretty-printed YAML output matching the config.

```bash
yq '.repos | keys | .[]' workspace.yml
```
Expected:
```
quarkus
quarkus-roq
quarkus-web-bundler
```

- [ ] **Step 3: Verify .gitignore allowlist works**

```bash
git status
```
Expected: all orchestration files tracked, no feature dirs or main/ showing as untracked.
