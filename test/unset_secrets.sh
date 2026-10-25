#!/bin/bash

if [ -z "${SECRETS+x}" ] || [ "${#SECRETS[@]}" -eq 0 ]; then
    echo "Error: SECRETS array is not set or empty. Please define SECRETS array before sourcing this script."
    return 1 2>/dev/null || exit 1
fi

echo "Unsetting secrets..."

for secret in "${SECRETS[@]}"; do
    if [ -n "${secret}" ]; then
        if [[ ! "${secret}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            echo "Warning: '${secret}' is not a valid environment variable identifier. Skipping." >&2
            continue
        fi

        unset "${secret}"
    fi
done

unset secret 2>/dev/null || true
