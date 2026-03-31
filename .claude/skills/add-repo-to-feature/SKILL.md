---
name: add-repo-to-feature
description: Add a repository worktree to an existing feature directory
user_invocable: true
---

# Add Repo to Feature

Usage: `/add-repo-to-feature <repo> <feature-number>` (e.g., `/add-repo-to-feature hibernate-orm 3223`)

Adds a worktree of the specified repository to an existing feature directory.

## Supported repos

- `hibernate-orm`
- `hibernate-reactive`
- `hibernate-tools`

## Prerequisites

- Feature directory `<number>/` must exist (run `/create-feature` first).
- The repo must be cloned in `main/` (run `/init-workspace` first).

## Steps

1. **Validate**: Check that `~/git/hibernate/<number>/` exists and `main/<repo>` exists. Fail with a clear message if not.

2. **Create worktree** from `main/<repo>`:
   ```
   cd ~/git/hibernate/main/<repo>
   git worktree add ~/git/hibernate/<number>/<repo> <number>
   ```
   If branch `<number>` doesn't exist, create it from `upstream/main`:
   ```
   git worktree add -b <number> ~/git/hibernate/<number>/<repo> upstream/main
   ```

3. **Set up Maven config** in the worktree:
   Create or prepend to `~/git/hibernate/<number>/<repo>/.mvn/maven.config`:
   ```
   -Dmaven.repo.local=$HOME/git/hibernate/<number>/.m2
   ```
   If `.mvn/maven.config` already exists (from the repo), prepend the line.

4. **Copy Maven safety extension** into `~/git/hibernate/<number>/<repo>/.mvn/`.

5. **Confirm**: Print the updated feature directory contents.
