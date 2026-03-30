---
name: create-feature
description: Create a new feature directory with Quarkus worktree and isolated .m2
user_invocable: true
---

# Create Feature

Usage: `/create-feature <number>` (e.g., `/create-feature 3223`)

Creates a feature directory with a Quarkus worktree and an isolated `.m2` seeded from `main/.m2`.

## Prerequisites

- `main/` must be initialized (run `/init-workspace` first).
- `main/.m2/` must contain built artifacts.

## Steps

1. **Validate**: Check that `main/quarkus` exists and `main/.m2/` has content. Fail with a clear message if not.

2. **Create feature directory**:
   ```
   mkdir -p ~/git/hibernate/<number>
   ```

3. **Create Quarkus worktree** from `main/quarkus`:
   ```
   cd ~/git/hibernate/main/quarkus
   git worktree add ~/git/hibernate/<number>/quarkus QUARKUS-<number>
   ```
   If branch `QUARKUS-<number>` doesn't exist, create it from `upstream/main`:
   ```
   git worktree add -b QUARKUS-<number> ~/git/hibernate/<number>/quarkus upstream/main
   ```

4. **Seed `.m2`** via hardlinks from `main/.m2`:
   ```
   rsync -a --link-dest=~/git/hibernate/main/.m2/ ~/git/hibernate/main/.m2/ ~/git/hibernate/<number>/.m2/
   ```

5. **Set up Maven config** in the worktree:
   Create `~/git/hibernate/<number>/quarkus/.mvn/maven.config` with:
   ```
   -Dmaven.repo.local=/Users/lmolteni/git/hibernate/<number>/.m2
   ```
   If `.mvn/maven.config` already exists (from the repo), prepend the line.

6. **Copy Maven safety extension** into `~/git/hibernate/<number>/quarkus/.mvn/` (symlink or copy the extension jar from the orchestration repo).

7. **Confirm**: Print the feature directory contents and remind the user they can open `~/git/hibernate/<number>/quarkus` in IntelliJ IDEA.
