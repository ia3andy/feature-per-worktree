# feature-per-worktree

Orchestrate multi-repo feature branches with isolated git worktrees and dependency isolation for Java/Maven projects.

Each feature gets its own directory with git worktrees and an isolated Maven local repository, so builds never interfere with each other or pollute ~/.m2.

## How It Works

A single workspace.yml file defines your repos. Skills and scripts read from it to clone, build, and manage feature branches.

### Maven Isolation via Tail Local Repository

Feature builds use Maven's tail local repository feature:
- Each feature has its own .m2 directory (starts empty)
- Maven reads from the feature .m2 first, then falls back to ~/.m2/repository
- Maven writes only to the feature .m2
- No rsync, no hardlinks, no seeding step

### A/B Comparison

1. Open main/<repo> in your IDE, pre-built upstream SNAPSHOTs ready
2. Open <feature>/<repo> in your IDE, your feature branch with its own SNAPSHOTs
3. Both are independently buildable and testable, no interference

## Getting Started

1. Clone this repo and cd into it
2. Edit workspace.yml with your repos and GitHub username
3. Run /init-workspace to clone repos and build SNAPSHOTs

## workspace.yml Format

```yaml
project: my-project
github_username: my-username

repos:
  my-repo:
    upstream: org/my-repo
    build_on_init: true
    build_on_refresh: true
  dependency-repo:
    upstream: org/dependency-repo
    build_on_init: false
    build_on_refresh: false
```

### Fields

- project: Short name for log messages and journal references.
- github_username: GitHub username. origin = https://github.com/<username>/<repo>.git.
- repos: Map of repo name to config:
  - upstream: org/repo on GitHub (upstream remote).
  - build_on_init: Build SNAPSHOTs during /init-workspace. Default false.
  - build_on_refresh: Rebuild SNAPSHOTs during /refresh-main. Default false.
  - default: Include in new features by default (when no repos specified). Default false.

## Prerequisites

- Java (JDK 17+)
- mvnd (Maven Daemon)
- Git
- yq (brew install yq)
- Forks of the upstream repositories under your GitHub account

## Usage with Claude Code

This repo is designed to be used with Claude Code. The .claude/skills/ directory contains skills that automate the workflow:

| Skill                                  | Description                                              |
|----------------------------------------|----------------------------------------------------------|
| /init-workspace                        | Clone all repos into main/, set up remotes, do builds    |
| /create-feature <name>                 | Create a feature directory with worktrees and isolated .m2 |
| /add-repo-to-feature <repo> <feature>  | Add another repo's worktree to a feature                 |
| /delete-feature <name>                 | Clean up worktrees and delete a feature directory        |
| /refresh-main                          | Start the hourly upstream refresh loop                   |
| /write-journal                         | Write a daily work journal entry for the current feature |
| /today-journal                         | Quick summary of today's work                            |

## Example: Roq Workspace

```yaml
project: roq
github_username: ia3andy

repos:
  quarkus-roq:
    upstream: quarkiverse/quarkus-roq
    build_on_init: true
    build_on_refresh: true
    default: true
  quarkus-web-bundler:
    upstream: quarkiverse/quarkus-web-bundler
    build_on_init: false
    build_on_refresh: false
  quarkus:
    upstream: quarkusio/quarkus
    build_on_init: false
    build_on_refresh: false
```
