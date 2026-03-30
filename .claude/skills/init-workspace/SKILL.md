---
name: init-workspace
description: Clone all repos into main/, set up remotes, do initial Quarkus build
user_invocable: true
---

# Init Workspace

Initialize the `~/git/hibernate/main/` directory with all repositories and a pre-built `.m2`.

## Steps

1. Create `main/` directory if it doesn't exist.

2. Clone each repository into `main/`:
   - `git clone git@github.com:lucamolteni/quarkus.git main/quarkus`
   - `git clone git@github.com:lucamolteni/hibernate-orm.git main/hibernate-orm`
   - `git clone git@github.com:lucamolteni/hibernate-reactive.git main/hibernate-reactive`
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

5. Create `main/.m2/` directory.

6. Set up `.mvn/maven.config` in `main/quarkus/` with:
   ```
   -Dmaven.repo.local=/Users/lmolteni/git/hibernate/main/.m2
   ```

7. Set up `.mvn/maven.config` in all other repos in `main/` with the same `.m2` path.

8. Build Quarkus into the local `.m2`:
   ```
   cd main/quarkus
   mvn clean install -DskipTests
   ```

9. Verify the build succeeded and `main/.m2/` contains `io/quarkus/` artifacts.
