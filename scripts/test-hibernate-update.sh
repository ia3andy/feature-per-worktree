#!/bin/bash
set -e

# Build all hibernate-related modules without tests, then run verification tests
# Usage: test-hibernate-update.sh <feature-dir>
# Example: test-hibernate-update.sh 3.33-branch-hibernate-update

if [ -z "$1" ]; then
    echo "Usage: $0 <feature-dir>"
    echo "Example: $0 3.33-branch-hibernate-update"
    exit 1
fi

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QUARKUS_DIR="$WORKSPACE_ROOT/$1/quarkus"

if [ ! -d "$QUARKUS_DIR" ]; then
    echo "ERROR: $QUARKUS_DIR does not exist"
    exit 1
fi

cd "$QUARKUS_DIR"

echo ">>> Building hibernate-related modules (skip tests) in $QUARKUS_DIR ..."
mvn -pl extensions/hibernate-reactive/runtime,extensions/hibernate-reactive/deployment,extensions/hibernate-orm/runtime,extensions/hibernate-orm/deployment,extensions/panache/hibernate-reactive-panache-common/runtime,extensions/panache/hibernate-reactive-panache-common/deployment,extensions/panache/hibernate-reactive-panache/runtime,extensions/panache/hibernate-reactive-panache/deployment,extensions/spring-data-jpa/runtime,extensions/spring-data-jpa/deployment,integration-tests/hibernate-reactive-postgresql,integration-tests/hibernate-reactive-panache,integration-tests/smallrye-context-propagation,integration-tests/devtools install -DskipTests

echo ">>> Running verification tests..."
mvn -pl extensions/hibernate-reactive/deployment,extensions/hibernate-orm/deployment,extensions/panache/hibernate-reactive-panache-common/deployment,extensions/panache/hibernate-reactive-panache/deployment,extensions/spring-data-jpa/deployment,integration-tests/hibernate-reactive-postgresql,integration-tests/hibernate-reactive-panache,integration-tests/smallrye-context-propagation,integration-tests/devtools verify -Dtest-containers=true
