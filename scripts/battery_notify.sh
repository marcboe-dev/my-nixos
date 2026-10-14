#!/usr/bin/env bash

BATTERY_DIR="/sys/class/power_supply/BAT0"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/battery-notify"

mkdir -p "$STATE_DIR"

# Kein Akku (z. B. VM): sauber beenden
if [[ ! -r "$BATTERY_DIR/capacity" ]]; then
    exit 0
fi

while true; do
    capacity="$(cat "$BATTERY_DIR/capacity")"
    status="$(cat "$BATTERY_DIR/status")"

    # Nach dem Aufladen Markierungen zurücksetzen
    if (( capacity > 25 )); then
        rm -f "$STATE_DIR/notified-20" "$STATE_DIR/notified-10"
    fi

    # Nur warnen, wenn der Akku wirklich entladen wird
    if [[ "$status" == "Discharging" ]]; then
        if (( capacity <= 10 )) && [[ ! -e "$STATE_DIR/notified-10" ]]; then
            notify-send --urgency=critical \
                "Akku kritisch" \
                "Akkustand: ${capacity} %. Bitte Ladegerät anschließen."
            touch "$STATE_DIR/notified-10" "$STATE_DIR/notified-20"
        elif (( capacity <= 20 )) && [[ ! -e "$STATE_DIR/notified-20" ]]; then
            notify-send --urgency=normal \
                "Akkuwarnung" \
                "Akkustand: ${capacity} %"
            touch "$STATE_DIR/notified-20"
        fi
    fi

    sleep 60
done
