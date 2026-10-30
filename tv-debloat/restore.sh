#!/usr/bin/env bash
# Reactiva todo lo que desactivó debloat.sh y restaura las animaciones.
# Uso: ./restore.sh <IP:PUERTO>
set -euo pipefail

TARGET="${1:-192.168.1.74:39937}"
LOG="$(dirname "$0")/disabled-packages.txt"

adb connect "$TARGET"
ADB=(adb -s "$TARGET")

if [[ -f "$LOG" ]]; then
  sort -u "$LOG" | while read -r p; do
    "${ADB[@]}" shell pm enable "$p" >/dev/null && echo "  reactivado: $p"
  done
  rm "$LOG"
fi

for k in window_animation_scale transition_animation_scale animator_duration_scale; do
  "${ADB[@]}" shell settings put global "$k" 1
done
echo "Restaurado."
