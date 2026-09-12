#!/usr/bin/env bash
set -euo pipefail
IN=${1:-grain_raw_30fps.uyvy}
OUT=${2:-grain_raw_30fps.mp4}
ffmpeg -y \
  -f rawvideo \
  -pixel_format uyvy422 \
  -video_size 1920x1200 \
  -framerate 30 \
  -i "$IN" \
  -c:v libx264 \
  -preset ultrafast \
  -crf 16 \
  "$OUT"
