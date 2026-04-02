---
name: today-journal
description: Use when the user wants a quick two-line summary of today's work from journal entries
---

# Today Journal

Usage: `/today-journal`

Produces a two-line summary of today's work across all features.

## Steps

1. Determine today's date:
   ```bash
   date "+%Y-%m-%d"
   ```

2. Scan for today's journal entries in two places:
   - **Active features**: check `~/git/hibernate/*/journal/YYYY-MM-DD.md`
   - **Archived journals**: check `~/git/hibernate/journal/*/events/YYYY-MM-DD.md`
   ```bash
   find ~/git/hibernate -maxdepth 2 -path '*/journal/*.md' -name "$(date +%Y-%m-%d).md"
   find ~/git/hibernate/journal -maxdepth 3 -path '*/events/*.md' -name "$(date +%Y-%m-%d).md"
   ```

3. Read all matching journal files. If none exist, say so and stop.

4. Produce two or three bullet points summarizing the entire day's work across all features. The summary should:
   - Cover all entries from all features, not just the latest one
   - Be concrete: mention what was built, fixed, refactored, or discovered
   - If multiple features had work, cover both

5. Copy the two-line summary to the clipboard:
   ```bash
   echo "<summary>" | pbcopy
   ```

6. Print the summary and confirm it was copied to the clipboard.
