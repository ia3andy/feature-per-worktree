#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_YML="$WORKSPACE/workspace.yml"
MAIN_DIR="$WORKSPACE/main"
M2_DIR="$HOME/.m2/repository"

log() { echo "[$(date '+%H:%M:%S')] $*"; }
fail() { log "ERROR: $1"; exit 1; }

trap 'echo ""; log "Interrupted (Ctrl+C). Exiting."; exit 130' INT
trap 'log "Terminated (SIGHUP/Ctrl+D or terminal closed). Exiting."; exit 143' HUP

# Verify workspace exists
[[ -f "$WORKSPACE_YML" ]] || fail "workspace.yml not found at $WORKSPACE_YML"
[[ -d "$MAIN_DIR" ]] || fail "main/ directory not found at $MAIN_DIR"

# Read config
ALL_REPOS=$(yq '.repos | keys | .[]' "$WORKSPACE_YML")
BUILD_REPOS=$(yq '.repos | to_entries | .[] | select(.value.build_on_refresh == true) | .key' "$WORKSPACE_YML")

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

build_repo() {
    local repo="$1"
    local dir="$MAIN_DIR/$repo"

    [[ -d "$dir" ]] || { log "SKIP $repo — not cloned"; return 0; }

    log "Building $repo (build-fast)..."
    cd "$dir"
    "$SCRIPT_DIR/build-fast.sh"
    log "$repo installed to ~/.m2/repository"
}

record_snapshot_timestamps() {
    local label="$1"
    "$SCRIPT_DIR/print-snapshot-timestamps.sh" "$M2_DIR" "$label" "$MAIN_DIR"
}

refresh_cycle() {
    local cycle="$1"
    log "========== Refresh cycle #$cycle starting =========="

    # Record pre-build timestamps
    record_snapshot_timestamps "before"

    # 1. Reset all repos to upstream/main
    for repo in $ALL_REPOS; do
        reset_repo "$repo"
    done

    # 2. Build repos with build_on_refresh: true
    for repo in $BUILD_REPOS; do
        build_repo "$repo"
    done

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
