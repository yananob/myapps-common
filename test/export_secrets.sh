#!/bin/bash

if [ -z "${SECRETS+x}" ] || [ "${#SECRETS[@]}" -eq 0 ]; then
    echo "Error: SECRETS array is not set or empty. Please define SECRETS array before sourcing this script."
    echo "Example: export SECRETS=(\"MY_SECRET_1\" \"MY_SECRET_2\")"
    return 1 2>/dev/null || exit 1
fi

echo "Exporting secrets..."

for secret in "${SECRETS[@]}"; do
    if [ -n "${secret}" ]; then
        echo "Fetching secret: ${secret}"
        VAL=$(gcloud secrets versions access latest --secret="${secret}" 2>/dev/null || echo "")
        export "${secret}=${VAL}"
    fi
done
