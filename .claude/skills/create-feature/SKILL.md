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
