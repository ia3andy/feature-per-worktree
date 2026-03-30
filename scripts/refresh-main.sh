#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="$HOME/git/hibernate"
MAIN_DIR="$WORKSPACE/main"
M2_DIR="$MAIN_DIR/.m2"

log() { echo "[$(date '+%H:%M:%S')] $*"; }
fail() { log "ERROR: $1"; exit 1; }

trap 'echo ""; log "Interrupted (Ctrl+C). Exiting."; exit 130' INT
trap 'log "Terminated (SIGHUP/Ctrl+D or terminal closed). Exiting."; exit 143' HUP

# Verify workspace exists
[[ -d "$MAIN_DIR" ]] || fail "main/ directory not found at $MAIN_DIR"

reset_repo() {
    local repo="$1"
    local dir="$MAIN_DIR/$repo"

    [[ -d "$dir" ]] || { log "SKIP $repo — not cloned"; return 0; }

    log "Resetting $repo to upstream/main..."
    cd "$dir"
    git fetch upstream
    git reset --hard upstream/main
    git clean -fd
    log "$repo reset to $(git rev-parse --short HEAD)"
}

build_gradle_repo() {
    local repo="$1"
    local dir="$MAIN_DIR/$repo"

    [[ -d "$dir" ]] || { log "SKIP $repo — not cloned"; return 0; }

    log "Building $repo (publishToMavenLocal)..."
    cd "$dir"
    ./gradlew publishToMavenLocal -x test --no-daemon \
        -Dmaven.repo.local="$M2_DIR"
    log "$repo published to $M2_DIR"
}

build_quarkus() {
    local dir="$MAIN_DIR/quarkus"

    log "Building Quarkus (mvn install -DskipTests)..."
    cd "$dir"
    ./mvnw -T1C clean install -DskipTests -Dno-format \
        -Dmaven.repo.local="$M2_DIR"
    log "Quarkus installed to $M2_DIR"
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

record_snapshot_timestamps() {
    local label="$1"
    "$SCRIPT_DIR/print-snapshot-timestamps.sh" "$M2_DIR" "$label"
}

refresh_cycle() {
    local cycle="$1"
    log "========== Refresh cycle #$cycle starting =========="

    # Record pre-build timestamps
    record_snapshot_timestamps "before"

    # 1. Reset all repos to upstream/main
    reset_repo quarkus
    reset_repo hibernate-orm
    reset_repo hibernate-reactive

    # 2. Build Hibernate ORM and Reactive (Gradle → publishToMavenLocal)
    build_gradle_repo hibernate-orm
    build_gradle_repo hibernate-reactive

    # 3. Build Quarkus (Maven → install)
    build_quarkus

    # Record post-build timestamps
    record_snapshot_timestamps "after"

    log "========== Refresh cycle #$cycle complete =========="

    local before="$MAIN_DIR/.snapshot-timestamps-before"
    local after="$MAIN_DIR/.snapshot-timestamps-after"
    local before_count after_count
    before_count=$(wc -l < "$before")
    after_count=$(wc -l < "$after")
    log "SNAPSHOT jars: before=$before_count, after=$after_count"

    if [[ -s "$before" && -s "$after" ]]; then
        local changed
        changed=$(diff "$before" "$after" | grep -c '^[><]' || true)
        log "Changed/new jars: $changed"
        log "Sample updated jars:"
        diff "$before" "$after" | grep '^>' | head -5 | while read -r line; do
            log "  ${line#> }"
        done || true
    fi
    log ""
}

# --- Main loop ---
cycle=1
while true; do
    refresh_cycle "$cycle"
    cycle=$((cycle + 1))
    log "Sleeping 1 hour until next refresh..."
    sleep 3600
done