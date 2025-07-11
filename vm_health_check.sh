#!/bin/bash

# Function to get CPU usage as a percent (integer)
get_cpu_usage() {
    # Get idle cpu percentage from top, then subtract from 100 for usage
    idle=$(top -bn1 | grep "Cpu(s)" | awk '{for (i=1;i<=NF;i++) if ($i ~ /id,/) print $(i-1)}' | cut -d. -f1)
    # If not found, fallback
    if [ -z "$idle" ]; then
        idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d. -f1)
    fi
    cpu_usage=$((100 - idle))
    echo "$cpu_usage"
}

# Function to get Memory usage as a percent (integer)
get_mem_usage() {
    mem_line=$(free | grep Mem:)
    total=$(echo "$mem_line" | awk '{print $2}')
    used=$(echo "$mem_line" | awk '{print $3}')
    mem_usage=$(awk "BEGIN {printf \"%d\", ($used/$total)*100}")
    echo "$mem_usage"
}

# Function to get Disk usage as a percent (integer, for / mount)
get_disk_usage() {
    disk_usage=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
    echo "$disk_usage"
}

# Main logic
EXPLAIN=0
if [[ "$1" == "explain" ]]; then
    EXPLAIN=1
fi

cpu=$(get_cpu_usage)
mem=$(get_mem_usage)
disk=$(get_disk_usage)

HEALTHY=1
REASONS=()

if [ "$cpu" -gt 60 ]; then
    HEALTHY=0
    REASONS+=("CPU usage is high ($cpu%)")
fi

if [ "$mem" -gt 60 ]; then
    HEALTHY=0
    REASONS+=("Memory usage is high ($mem%)")
fi

if [ "$disk" -gt 60 ]; then
    HEALTHY=0
    REASONS+=("Disk usage is high ($disk%)")
fi

if [ "$HEALTHY" -eq 1 ]; then
    echo "VM Health: Healthy"
    if [ "$EXPLAIN" -eq 1 ]; then
        echo "Reason: All resource usages (CPU: $cpu%, Memory: $mem%, Disk: $disk%) are below the 60% threshold."
    fi
else
    echo "VM Health: Not Healthy"
    if [ "$EXPLAIN" -eq 1 ]; then
        echo "Reason(s):"
        for reason in "${REASONS[@]}"; do
            echo " - $reason"
        done
    fi
fi
