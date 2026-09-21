#!/bin/bash

if [ -z "${SECRETS+x}" ] || [ "${#SECRETS[@]}" -eq 0 ]; then
    echo "Error: SECRETS array is not set or empty. Please define SECRETS array before sourcing this script."
    return 1 2>/dev/null || exit 1
fi

echo "Unsetting secrets..."

for secret in "${SECRETS[@]}"; do
    if [ -n "${secret}" ]; then
        unset "${secret}"
    fi
done
