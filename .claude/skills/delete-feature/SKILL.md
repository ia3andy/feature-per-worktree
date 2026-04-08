---
name: delete-feature
description: Remove a feature directory, its worktrees, and its .m2
user_invocable: true
---

# Delete Feature

Usage: /delete-feature <name> (e.g., /delete-feature fix-frontmatter)

Cleans up a feature directory completely: removes git worktrees and deletes the directory.

## Steps

1. Read workspace.yml to get the repo list.

2. Validate: Check that <workspace-root>/<name>/ exists. Fail with a clear message if not.

3. List worktrees in the feature directory to identify which repos are present:
   ```bash
   ls <workspace-root>/<name>/
   ```

4. Remove each worktree via git:
   ```bash
   # For each repo dir found:
   cd <workspace-root>/main/<repo>
   git worktree remove <workspace-root>/<name>/<repo> --force
   ```

5. Archive journal: move daily journal files to the workspace archive:
   ```bash
   mkdir -p <workspace-root>/journal/<name>/events
   mv <workspace-root>/<name>/journal/*.md <workspace-root>/journal/<name>/events/
   ```

6. Generate summary: read all day files in chronological order and write <workspace-root>/journal/<name>/summary-<name>.md:
   - A short narrative intro: what the feature was about, when work started and ended
   - A condensed milestone list: key decisions, breakthroughs, final outcome
   - Aim for under 20 bullets regardless of how long the feature lasted
   - Formatting: headings and bullet lists only, no bold, no italics, no code blocks, no emoji

7. Commit the archived journal:
   ```bash
   git add <workspace-root>/journal/<name>/
   git commit -m "Archive journal for feature <name>"
   ```

8. Delete the feature directory and its .m2:
   ```bash
   rm -rf <workspace-root>/<name>/
   ```

9. Prune worktree references in each parent repo:
   ```bash
   # For each repo in workspace.yml:
   cd <workspace-root>/main/<repo> && git worktree prune
   ```

10. Confirm: Print that the feature has been deleted and list remaining feature directories.

## Safety

- Ask for confirmation before deleting. Show the user what will be removed (worktrees, branches, .m2 size).
- Ask whether to also delete the local branches or keep them.
