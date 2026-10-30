#!/usr/bin/env bash
# Debloat de Android TV / Google TV vía ADB inalámbrico.
# Uso: ./debloat.sh <IP:PUERTO> [--pair <IP:PUERTO_PAREO> <CODIGO>]
# Todo es reversible con ./restore.sh (usa "pm disable-user", no desinstala).
set -euo pipefail

TARGET="${1:-192.168.1.74:39937}"
LOG="$(dirname "$0")/disabled-packages.txt"

command -v adb >/dev/null || { echo "Instala adb (Android platform-tools) primero."; exit 1; }

if [[ "${2:-}" == "--pair" ]]; then
  adb pair "$3" "$4"
fi

adb connect "$TARGET"
ADB=(adb -s "$TARGET")
"${ADB[@]}" wait-for-device

echo "Dispositivo: $("${ADB[@]}" shell getprop ro.product.manufacturer) $("${ADB[@]}" shell getprop ro.product.model)"

# Modo inventario: guarda todos los paquetes del TV para revisar qué es bloatware del fabricante.
if [[ "${2:-}" == "--list" ]]; then
  OUT="$(dirname "$0")/packages-$(date +%Y%m%d).txt"
  {
    echo "# $("${ADB[@]}" shell getprop ro.product.manufacturer) $("${ADB[@]}" shell getprop ro.product.model) Android $("${ADB[@]}" shell getprop ro.build.version.release)"
    echo "## Sistema"; "${ADB[@]}" shell pm list packages -s | sed 's/^package://' | sort
    echo "## Instaladas"; "${ADB[@]}" shell pm list packages -3 | sed 's/^package://' | sort
  } | tr -d '\r' >"$OUT"
  echo "Inventario guardado en $OUT"
  exit 0
fi

# Bloatware habitual en Android TV / Google TV y marcas (TCL, Xiaomi, Hisense, Philips, Sony).
# Solo se desactiva lo que exista en el TV.
BLOAT=(
  com.google.android.tvrecommendations
  com.google.android.leanbacklauncher.recommendations
  com.google.android.feedback
  com.google.android.marvin.talkback
  com.google.android.videos
  com.google.android.play.games
  com.google.android.music
  com.google.android.apps.youtube.music
  com.google.android.apps.mediashell
  com.google.android.katniss
  com.google.android.tungsten.setupwraith
  com.google.android.partnersetup
  com.google.android.apps.tv.dreamx
  com.google.android.backdrop
  com.android.printspooler
  com.android.dreams.basic
  com.amazon.amazonvideo.livingroom
  com.netflix.ninja
  com.spotify.tv.android
  com.disney.disneyplus
  com.facebook.katana
  com.tcl.partnercustomizer
  com.tcl.tvweishi
  com.tcl.usercenter
  com.tcl.ui_mediaCenter
  com.tcl.browser
  com.tcl.appmarket
  com.tcl.ad
  com.mitv.tvhome.atv
  com.xiaomi.mitv.calendar
  com.mitv.videoplayer
  com.xiaomi.mitv.upgrade
  com.hisense.store.tv
  com.hisense.vidaa.portal
  com.philips.tv.ambilight.store
  com.sony.dtv.promos
  com.sony.dtv.recommendationservice
  com.sony.dtv.sonyselect
)

PKGS="$("${ADB[@]}" shell pm list packages | sed 's/^package://' | tr -d '\r')"
FOUND=()
for p in "${BLOAT[@]}"; do
  grep -qx "$p" <<<"$PKGS" && FOUND+=("$p")
done

if ((${#FOUND[@]} == 0)); then
  echo "No se encontró bloatware conocido."
else
  echo "Se desactivarán ${#FOUND[@]} paquetes:"
  printf '  %s\n' "${FOUND[@]}"
  read -rp "¿Continuar? (s/N) " ok
  if [[ "$ok" =~ ^[sS]$ ]]; then
    for p in "${FOUND[@]}"; do
      if "${ADB[@]}" shell pm disable-user --user 0 "$p" >/dev/null 2>&1; then
        echo "$p" >>"$LOG"; echo "  desactivado: $p"
      else
        echo "  no se pudo:  $p"
      fi
    done
  fi
fi

# Interfaz más rápida: animaciones al 50 % y menos procesos en segundo plano.
"${ADB[@]}" shell settings put global window_animation_scale 0.5
"${ADB[@]}" shell settings put global transition_animation_scale 0.5
"${ADB[@]}" shell settings put global animator_duration_scale 0.5

# Launcher ligero (opcional): pon un APK en esta carpeta como launcher.apk
# (p. ej. Projectivy Launcher o FLauncher descargado de su fuente oficial).
APK="$(dirname "$0")/launcher.apk"
if [[ -f "$APK" ]]; then
  "${ADB[@]}" install -r "$APK"
  echo "Launcher instalado. Pulsa HOME en el mando y elígelo como predeterminado."
  read -rp "¿Desactivar también el launcher original? (s/N) " ok
  if [[ "$ok" =~ ^[sS]$ ]]; then
    for p in com.google.android.apps.tv.launcherx com.google.android.tvlauncher com.google.android.leanbacklauncher; do
      if grep -qx "$p" <<<"$PKGS"; then
        "${ADB[@]}" shell pm disable-user --user 0 "$p" >/dev/null && echo "$p" >>"$LOG" && echo "  desactivado: $p"
      fi
    done
  fi
else
  echo "Sin launcher.apk: se mantiene la interfaz original."
fi

echo "Listo. Reinicia el TV: adb -s $TARGET reboot"
