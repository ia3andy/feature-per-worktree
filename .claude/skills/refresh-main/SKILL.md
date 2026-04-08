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
