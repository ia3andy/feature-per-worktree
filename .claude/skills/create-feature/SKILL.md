---
name: create-feature
description: Create a new feature directory with Quarkus worktree and isolated .m2
user_invocable: true
---

# Create Feature

Usage: `/create-feature <name> [base-branch]` (e.g., `/create-feature 3223` or `/create-feature 3.33-backport 3.33`)

Creates a feature directory with a Quarkus worktree and an isolated `.m2` seeded from `~/.m2/repository` via hardlinks.

- `<name>`: Feature name (used for directory and branch naming).
- `[base-branch]`: Optional upstream branch to base the worktree on. Defaults to `upstream/main`. If provided, fetch and use `upstream/<base-branch>` instead.

## Prerequisites

- `main/` must be initialized (run `/init-workspace` first).
- `~/.m2/repository` must contain built artifacts.

## Steps

1. **Validate**: Check that `main/quarkus` exists. Fail with a clear message if not.

2. **Create feature directory**:
   ```
   mkdir -p ~/git/hibernate/<number>/journal
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

4. **Seed `.m2`** via hardlinks from `~/.m2/repository`:
   ```
   rsync -a --link-dest=$HOME/.m2/repository/ $HOME/.m2/repository/ ~/git/hibernate/<name>/.m2/
   ```

5. **Set up Maven config** in the worktree:
   Create or prepend to `~/git/hibernate/<name>/quarkus/.mvn/maven.config`:
   ```
   -Dmaven.repo.local=$HOME/git/hibernate/<name>/.m2
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

9. **Confirm**: Print the feature directory contents and remind the user to configure IntelliJ IDEA before opening `~/git/hibernate/<name>/quarkus`:

   **IntelliJ setup (required):**
   - **Local repository override**: Settings → Build → Build Tools → Maven → check "Override" on "Local repository" and set it to `~/git/hibernate/<name>/.m2`. IntelliJ does not respect `-Dmaven.repo.local` from `.mvn/maven.config` for plugin resolution during import.
   - **Disable `--release` flag**: Settings → Build → Compiler → Java Compiler → uncheck "Use '--release' option for cross-compilation (Java 9 and later)". Without this, Quarkus fails to compile because `--release` conflicts with `--add-exports` for internal JDK APIs.
