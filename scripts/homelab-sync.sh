#!/usr/bin/env bash
# homelab-sync.sh — publish Proxmox host status and sanitized configs to GitHub.
# The portfolio Lab Log page (lab.html) reads both from this repo.
#
#   homelab-sync.sh status          publish status.json to the "status" branch
#   homelab-sync.sh configs         copy sanitized Proxmox configs into proxmox/ and push if changed
#   homelab-sync.sh log "message"   add a Lab Log entry (an empty "log:" commit) to the site
#
# Run as root on the Proxmox host from a clone at $REPO_DIR (see SETUP.md).
set -euo pipefail

REPO_DIR="${REPO_DIR:-/opt/homelab}"
BRANCH="main"
# Any line matching this (case-insensitive) is dropped from synced configs
SECRET_PATTERN='password|passwd|secret|token|api[_-]?key|private|sshkeys|cipassword'

cd "$REPO_DIR"

# Don't let a cron run and a manual run push at the same time
exec 9>/run/homelab-sync.lock
flock -w 60 9

publish_status() {
    local uptime load1 mem_total mem_avail vm_run vm_total ct_run ct_total pve tmp blob tree commit
    read -r uptime _ < /proc/uptime
    read -r load1 _ < /proc/loadavg
    mem_total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
    mem_avail=$(awk '/^MemAvailable:/ {a=$2} /^MemFree:/ {f=$2} END {print (a ? a : f) + 0}' /proc/meminfo)
    read -r vm_run vm_total < <(qm list | awk 'NR>1 {t++; if ($3 == "running") r++} END {print r+0, t+0}')
    read -r ct_run ct_total < <(pct list | awk 'NR>1 {t++; if ($2 == "running") r++} END {print r+0, t+0}')
    pve=$(pveversion | cut -d/ -f2)

    tmp=$(mktemp)
    cat > "$tmp" <<EOF
{
  "updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "uptime_seconds": ${uptime%.*},
  "pve_version": "$pve",
  "cpu_cores": $(nproc),
  "load_1m": $load1,
  "mem_total_kb": $mem_total,
  "mem_available_kb": $mem_avail,
  "vms": { "running": $vm_run, "total": $vm_total },
  "containers": { "running": $ct_run, "total": $ct_total }
}
EOF

    # Force-push a single parentless commit so frequent status updates never clutter main's history
    blob=$(git hash-object -w "$tmp")
    tree=$(printf '100644 blob %s\tstatus.json\n' "$blob" | git mktree)
    commit=$(git commit-tree "$tree" -m "status: $(date -u +%FT%TZ)")
    git push -q -f origin "$commit:refs/heads/status"
    rm -f "$tmp"
}

sync_configs() {
    git pull -q --rebase origin "$BRANCH"

    # proxmox/ is owned by this script; it is rebuilt from scratch every run
    rm -rf proxmox
    mkdir -p proxmox/qemu proxmox/lxc
    cp /etc/pve/qemu-server/*.conf proxmox/qemu/ 2>/dev/null || true
    cp /etc/pve/lxc/*.conf proxmox/lxc/ 2>/dev/null || true
    cp /etc/pve/storage.cfg proxmox/ 2>/dev/null || true
    find proxmox -type f -exec sed -i -E "/$SECRET_PATTERN/Id" {} +

    git add -A proxmox
    if git diff --cached --quiet; then
        return
    fi
    git commit -q -m "auto: sync Proxmox configs ($(git diff --cached --name-only | wc -l) files)"
    git push -q origin "$BRANCH"
}

add_log() {
    if [ -z "$1" ]; then
        echo 'usage: homelab-sync.sh log "what you did"' >&2
        exit 1
    fi
    git pull -q --rebase origin "$BRANCH"
    git commit -q --allow-empty -m "log: $1"
    git push -q origin "$BRANCH"
    echo "Posted to Lab Log: $1"
}

case "${1:-}" in
    status)  publish_status ;;
    configs) sync_configs ;;
    log)     shift; add_log "$*" ;;
    *)
        echo 'usage: homelab-sync.sh {status|configs|log "message"}' >&2
        exit 1
        ;;
esac
