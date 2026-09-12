#!/usr/bin/env bash
set -euo pipefail
DEV=${1:-/dev/video0}
gst-launch-1.0 v4l2src device="$DEV" io-mode=2 ! \
'video/x-raw,format=UYVY,width=1920,height=1200,framerate=30/1' ! \
videoconvert ! autovideosink sync=false
