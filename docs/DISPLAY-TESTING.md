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
The result points to the touch-spot composition path.

### Where presentation stalls

The same fixed-120-Hz traces show that the extra time accumulates in the
Hardware Composer call. These are median slice durations for calls that start
within 450 ms of a physical touch reaching Settings.

| Trace slice | Show taps off | Show taps on |
|---|---:|---:|
| SurfaceFlinger `present` | 1.88 ms | 9.18 ms |
| SurfaceFlinger `HwcPresentDisplay 0` | 0.95 ms | 6.06 ms |
| Qualcomm composer `atomic_commit` | 0.07 ms | 5.48 ms |

The discrete HWC present call also occurred more often with Show taps on
(414 of 545 presentations versus 76 of 943). In a sample of 50 slow
`atomic_commit` calls from the enabled trace, the composer thread spent about
97% of the measured interval asleep. This explains why FrameTimeline marked
CPU deadline misses even though the driver call spent most of its time waiting.
[Perfetto FrameTimeline reference](https://perfetto.dev/docs/data-sources/frametimeline)

All 50 sampled calls contained a Qualcomm SDE vblank callback and a trace event
from `_sde_encoder_phys_vid_wait_for_vblank`. The wait event appeared a median
0.24 ms before the commit returned. This places the stall in the display sync
path. The public Qualcomm driver uses that function to wait for a VSYNC IRQ.
The trace does not yet explain why adding the touch spot sends more frames down
this path. [Qualcomm SDE reference implementation](https://android.googlesource.com/kernel/msm-extra/display-drivers/+/e7ab2aa8bd2f6f27b311ccada3722d20dee4bcef/msm/sde/sde_encoder_phys_vid.c)

The trace config includes scheduler wakeups, DMA fence waits, SDE fence status
and DRM vblank events to compare against the SDE callbacks. Use it to see which
layer and commit changes precede the wait. [Linux DRM atomic commit documentation](https://docs.kernel.org/gpu/drm-kms-helpers.html)

### Present route when the touch spot is active

Within the fixed-120-Hz Show taps trace, group SurfaceFlinger `present` slices
by how recently `Sprite` appeared in the main thread's layer summary. Count
the separate `HwcPresentDisplay 0` calls nested inside each presentation.

| Last Sprite layer summary | Presentations | Separate HWC presents | Median `present` |
|---|---:|---:|---:|
| Within 7 ms | 409 | 409 | 9.38 ms |
| 7–30 ms earlier | 29 | 1 | 3.46 ms |
| At least 30 ms earlier or absent | 689 | 14 | 1.79 ms |

The summary marker indicates when SurfaceFlinger evaluated the layer. It does
not report a new buffer or the composition type selected for that frame. The
separate HWC present correlates with that marker. AOSP can combine validation
and presentation when the composition state and expected present time allow
it. Check the effective composition type of `Sprite` and the rest of the
layers before attributing the change to cursor-plane support.
[AOSP HWComposer implementation](https://android.googlesource.com/platform/frameworks/native/+/main/services/surfaceflinger/DisplayHardware/HWComposer.cpp)

The physical layer capture at fixed 120 Hz contained 245 snapshots. The
touch-spot buffer layer was visible in 232, and all 232 reported `DEVICE` (2).
The same snapshots kept the Settings surface and the refresh-rate indicator
as `DEVICE` whether the spot was visible or hidden. The hardware composed the
spot as an overlay. The capture did not show it using the `CURSOR` composition
type or causing Settings to fall back to `CLIENT` composition.
[Composer HAL composition types](https://android.googlesource.com/platform/hardware/interfaces/+/refs/heads/master/graphics/composer/aidl/android/hardware/graphics/composer3/Composition.aidl)

The trace also recorded that `crtc_commit:141` woke the Qualcomm composer in
all 50 sampled slow `atomic_commit` calls. The observation supports inspecting
presentation and display synchronization with the extra overlay.

### Refresh-rate indicator control

The same fixed-120-Hz physical test was repeated with Show taps on and the
developer refresh-rate indicator off. It used the original timing profile
from `936d08b`, hardware overlays allowed, and the same Display settings page.
The owner reported a slight delay. The panel reported 120 Hz before and after
the run, and Perfetto recorded an 8.33 ms vsync period.

| Refresh-rate indicator | Median gap between new frames | Gaps near 16.7 ms | Separate HWC presents within 7 ms of a Sprite summary | Median `present` in those frames |
|---|---:|---:|---:|---:|
| On | 16.68 ms | 373 / 444 | 409 / 409 | 9.38 ms |
| Off | 16.68 ms | 447 / 540 | 477 / 477 | 9.36 ms |

These runs had different numbers of gestures. Both reproduced the pacing
problem with the touch spot, so the refresh-rate indicator is not required
for it. Disabling Show taps remains the verified workaround on this build.

### Comparison with HyperOS Global 307

Read-only comparison of the local Global `OS3.0.307.0.WOPMIXM` fastboot image,
the vendor dump with the same firmware fingerprint, and the published kernel
and vendor revisions `ac41a99` and `e5f5650`:

| Component | Result |
|---|---|
| Kernel payload from `boot.img` | Byte-identical to the published prebuilt kernel. |
| `msm_drm.ko` from `vendor_dlkm_a` | Byte-identical to the module in the kernel tree. |
| Three DTBs from `vendor_boot.img` | All three payloads match the published DTBs. |
| DTBO entries | Entry 0 matches. In entry 1, the only decoded property differences are in five panel nodes where `qcom,dsi-supported-dfps-list` drops `30`, keeping `120`, `90` and `60`. The test device reports DTBO index 1. |
| `libsdmcore.so`, `libsdmutils.so`, `libsdedrm.so` | All three match the stock dump byte for byte. |
| Qualcomm composer service | ELF build ID, `.text` and `.rodata` match. The extraction fixup changes the package's ELF dependency from `libtinyxml2.so` to `libtinyxml2-v34.so`, so the full executable hash differs. |

This audit narrows the first comparison to the graphics framework and display
configuration with the same lower-level driver. It does not establish how
stock HyperOS presents the touch spot. [AOSP DTBO layout](https://source.android.com/docs/core/architecture/dto/partitions)

The installed LineageOS reads `debug.sf.auto_latch_unsignaled=0` and
`vendor.display.idle_time=0`; stock declares `1` and `80`, respectively.
`debug.sf.enable_advanced_sf_phase_offset` and
`debug.sf.mi_asynchronous_re.enable` are declared by stock and have no matching
property read in the audited Lineage `frameworks/native` SurfaceFlinger or
`libgui` sources at `26f530caef`. `debug.sf.auto_latch_unsignaled` is read there
and selects the single-layer unsignaled-buffer path. It is a frame scheduling
setting with broader effects than the touch spot. These property differences
are candidates for isolation and do not by themselves explain the vblank wait.

#### Stock physical touch test

On stock Global 307 installed with Clean all, the owner selected 120 Hz in
Display settings. ADB reported mode 1 at 120 Hz before and after each trace.
With Show taps enabled, the owner reported smooth scrolling. The trace showed
the `Sprite` layer and a median gap of 8.34 ms between display frames across
four touches on the Display settings page. Of 179 gaps, 176 were near 8.3 ms
and two were near 16.7 ms. This run did not reproduce LineageOS's sustained
16.68 ms median with Show taps enabled.
The two attempts with Show taps off captured gestures in the notification
shade rather than on the Display settings page. They are excluded from the
matched scrolling comparison.

On the stock SurfaceFlinger main thread the enabled trace recorded 1,576
`HwcPresentOrValidateDisplay 0` slices, with a 1.66 ms median, and no separate
`HwcPresentDisplay 0` slice. `presentAndGetReleaseFences` took a median of
0.004 ms. This contrasts with the separate present calls observed when the
touch spot was active on LineageOS and gives a specific path to compare.

Using the same 7 ms `Sprite` layer-summary window as the LineageOS trace,
stock recorded no separate HWC present calls in 661 presentations and a
2.76 ms median `present` slice. LineageOS recorded a separate call in all
409 presentations in that window and a 9.38 ms median. Stock and LineageOS
also used different scheduler work durations at 120 Hz:

| Trace counter | HyperOS Global 307 | LineageOS |
|---|---:|---:|
| `VsyncWorkDuration-app` | 11.67 ms | 13.67 ms |
| `VsyncWorkDuration-sf` | 12.33 ms | 10.50 ms |
| `VsyncWorkDuration-appSf` | 8.33 ms | 8.33 ms |

Stock still declares `debug.sf.late.app.duration=13666666` and
`debug.sf.late.sf.duration=10500000`, the same values as the device tree.
The active trace counters differ, so the property values alone do not describe
the scheduling behavior. Compare `presentOrValidate` results and the expected
presentation timestamp before changing work durations.

The stock trace uses the InputDispatcher's touch-down marker to anchor the
450 ms window because it exposes different input events than LineageOS. It
uses the display-frame rows rather than app-surface rows for the cadence.
The test narrows the search to differences between LineageOS and its stock
reference with the same panel and driver. It does not yet identify a specific
framework change or display property to carry into the tree.

#### Stock Control Center blur

HyperOS reports cross-window blur supported and enabled. The tested phone
uses the split Control Center. Open it from the upper-right corner because
the generic status-bar expansion command can show the notification shade.
[AOSP window blur implementation](https://source.android.com/docs/core/display/window-blurs?hl=en)

Two physical captures at 120 Hz over Display settings contained three Control
Center openings. Each opening had one `captureBlurOrBlend` call and one
`drawBlurRegion` inside RenderEngine's `ScreenCaptureOutput`. The first was
followed by inflation of MIUI Control Center views. The two other captures
started 36 and 59 ms after the corresponding status-bar touch-down. In each
500 ms window following a blur capture, there were 54, 55 and 56 display-frame
records respectively, without late presents or GPU composition deadline
misses. A layer dump with the panel visible showed no nonzero continuous
`backgroundBlurRadius`.

In the earlier LineageOS trace with QS blur enabled, three ADB gesture
sequences over Settings recorded 385 `BackgroundBlur` and 385
`drawBlurRegion` slices. With QS blur disabled, neither slice appeared.
The stock and LineageOS panels and gestures differ, so the counts describe
their rendering paths rather than a normalized benchmark. The stock trace
shows one trace-visible blur capture per opening. The LineageOS trace shows
live blur during the animation. A fix still needs to preserve the visual effect
while reducing that per-frame work.

### Capturing the layer composition type

For a short structural capture, append the following to a copy of
`display-perfetto.pbtxt`. Inspect the visible `Sprite` layers and their
`hwc_composition_type` in Winscope or Perfetto. Use the base config for frame
timing because active layer tracing adds work to SurfaceFlinger.
[AOSP Winscope capture guide](https://source.android.com/docs/core/graphics/winscope/capture/adb)

```textproto
buffers { size_kb: 32768 fill_policy: RING_BUFFER }
data_sources {
  config {
    name: "android.surfaceflinger.layers"
    target_buffer: 1
    surfaceflinger_layers_config {
      mode: MODE_ACTIVE
      trace_flags: TRACE_FLAG_COMPOSITION
    }
  }
}
```

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

## GPU boost while SurfaceFlinger composites blur

SurfaceFlinger already reports `EXPENSIVE_RENDERING` through `IPower::setMode`
whenever it composites expensive content, and the LineageOS libperfmgr HAL turns
that mode into `HintManager::DoHint("EXPENSIVE_RENDERING")`. The amethyst
`powerhint.json` attached no node to that hint, so the HAL received the call and
did nothing with it; the GPU only left `min_pwrlevel 8` on the 80 ms INTERACTION
boost that a touch triggers.

`exp/perf-hints` adds three actions held while the mode stays set
(`Duration: 0`): `kgslMinPwrlevel` 0, `ddrBoostFreq` 2092000 and `l3BoostFreq`
1708800. `EndHint` runs when SurfaceFlinger stops composing expensive content,
so the node returns to its default.

The L3 node only takes the frequencies listed in
`/sys/devices/system/cpu/bus_dcvs/L3/available_frequencies` (364800 to 1708800,
thirteen steps). Anything above that, including the 2035200 the first cut used,
is rejected with `EINVAL` and the HAL logs `Failed to write to node:
/sys/devices/system/cpu/bus_dcvs/L3/boost_freq`, so the boost silently did
nothing there; the DDR node has no such limit at 2092000, its own maximum. The
boost value is now 1708800, the top of the L3 table.

Checked without a new build: the HAL honours `vendor.powerhal.config.debug`,
loading `/data/vendor/etc/powerhint.json` instead of `/vendor/etc/powerhint.json`
(the binary aborts with `Invalid debug config` when that file is missing). With a
patched copy there, sampling the two nodes during a `LAUNCH` showed 1708800 and
2092000 and a return to 364800 and 547000, with no write failures.

Verified on `lineage-23.2-20261122-UNOFFICIAL-refresh-switches-amethyst.zip`
(`post-build-incremental=1795373782`, SHA-256
`e6c1d383dd47d3a1c6ced7bd1c799f06d747acc11796e5ff31ee07a805c255ad`), sampling
`/sys/class/kgsl/kgsl-3d0` while injecting a shade pull:

| State | min_pwrlevel | gpu clock |
| --- | ---: | ---: |
| Shade closed | 8 | 362 MHz |
| Pulling the shade | 0 | 960 MHz |
| Shade open, settled | 2 | 895 MHz |
| Shade closed again | 8 | 362 MHz |

`init.svc.vendor.power-hal-aidl=running` and `vendor.powerhal.init=1` without an
`avc: denied`. The earlier percent-of-janky-frames numbers came from the Perfetto
harness described above, which is not part of this tree; the A/B for this hint
still has to run through it.

## Choosing the refresh rate range

The AOSP "Smooth display" switch is `PeakRefreshRateSwitchPreference`, added by
`DisplayScreen.kt` and gated on `config_show_smooth_display`. It only writes
`Settings.System.PEAK_REFRESH_RATE`: off means 60 Hz, on means the highest panel
mode. That duplicates the range choice, and turning it off also stops the
automatic range. The device tree had the boolean set to `true`, which is what
made the switch appear.

`overlay/SettingsOverlayAmethyst` now sets it to `false`, so the switch is
hidden. Nothing else on the screen depends on the value:
`display_settings.xml` binds `max_refresh_rate` to
`PeakRefreshRateListPreferenceController` (gated on
`config_show_peak_refresh_rate_switch`) and `min_refresh_rate` to
`MinRefreshRatePreferenceController` (gated on
`config_show_min_refresh_rate_switch`). Both lists are built from the modes of
the default display at 1220 x 2712, so the range is chosen as 60, 90 or 120 Hz
and `peak_refresh_rate` keeps the value written by the list.

State kept on the phone after the test: `window_animation_scale`,
`transition_animation_scale` and `animator_duration_scale` at `1.0`,
`min_refresh_rate=60.0`, `peak_refresh_rate=Infinity` and mode 1 at 120 Hz.
Animations stay at their default 1.0. The 0.5x runs felt faster, but the scale
is not a device property to change and navigation and the shade pull were
already smooth at 1.0.

## The cpu_dma_latency node

`powerhint.json` carried Qualcomm's default `cpuDmaLatency` values, `1`, `44`
and `2000000000` microseconds, with the last one as `DefaultIndex`. This kernel
rejects `2000000000` with `ERANGE`. The HAL runs as `root` (its `.rc` declares
`user root`) and writing the same value as root fails too, so this is not a
permission problem: the value is out of range for the driver. The HAL therefore
logged `Failed to write to node: /dev/cpu_dma_latency with value: 2000000000`
whenever a hint expired, and the state the default was supposed to restore
never landed. The 44 us `LAUNCH` and the 1 us `CAMERA_LAUNCH` constraints stayed
on the file until something else wrote to it.

Measured by writing into the node as root:

| Value (us) | Result |
| ---: | --- |
| 1, 44, 1000000, 50000000 | accepted |
| 80000000, 99999999, 500000000, 1000000000, 2000000000, 2147483647 | `ERANGE` |

The default is now `1000000` (one second). Every real exit latency on the
platform is far below one second, so the request keeps Qualcomm's intended
meaning, "no DMA latency constraint", without the failed writes. `HoldFd` and
the other two values are unchanged.
## Jank A/B at 120 Hz: the power hints with and without the GPU, DDR and L3 boosts

Measured on `lineage-23.2-20261122-UNOFFICIAL-refresh-range-amethyst.zip`
(`post-build-incremental=1795376645`, SHA-256
`3c3fc6d67693d6e6190d35e6c71d215171a9ddfcdcabb146954355a2f64d92e2`).

The two configs are the same file except for the boost actions: the shipped
`powerhint.json` (with the L3 value already corrected to 1708800) against the
same file with every GPU, DDR and L3 action removed, seven in total:
`INTERACTION` `kgslMinPwrlevel` 2; `LAUNCH` `ddrBoostFreq` 2092000,
`l3BoostFreq` 1708800 and `kgslMinPwrlevel` 0; the three `EXPENSIVE_RENDERING`
actions. Everything else stays identical, including the CPU frequency and
scheduler actions. Both are loaded hot through the HAL debug path
(`vendor.powerhal.config.debug` plus `/data/vendor/etc/powerhint.json`), so the
comparison needs no rebuild and no reboot, and the only variable is the boost.

Method:

- Display locked at 120 Hz: `min_refresh_rate` and `peak_refresh_rate` both at
  120, confirmed with `cmd display get-active-mode 0` (120.00 Hz).
- Screen kept awake for the whole run (`svc power stayon true`,
  `screen_off_timeout` at 30 minutes).
- Workload per pass: launch Settings, then five scroll swipes
  (`input swipe 610 2200 610 700 900`, 500 ms apart).
- Trace: `docs/display-perfetto.pbtxt` with `duration_ms` shortened to 12000,
  fed to the device on **stdin** (`perfetto --txt -c -`); Perfetto cannot read a
  config from `/data/local/tmp` because of its SELinux domain (`EACCES`).
- Three passes per config, interleaved as A/B/A/B/A/B.
- Frames come from `Choreographer#doFrame*` in `com.android.settings`. One vsync
  at 120 Hz is 8.33 ms; a *late* frame is an interval above 12.5 ms and
  *dropped* counts the vsync periods lost between consecutive frames.

| pass | frames | late | dropped | avg interval | worst |
| --- | --- | --- | --- | --- | --- |
| boost 1 | 770 | 1.2% | 10.5% | 9.32 ms | 184 ms |
| boost 2 | 761 | 1.3% | 11.7% | 9.45 ms | 183 ms |
| boost 3 | 759 | 1.3% | 11.4% | 9.42 ms | 175 ms |
| no boost 1 | 760 | 1.3% | 11.4% | 9.41 ms | 183 ms |
| no boost 2 | 819 | 2.7% | 26.4% | 11.26 ms | 1307 ms |
| no boost 3 | 760 | 1.3% | 11.6% | 9.44 ms | 175 ms |

Medians: 1.3% late, 11.4% dropped and 9.42 ms with the boosts; 1.3% late, 11.6%
dropped and 9.44 ms without them. The difference is inside the noise. The second
"no boost" pass carries a 1.3 s stall from some other system event (it also ran
longer, 819 frames), not from the scroll.

The average interval of about 9.4 ms means roughly 89% of the frames land on the
8.33 ms cadence and 11% skip a vsync, which is exactly what the `dropped` column
counts; the panel itself stays at 120 Hz.

Reading: removing the GPU, DDR and L3 boosts changes nothing measurable while
scrolling at 120 Hz, which matches what the HAL logs show. `EXPENSIVE_RENDERING`
never reaches the HAL in normal use (dragging the shade, blurring Settings behind
it, produced only `INTERACTION` hints), and the boosts that do fire are either
short (`INTERACTION`, 80 ms) or irrelevant to this workload. The hint set of this
power HAL is not buying scrolling performance, and the L3 action never showed up
in the node even with a valid value.

To reproduce, from a checkout with the harness next to it (the `jank/` directory
of the working tree: `ab_probe.sh`, `probe.pbtxt`, `powerhint-l3fix.json`,
`powerhint-noboost-all.json`), with `adb` root available:

```
bash jank/ab_probe.sh
```

It writes `jank/traces/{boost,noboost}[1-3].pftrace`, prints the trace size per
pass and restores the phone at the end. A trace of only about 1.4 MB means the
atrace categories did not apply and the pass has no frame data; the good ones are
around 30 MB. Analysis with `trace_processor`:

```
trace_processor query -f jank/pacing_settings.sql jank/traces/boost1.pftrace
```
