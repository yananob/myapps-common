#!/bin/bash

GOOGLE_CLOUD_PROJECT=$(gcloud config get core/project 2>/dev/null || echo "")
REGION="${REGION:-us-west1}"

check_prerequisites() {
    local target_dir="$1"
    echo "Checking ${target_dir}"

    if [ ! -f ".gcloudignore" ]; then
        echo ".gcloudignore doesn't exist. Please create it."
        exit 1
    fi

    if [ -f "configs/config.json.sample" ] && [ ! -f "configs/config.json" ]; then
        echo "configs/config.json.sample exists. Please create configs/config.json for this app."
        exit 1
    fi
}

resolve_rsync_conf() {
    local common_script_dir="${1:-}"
    local rsync_conf="${common_script_dir}/rsync_exclude.conf"

    if [ -f "${rsync_conf}" ]; then
        echo "${rsync_conf}"
    elif [ -f "./_myapps-common/deploy/rsync_exclude.conf" ]; then
        echo "./_myapps-common/deploy/rsync_exclude.conf"
    else
        echo "rsync_exclude.conf"
    fi
}

prepare_staging_dir() {
    local target_dir="$1"
    local work_dir="$2"
    local common_script_dir="${3:-}"

    rm -rf "${work_dir}"
    mkdir -p "${work_dir}"

    local rsync_conf
    rsync_conf=$(resolve_rsync_conf "${common_script_dir}")

    rsync -vaL --exclude-from="${rsync_conf}" "./${target_dir}/" "${work_dir}/"
}
