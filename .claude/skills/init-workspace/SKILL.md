---
name: init-workspace
description: Clone all repos into main/, set up remotes, build all projects into ~/.m2
user_invocable: true
---

# Init Workspace

Initialize the `~/git/hibernate/main/` directory with all repositories. Builds install SNAPSHOTs into `~/.m2/repository`.

## Steps

1. Create `main/` directory if it doesn't exist.

2. Clone each repository into `main/`:
   - `git clone git@github.com:$GITHUB_USERNAME/quarkus.git main/quarkus`
   - `git clone git@github.com:$GITHUB_USERNAME/hibernate-orm.git main/hibernate-orm`
   - `git clone git@github.com:$GITHUB_USERNAME/hibernate-reactive.git main/hibernate-reactive`
   - Clone quarkus-wiki (URL TBD)

3. For each cloned repo, add the upstream remote:
   - `cd main/quarkus && git remote add upstream git@github.com:quarkusio/quarkus.git`
   - `cd main/hibernate-orm && git remote add upstream git@github.com:hibernate/hibernate-orm.git`
   - `cd main/hibernate-reactive && git remote add upstream git@github.com:hibernate/hibernate-reactive.git`

4. Fetch upstream and reset to upstream/main for each repo:
   ```
   git fetch upstream
   git reset --hard upstream/main
   ```

5. For each repo, if the local default branch is called `master`, rename it to `main`, set it to track `origin/main`, push it, and update the GitHub fork's default branch to `main`.

6. `main/` repos use `~/.m2/repository` directly — do **not** set `-Dmaven.repo.local` in any `main/` worktree. Do **not** create a `main/.m2/` directory.

7. Build Quarkus into `~/.m2`:
   ```
   cd main/quarkus
   mvn clean install -DskipTests
   ```

8. Build hibernate-orm SNAPSHOTs (Gradle project):
    ```
    cd main/hibernate-orm
    ./gradlew publishToMavenLocal -x test
    ```

9. Build hibernate-reactive SNAPSHOTs (Gradle project):
    ```
    cd main/hibernate-reactive
    ./gradlew publishToMavenLocal -x test
    ```

10. Verify the builds succeeded and `~/.m2/repository` contains `io/quarkus/`, `org/hibernate/orm/`, and `org/hibernate/reactive/` artifacts.
