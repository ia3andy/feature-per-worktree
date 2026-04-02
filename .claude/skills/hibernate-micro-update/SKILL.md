---
name: hibernate-micro-update
description: Use when bumping Hibernate ORM, Reactive, and Tools versions in a Quarkus feature branch — either from a dependabot PR URL or explicit version numbers
---

# Hibernate Micro Update

Usage: `/hibernate-micro-update <versions or PR URL>` in a feature directory context.

Examples:
- `/hibernate-micro-update ORM 7.2.9.Final, Reactive 3.2.9.Final`
- `/hibernate-micro-update https://github.com/quarkusio/quarkus/pull/53334`

## Input Parsing

**From explicit versions:** Extract ORM and Reactive versions from free text. Tools version always equals ORM version.

**From PR URL:** Fetch with `gh pr view <number> --repo quarkusio/quarkus --json body,title,baseRefName` and parse the version table from the body to extract target versions.

## Prerequisites

- A feature directory must already exist with a Quarkus worktree and seeded `.m2`. If not, tell the user to run `/create-feature` first.
- The feature directory must contain `hibernate-orm/` and `hibernate-reactive/` worktrees (use `/add-repo-to-feature` if missing).

## Steps

### 1. Read current versions

Extract current values from `<feature>/quarkus/pom.xml`:
- `hibernate-orm.version`
- `hibernate-reactive.version`
- `hibernate-tools.version`
- `bytebuddy.version`
- `antlr.version`
- `hibernate-models.version`
- `geolatte.version`

These become the "From" column in the PR body.

### 2. Align ORM-controlled dependency versions

The Quarkus pom.xml tracks several properties that must stay aligned with what Hibernate ORM uses internally. These are marked with `<!-- version controlled by Hibernate ORM's needs -->`.

In `<feature>/hibernate-orm/`, fetch tags and read the target ORM version's `settings.gradle` to extract:
```bash
cd <feature>/hibernate-orm
git fetch upstream --tags
git show <new-orm-tag>:settings.gradle | grep -E 'def (antlrVersion|byteBuddyVersion|geolatteVersion|hibernateModelsVersion)'
```

The tag format is the version without `.Final` suffix (e.g., ORM `7.2.9.Final` → tag `7.2.9`).

Extract these version strings and compare with current Quarkus pom.xml values:
- `antlrVersion` → `antlr.version`
- `byteBuddyVersion` → `bytebuddy.version`
- `geolatteVersion` → `geolatte.version`
- `hibernateModelsVersion` → `hibernate-models.version`

Update any that differ.

### 3. Update pom.xml

Set these properties in `<feature>/quarkus/pom.xml`:
- `hibernate-orm.version` → new ORM version
- `hibernate-reactive.version` → new Reactive version
- `hibernate-tools.version` → new ORM version (same as ORM)
- `bytebuddy.version`, `antlr.version`, `geolatte.version`, `hibernate-models.version` → if changed (from step 2)

### 4. Build Quarkus

```bash
cd <feature>/quarkus
~/git/hibernate/scripts/build-fast.sh
```

Use `-B` flag and redirect output to a temp file to capture errors.

**If build fails:** STOP. Show the user the compilation errors. Let them fix the issues (e.g., API changes between versions). After they fix, re-run the build. Stage any files they changed alongside `pom.xml`.

### 5. Run Hibernate tests

```bash
~/git/hibernate/scripts/test-hibernate-update.sh <feature-name>
```

**If tests fail:** STOP. Show the user the test failures. Let them fix. After they fix, re-run the tests.

### 6. Commit

Stage `pom.xml` and any other files changed during fixes. Do NOT stage `.mvn/maven.config` (local repo path is a local-only change).

Create a single commit:
```
Bump Hibernate ORM to <ORM version>, Reactive to <Reactive version>
```

If amending an existing commit from a previous attempt, use `git commit --amend`. Otherwise create a new commit.

### 7. Push

```bash
git push origin <branch-name>
```

If the branch was force-pushed before (amending), use `--force`.

### 8. Create or update PR

**If a PR already exists** for this branch (check with `gh pr list --head <branch>`): update title and body with `gh pr edit`.

**If no PR exists:** create one with `gh pr create` targeting the upstream branch.

**PR title format:**
```
[<base-branch>] Bump Hibernate ORM to <ORM>, Reactive to <Reactive>
```

**PR body format:**
```markdown
## Summary
Bumps the hibernate group with N updates:

| Package | From | To |
| --- | --- | --- |
| org.hibernate.orm:hibernate-core | <old> | <new> |
| org.hibernate.orm:hibernate-graalvm | <old> | <new> |
| org.hibernate.orm:hibernate-envers | <old> | <new> |
| org.hibernate.orm:hibernate-spatial | <old> | <new> |
| org.hibernate.orm:hibernate-processor | <old> | <new> |
| org.hibernate.orm:hibernate-jpamodelgen | <old> | <new> |
| org.hibernate.orm:hibernate-community-dialects | <old> | <new> |
| org.hibernate.orm:hibernate-vector | <old> | <new> |
| org.hibernate.reactive:hibernate-reactive-core | <old-reactive> | <new-reactive> |
| org.hibernate.tool:hibernate-tools-language | <old-tools> | <new-tools> |

<any additional notes about fixes applied, e.g. test changes>

## Test plan
- [x] Hibernate ORM/Reactive extensions and integration tests pass locally
```

The "N updates" count is the number of rows in the table (always 10).

If any ORM-controlled dependencies were also updated (bytebuddy, antlr, etc.), add them as additional rows in the table.

## Handling Compilation Failures

When the build fails due to API changes between Hibernate versions:

1. Check out the appropriate tag in `<feature>/hibernate-orm` or `<feature>/hibernate-reactive` to investigate the API change.
2. Show the user the error and the relevant API diff.
3. Let the user fix the Quarkus code.
4. After the fix, re-run build and tests.
5. Include a note about the fix in the PR body (e.g., "Backport test fix from #XXXXX: ...").
