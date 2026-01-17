#!/bin/bash

DIR="$HOME/Videos/Recordings"
mkdir -p "$DIR"

FILE="$DIR/record_$(date +%Y-%m-%d_%H-%M-%S).mp4"

if pgrep wf-recorder >/dev/null; then
  pkill wf-recorder
  notify-send "Gravação" "Gravação finalizada 🎬"
  exit 0
fi

AREA=$(slurp)
[ -z "$AREA" ] && exit 0

notify-send "Gravação" "Gravando tela... ⏺️"
wf-recorder -g "$AREA" -f "$FILE"
