#!/bin/bash

nmcli radio wifi on

choice=$(nmcli -f IN-USE,SSID,SECURITY,SIGNAL device wifi list | sed '1d' | rofi -dmenu -p "Wi-Fi")

[ -z "$choice" ] && exit 0

ssid=$(echo "$choice" | awk '{print $2}')

nmcli device wifi connect "$ssid" && \
notify-send "Wi-Fi" "Conectado em $ssid"
