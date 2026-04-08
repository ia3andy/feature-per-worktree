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
