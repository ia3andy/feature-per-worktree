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
