#!/bin/bash

LAST=""

while true; do
  CURRENT=$(swww query | sed -n 's/.*image: //p' | head -n 1)

  if [[ -n "$CURRENT" && "$CURRENT" != "$LAST" && -f "$CURRENT" ]]; then
    ln -sf "$CURRENT" /home/thalyson/.local/share/wallpapers/.current.wall
    LAST="$CURRENT"
  fi

  sleep 1
done
