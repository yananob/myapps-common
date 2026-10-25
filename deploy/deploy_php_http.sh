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
    echo "  Usage: $0 <dirname to be deployed> <name on Cloud Functions> [entry point: default=main_http]"
    echo ""
    exit 1
fi

TARGET_DIR="$1"
FUNC_NAME="${2%/}"
ENTRY_POINT="${3:-main_http}"
WORK_DIR="${PWD}/_deploy"

check_prerequisites "${TARGET_DIR}"

echo "----------------------------------------------------------------"
echo "Starting to deploy ${FUNC_NAME}"

# Clean up temporary deployment directory on exit or failure
trap 'rm -rf "${WORK_DIR}"' EXIT

prepare_staging_dir "${TARGET_DIR}" "${WORK_DIR}" "${COMMON_SCRIPT_DIR}"

pushd "${WORK_DIR}" > /dev/null

printf "\033[33m deploying http function [%s] \033[0m\n" "${FUNC_NAME}"
gcloud functions deploy "${FUNC_NAME}" \
    --gen2 \
    --runtime=php82 \
    --region="${REGION:-us-west1}" \
    --source=. \
    --entry-point="${ENTRY_POINT}" \
    --trigger-http \
    --allow-unauthenticated \
    --max-instances 1

popd > /dev/null
