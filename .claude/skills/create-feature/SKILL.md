---
name: create-feature
description: Create a new feature directory with Quarkus worktree and isolated .m2
user_invocable: true
---

# Create Feature

Usage: `/create-feature <name> [base-branch]` (e.g., `/create-feature 3223` or `/create-feature 3.33-backport 3.33`)

Creates a feature directory with a Quarkus worktree and an isolated `.m2` seeded from `main/.m2`.

- `<name>`: Feature name (used for directory and branch naming).
- `[base-branch]`: Optional upstream branch to base the worktree on. Defaults to `upstream/main`. If provided, fetch and use `upstream/<base-branch>` instead.

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
   If a base branch was specified, fetch it first:
   ```
   cd ~/git/hibernate/main/quarkus
   git fetch upstream <base-branch>
   ```
   Then create the worktree (use `upstream/main` if no base branch was specified):
   ```
   git worktree add ~/git/hibernate/<name>/quarkus QUARKUS-<name>
   ```
   If branch `QUARKUS-<name>` doesn't exist, create it from the base:
   ```
   git worktree add -b QUARKUS-<name> ~/git/hibernate/<name>/quarkus upstream/<base-branch>
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

6. **Copy Maven safety extension** into `~/git/hibernate/<name>/quarkus/.mvn/` (symlink or copy the extension jar from the orchestration repo).

7. **Build Quarkus** into the feature's `.m2`:
   ```
   cd ~/git/hibernate/<name>/quarkus
   ./mvnw -T1C clean install -DskipTests -Dno-format
   ```
   (The `-Dmaven.repo.local` is already set via `.mvn/maven.config`.)

8. **Verify SNAPSHOT artifacts were updated** using the shared script:
   ```
   ~/git/hibernate/scripts/print-snapshot-timestamps.sh ~/git/hibernate/<name>/.m2 after
   ```
   This prints a summary with jar count and timestamps to confirm the build populated the feature's `.m2`.

9. **Confirm**: Print the feature directory contents and remind the user they can open `~/git/hibernate/<name>/quarkus` in IntelliJ IDEA.
