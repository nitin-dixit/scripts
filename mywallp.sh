#!/usr/bin/env bash
WALL=$(find ~/Pictures/Wallpapers/2kplus/dark/ -type f ( -iname ".jpg" -o -iname ".png" -o -iname "*.webp" ) | shuf -n 1)
~/.config/quickshell/ii/scripts/colors/switchwall.sh --image "$WALL" --mode dark
