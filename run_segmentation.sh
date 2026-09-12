#!/usr/bin/env bash
set -euo pipefail
VIDEO=${1:-$HOME/Downloads/grain_raw_30fps.mp4}
OUT=${2:-$HOME/Downloads/grain_segment_v4_results}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/grain_segment_v4.py" \
  --video "$VIDEO" \
  --out "$OUT"
printf 'Results: %s\n' "$OUT"
