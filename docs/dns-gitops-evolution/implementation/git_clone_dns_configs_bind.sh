#!/bin/bash
set -euo pipefail

# ================================
# DNS Configs Sync Script for BIND
# ================================
# Author: @safesploit
# Date: 2025-12-11
#
# Description:
#   Periodically checks a GitHub repository for changes on the `main` branch.
#   If changes are detected, clones the repo, syncs BIND zone files,
#   restarts BIND, and records the last applied commit.
#
# Cron usage example (every 5 minutes):
#   */5 * * * * /usr/local/scripts/git_clone_dns_configs_bind.sh --quiet
#
# Manual verbose run:
#   /usr/local/scripts/git_clone_dns_configs_bind.sh
#
# Quiet run:
#   /usr/local/scripts/git_clone_dns_configs_bind.sh --quiet
# ================================

# ----------------
# Global Variables
# ----------------
REPO="OMITTED_FOR_PRIVACY"
OWNER="OMMITTED_FOR_PRIVACY"
BRANCH="main"
REPO_FULL_LINK="git@github.com:${OWNER}/${REPO}.git"

GITHUB_DEPLOY_KEY="${HOME}/.ssh/id_ed25519_github_deploy_key"

WORKDIR="/tmp"
STATE_DIR="/var/lib/${REPO}-sync"
STATE_FILE="${STATE_DIR}/last_commit"

LOG_FILE="/var/log/${REPO}-sync.log"

SOURCE_DIR="${WORKDIR}/${REPO}/bind/var_named/git/"
DESTINATION_DIR="/var/named/git/"

# Equiv to Dnsmasq expand-hosts domain, but for BIND.
ZONE_SNIPPET_DIR="${DESTINATION_DIR}/zones/net-172.16"
OUTPUT_FILE="${ZONE_SNIPPET_DIR}/cname-generated.out.zone"
FQDN_SUFFIX=".safesploit.com"

QUIET=false

# ANSI colour codes (console only)
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# ----------------
# Logging
# ----------------
log() {
    local msg="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    echo "[${timestamp}] ${msg}" >> "${LOG_FILE}"

    if [[ "${QUIET}" == false ]]; then
        echo -e "${msg}"
    fi
}

# ----------------
# Argument Parsing
# ----------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -q|--quiet)
                QUIET=true
                ;;
            *)
                echo "Unknown argument: $1"
                exit 1
                ;;
        esac
        shift
    done
}

# ----------------
# SSH Handling
# ----------------
setup_ssh() {
    log "${BLUE}Setting up SSH agent${NC}"
    eval "$(ssh-agent -s)" >/dev/null
    ssh-add "${GITHUB_DEPLOY_KEY}" >/dev/null
}

cleanup_ssh() {
    if [[ -n "${SSH_AGENT_PID:-}" ]]; then
        log "${BLUE}Killing SSH agent${NC}"
        eval "$(ssh-agent -k)" >/dev/null
    fi
}

# ----------------
# Environment Prep
# ----------------
prepare_environment() {
    mkdir -p "${WORKDIR}"
    mkdir -p "$(dirname "${LOG_FILE}")"
    cd "${WORKDIR}"
}

# ----------------
# Git State Helpers
# ----------------
ensure_git_check_repo() {
    if [[ ! -d ".git-check" ]]; then
        git clone --bare "${REPO_FULL_LINK}" .git-check >/dev/null
    fi
}

fetch_remote_state() {
    cd "${WORKDIR}/.git-check"
    git fetch origin "${BRANCH}" >/dev/null
}

get_remote_commit() {
    git ls-remote origin "${BRANCH}" | awk '{print $1}'
}

get_cached_commit() {
    [[ -f "${STATE_FILE}" ]] && cat "${STATE_FILE}" || echo ""
}

save_commit() {
    mkdir -p "${STATE_DIR}"
    echo "$1" > "${STATE_FILE}"
}

# ----------------
# Change Detection
# ----------------
detect_repo_changes() {
    local remote_commit
    local cached_commit

    remote_commit=$(get_remote_commit)
    cached_commit=$(get_cached_commit)

    if [[ "${remote_commit}" == "${cached_commit}" ]]; then
        log "${GREEN}No changes detected on ${BRANCH}. Exiting.${NC}"
        return 1
    fi

    log "${BLUE}Change detected on ${BRANCH}${NC}"
    log "Old commit: ${cached_commit}"
    log "New commit: ${remote_commit}"
    log "${BLUE}Proceeding with update...${NC}"

    DETECTED_COMMIT="${remote_commit}"
    return 0
}

# ----------------
# Repo Operations
# ----------------
clone_repo() {
    log "${GREEN}Cloning ${REPO_FULL_LINK} (branch: ${BRANCH})${NC}"
    git clone --branch "${BRANCH}" --depth 1 "${REPO_FULL_LINK}"
}

cleanup_repo() {
    rm -rf "${REPO}"
}

# ----------------
# BIND Pre-deployment Checks
# ----------------
pre_deploy_checks() {
    local source_dir=${SOURCE_DIR}

    log "${BLUE}Running named.conf syntax check${NC}"
    named-checkconf || { log "${RED}named.conf invalid${NC}"; exit 1; }

    log "${BLUE}Validating all zone files in ${source_dir}${NC}"
    find "${source_dir}" -type f -name '*.zone' | while read -r zone; do
        log "Checking ${zone}"
        named-checkzone "$(basename "${zone}" .zone)" "${zone}" || { log "${RED}Zone invalid: ${zone}${NC}"; exit 1; }
    done
}


# ----------------
# BIND Handling
# ----------------
copy_bind_files() {
    local source_dir=${SOURCE_DIR}
    local destination_dir=${DESTINATION_DIR}
    local bind_user="named"
    local bind_group="named"

    if [[ ! -d "${source_dir}" ]]; then
        log "${RED}Source directory not found: ${source_dir}${NC}"
        exit 1
    fi

    log "${BLUE}Syncing BIND zone files from ${source_dir} to ${destination_dir}${NC}"
    sudo mkdir -p "${destination_dir}"

    # Recursive sync
    sudo rsync -a --delete "${source_dir}" "${destination_dir}"
}

set_bind_permissions() {
    local destination_dir=${DESTINATION_DIR}
    local bind_user="named"
    local bind_group="named"

    log "${BLUE}Setting ownership and permissions${NC}"
    chown -R "${bind_user}":"${bind_group}" "${destination_dir}"
    chmod 750 "${destination_dir}"
    chmod 640 "${destination_dir}"/*.zone
}

restart_bind() {
    log "${BLUE}Restarting BIND${NC}"
    sudo systemctl restart named
}

# ----------------
# Generated CNAME Records
# ----------------
generate_cname_header() {
    local date_str="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    local hostname="$(hostname)"
    local timestamp="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    local script_name="$(basename "$0")"

    cat <<EOF > "${OUTPUT_FILE}"
; =========================================
; AUTO-GENERATED FILE
; =========================================
; Generated: ${date_str}
; Host: ${hostname}
; Script: ${script_name}
; Source Directory:
;   ${ZONE_SNIPPET_DIR}
;
; DO NOT EDIT MANUALLY
; Changes will be overwritten.
; =========================================

EOF
}

generate_cnames() {
    # Empty output file first
    log "${BLUE}Generating CNAME records in ${OUTPUT_FILE}${NC}"
    touch "${OUTPUT_FILE}"
    generate_cname_header

    # Loop through all zone snippet files
    for zone_file in "${ZONE_SNIPPET_DIR}"/*.zone; do
        # Skip generated output file if it exists
        [[ "${zone_file}" == "${OUTPUT_FILE}" ]] && continue

        # Parse A records only
        grep -E '^\s*[^;#]+\s+IN\s+A\s+' "${zone_file}" | while read -r line; do
            # Extract shortname (first field)
            shortname=$(echo "${line}" | awk '{print $1}')

            # Skip empty lines
            [[ -z "${shortname}" ]] && continue

            # Generate FQDN CNAME
            echo "${shortname}${FQDN_SUFFIX} IN CNAME ${shortname}" >> "${OUTPUT_FILE}"
        done
    done

    log "Generated FQDN CNAMEs written to ${OUTPUT_FILE}"
}


# ----------------
# Apply Updates
# ----------------
apply_updates() {
    cd "${WORKDIR}"
    rm -rf "${REPO}"

    clone_repo
    # pre_deploy_checks
    copy_bind_files
    set_bind_permissions
    restart_bind
    generate_cnames
    save_commit "${DETECTED_COMMIT}"
    cleanup_repo

    log "${GREEN}Update applied successfully${NC}"
}

# ----------------
# Main
# ----------------
main() {
    parse_args "$@"
    trap cleanup_ssh EXIT

    # Prepare environment
    prepare_environment
    setup_ssh
    ensure_git_check_repo
    fetch_remote_state
    detect_repo_changes || exit 0

    # If we reach here, changes were detected
    apply_updates
}

# Execute
main "$@"