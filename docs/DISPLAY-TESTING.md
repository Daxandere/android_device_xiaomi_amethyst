# Display responsiveness

## Report from the Global device

On `k307-eis2diag` with Global 307 firmware, the owner reported two cases:

- Pulling down Quick Settings (QS) stutters with background blur enabled.
  Turning blur off helps. Changing the launcher sometimes helps too.
- A developer touch indicator causes a short delay at the start of a touch,
  followed by fast response. The owner observed this with 120 Hz selected.
  Test the two Android indicators separately: **Show taps** draws the dot
  (`show_touches`), and **Pointer location** draws the trail and coordinates
  (`pointer_location`).

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
The measured slowdowns persisted at 120 Hz, so the 90 Hz mode is not needed
to reproduce them with these gestures. Repeat with finger input to check
hardware touch latency, and repeat over the home screen to compare launchers.

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
