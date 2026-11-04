#!/usr/bin/env bash
# Run only preprocessing, serial compilation, and the bounded Honshu smoke test.
set -euo pipefail
REPRO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPRO_ROOT/.."
RUN_DIR="$REPRO_ROOT/results/phase2-smoke-20261104"
mkdir -p "$RUN_DIR"
exec 9>"$REPRO_ROOT/environment/phase2.lock"
flock -n 9 || { echo "Another Phase 2 runner is active" >&2; exit 1; }
for STAGE in preprocess compile_models smoke_honshu; do
  STAGE_LOG="$RUN_DIR/${STAGE}.log"
  if [ -e "$STAGE_LOG" ]; then
    echo "Refusing to overwrite $STAGE_LOG; inspect or use the stage script directly." >&2
    exit 1
  fi
  bash "$REPRO_ROOT/scripts/run_r.sh" "$REPRO_ROOT/scripts/${STAGE}.R" > "$STAGE_LOG" 2>&1
done
echo "Phase 2 stages finished. Inspect diagnostics; this is not full inference."
