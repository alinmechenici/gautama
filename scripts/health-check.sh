#!/usr/bin/env bash
# Gautama System Health Check
# Performs comprehensive health checks across all system components

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Functions
print_header() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_check() {
    ((TOTAL_CHECKS++))
    echo -n "  Checking $1... "
}

pass() {
    ((PASSED_CHECKS++))
    echo -e "${GREEN}✓ PASS${NC}"
}

fail() {
    ((FAILED_CHECKS++))
    echo -e "${RED}✗ FAIL${NC}"
    [ -n "${1:-}" ] && echo -e "    ${RED}Error: $1${NC}"
}

warn() {
    ((WARNING_CHECKS++))
    echo -e "${YELLOW}⚠ WARNING${NC}"
    [ -n "${1:-}" ] && echo -e "    ${YELLOW}Warning: $1${NC}"
}

# System Health Checks
check_system() {
    print_header "System Health"

    print_check "System uptime"
    uptime=$(cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1)
    if [ "$uptime" -gt 60 ]; then
        pass
    else
        warn "System recently rebooted"
    fi

    print_check "Failed systemd services"
    failed=$(systemctl --failed --no-legend | wc -l)
    if [ "$failed" -eq 0 ]; then
        pass
    else
        fail "$failed failed services"
        systemctl --failed --no-legend | sed 's/^/      /'
    fi

    print_check "Disk space"
    full_disks=$(df -h | awk '0+$5 >= 90 {print}' | tail -n +2)
    if [ -z "$full_disks" ]; then
        pass
    else
        fail "Some filesystems are >90% full"
        echo "$full_disks" | sed 's/^/      /'
    fi

    print_check "Memory pressure"
    available=$(free -m | awk '/^Mem:/{print $7}')
    total=$(free -m | awk '/^Mem:/{print $2}')
    percent=$((available * 100 / total))
    if [ "$percent" -gt 10 ]; then
        pass
    else
        warn "Low available memory: $available MB ($percent%)"
    fi
}

# ZFS Health Checks
check_zfs() {
    print_header "ZFS Storage"

    print_check "ZFS pool health"
    if zpool status | grep -q "DEGRADED\|FAULTED\|OFFLINE\|UNAVAIL"; then
        fail "One or more pools are degraded"
        zpool status | grep -E "pool:|state:" | sed 's/^/      /'
    else
        pass
    fi

    print_check "ZFS pool capacity"
    high_usage=$(zpool list -H -o name,capacity | awk '$2+0 >= 80 {print}')
    if [ -z "$high_usage" ]; then
        pass
    else
        warn "Some pools are >80% full"
        echo "$high_usage" | sed 's/^/      /'
    fi

    print_check "ZFS scrub status"
    last_scrub=$(zpool status | grep -A 2 "scan:" | grep "scrub repaired" | awk '{print $6, $7, $8}')
    if [ -n "$last_scrub" ]; then
        pass
    else
        warn "No recent scrub found"
    fi
}

# Service Health Checks
check_services() {
    print_header "Critical Services"

    services=(
        "nginx"
        "postgresql"
        "prometheus"
        "grafana"
        "home-assistant"
    )

    for service in "${services[@]}"; do
        print_check "$service"
        if systemctl is-active --quiet "$service"; then
            pass
        else
            fail "Service not running"
        fi
    done
}

# Container Health Checks
check_containers() {
    print_header "Container Platform"

    print_check "Podman service"
    if systemctl is-active --quiet podman.socket 2>/dev/null || command -v podman &> /dev/null; then
        pass
    else
        warn "Podman not available"
        return
    fi

    print_check "Container health"
    unhealthy=$(podman ps --filter health=unhealthy -q 2>/dev/null | wc -l || echo "0")
    if [ "$unhealthy" -eq 0 ]; then
        pass
    else
        fail "$unhealthy containers unhealthy"
    fi

    print_check "Exited containers"
    exited=$(podman ps -a --filter status=exited -q 2>/dev/null | wc -l || echo "0")
    if [ "$exited" -eq 0 ]; then
        pass
    else
        warn "$exited containers exited"
    fi
}

# Backup Health Checks
check_backups() {
    print_header "Backup Systems"

    print_check "ZFS snapshots"
    snapshots=$(zfs list -t snapshot 2>/dev/null | wc -l || echo "0")
    if [ "$snapshots" -gt 0 ]; then
        pass
    else
        fail "No ZFS snapshots found"
    fi

    print_check "Restic backup timers"
    timers=$(systemctl list-timers "restic-backups-*" --no-legend 2>/dev/null | wc -l || echo "0")
    if [ "$timers" -gt 0 ]; then
        pass
    else
        warn "No Restic backup timers found"
    fi

    print_check "Recent backup success"
    failed_backups=$(systemctl list-units "restic-backups-*" --failed --no-legend 2>/dev/null | wc -l || echo "0")
    if [ "$failed_backups" -eq 0 ]; then
        pass
    else
        warn "$failed_backups backup jobs failed recently"
    fi
}

# Monitoring Health Checks
check_monitoring() {
    print_header "Monitoring Stack"

    print_check "Prometheus API"
    if curl -sf http://localhost:9090/-/healthy &>/dev/null; then
        pass
    else
        fail "Prometheus not responding"
    fi

    print_check "Prometheus targets"
    if command -v curl &>/dev/null && command -v jq &>/dev/null; then
        down=$(curl -s http://localhost:9090/api/v1/targets 2>/dev/null | \
               jq -r '.data.activeTargets[] | select(.health != "up") | .scrapeUrl' | \
               wc -l || echo "unknown")
        if [ "$down" = "0" ]; then
            pass
        elif [ "$down" = "unknown" ]; then
            warn "Could not check targets"
        else
            warn "$down targets down"
        fi
    else
        warn "jq not available, skipping"
    fi

    print_check "Grafana API"
    if curl -sf http://localhost:3000/api/health &>/dev/null; then
        pass
    else
        warn "Grafana not responding"
    fi
}

# Network Health Checks
check_network() {
    print_header "Network Connectivity"

    print_check "Internet connectivity"
    if ping -c 1 -W 2 1.1.1.1 &>/dev/null; then
        pass
    else
        fail "No internet connectivity"
    fi

    print_check "DNS resolution"
    if host nixos.org &>/dev/null; then
        pass
    else
        fail "DNS resolution failing"
    fi

    print_check "HTTPS connectivity"
    if curl -sf --max-time 5 https://nixos.org &>/dev/null; then
        pass
    else
        warn "HTTPS connectivity issues"
    fi
}

# Certificate Health Checks
check_certificates() {
    print_header "TLS Certificates"

    print_check "step-ca service"
    if systemctl is-active --quiet step-ca; then
        pass
    else
        warn "step-ca not running"
    fi

    print_check "Certificate expiry"
    if [ -d "/var/lib/nginx-certs" ]; then
        expiring=$(find /var/lib/nginx-certs -name "*.crt" -exec openssl x509 -noout -checkend 2592000 -in {} \; 2>/dev/null | grep -c "will expire" || echo "0")
        if [ "$expiring" -eq 0 ]; then
            pass
        else
            warn "$expiring certificates expiring within 30 days"
        fi
    else
        warn "Certificate directory not found"
    fi
}

# Security Checks
check_security() {
    print_header "Security"

    print_check "Secrets decryption"
    if [ -d "/run/secrets" ] && [ "$(ls -A /run/secrets 2>/dev/null | wc -l)" -gt 0 ]; then
        pass
    else
        fail "No secrets found in /run/secrets"
    fi

    print_check "Firewall active"
    if systemctl is-active --quiet nftables || nft list ruleset &>/dev/null; then
        pass
    else
        warn "Firewall may not be active"
    fi

    print_check "SSH root login"
    if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
        pass
    else
        warn "Root SSH login may be enabled"
    fi
}

# Summary
print_summary() {
    print_header "Health Check Summary"
    echo -e "  Total checks:   ${TOTAL_CHECKS}"
    echo -e "  ${GREEN}Passed:${NC}        ${PASSED_CHECKS}"
    echo -e "  ${YELLOW}Warnings:${NC}      ${WARNING_CHECKS}"
    echo -e "  ${RED}Failed:${NC}        ${FAILED_CHECKS}"
    echo ""

    if [ "$FAILED_CHECKS" -eq 0 ] && [ "$WARNING_CHECKS" -eq 0 ]; then
        echo -e "${GREEN}✓ System is healthy!${NC}"
        exit 0
    elif [ "$FAILED_CHECKS" -eq 0 ]; then
        echo -e "${YELLOW}⚠ System is healthy with warnings${NC}"
        exit 0
    else
        echo -e "${RED}✗ System has issues that need attention${NC}"
        exit 1
    fi
}

# Main execution
main() {
    echo -e "${BLUE}Gautama System Health Check${NC}"
    echo -e "${BLUE}$(date)${NC}"

    check_system
    check_zfs
    check_services
    check_containers
    check_backups
    check_monitoring
    check_network
    check_certificates
    check_security
    print_summary
}

main "$@"
