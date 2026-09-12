# GrainCapture

Jetson-based AR0234 grain capture and candidate-segmentation tools. The working pipeline records a raw UYVY stream, converts it to MP4, and produces per-frame grain candidate crops, masks, a background model, and an annotated preview.

> **Project status:** This is a working engineering bundle, not a finished production system. Camera colour/exposure calibration and temporal per-grain tracking remain in progress; see [MANAGER_STATUS.md](MANAGER_STATUS.md) for the current limitations and next milestone.

## Current camera state

Verified camera path on Jetson:
- Sensor ID reported by driver: `0x0234` (AR0234)
- Firmware: `0x0003`
- Capture formats: `UYVY` and `NV16`
- Working mode used for tests: `UYVY 1920x1200 @ 30 fps`
- Stable baseline controls after recovering from green/black states:
  - exposure = 1
  - brightness = 33000
  - gain = 0
  - contrast = 2
  - saturation = 2
  - gamma = 0
  - white_balance_temperature = 0
  - sharpness = 3
  - backlight_compensation = 6
  - frame_rate = 30

IMPORTANT: This is a **stable baseline**, not a final color/exposure calibration. At this baseline the stream works, but the blue sheet can be over-bright and darker objects/grains may still have poor tonal/color reproduction. Do not claim camera image quality is finalized.

## Recommended test workflow

### 1. Restore stable controls
```bash
./set_camera_baseline.sh
```

### 2. Check live preview
```bash
./camera_preview.sh
```

### 3. Record 10 seconds of raw video at 30 fps
The recording script intentionally leaves exposure/gain/brightness unchanged.
```bash
./capture_raw_10s.sh /dev/video0 "$HOME/Downloads/grain_raw_30fps.uyvy"
```
Recommended sequence during the same 10-second recording:
- 0–3 s: empty blue sheet
- 3–8 s: drop grains
- 8–10 s: empty blue sheet

The segmentation defaults build their background model from 0.5–2.5 seconds, so that interval must remain clear of grains.

### 4. Convert raw recording to MP4 after capture
```bash
./convert_raw_to_mp4.sh \
  "$HOME/Downloads/grain_raw_30fps.uyvy" \
  "$HOME/Downloads/grain_raw_30fps.mp4"
```

### 5. Run current segmentation pipeline
```bash
./run_segmentation.sh \
  "$HOME/Downloads/grain_raw_30fps.mp4" \
  "$HOME/Downloads/grain_segment_v4_results"
```

To use a different clear-background interval or tune candidate sensitivity, invoke the Python script directly:
```bash
python3 grain_segment_v4.py \
  --video "$HOME/Downloads/grain_raw_30fps.mp4" \
  --out "$HOME/Downloads/grain_segment_v4_results" \
  --bg-start 0.5 --bg-end 2.5 --chroma-th 14
```

Outputs:
- `segmentation_preview_v4.mp4` — annotated preview
- `background_model.jpg` — temporal-median blue background
- `crops/` — candidate grain crops
- `masks/` — binary candidate masks

## Requirements

- Jetson/Linux capture host with `v4l2-ctl`, GStreamer (`gst-launch-1.0`), and FFmpeg installed
- Python 3 with the packages in `requirements.txt`:
  ```bash
  python3 -m pip install -r requirements.txt
  ```

## Current segmentation algorithm (v4)

1. Build a temporal-median background from the clear-sheet interval (default: 0.5–2.5 s).
2. Convert background and each frame to Lab color space.
3. Restrict processing to the detected blue-sheet ROI.
4. Compensate global chroma drift between current frame and reference background.
5. Compute chroma distance in Lab `a/b` channels to reduce sensitivity to illumination gradients.
6. Threshold foreground candidates.
7. Morphological opening/closing to remove noise and fill small gaps.
8. Connected-component filtering using area, width, height, and border constraints.
9. Save crop and mask for each accepted component.
10. Render an annotated segmentation preview.

## Current known issues

### Capture/image quality
- Stable stream is working, but natural grain/skin color is not yet calibrated.
- The blue background can dominate exposure/tone response.
- Short manual exposure tests caused black/green output; therefore manual shutter control is not yet considered production-safe on the current driver/firmware path.
- Higher gain values were accepted by the driver but did not provide the expected visual improvement.
- Falling grains can still motion-blur if shutter time remains too long.
- Lighting is uneven, though local background subtraction can compensate for much of this in software.

### Segmentation
- v4 is a **candidate segmentation** pipeline, not final per-grain production tracking.
- It is much less sensitive to sheet brightness gradients than the older HSV/background-difference pipeline.
- Accurate one-clear-image-per-grain output still depends on the source frame capturing a sharp, separated grain. Software cannot recover exact grain boundaries/color from severe motion blur or underexposure.

## Current recommendation

Keep `UYVY 1920x1200 @ 30 fps` and raw V4L2 capture as the working acquisition path. Continue color/exposure calibration from the known stable baseline. Do not use `exposure=0` as a production setting until the black/green behavior is understood. For segmentation, use v4 rather than the older hard-HSV pipeline. The next engineering milestone is to obtain sharp, naturally exposed moving grains and then add robust temporal tracking/best-frame selection on top of v4 segmentation.
