# Display responsiveness

## Report from the Global device

On `k307-eis2diag` with Global 307 firmware, the owner reported two cases:

- Pulling down Quick Settings (QS) stutters with background blur enabled.
  Turning blur off helps. Changing the launcher sometimes helps too.
- The owner confirmed a short delay at the start of a physical touch with
  **Show taps** (`show_touches`, displayed as **Mostrar presiones**), even
  with 120 Hz selected. It draws the dot below the finger. **Pointer location**
  (`pointer_location`) draws a trail and coordinates and is a separate test.

ADB confirmed three modes at 1220 × 2712, at 60, 90 and 120 Hz. The physical
mode and the rate at which new frames are presented are separate measurements.
DisplayManager sets the allowed range and SurfaceFlinger selects a mode based
on its policy and the active layers. [AOSP refresh-rate documentation](https://source.android.com/docs/core/graphics/multiple-refresh-rate)

## ADB and Perfetto results

Each condition used a 12-second trace with three repeated gesture sequences
injected through ADB. QS opened over the same Settings screen in both runs.
The dynamic traces recorded 60 and 120 Hz in `ActiveModeFps`, with no observed
90 Hz mode. The fixed runs reported 120 Hz before and after the gestures. Their
traces showed an 8.33 ms `VsyncPeriod` and only the 120 Hz display mode.

| Condition | SurfaceFlinger late presents | SurfaceFlinger GPU deadline misses |
|---|---:|---:|
| Dynamic, touch indicators off | 3 / 607 | 0 / 607 |
| Dynamic, Show taps | 2 / 625 | 0 / 625 |
| Dynamic, Pointer location | 35 / 630 | 12 / 630 |
| Fixed 120 Hz, touch indicators off | 0 / 624 | 0 / 624 |
| Fixed 120 Hz, Pointer location | 38 / 633 | 13 / 633 |
| Dynamic, QS blur off | 32 / 772 | 21 / 772 |
| Dynamic, QS blur on | 396 / 467 | 370 / 467 |
| Fixed 120 Hz, QS blur off | 33 / 777 | 28 / 777 |
| Fixed 120 Hz, QS blur on | 393 / 453 | 378 / 453 |

The denominators count SurfaceFlinger FrameTimeline records in each trace.
The blur and Pointer location slowdowns persisted at 120 Hz with injected
gestures. The Show taps row above is a synthetic-input control. It does not
measure the owner's physical-touch symptom. Repeat over the home screen to
compare launchers for the QS case.

## Check the hardware overlay hypothesis

Two ADB runs in each composition mode used the same Display settings screen and
the owner's indicators (`show_touches=1`, `pointer_location=0`). SurfaceFlinger
recorded 60 and 120 Hz in all four runs.

| Composition mode | GPU-composed records | Late presents | GPU deadline misses |
|---|---:|---:|---:|
| Hardware overlays allowed | 0 / 1,651 | 4 / 1,651 | 0 / 1,651 |
| GPU composition forced | 1,153 / 1,158 | 691 / 1,158 | 420 / 1,158 |

Forcing GPU composition made the scripted scroll less consistent. The traces
did not show the touch-spot surface, so this comparison cannot establish whether
the switch improves the first physical touch with Show taps enabled.

Leave **Show taps** on and **Pointer location** off. Start on the same scrollable
Settings page and repeat three finger swipes with two seconds of idle before each
one. Repeat with **Disable HW overlays** enabled, then with it off again. The
switch forces SurfaceFlinger client composition on the GPU while enabled. Use
FrameTimeline's GPU Composition field to verify that the composition path changed.
[AOSP Hardware Composer documentation](https://source.android.com/docs/core/graphics/implement-hwc)

Use physical input for the verdict. ADB `input swipe` injects a virtual motion
event. It can compare the render paths on the same screen, but does not exercise
the touchscreen driver or establish when the touch spot appears. In the physical
traces, compare the first frames after touch-down, active mode, late presents,
and any Display HAL or GPU deadline misses. Restore the switch after the tests.

### Physical touch results

The touchscreen logged `BTN_TOUCH DOWN` in both runs and Perfetto showed the
`Sprite` layer for the touch spot. The owner felt a brief slowdown followed by
acceleration in both modes. It was nearly imperceptible and more noticeable
with **Disable HW overlays** enabled.

| Composition mode | Touch-downs | Late presents in the first 450 ms | GPU deadline misses in the first 450 ms |
|---|---:|---:|---:|
| Hardware overlays allowed | 8 | 189 / 250 | 46 / 250 |
| GPU composition forced | 15 | 361 / 433 | 328 / 433 |

The frame windows start at dispatch of each physical `DOWN` to Settings. The
owner's cadence differed between runs, so these counts describe the traces and
do not measure finger-to-photon latency. With overlays allowed, two gestures
began at 60 Hz and SurfaceFlinger recorded 120 Hz 46–52 ms after dispatch.
Other gestures began at 120 Hz and still had late presents. Every GPU-forced
gesture began at 120 Hz. Together with the owner's report, the test does not
support forcing GPU composition as a fix for this symptom.

### Show taps at fixed 120 Hz

Both runs used physical gestures over the same Display settings page with
hardware overlays allowed and Pointer location off. ADB reported 120 Hz before
and after each run. The `VsyncPeriod` track showed 8.33 ms in both captures, and
the display mode recorded by SurfaceFlinger was 120 Hz.

| Show taps | Median gap between new frames | Gaps near 8.3 ms | Gaps near 16.7 ms |
|---|---:|---:|---:|
| On | 16.68 ms | 68 / 444 | 373 / 444 |
| Off | 8.34 ms | 757 / 830 | 69 / 830 |

Gaps between unique SurfaceFlinger present timestamps were measured in the
first 450 ms after each touch reached Settings. The comparison uses gaps below
50 ms to exclude pauses and includes a different number of gestures per run.
It measures presentation cadence during the gestures. The owner described
the first run as feeling like 60 Hz and the second as slightly faster.

With Show taps enabled, new frames usually arrived every other panel refresh.
Disabling it restored presentation on most refreshes in the test. The enabled
trace recorded 348 SurfaceFlinger CPU deadline misses. The disabled trace
recorded zero of that type, with some GPU deadline misses in both traces.
The result points to the touch-spot composition path. Inspect SurfaceFlinger's
CPU work and Hardware Composer calls while the `Sprite` layer updates before
changing refresh modes or interaction power hints.

## Reproduce and trace

Keep the launcher, wallpaper, foreground screen, brightness and battery saver
setting constant within each comparison. Start each gesture after about two
seconds of idle time and repeat it at least three times per condition.

1. Pull down QS from the same screen with blur off, then with blur on. Change
   the launcher only in a separate comparison from the home screen.
2. Scroll the same Settings page with both indicators off, with Show taps
   alone, then with Pointer location alone. Repeat with finger gestures to
   include the hardware input path.
3. Repeat the affected pairs at fixed 120 Hz. Save both settings before setting
   `min_refresh_rate` and `peak_refresh_rate` to `120.0`. Confirm the active mode
   and restore the previous values after the run. A setting originally read as
   `null` is restored with `settings delete system <key>`.

Commands checked on the Global 307 test build:

```sh
adb shell cmd display get-supported-modes 0
adb shell cmd display get-active-mode 0
adb shell settings get system min_refresh_rate
adb shell settings get system peak_refresh_rate
adb shell settings get system show_touches
adb shell settings get system pointer_location
adb shell wm disable-blur
```

From the device tree, capture one trace per condition. Perform the gestures
while the 12-second capture runs. Use a different name for each run.

```sh
adb shell -T 'perfetto --txt -c - -o /data/misc/perfetto-traces/amethyst-display.pftrace' < docs/display-perfetto.pbtxt
adb pull /data/misc/perfetto-traces/amethyst-display.pftrace
```

In PowerShell, pipe `Get-Content -Raw docs/display-perfetto.pbtxt` to the same
`adb shell` command in place of the `<` redirection. Open the trace in
[Perfetto UI](https://ui.perfetto.dev). Check the mode or vsync tracks during
each gesture, and compare SystemUI and SurfaceFlinger in FrameTimeline for late
or dropped frames. Use the input, thread scheduling and CPU-frequency tracks to
inspect the first delayed gesture. [Perfetto FrameTimeline reference](https://perfetto.dev/docs/data-sources/frametimeline)

## Decide what to change

- If the stutter remains at a verified 120 Hz, inspect which process misses
  its frame deadline. For QS, compare SurfaceFlinger GPU composition with and
  without blur. [AOSP window blur documentation](https://source.android.com/docs/core/display/window-blurs)
- If fixed 120 Hz helps and a transition through 90 Hz lines up with the stutter,
  compare the current build with a test build that exposes only 60 and 120 Hz.
  Keep dynamic switching and the same power profiles in both builds. Fixing at
  120 Hz alone removes every transition, so it cannot isolate 90 Hz.
- If the trace shows repeated scheduling delays at the first touch, check the
  interaction hints and frequency ramp before changing the Qualcomm performance
  blobs or the Volcano `powerhint.xml` selected by `device.mk`.
