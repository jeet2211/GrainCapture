#!/usr/bin/env bash
set -euo pipefail

DEV=${1:-/dev/video0}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE=${CAMERA_PROFILE:-"$SCRIPT_DIR/camera_profile.conf"}

if ! command -v v4l2-ctl >/dev/null 2>&1; then
  echo "ERROR: v4l2-ctl is not installed." >&2
  exit 1
fi

if [[ ! -e "$DEV" ]]; then
  echo "ERROR: camera device not found: $DEV" >&2
  exit 1
fi

if [[ ! -f "$PROFILE" ]]; then
  echo "ERROR: camera profile not found: $PROFILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$PROFILE"

apply_control() {
  local name=$1
  local value=${2:-}

  [[ -n "$value" ]] || return 0

  if v4l2-ctl -d "$DEV" -c "$name=$value" >/dev/null 2>&1; then
    printf '[camera] %-27s = %s\n' "$name" "$value"
  else
    printf '[camera] WARN: could not apply %s=%s (unsupported or rejected by driver)\n' "$name" "$value" >&2
  fi
}

printf '[camera] Applying profile %s to %s\n' "$PROFILE" "$DEV"

apply_control exposure "${EXPOSURE:-}"
apply_control brightness "${BRIGHTNESS:-}"
apply_control gain "${GAIN:-}"
apply_control contrast "${CONTRAST:-}"
apply_control saturation "${SATURATION:-}"
apply_control gamma "${GAMMA:-}"
apply_control white_balance_temperature "${WHITE_BALANCE_TEMPERATURE:-}"
apply_control sharpness "${SHARPNESS:-}"
apply_control backlight_compensation "${BACKLIGHT_COMPENSATION:-}"
apply_control frame_rate "${FRAME_RATE:-}"

# Read back the most important controls so a failed/reset value is visible immediately.
for control in exposure brightness gain saturation white_balance_temperature frame_rate; do
  v4l2-ctl -d "$DEV" -C "$control" 2>/dev/null || true
done
