---
name: create-feature
description: Create a new feature directory with worktrees and isolated .m2
user_invocable: true
---

# Create Feature

Usage: /create-feature [name] [repo1 repo2 ...]

Creates a feature directory with git worktrees and an isolated .m2 using Maven's tail local repository.

- If no name is provided, ask the user for one.
- If no repos are specified, use repos with `default: true` in workspace.yml.
- Repos with `build_on_init: true` are built automatically without prompting.

## Prerequisites

- main/ must be initialized (run /init-workspace first).
- ~/.m2/repository must contain built artifacts.

## Steps

1. Read workspace.yml to get the repo list. If no name was provided as argument, ask the user.

2. Validate: Check that main/ exists and contains at least one repo. Fail with a clear message if not.

3. Determine which repos to include: use the repos specified as arguments, or repos with `default: true` if none specified.

4. Create feature directory and .m2:
   ```
   mkdir -p <workspace-root>/<name>/journal <workspace-root>/<name>/.m2
   ```

5. For each selected repo, update main/<repo> to latest upstream and create the worktree:
   ```
   cd <workspace-root>/main/<repo>
   git fetch upstream
   git rebase upstream/main
   git worktree add -b <name> <workspace-root>/<name>/<repo> upstream/main
   ```
   If branch <name> already exists:
   ```
   git worktree add <workspace-root>/<name>/<repo> <name>
   ```

6. For each worktree, set up Maven config. Create or prepend to <workspace-root>/<name>/<repo>/.mvn/maven.config:
   ```
   -Dmaven.repo.local=<absolute-path-to-feature>/.m2
   -Daether.enhancedLocalRepository.localPath.tail=$HOME/.m2/repository
   ```
   If .mvn/maven.config already exists (from the repo), prepend these lines.

7. For each repo with `build_on_init: true` in workspace.yml, build SNAPSHOTs automatically:
   ```
   cd <workspace-root>/<name>/<repo>
   <workspace-root>/scripts/build-fast.sh
   ```

8. For each worktree, configure IntelliJ IDEA's Maven local repository override via `.idea/workspace.xml`.
   If the file exists, add or update the `MavenImportPreferences` component. If it doesn't exist, create it.
   The component should contain:
   ```xml
   <component name="MavenImportPreferences">
     <option name="generalSettings">
       <MavenGeneralSettings>
         <option name="localRepository" value="<absolute-path-to-feature>/.m2" />
       </MavenGeneralSettings>
     </option>
   </component>
   ```
   This is required because IntelliJ does not respect `-Dmaven.repo.local` from `.mvn/maven.config` for plugin resolution during import.

9. Print the feature directory contents and note:
   - Reload the project in IntelliJ (close and reopen, or File > Invalidate Caches) so it picks up the Maven local repository override.
   - List repos from workspace.yml that are NOT included in this feature as available dependency sources in `main/`.
