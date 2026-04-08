# Generic Feature Workspace

Make the feature-per-worktree workspace reusable across projects (Roq, Web Bundler, mvnpm, esbuild-java, etc.). Each project gets its own workspace directory cloned from this template repo, configured via a single `workspace.yml` file. Replace the rsync/hardlink `.m2` seeding with Maven's tail local repository.

## workspace.yml

Single source of truth for project-specific configuration. All skills and scripts read from this file.

```yaml
project: roq
github_username: ia3andy

repos:
  quarkus-roq:
    upstream: quarkiverse/quarkus-roq
    build_on_init: true
    build_on_refresh: true
  quarkus-web-bundler:
    upstream: quarkiverse/quarkus-web-bundler
    build_on_init: false
    build_on_refresh: false
  quarkus:
    upstream: quarkusio/quarkus
    build_on_init: false
    build_on_refresh: false
```

### Fields

- **project**: Short name, used in log messages and journal archive references.
- **github_username**: GitHub username for fork URLs. `origin` = `https://github.com/<github_username>/<repo>.git`, `upstream` = `https://github.com/<upstream>.git`.
- **repos**: Map of repo name to config:
  - **upstream**: `org/repo` on GitHub (upstream remote).
  - **build_on_init**: Whether to build SNAPSHOTs during `/init-workspace`. Default `false`.
  - **build_on_refresh**: Whether to rebuild SNAPSHOTs during `/refresh-main` cycle. Default `false`.

### Parsing

- **Skills** (Claude): Read the file as text. Claude understands YAML natively.
- **Scripts** (bash): Use `yq` (install via `brew install yq`). Example: `yq '.repos | keys | .[]' workspace.yml` to list repo names, `yq '.repos["quarkus-roq"].build_on_refresh' workspace.yml` to check flags.

### Example: other projects

**Web Bundler workspace** (`~/workspace/web-bundler-features/workspace.yml`):
```yaml
project: web-bundler
github_username: ia3andy

repos:
  quarkus-web-bundler:
    upstream: quarkiverse/quarkus-web-bundler
    build_on_init: true
    build_on_refresh: true
  quarkus-roq:
    upstream: quarkiverse/quarkus-roq
    build_on_init: false
    build_on_refresh: false
```

**mvnpm workspace** (`~/workspace/mvnpm-features/workspace.yml`):
```yaml
project: mvnpm
github_username: ia3andy

repos:
  mvnpm:
    upstream: mvnpm/mvnpm
    build_on_init: true
    build_on_refresh: true
  quarkus-web-bundler:
    upstream: quarkiverse/quarkus-web-bundler
    build_on_init: false
    build_on_refresh: false
  quarkus-roq:
    upstream: quarkiverse/quarkus-roq
    build_on_init: false
    build_on_refresh: false
```

## Directory Structure

```
~/workspace/<project>-features/
├── CLAUDE.md                    # generic, reads workspace.yml for project details
├── workspace.yml                # project-specific config
├── scripts/
│   ├── build-fast.sh            # generic mvnd build
│   ├── build-docs.sh            # build with docs
│   ├── format.sh                # source formatting
│   ├── refresh-main.sh          # reads workspace.yml
│   └── print-snapshot-timestamps.sh
├── main/                        # real clones, always at upstream/main
│   ├── <repo-1>/
│   ├── <repo-2>/
│   └── ...
├── <feature-name>/              # feature directory (named freely)
│   ├── <repo>/                  # worktree (ask user which repos)
│   ├── .m2/                     # local repo (read+write), falls back to ~/.m2
│   └── journal/
├── journal/                     # archived journals from completed features
```

## Maven Isolation via Tail Local Repository

Replaces the previous rsync/hardlink approach entirely.

Each feature worktree's `.mvn/maven.config` contains:

```
-Dmaven.repo.local=<absolute-path-to-feature>/.m2
-Daether.enhancedLocalRepository.localPath.tail=$HOME/.m2/repository
```

How it works:
- Maven reads from the feature `.m2` first, then falls back to `~/.m2/repository` (read-only tail)
- Maven writes all new artifacts to the feature `.m2` only
- The feature `.m2` starts empty; no seeding step required
- `~/.m2/repository` is never polluted by feature builds

`main/` repos use `~/.m2/repository` directly (no override), same as before.

## Remote Convention

All URLs use HTTPS. Remotes follow `origin`/`upstream` convention:
- `origin` = fork (`https://github.com/<github_username>/<repo>.git`)
- `upstream` = upstream (`https://github.com/<upstream-org>/<repo>.git`)

## Feature Naming

Features are named freely (e.g., `fix-frontmatter`, `new-plugin`, `roq-42`). No prefix convention. The name is used for both the directory and the branch name in each worktree.

## What Changes

### CLAUDE.md

Rewrite to be generic. Instead of hardcoding repos and paths:
- Reference `workspace.yml` for the repo list
- Use the workspace root path (`$WORKSPACE_ROOT` or auto-detected from the directory)
- Document the Maven tail repo approach
- List generic skills (no project-specific skills like hibernate-micro-update)
- Shell aliases use relative paths from the workspace root

### workspace.yml (new file)

Created per project. The Roq workspace gets the example shown above.

### Skills

All skills become generic by reading `workspace.yml`:

**init-workspace**: Parse `workspace.yml` for repos. Clone each into `main/`, set up `origin`/`upstream` remotes. Build SNAPSHOTs for repos with `build_on_init: true`.

**create-feature**: Ask the user which repos (from `workspace.yml`) to include as worktrees. Set up `.mvn/maven.config` with `maven.repo.local` and `localPath.tail`. If a repo is included that has `build_on_init: false`, ask whether to build its SNAPSHOTs.

**add-repo-to-feature**: List of supported repos comes from `workspace.yml` (all repos except the one already in the feature). Set up `.mvn/maven.config`.

**delete-feature**: Prune worktrees for whichever repos exist in the feature directory. Repo list from `workspace.yml` for pruning.

**refresh-main**: Reset all repos from `workspace.yml` to upstream/main. Build SNAPSHOTs only for repos with `build_on_refresh: true`.

**write-journal**: Uses workspace root path (auto-detected). No project-specific content.

**today-journal**: Uses workspace root path (auto-detected). No project-specific content.

**hibernate-micro-update**: Remove entirely (Hibernate-specific, not generic).

### Scripts

**build-fast.sh**: Keep as-is (generic mvnd command).

**build-docs.sh**: Keep as-is.

**format.sh**: Keep as-is.

**refresh-main.sh**: Rewrite to parse `workspace.yml`. Reset all repos. Build only repos with `build_on_refresh: true`.

**print-snapshot-timestamps.sh**: Remove the hardcoded `io/quarkus/*` and `org/hibernate/*` path filters. Instead, scan all SNAPSHOT jars in the given `.m2` directory (simpler and works for any project).

**test-hibernate-update.sh**: Remove (Hibernate-specific).

### .gitignore

Switch to an allowlist approach since feature directories are now freely named:

```
# Ignore everything
*

# Allow orchestration files
!CLAUDE.md
!README.md
!workspace.yml
!.gitignore
!scripts/
!scripts/**
!journal/
!journal/**
!docs/
!docs/**
!.claude/
!.claude/**
```

### README.md

Rewrite as a generic template README:
- Explain the feature-per-worktree pattern
- Document `workspace.yml` format
- List skills and their usage
- Include a "Getting started" section: clone repo, edit `workspace.yml`, run `/init-workspace`
