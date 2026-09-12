#!/usr/bin/env bash
set -euo pipefail
DEV=${1:-/dev/video0}
OUT=${2:-grain_raw_30fps.uyvy}
# Does NOT change exposure/gain/brightness; it records whatever camera settings are active.
v4l2-ctl -d "$DEV" \
  -c frame_rate=30 \
  --set-fmt-video=width=1920,height=1200,pixelformat=UYVY \
  --stream-mmap=4 \
  --stream-count=300 \
  --stream-to="$OUT"
