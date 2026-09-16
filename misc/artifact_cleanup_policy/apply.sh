#!/bin/bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SCRIPT="${SCRIPT_DIR}/../../deploy/common.sh"

if [ -f "${COMMON_SCRIPT}" ]; then
    source "${COMMON_SCRIPT}"
fi

PROJECT_ID="${PROJECT_ID:-${GOOGLE_CLOUD_PROJECT:-}}"
REGION_NAME="${REGION:-us-west1}"

if [ -z "${PROJECT_ID}" ]; then
    echo "Error: PROJECT_ID or GOOGLE_CLOUD_PROJECT is not set."
    exit 1
fi

echo "Applying Artifact Registry cleanup policy to repository 'gcf-artifacts' in project '${PROJECT_ID}' (${REGION_NAME})..."

gcloud artifacts repositories set-cleanup-policies gcf-artifacts \
    --project="${PROJECT_ID}" \
    --location="${REGION_NAME}" \
    --policy="${SCRIPT_DIR}/policy.json" \
    --no-dry-run

echo "Listing current cleanup policies for 'gcf-artifacts':"
gcloud artifacts repositories list-cleanup-policies gcf-artifacts \
    --project="${PROJECT_ID}" \
    --location="${REGION_NAME}"
