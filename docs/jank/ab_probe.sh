#!/usr/bin/env bash
# Jank A/B of the power hints at 120 Hz: the shipped config against the same one
# with the GPU, DDR and L3 actions removed. Both are loaded through the HAL debug
# config path, so the build and the boot stay the same for every pass.
#
# Usage, from the root of the device tree, with adb root available:
#   bash docs/jank/ab_probe.sh
#
# Writes traces/ next to this script and restores the phone at the end.
set -u
ADB="${ADB:-adb}"
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"
HAL=android.hardware.power-service.lineage-libperfmgr
MIN_BYTES=8000000
mkdir -p traces

sh_() { "$ADB" shell "$1" 2>/dev/null | tr -d '\r'; }

restore() {
  sh_ "setprop log.tag.libperfmgr ''; setprop vendor.powerhal.config.debug ''; rm -f /data/vendor/etc/powerhint.json /data/misc/perfetto-traces/*.pftrace; setprop ctl.restart vendor.power-hal-aidl" >/dev/null
  sh_ "settings put system min_refresh_rate 60; settings put system peak_refresh_rate Infinity; settings put system screen_off_timeout 60000; svc power stayon false; cmd statusbar collapse" >/dev/null
  sleep 2
  "$ADB" unroot >/dev/null 2>&1
}
trap restore EXIT

apply_cfg() { # $1 json in this directory  $2 tag
  local old new w
  "$ADB" push "$1" /data/vendor/etc/powerhint.json >/dev/null 2>&1 || { echo "[$2] push failed"; return 1; }
  old=$(sh_ "pidof $HAL")
  sh_ "chmod 644 /data/vendor/etc/powerhint.json; chcon u:object_r:vendor_configs_file:s0 /data/vendor/etc/powerhint.json; setprop vendor.powerhal.config.debug 1; setprop ctl.restart vendor.power-hal-aidl" >/dev/null
  for w in $(seq 1 40); do
    new=$(sh_ "pidof $HAL")
    [ -n "$new" ] && [ "$new" != "$old" ] && break
    sleep 0.5
  done
  echo "[$2] hal=$new loaded=$(sh_ "logcat -d -b all | grep -c 'successfully loaded debug config'")"
}

rep() { # $1 tag  $2 attempt
  local tag=$1 att=$2 size
  sh_ "rm -f /data/misc/perfetto-traces/$tag.pftrace" >/dev/null
  sh_ "input keyevent KEYCODE_WAKEUP; sleep 0.5; wm dismiss-keyguard; input keyevent KEYCODE_HOME; sleep 1; monkey -p com.android.settings -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 3" >/dev/null
  echo "[$tag] focus=$(sh_ 'dumpsys window | grep -m1 mCurrentFocus' | sed 's/.*u0 //')"
  ( "$ADB" shell "perfetto --txt -c - -o /data/misc/perfetto-traces/$tag.pftrace" < probe.pbtxt > "${tag}_perfetto.log" 2>&1 ) &
  local tp=$!
  sleep 2
  sh_ 'for i in 1 2 3 4 5; do input swipe 610 2200 610 700 900; sleep 0.5; done' >/dev/null
  wait $tp
  "$ADB" pull /data/misc/perfetto-traces/$tag.pftrace "traces/$tag.pftrace" >/dev/null 2>&1
  size=$(stat -c %s "traces/$tag.pftrace" 2>/dev/null || echo 0)
  echo "[$tag] trace=${size}B"
  # a trace around 1.4 MB means the atrace categories did not apply: no frame data
  if [ "$size" -lt "$MIN_BYTES" ] && [ "$att" -lt 2 ]; then
    echo "[$tag] short trace, retrying"
    rep "$tag" $((att+1))
  fi
}

echo "== prep =="
"$ADB" root >/dev/null 2>&1; sleep 2
echo "uid=$(sh_ 'id -u')"
sh_ "setprop log.tag.libperfmgr VERBOSE; svc power stayon true; settings put system screen_off_timeout 1800000" >/dev/null
for w in $(seq 1 10); do
  sh_ "settings put system min_refresh_rate 120; settings put system peak_refresh_rate 120" >/dev/null
  [ "$(sh_ 'settings get system min_refresh_rate')" = "120.0" ] && break
  sleep 1
done
echo "refresh min=$(sh_ 'settings get system min_refresh_rate') peak=$(sh_ 'settings get system peak_refresh_rate')"

for r in 1 2 3; do
  apply_cfg "powerhint-with-boost.json" "boost$r" || exit 1
  rep "boost$r" 1
  apply_cfg "powerhint-without-boost.json" "noboost$r" || exit 1
  rep "noboost$r" 1
done

echo "== restore =="
restore
sleep 2
echo "fin: hal=$(sh_ "pidof $HAL") min=$(sh_ 'settings get system min_refresh_rate') peak=$(sh_ 'settings get system peak_refresh_rate') uid=$(sh_ 'id -u')"
