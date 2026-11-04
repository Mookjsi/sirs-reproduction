#!/usr/bin/env bash
# User-invoked entry point only. No jobs are launched automatically.
set -euo pipefail
REPRO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec bash "$REPRO_ROOT/scripts/run_r.sh" "$REPRO_ROOT/scripts/pipeline.R" "$@"
