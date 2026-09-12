# GrainCapture — Current Engineering Status

For the complete capture and processing workflow, see [README.md](README.md).

## Objective
Extract one clear image per falling grain against a controlled blue background, with a segmentation mask suitable for downstream grain analysis/classification.

## What is working
- AR0234 camera is detected and streaming on Jetson.
- UYVY 1920x1200 capture works.
- Direct V4L2 raw capture sustains a verified 30 fps for 300 frames / 10 seconds.
- Raw UYVY can be converted to high-quality H.264 MP4 after capture.
- Empty-sheet temporal background modeling works.
- OpenCV Lab/chroma-based segmentation can isolate foreground candidates while handling the non-uniform blue-sheet illumination better than the original fixed HSV pipeline.
- Candidate crops, masks, a background model, and an annotated segmentation video are generated.

## Current blockers
1. Camera color/exposure is not calibrated yet. The stable default stream works, but darker objects/grains can be rendered too dark while the blue sheet is bright.
2. Manual exposure control has produced black/green frames on this driver/firmware path, so it is not yet safe to use as a production setting.
3. Gain control is accepted by the driver, but the visual response is weaker than expected.
4. Moving grains can still be motion blurred. Individual-grain segmentation cannot be reliable when the source image contains a streak rather than a sharp grain.
5. Segmentation v4 currently generates foreground candidates per frame; final temporal tracking and one-best-frame-per-physical-grain selection remain the next stage after capture quality is stabilized.

## Current stable baseline
- Format: UYVY
- Resolution: 1920x1200
- Frame rate: 30 fps
- Exposure control: 1
- Brightness: 33000
- Gain: 0
- Contrast: 2
- Saturation: 2
- Gamma: 0
- White balance control: 0
- Sharpness: 3
- Backlight compensation: 6

This baseline is the recovery/stability configuration, not the final calibrated image-quality configuration.

## Recommended next step
Keep the current stable UYVY/30-fps acquisition path, tune illumination and camera color/exposure without using the unstable manual exposure mode, validate sharpness on stationary and falling grains, then add temporal tracking and best-frame selection to segmentation v4.
