#!/usr/bin/env bash
# Quick status overview of all Gautama services

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Gautama Service Status Overview${NC}\n"

# Core Infrastructure
echo -e "${BLUE}═══ Core Infrastructure ═══${NC}"
for svc in nginx postgresql step-ca dovecot postfix; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        echo -e "  ${GREEN}●${NC} $svc"
    else
        echo -e "  ${RED}●${NC} $svc (inactive)"
    fi
done

# Web Services
echo -e "\n${BLUE}═══ Web Services ═══${NC}"
for svc in home-assistant nextcloud jellyfin gitea roundcube glance; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        echo -e "  ${GREEN}●${NC} $svc"
    else
        echo -e "  ${YELLOW}○${NC} $svc (inactive)"
    fi
done

# Monitoring
echo -e "\n${BLUE}═══ Monitoring ═══${NC}"
for svc in prometheus grafana alertmanager node_exporter postgres_exporter; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        echo -e "  ${GREEN}●${NC} $svc"
    else
        echo -e "  ${RED}●${NC} $svc (inactive)"
    fi
done

# Containers
echo -e "\n${BLUE}═══ Containers ═══${NC}"
if command -v podman &>/dev/null; then
    running=$(podman ps --format "{{.Names}}" 2>/dev/null | wc -l || echo "0")
    total=$(podman ps -a --format "{{.Names}}" 2>/dev/null | wc -l || echo "0")
    echo -e "  ${GREEN}Running:${NC} $running/$total containers"

    if [ "$running" -ne "$total" ]; then
        echo -e "  ${YELLOW}Stopped containers:${NC}"
        podman ps -a --filter status=exited --format "    - {{.Names}}" 2>/dev/null || true
    fi
else
    echo -e "  ${YELLOW}Podman not available${NC}"
fi

# Storage
echo -e "\n${BLUE}═══ Storage ═══${NC}"
if command -v zpool &>/dev/null; then
    zpool list -H -o name,size,allocated,free,capacity | while read -r pool size alloc free cap; do
        if [ "${cap%%%}" -ge 80 ]; then
            echo -e "  ${YELLOW}●${NC} $pool: $cap full ($free free)"
        else
            echo -e "  ${GREEN}●${NC} $pool: $cap full ($free free)"
        fi
    done
else
    echo -e "  ${YELLOW}ZFS not available${NC}"
fi

# Backups
echo -e "\n${BLUE}═══ Backups ═══${NC}"
snapshots=$(zfs list -t snapshot 2>/dev/null | tail -n +2 | wc -l || echo "0")
echo -e "  ${GREEN}ZFS Snapshots:${NC} $snapshots"

failed_backups=$(systemctl list-units "restic-backups-*" --failed --no-legend 2>/dev/null | wc -l || echo "0")
if [ "$failed_backups" -eq 0 ]; then
    echo -e "  ${GREEN}Restic Backups:${NC} All OK"
else
    echo -e "  ${RED}Restic Backups:${NC} $failed_backups failed"
fi

# Summary
echo -e "\n${BLUE}═══ Summary ═══${NC}"
failed=$(systemctl --failed --no-legend 2>/dev/null | wc -l || echo "0")
if [ "$failed" -eq 0 ]; then
    echo -e "  ${GREEN}✓ No failed services${NC}"
else
    echo -e "  ${RED}✗ $failed failed services${NC}"
    echo -e "    Run 'systemctl --failed' for details"
fi

load=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | xargs)
echo -e "  ${BLUE}Load Average:${NC} $load"

echo ""
