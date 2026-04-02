# Feature 3.33-branch-hibernate-update

Backport of Hibernate version bumps to the Quarkus 3.33 release branch. Work started and completed on 2026-04-02.

## Milestones

- Updated Quarkus 3.33 branch to Hibernate ORM 7.2.9.Final, Reactive 3.2.9.Final, and Tools 7.2.9.Final
- Built ORM and Reactive locally from release tags into the feature .m2
- Verified ORM-controlled dependency versions (bytebuddy, antlr, hibernate-models, geolatte) unchanged between 7.2.8 and 7.2.9
- Confirmed ReactiveGeneratorWrapper removal and @Disabled test annotations still required for Reactive 3.2.9
- Full Hibernate test suite passed with no new issues
- Squashed into single commit and force-pushed to PR https://github.com/quarkusio/quarkus/pull/53334
- Created the /hibernate-micro-update skill to automate this workflow for future bumps
