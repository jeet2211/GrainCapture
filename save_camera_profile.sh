#!/usr/bin/env bash
set -euo pipefail

DEV=${1:-/dev/video0}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT=${2:-"$SCRIPT_DIR/camera_profile.conf"}
TMP="${OUT}.tmp"

if ! command -v v4l2-ctl >/dev/null 2>&1; then
  echo "ERROR: v4l2-ctl is not installed." >&2
  exit 1
fi

if [[ ! -e "$DEV" ]]; then
  echo "ERROR: camera device not found: $DEV" >&2
  exit 1
fi

: > "$TMP"
cat >> "$TMP" <<'EOF'
# GrainCapture camera profile
# Auto-generated from the camera's current V4L2 controls.
# It is applied automatically by camera_preview.sh and capture_raw_10s.sh.

EOF

save_control() {
  local control=$1
  local var=$2
  local line value

  if ! line=$(v4l2-ctl -d "$DEV" -C "$control" 2>/dev/null); then
    printf '[camera] WARN: cannot read %s; skipping\n' "$control" >&2
    return 0
  fi

  value=${line#*: }
  value=${value%% *}

  if [[ -z "$value" || ! "$value" =~ ^-?[0-9]+$ ]]; then
    printf '[camera] WARN: unexpected value for %s: %s; skipping\n' "$control" "$line" >&2
    return 0
  fi

  printf '%s=%s\n' "$var" "$value" >> "$TMP"
  printf '[camera] saved %-27s = %s\n' "$control" "$value"
}

save_control exposure EXPOSURE
save_control brightness BRIGHTNESS
save_control gain GAIN
save_control contrast CONTRAST
save_control saturation SATURATION
save_control gamma GAMMA
save_control white_balance_temperature WHITE_BALANCE_TEMPERATURE
save_control sharpness SHARPNESS
save_control backlight_compensation BACKLIGHT_COMPENSATION
save_control frame_rate FRAME_RATE

mv "$TMP" "$OUT"
printf '[camera] Profile saved to %s\n' "$OUT"
printf '[camera] Future preview/capture runs will apply it automatically.\n'
