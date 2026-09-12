#!/usr/bin/env bash
set -euo pipefail
DEV=${1:-/dev/video0}
v4l2-ctl -d "$DEV" \
  -c exposure=1 \
  -c brightness=33000 \
  -c gain=0 \
  -c contrast=2 \
  -c saturation=2 \
  -c gamma=0 \
  -c white_balance_temperature=0 \
  -c sharpness=3 \
  -c backlight_compensation=6 \
  -c frame_rate=30
v4l2-ctl -d "$DEV" -C exposure -C brightness -C gain -C frame_rate
