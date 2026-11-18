# Testing and validation

A build that boots is not a working device. This checklist is the minimum for
calling a release usable, and it is also the evidence required for an official
submission.

## Status matrix

Copy this table into the pull request or release notes and fill it in.

| Area | Status | Notes |
|---|---|---|
| Boot to setup wizard | ⬜ | |
| Boot to launcher | ⬜ | |
| Calls (in/out) | ⬜ | |
| SMS / MMS | ⬜ | |
| VoLTE | ⬜ | Verify on stock first |
| VoWiFi | ⬜ | Verify on stock first |
| Mobile data | ⬜ | |
| Dual SIM | ⬜ | |
| Wi-Fi 2.4/5/6 GHz | ⬜ | |
| Wi-Fi hotspot | ⬜ | |
| Bluetooth audio | ⬜ | |
| Bluetooth LE Audio | ⬜ | |
| NFC | ⬜ | |
| eSIM | ⬜ | |
| GPS / GNSS | ⬜ | |
| Camera — main | ⬜ | Aperture |
| Camera — ultrawide | ⬜ | |
| Camera — telephoto | ⬜ | |
| Camera — front | ⬜ | |
| Camera — video | ⬜ | EIS on/off |
| Camera — MiuiCamera | ⬜ | If installed |
| Fingerprint (UDFPS) | ⬜ | Enrollment + unlock |
| Face unlock | ⬜ | |
| Sensors | ⬜ | Accelerometer, gyro, light, proximity |
| IR blaster | ⬜ | |
| Vibration / haptics | ⬜ | |
| Charging (wired) | ⬜ | 120 W |
| Charging limit | ⬜ | If implemented |
| USB file transfer | ⬜ | |
| USB OTG | ⬜ | |
| USB tethering | ⬜ | |
| Screen cast | ⬜ | |
| Idle battery drain | ⬜ | %/hour overnight |
| Encryption | ⬜ | |
| SafetyNet / Play Integrity | ⬜ | Expected to fail without fixes |
| OTA update | ⬜ | Same keys only |

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
