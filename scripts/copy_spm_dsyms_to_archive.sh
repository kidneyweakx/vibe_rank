#!/bin/bash
set -euo pipefail

# Requires Xcode Archive Post-action with "Provide build settings from" your app target.

DSYM_DIR="$ARCHIVE_PATH/dSYMs"
TMP="$(mktemp -d)"

# Common locations SwiftPM uses
SPM_DIRS=(
  "${DERIVED_DATA_DIR}/SourcePackages"
  "${HOME}/Library/Caches/org.swift.swiftpm"
)

mkdir -p "$DSYM_DIR"

copy_found_dsYMs() {
  local root="$1"

  # 1) Already-unzipped .dSYM dirs (including inside .xcframework/dSYMs)
  find "$root" -type d -name "*.dSYM" -print0 2>/dev/null \
    | xargs -0 -I{} rsync -a "{}" "$DSYM_DIR/" || true

  # 2) Any *.dSYM.zip artifacts (SPM binary targets often download these)
  find "$root" -type f -name "*.dSYM.zip" -print0 2>/dev/null \
    | while IFS= read -r -d '' z; do unzip -q -o "$z" -d "$TMP"; done

  find "$TMP" -type d -name "*.dSYM" -print0 2>/dev/null \
    | xargs -0 -I{} rsync -a "{}" "$DSYM_DIR/" || true
}

for d in "${SPM_DIRS[@]}"; do
  [ -d "$d" ] || continue
  copy_found_dsYMs "$d"
done

echo "[copy_spm_dsyms] Collected dSYMs into: $DSYM_DIR"
ls -1 "$DSYM_DIR" || true