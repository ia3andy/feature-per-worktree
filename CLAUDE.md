# Feature Workspace

This is the root directory for daily work. Claude is run from here and has access to all repos and feature branches.
This root folder is a git repository itself, but contains no source code, only orchestration, scripts, and Claude config.

## Project Configuration

All project-specific settings live in `workspace.yml`. Read it at the start of every session to know which repos are configured, their upstream URLs, and build flags.

## Directory Structure

```
<workspace-root>/
├── CLAUDE.md
├── workspace.yml                # project config (repos, usernames, build flags)
├── scripts/
├── main/                        # real clones, always at upstream/main
│   ├── <repo-1>/
│   ├── <repo-2>/
│   └── ...
├── <feature-name>/              # feature directory (named freely)
│   ├── <repo>/                  # worktree from main/<repo>
│   ├── .m2/                     # isolated local repo, falls back to ~/.m2
│   └── journal/
├── journal/                     # archived journals from completed features
```

## Repositories

Defined in `workspace.yml`. All repos follow the same remote convention:
- `origin` = fork (`https://github.com/<github_username>/<repo>.git`)
- `upstream` = upstream (`https://github.com/<upstream-org>/<repo>.git`)

## The main/ Folder

- Contains the real clones of all repos (not worktrees).
- Always tracks upstream/main, reset via the refresh script.
- Uses the global ~/.m2/repository directly (no -Dmaven.repo.local override).

## Feature Directories

- Named freely (e.g., fix-frontmatter, new-plugin, roq-42).
- The name is used for both the directory and the branch name in each worktree.
- Created on demand with a skill. The skill asks which repos to include.
- Each feature has its own .m2 directory for Maven isolation.

## Maven Isolation via Tail Local Repository

Each feature worktree's .mvn/maven.config contains:

```
-Dmaven.repo.local=<absolute-path-to-feature>/.m2
-Daether.enhancedLocalRepository.localPath.tail=$HOME/.m2/repository
```

- Maven reads from the feature .m2 first, then falls back to ~/.m2/repository (read-only tail).
- Maven writes all new artifacts to the feature .m2 only.
- The feature .m2 starts empty; no seeding step required.
- ~/.m2/repository is never polluted by feature builds.

main/ repos use ~/.m2/repository directly (no override).

## IntelliJ IDEA

- Each repo in a feature is opened as a separate IntelliJ project (no multi-module).
- Both main/ and feature dirs must be openable in IDEA and able to run tests directly.
- IntelliJ local repository override: the create-feature skill sets this automatically via `.idea/workspace.xml` using the `MavenImportPreferences` component. IntelliJ does not respect `-Dmaven.repo.local` from `.mvn/maven.config` for plugin resolution during import, so the XML override is required.
- The tail local repository setting may not be used by IntelliJ during import. This is acceptable because the feature `.m2` contains all built SNAPSHOTs, and released dependencies are downloaded from Maven Central.

## A/B Comparison Workflow

When in doubt about how something worked before a change:
1. Open main/<repo> in IDEA (or run Maven there), it has pre-built upstream SNAPSHOTs ready.
2. Open <feature>/<repo> in IDEA, it has the feature branch with its own SNAPSHOTs.
3. Both are independently buildable and testable without interfering with each other.

## Skills

1. init-workspace: Clone all repos from workspace.yml into main/, set up remotes, build repos with build_on_init: true.
2. create-feature: Create a feature directory, ask which repos to include, set up worktrees and Maven config.
3. add-repo-to-feature: Add another repo's worktree to an existing feature.
4. delete-feature: Clean up worktrees and delete a feature directory. Archives the journal.
5. refresh-main: Reset all repos to upstream/main, rebuild repos with build_on_refresh: true.
6. write-journal: Append a daily journal entry for the current feature.
7. today-journal: Quick summary of today's work from journal entries.

## Shell Aliases

```bash
alias build-fast="<workspace-root>/scripts/build-fast.sh"
alias build-docs="<workspace-root>/scripts/build-docs.sh"
alias format="<workspace-root>/scripts/format.sh"
```

- build-fast: full build skipping tests, docs, and non-essential steps
- build-docs: build with docs but skip tests
- format: run source formatting only

## PRs and Issues

When creating pull requests or issues, keep descriptions concise and informative:
- Summarize what changed and why in a few bullet points.
- Do not add a "Validation" or "Test plan" section.
- No boilerplate, checklists, or filler text.
- Do not add "Generated with Claude Code" or similar attribution lines.

## Git Structure of This Repo

This root directory is its own git repo containing:
- CLAUDE.md, workspace.yml
- Scripts (refresh loop, snapshot timestamps, etc.)
- .gitignore (allowlist approach, ignores everything except orchestration files)
- No source code
