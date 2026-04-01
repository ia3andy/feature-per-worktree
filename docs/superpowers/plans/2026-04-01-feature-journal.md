# Feature Journal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add daily work journaling to feature branches, with archiving on feature deletion.

**Architecture:** Three skill files are touched. One new skill (`write-journal`) and two existing skills modified (`create-feature`, `delete-feature`). All skills are Claude Code SKILL.md files in `.claude/skills/`.

**Spec:** `docs/superpowers/specs/2026-04-01-feature-journal-design.md`

---

## File Structure

- Create: `.claude/skills/write-journal/SKILL.md` — new skill for writing journal entries
- Modify: `.claude/skills/create-feature/SKILL.md` — add journal dir initialization
- Modify: `.claude/skills/delete-feature/SKILL.md` — add journal archiving before deletion

---

### Task 1: Create the /write-journal skill

**Files:**
- Create: `.claude/skills/write-journal/SKILL.md`

- [ ] **Step 1: Create the skill file**

Create `.claude/skills/write-journal/SKILL.md` with the following content:

```markdown
---
name: write-journal
description: Write a daily work journal entry for the current feature
user_invocable: true
---

# Write Journal

Usage: `/write-journal [extra context]` (e.g., `/write-journal we decided to drop the reactive approach`)

Appends a journal entry for the current feature, capturing what was done in the session.

## Feature Detection

Auto-detect which feature is active:

1. Check the current working directory for a feature path (e.g., `~/git/hibernate/3223/...`)
2. Check conversation context for recent commands or file reads in a feature directory
3. If ambiguous or no feature context is found, ask the user which feature to journal

## Writing the Entry

1. **Determine the current date and time**:
   ```bash
   date "+%Y-%m-%d %H:%M"
   ```

2. **Gather git commits** on the feature branch(es) since the last journal entry (or all commits if no prior entry exists):
   ```bash
   # For each repo in the feature directory:
   cd ~/git/hibernate/<feature>/<repo>
   git log --oneline --since="<last entry timestamp or start of day>" HEAD
   ```

3. **Build the entry** from:
   - Session context: what problems were investigated, what was tried, what was learned
   - Git commits as milestones (short hash, commit message)
   - User-provided extra text (from the argument)

4. **Write to file** at `~/git/hibernate/<feature>/journal/YYYY-MM-DD.md`:
   - If the file exists, prepend the new entry at the top (newest first), separated by a blank line from the existing content
   - If the file does not exist, create it

## Entry Format

Each entry starts with a heading using the datetime, followed by bullet points. Entries must have enough prose to understand the problem context a month later.

```
## 2026-04-01 16:45

- Found the root cause of the flaky ORM batch insert test. H2 uses READ_COMMITTED by default but the test assumed REPEATABLE_READ. Fixed by explicitly setting the isolation level in the test configuration.
- commit: def5678 - Fix flaky batch insert test isolation level
```

## Formatting Rules

- No bold, no italics, no code blocks, no emoji
- Only headings (##) and unordered bullet lists (-)
- Terse but substantive: enough context to understand the problem, not just a list of actions
- No AI slop: no filler phrases, no unnecessary padding

## After Writing

Print the entry that was written and the file path.
```

- [ ] **Step 2: Verify the skill file exists and is well-formed**

```bash
cat .claude/skills/write-journal/SKILL.md | head -5
```

Expected: the YAML frontmatter with `name: write-journal`.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/write-journal/SKILL.md
git commit -m "Add /write-journal skill for daily feature journaling"
```

---

### Task 2: Modify /create-feature to initialize journal directory

**Files:**
- Modify: `.claude/skills/create-feature/SKILL.md:25-28` (after the mkdir step)

- [ ] **Step 1: Add journal directory creation**

In `.claude/skills/create-feature/SKILL.md`, after step 2 ("Create feature directory" with `mkdir -p ~/git/hibernate/<number>`), add the journal directory creation to the same step so it reads:

```
2. **Create feature directory**:
   ```
   mkdir -p ~/git/hibernate/<number>/journal
   ```
```

This replaces the existing `mkdir -p ~/git/hibernate/<number>` since `mkdir -p` with the `/journal` subdirectory creates both directories.

- [ ] **Step 2: Verify the change**

```bash
grep -A2 "Create feature directory" .claude/skills/create-feature/SKILL.md
```

Expected: shows `mkdir -p ~/git/hibernate/<number>/journal`.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/create-feature/SKILL.md
git commit -m "Init journal directory in /create-feature"
```

---

### Task 3: Modify /delete-feature to archive journals

**Files:**
- Modify: `.claude/skills/delete-feature/SKILL.md` (insert archive steps before step 4)

- [ ] **Step 1: Add archive steps to delete-feature**

In `.claude/skills/delete-feature/SKILL.md`, insert new steps between step 3 ("Remove each worktree") and the current step 4 ("Delete the feature directory"). The existing steps 4-6 become steps 7-9. The Safety section at the end of the file remains unchanged. Add these new steps:

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
```

- [ ] **Step 2: Verify the updated step numbering**

```bash
grep -n "^\d\." .claude/skills/delete-feature/SKILL.md
```

Expected: 9 steps total, numbered 1-9.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/delete-feature/SKILL.md
git commit -m "Add journal archiving to /delete-feature"
```

---

### Task 4: Manual verification

- [ ] **Step 1: Verify all three skill files parse correctly**

```bash
for skill in write-journal create-feature delete-feature; do
  echo "=== $skill ==="
  head -5 .claude/skills/$skill/SKILL.md
  echo
done
```

Expected: each shows valid YAML frontmatter.

- [ ] **Step 2: Test /write-journal on an existing feature**

If a feature directory exists (e.g., `48005/`), run `/write-journal` and verify:
- It detects the feature
- It creates a journal file at `<feature>/journal/YYYY-MM-DD.md`
- The entry has the correct datetime heading format (`## YYYY-MM-DD HH:MM`)
- The content is substantive prose with no formatting violations

- [ ] **Step 3: Test prepend behavior**

Run `/write-journal` again on the same feature and verify:
- The new entry appears at the top of the same day file
- A blank line separates the two entries
- The newer timestamp is above the older one

---

### Task 5: Update CLAUDE.md directory structure

**Files:**
- Modify: `CLAUDE.md` (directory structure section)

- [ ] **Step 1: Add journal/ to the directory structure**

In `CLAUDE.md`, update the directory structure diagram to include the `journal/` directory at the workspace root:

```
├── journal/                     # archived journals from completed features
│   └── 3223/
│       ├── events/              # daily journal files
│       └── summary-3223.md      # condensed summary
```

Also add `journal/` to the feature directory example:

```
├── 3223/                        # feature QUARKUS-3223
│   ├── quarkus/
│   ├── hibernate-orm/
│   ├── .m2/
│   └── journal/                 # daily work journal
```

- [ ] **Step 2: Add /write-journal to the Skills Needed section**

Add to the "Skills Needed" list in CLAUDE.md:

```
6. **write-journal** — e.g., "/write-journal" → appends a daily journal entry for the current feature, capturing session context and git commits.
```

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "Document journal directory and /write-journal skill in CLAUDE.md"
```
