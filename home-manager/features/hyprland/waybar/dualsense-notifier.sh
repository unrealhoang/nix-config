#!/bin/bash

notify_id=-1
icon=$icon_path

dev=$(echo $DS_DEV | tr '[:lower:]' '[:upper:]')

case "$1" in
add)
    notify_id=$(notify-desktop -r $notify_id -i $icon "$dev" "Controller connected")
    while true; do
        class=""
        battery=$(dualsensectl battery 2> /dev/null)
        perc=$(echo $battery | cut -d' ' -f1)
        state=$(echo $perc | cut -d' ' -f2)
        if [ -z "$perc" -o -z "$state" ]; then
            exit;
        fi
        if [ $perc -lt 15 -a "$state" != "charging" ]; then
            notify_id=$(notify-desktop -r $notify_id -i $icon "$dev" "Low battery ${perc}%")
        fi
        echo "{\"class\": \"$class\", \"text\": \" ${perc}%\"}"
        sleep 5m
    done
    ;;
remove)
    notify_id=$(notify-desktop -r $notify_id -i $icon "$dev" "Controller disconnected")
    echo "{\"text\": \"\"}"
    ;;
*)
    echo "{\"text\": \"\"}"
    exec dualsensectl monitor add "${BASH_SOURCE[0]} add" remove "${BASH_SOURCE[0]} remove"
    ;;
esac
