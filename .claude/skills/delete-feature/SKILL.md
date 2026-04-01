---
name: delete-feature
description: Remove a feature directory, its worktrees, and its .m2
user_invocable: true
---

# Delete Feature

Usage: `/delete-feature <number>` (e.g., `/delete-feature 3223`)

Cleans up a feature directory completely: removes git worktrees and deletes the directory.

## Steps

1. **Validate**: Check that `~/git/hibernate/<number>/` exists. Fail with a clear message if not.

2. **List worktrees** in the feature directory to identify which repos are present:
   ```bash
   ls ~/git/hibernate/<number>/
   ```

3. **Remove each worktree** via git:
   ```bash
   # For each repo dir found (e.g., quarkus, hibernate-orm):
   cd ~/git/hibernate/main/<repo>
   git worktree remove ~/git/hibernate/<number>/<repo> --force
   ```

4. **Archive journal** — move daily journal files to the workspace archive:
   ```bash
   mkdir -p ~/git/hibernate/journal/<number>/events
   mv ~/git/hibernate/<number>/journal/*.md ~/git/hibernate/journal/<number>/events/
   ```

5. **Generate summary** — read all day files in chronological order and write `~/git/hibernate/journal/<number>/summary-<number>.md`:
   - A short narrative intro: what the feature was about, when work started and ended
   - A condensed milestone list: key decisions, breakthroughs, final outcome
   - Aim for under 20 bullets regardless of how long the feature lasted
   - Formatting: headings and bullet lists only, no bold, no italics, no code blocks, no emoji

6. **Commit the archived journal**:
   ```bash
   git add ~/git/hibernate/journal/<number>/
   git commit -m "Archive journal for feature <number>"
   ```

7. **Delete the feature directory** and its `.m2`:
   ```bash
   rm -rf ~/git/hibernate/<number>/
   ```

8. **Prune worktree references** in each parent repo:
   ```bash
   cd ~/git/hibernate/main/quarkus && git worktree prune
   cd ~/git/hibernate/main/hibernate-orm && git worktree prune
   cd ~/git/hibernate/main/hibernate-reactive && git worktree prune
   ```

9. **Confirm**: Print that the feature has been deleted and list remaining feature directories.

## Safety

- **Ask for confirmation** before deleting. Show the user what will be removed (worktrees, branches, `.m2` size).
- Ask whether to also delete the local branches (e.g., `QUARKUS-3223`) or keep them.
