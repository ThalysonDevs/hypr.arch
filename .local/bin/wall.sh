#!/bin/bash

WALL="$1"

# validação
[ -f "$WALL" ] || { echo "Wallpaper não encontrado"; exit 1; }

# atualiza link para hyprlock
ln -sf "$WALL" /home/thalyson/.local/share/wallpapers/.current.wall

# aplica no swww
swww img "$WALL" \
  --transition-type grow \
  --transition-duration 1.2 \
  --transition-fps 60

# opcional: pywal
# wal -i "$WALL"
