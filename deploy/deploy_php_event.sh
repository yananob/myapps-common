#!/bin/bash
set -eu

COMMON_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${COMMON_SCRIPT_DIR}/common.sh" ]; then
    source "${COMMON_SCRIPT_DIR}/common.sh"
elif [ -f "./_myapps-common/deploy/common.sh" ]; then
    source ./_myapps-common/deploy/common.sh
fi

if [ "$#" -lt 2 ]; then
    echo ""
    echo "  Insufficient arguments."
    echo "  Usage: $0 <dirname to be deployed> <name on Cloud Functions> [entry point: default=main_event]"
    echo ""
    exit 1
fi

TARGET_DIR="$1"
FUNC_NAME="${2%/}"
ENTRY_POINT="${3:-main_event}"
WORK_DIR="${PWD}/_deploy"

echo "Checking ${TARGET_DIR}"

# Check existence of .gcloudignore
if [ ! -f ".gcloudignore" ]; then
    echo ".gcloudignore doesn't exist. Please create it."
    exit 1
fi

# Check existence of config.json if config.json.sample exists
if [ -f "configs/config.json.sample" ] && [ ! -f "configs/config.json" ]; then
    echo "configs/config.json.sample exists. Please create configs/config.json for this app."
    exit 1
fi

echo "----------------------------------------------------------------"
echo "Starting to deploy ${FUNC_NAME}"

# Clean up temporary deployment directory on exit or failure
trap 'rm -rf "${WORK_DIR}"' EXIT

rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}"

RSYNC_CONF="./_myapps-common/deploy/rsync_exclude.conf"
if [ ! -f "${RSYNC_CONF}" ]; then
    RSYNC_CONF="${COMMON_SCRIPT_DIR}/rsync_exclude.conf"
fi

rsync -vaL --exclude-from="${RSYNC_CONF}" "./${TARGET_DIR}/" "${WORK_DIR}/"
pushd "${WORK_DIR}" > /dev/null

echo -e "\e[33m deploying event function [${FUNC_NAME}] \e[m"
gcloud functions deploy "${FUNC_NAME}" \
    --gen2 \
    --runtime=php82 \
    --region="${REGION:-us-west1}" \
    --source=. \
    --entry-point="${ENTRY_POINT}" \
    --trigger-topic="${FUNC_NAME}"

popd > /dev/null
