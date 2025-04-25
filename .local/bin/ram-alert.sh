#!/usr/bin/env bash

# ——— CONFIG ———
THRESHOLD=90                  # Percentage of RAM usage to trigger alert
ALERT_COOLDOWN=300            # Seconds between repeat alerts
STATEFILE="${XDG_RUNTIME_DIR:-/tmp}/.last-ram-alert"  # Tempfile for cooldown tracking
NOTIFY_URGENCY="critical"     # Urgency level (low, normal, critical)

# ——— CALCULATION ———
read_meminfo() {
    while IFS=": " read -r key value _; do
        case "$key" in
            MemTotal) total_kb="$value" ;;
            MemAvailable) avail_kb="$value" ;;
        esac
    done < /proc/meminfo
}

read_meminfo

used_kb=$(( total_kb - avail_kb ))
used_pct=$(( used_kb * 100 / total_kb ))

# ——— DECIDE & NOTIFY ———
if (( used_pct >= THRESHOLD )); then
    now=$(date +%s)
    last=$(<"$STATEFILE" 2>/dev/null || echo 0)

    if (( now - last >= ALERT_COOLDOWN )); then
        # Human-readable memory values
        avail_mb=$(( avail_kb / 1024 ))
        total_mb=$(( total_kb / 1024 ))
        used_mb=$(( used_kb / 1024 ))

        notify-send \
            --app-name="RAM Monitor" \
            --urgency="$NOTIFY_URGENCY" \
            "High Memory Usage Alert" \
            "RAM usage is at ${used_pct}% (${used_mb} MB used / ${total_mb} MB total)\nOnly ${avail_mb} MB remaining!"

        printf "%d" "$now" >"$STATEFILE"
    fi
fi
