# Hibernate Workspace — Claude Orchestration

This is the root directory for daily work. Claude is run from here and has access to all repos and feature branches.
This root folder is a **git repository** itself, but contains no source code — only orchestration, scripts, and Claude config. All `main/` and feature directories (and their `.m2` dirs) should be in `.gitignore`.

## Directory Structure

```
~/git/hibernate/
├── CLAUDE.md
├── main/                        # "real" clones, always at upstream/main
│   ├── quarkus/                 # primary repo
│   ├── hibernate-orm/
│   ├── hibernate-reactive/
│   ├── quarkus-wiki/            # reference only, lives only in main/
│   └── .m2/                     # pre-built SNAPSHOTs, always fresh
├── 3223/                        # feature QUARKUS-3223
│   ├── quarkus/                 # worktree from main/quarkus, branch QUARKUS-3223
│   ├── hibernate-orm/           # worktree, added on demand
│   ├── .m2/                     # seeded from main/.m2 via hardlinks
│   └── .mvn-settings/           # maven config pointing to this .m2
├── 4567/                        # another feature
│   └── ...
```

## Repositories

All repos follow the same remote convention:

| Repo                 | upstream (read-only)                                  | origin (fork)                                          |
|----------------------|-------------------------------------------------------|--------------------------------------------------------|
| quarkus              | `git@github.com:quarkusio/quarkus.git`                | `git@github.com:lucamolteni/quarkus.git`               |
| hibernate-orm        | `git@github.com:hibernate/hibernate-orm.git`          | `git@github.com:lucamolteni/hibernate-orm.git`         |
| hibernate-reactive   | `git@github.com:hibernate/hibernate-reactive.git`     | `git@github.com:lucamolteni/hibernate-reactive.git`    |
| quarkus-wiki         | TBD                                                   | TBD                                                    |

## The `main/` folder

- Contains the "real" clones of all repos (not worktrees).
- Always tracks `upstream/main` — reset hourly via a bash script.
- `main/` only needs the Quarkus clone for building — hibernate-orm and hibernate-reactive are cloned here as worktree sources for feature branches, but `main/` itself uses released final versions of Hibernate, not SNAPSHOTs.
- Has its own `.m2` directory with pre-built SNAPSHOT artifacts so A/B comparison is always instant.
- **Refresh script** is a long-running bash script (not a cron job). When executed, it loops: fetches upstream, resets all repos to `upstream/main`, rebuilds Quarkus (`mvn clean install -DskipTests`), then sleeps for 1 hour and repeats. The user decides when to start/stop it.
- Quarkus build takes ~7 minutes. The `main/.m2` must always be ready for comparison.

## Feature directories (e.g. `3223/`)

- Named after the issue number (e.g., QUARKUS-3223 becomes `3223/`).
- Created on demand with a skill.
- Always contains a Quarkus worktree (all features involve Quarkus so far).
- Other repos (hibernate-orm, hibernate-reactive) are added on demand via a separate skill.
- Each feature has its own `.m2` directory, seeded from `main/.m2` using `rsync --link-dest` (hardlinks).
  - This is instant and uses near-zero extra disk space.
  - Only rebuilt SNAPSHOT artifacts (io/quarkus/*, org/hibernate/*) diverge and use real space.
  - Maven config (`.mvn/maven.config`) in each worktree points to the feature's `.m2` via `-Dmaven.repo.local`.

## IntelliJ IDEA

- Each repo in a feature is opened as a **separate IntelliJ project** (no multi-module).
- Both `main/` and feature dirs must be openable in IDEA and able to run tests directly.
- The per-feature `.m2` + `.mvn/maven.config` ensures IDEA uses the correct local repo.

## A/B Comparison Workflow

When in doubt about how something worked before a change:
1. Open `main/quarkus` in IDEA (or run Maven there) — it has pre-built upstream SNAPSHOTs ready.
2. Open `3223/quarkus` in IDEA — it has the feature branch with its own SNAPSHOTs.
3. Both are independently buildable and testable without interfering with each other.

## Maven Safety: Prevent Use of ~/.m2

Every worktree (both `main/` and feature dirs) must be configured so Maven **never** reads from or writes to the global `~/.m2`. Options to enforce this:

1. **`.mvn/maven.config`** in every worktree with `-Dmaven.repo.local=<absolute-path-to-feature/.m2>` — this is the primary mechanism.
2. **Maven extension** (`.mvn/extensions.xml` + a small jar built in this orchestration repo) that runs at build start and verifies `maven.repo.local` points to a path inside `~/git/hibernate/`. If it doesn't (i.e., Maven would use `~/.m2`), the build fails immediately with a clear error. Since the extension lives in `.mvn/` inside each worktree, it only affects projects within this workspace — no impact on any other Maven project on the machine. It also catches builds triggered by IntelliJ IDEA, not just CLI.
3. The extension jar is built and versioned in this orchestration repo, then symlinked or copied into each worktree's `.mvn/` during feature creation.

This is critical: if Maven silently falls back to `~/.m2`, the entire isolation model breaks and A/B comparison becomes unreliable.

## Skills Needed

1. **init-workspace** — Clone all repos into `main/`, set up remotes (origin + upstream), do initial Quarkus build into `main/.m2`.
2. **create-feature** — e.g., "create feature 3223" → creates `3223/` dir, Quarkus worktree on branch `QUARKUS-3223`, seeds `.m2` from `main/.m2` via hardlinks, sets up `.mvn/maven.config`.
3. **add-repo-to-feature** — e.g., "add hibernate-orm to 3223" → creates worktree in `3223/hibernate-orm/` from `main/hibernate-orm`.
4. **refresh-main** — Bash script for hourly cron: fetches upstream, resets all repos to upstream/main, rebuilds Quarkus into `main/.m2`.
5. **delete-feature** — Cleans up worktrees (via `git worktree remove`) and deletes the feature directory + its `.m2`.

## Git Structure of This Repo

This root directory (`~/git/hibernate/`) is its own git repo containing:
- `CLAUDE.md` — this file
- Scripts (refresh loop, maven safety check, etc.)
- `.gitignore` — excludes `main/`, feature dirs (`[0-9]*/`), and `.m2/` directories
- No source code
