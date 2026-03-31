#!/usr/bin/env bash
set -euo pipefail

# Usage: print-snapshot-timestamps.sh <m2-dir> [label] [output-dir]
# Finds SNAPSHOT jars (io/quarkus/*, org/hibernate/*) in the given .m2 directory,
# prints their modification timestamps, and writes them to a file for diffing.

M2_DIR="${1:?Usage: print-snapshot-timestamps.sh <m2-dir> [label] [output-dir]}"
LABEL="${2:-snapshot}"
OUT_DIR="${3:-${M2_DIR}/..}"
OUTFILE="${OUT_DIR}/.snapshot-timestamps-${LABEL}"

find "$M2_DIR" \( -path "*/io/quarkus/*" -o -path "*/org/hibernate/*" \) \
    -name "*SNAPSHOT*.jar" \
    ! -name "*-sources.jar" ! -name "*-javadoc.jar" ! -name "*-tests.jar" \
    -exec stat -f '%Sm|%N' -t '%Y-%m-%d %H:%M:%S' {} \; 2>/dev/null \
    | sort > "$OUTFILE"

COUNT=$(wc -l < "$OUTFILE")
echo "[$(date '+%H:%M:%S')] Recorded $LABEL timestamps ($COUNT jars) → $OUTFILE"

# Print a sample of the most recent 5
echo "Sample jars:"
sort -t'|' -k1,1r "$OUTFILE" | head -5 | while IFS='|' read -r ts path; do
    echo "  $ts  ${path##*/}"
done || true