---
name: write-journal
description: Write a daily work journal entry for the current feature
user_invocable: true
---

# Write Journal

Usage: /write-journal [extra context] (e.g., /write-journal we decided to drop the reactive approach)

Appends a journal entry for the current feature, capturing what was done in the session.

## Feature Detection

Auto-detect which feature is active:

1. Determine the workspace root (the directory containing workspace.yml and CLAUDE.md).
2. Check the current working directory for a feature path within the workspace root.
3. Check conversation context for recent commands or file reads in a feature directory.
4. If ambiguous or no feature context is found, ask the user which feature to journal.

## Writing the Entry

1. **Determine the current date and time**:
   ```bash
   date "+%Y-%m-%d %H:%M"
   ```

2. **Gather git commits** on the feature branch(es) since the last journal entry (or all commits if no prior entry exists). Parse the first `## YYYY-MM-DD HH:MM` heading from the existing day file to determine the cutoff:
   ```bash
   # For each repo in the feature directory:
   cd <workspace-root>/<feature>/<repo>
   git log --oneline --since="<last entry timestamp or start of day>" HEAD
   ```

3. **Build the entry** from:
   - Session context: what problems were investigated, what was tried, what was learned
   - Git commits as milestones (short hash, commit message)
   - User-provided extra text (from the argument)

4. **Write to file** at `<workspace-root>/<feature>/journal/YYYY-MM-DD.md`:
   - If the file exists, prepend the new entry at the top (newest first), separated by a blank line from the existing content
   - If the file does not exist, create it

## Entry Format

Each entry starts with a heading using the datetime, followed by bullet points. Entries must have enough prose to understand the problem context a month later.

```
## 2026-04-01 16:45

- Found the root cause of the flaky batch insert test. H2 uses READ_COMMITTED by default but the test assumed REPEATABLE_READ. Fixed by explicitly setting the isolation level in the test configuration.
- commit: def5678 - Fix flaky batch insert test isolation level
```

## Formatting Rules

- No bold, no italics, no code blocks, no emoji
- Only headings (##) and unordered bullet lists (-)
- Terse but substantive: enough context to understand the problem, not just a list of actions
- No AI slop: no filler phrases, no unnecessary padding

## After Writing

Print the entry that was written and the file path.
