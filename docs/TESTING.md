# Testing and validation

A build that boots is not a working device. This checklist is the minimum for
calling a release usable, and it is also the evidence required for an official
submission.

## Status matrix

Results for the Global `24115RA8EG` on HyperOS Global 307 firmware, the
`k307-eis2diag` configuration and the owner's daily use of `rcd2`. The current
test build `rcd3-test` (`userdebug`, own release keys) has been compiled and
checked in the package but not flashed yet, so it is not in this table. The
device owner confirmed everyday hardware use. ADB and the original camera clips
cover the checks noted below.

| Area | Status | Notes |
|---|---|---|
| Boot to setup wizard | ✅ | Verified during the clean installation of the Global 307 base build |
| Boot to launcher | ✅ | Verified on `k307-eis2diag` |
| Calls | ✅ | Device-owner test |
| SMS | ✅ | Device-owner test |
| MMS | ⬜ | |
| VoLTE | ⬜ | Verify on stock first |
| VoWiFi | ⬜ | Verify on stock first |
| Cellular network and mobile data | ✅ | Device-owner test |
| Dual SIM | ⬜ | |
| Wi-Fi | ✅ | Device-owner test |
| Individual Wi-Fi bands | ⬜ | |
| Wi-Fi hotspot | ✅ | Device-owner test |
| Bluetooth | ✅ | Device-owner test |
| Bluetooth connection to a car | ✅ | Device-owner test |
| Android Auto | ⬜ | |
| Bluetooth audio | ⬜ | |
| Bluetooth LE Audio | ⬜ | |
| NFC | ⬜ | |
| eSIM | ⬜ | No eSIM available to test. |
| GPS / GNSS | ⬜ | |
| Camera — main | ✅ | Aperture recording at 1080p, 720p and 4K |
| Camera — ultrawide | ⬜ | |
| Camera — telephoto | ⬜ | |
| Camera — front | ✅ | Aperture recording at 1080p30 |
| Camera — video | ⚠️ | Color verified. CamX reported `EISMode:0` at 1080p, 720p and 4K. |
| Camera — MiuiCamera | ⬜ | If installed |
| Fingerprint (UDFPS) | ⚠️ | Screen-off and normal unlocks verified (6/6). **Caveat:** enrolling a new fingerprint leaves `LHBM_ON_WHITE_1000NIT` lit until display off (`rem=0` does not emit `lhbm_value(0)`). |
| Face unlock | ⬜ | |
| Quick Settings with background blur | ⚠️ | Owner reports stutter. Perfetto shows more GPU deadline misses with blur, including at fixed 120 Hz. See [display diagnosis](DISPLAY-TESTING.md). |
| Developer touch indicators | ⚠️ | Physical Show taps test at fixed 120 Hz measured median frame gaps of 16.68 ms on and 8.34 ms off. Pointer location produced late frames in a separate ADB test. See [display diagnosis](DISPLAY-TESTING.md). |
| Proximity | ✅ | Verified during calls and live via HAL (`5.0` ↔ `0.0`). |
| Other sensors | ✅ | Verified on `rcd6`: `icm4x6xx` (accel/gyro + uncalibrated), `qmc630x` (mag + uncalibrated), `sip1328` (front/back ALS & flicker), `sns_tilt`, `pickup`, `ois_manager`, `pocket_mode`, `NonUi`, `sar_detector`, `GripPostureDetection`, `har`, `activity_recognition`, `traffic_detect`, `fod_detector`. Pending physical/API trigger tests: `pedometer`, `motion_detect`/`sns_smd`, `Elevator_Acc_Grv`. |
| IR blaster | ⬜ | |
| Vibration / haptics | ⬜ | |
| Charging (120 W) | ⬜ | Peak charging power remains unmeasured. |
| Charging limit | ⬜ | If implemented |
| USB data and ADB | ✅ | Verified over USB. |
| USB file transfer (MTP) | ⬜ | |
| USB OTG | ⬜ | |
| USB tethering | ⬜ | |
| Screen cast | ⬜ | |
| Idle battery drain | ⬜ | %/hour overnight |
| Encryption | ⬜ | |
| SafetyNet / Play Integrity | ⬜ | Expected to fail without fixes |
| Sideload update | ✅ | Recovery and boot verified for the same test-key builds. |
| Updater app and snapshot merge | ⬜ | |

Legend: ✅ works, ⚠️ works with caveat, ❌ broken, ⬜ untested.

## Before flashing anything

Test the following on **stock HyperOS**, because a custom ROM cannot fix a
carrier or hardware problem:

- Calls and SMS.
- VoLTE and VoWiFi.
- Mobile data.
- Wi-Fi and Bluetooth.
- GPS.
- Fingerprint enrollment.

If something does not work on stock, it is not a ROM regression.

## Collect logs

```bash
# Full log buffer
adb logcat -b all -d > logcat.txt

# Kernel log
adb shell dmesg > dmesg.txt

# Last boot crash (if pstore is enabled)
adb shell ls -l /sys/fs/pstore
adb shell cat /sys/fs/pstore/console-ramoops-0 > ramoops.txt

# Full bug report
adb bugreport bugreport.zip

# Radio
adb shell dumpsys telephony.registry > telephony.txt
adb shell dumpsys carrier_config > carrier.txt

# Camera
adb logcat -b all -d | grep -iE 'camera|chi|camx' > camera.txt

# Audio
adb logcat -b all -d | grep -iE 'audio|agm|pal|adm' > audio.txt
adb shell dumpsys media.audio_flinger > audio_flinger.txt

# SELinux denials
adb shell dmesg | grep -i avc
```

Attach the smallest relevant log to the issue, not the whole 50 MB bug report,
unless asked.

## Camera notes

- Aperture is LineageOS's camera app; MiuiCamera is Xiaomi's and may be added
  separately.
- If the front camera records with wrong colors, disable EIS and retest. This is
  a known workaround in the Android 17 ports.
- Test photo, video, portrait, night, 200 MP (if supported), and all lenses.

## Battery notes

Measure idle drain with:

```bash
adb shell dumpsys batterystats --reset
# leave the phone idle, screen off, 8 hours
adb shell dumpsys batterystats > batterystats.txt
```

Compare against stock. A drain above 2 %/hour idle is worth investigating.

## Release gate

A build can be published as “testing” when:

- It boots to the launcher.
- Calls, SMS, mobile data and Wi-Fi work.
- The camera opens and takes a photo.
- Fingerprint unlock works.

A build can be called “daily driver” when the whole matrix is ✅ or has a
documented ⚠️.
