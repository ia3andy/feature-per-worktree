---
name: refresh-main
description: Long-running script that resets main/ to upstream and rebuilds Quarkus hourly
user_invocable: true
---

# Refresh Main

Usage: `/refresh-main`

Creates and runs a long-running bash script that keeps `main/` in sync with upstream. The script loops forever: fetch, reset, build, sleep 1 hour.

## What the script does (each iteration)

1. **Fetch and reset all repos**:
   ```bash
   for repo in quarkus hibernate-orm hibernate-reactive; do
     cd ~/git/hibernate/main/$repo
     git fetch upstream
     git reset --hard upstream/main
   done
   ```

2. **Build Quarkus** (only Quarkus, not the other repos):
   ```bash
   cd ~/git/hibernate/main/quarkus
   mvn clean install -DskipTests -Dmaven.repo.local=~/git/hibernate/main/.m2
   ```

3. **Log** the timestamp and build result.

4. **Sleep 1 hour**, then repeat.

## Script location

Write the script to `~/git/hibernate/scripts/refresh-main.sh` and make it executable.

## Running

Run the script in the background or in a dedicated terminal tab:
```bash
~/git/hibernate/scripts/refresh-main.sh
```

The user can stop it with Ctrl+C at any time. The script should handle SIGINT gracefully (print a message and exit cleanly).
