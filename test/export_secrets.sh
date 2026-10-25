#!/bin/bash

if [ -z "${SECRETS+x}" ] || [ "${#SECRETS[@]}" -eq 0 ]; then
    echo "Error: SECRETS array is not set or empty. Please define SECRETS array before sourcing this script."
    echo "Example: export SECRETS=(\"MY_SECRET_1\" \"MY_SECRET_2\")"
    return 1 2>/dev/null || exit 1
fi

echo "Exporting secrets..."

for secret in "${SECRETS[@]}"; do
    if [ -n "${secret}" ]; then
        if [[ ! "${secret}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            echo "Warning: '${secret}' is not a valid environment variable identifier. Skipping." >&2
            continue
        fi

        echo "Fetching secret: ${secret}"
        if VAL=$(gcloud secrets versions access latest --secret="${secret}" 2>/dev/null); then
            export "${secret}=${VAL}"
        else
            echo "Warning: Failed to fetch secret '${secret}' from Secret Manager." >&2
            export "${secret}="
        fi
    fi
done

unset secret VAL 2>/dev/null || true
