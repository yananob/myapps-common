#!/bin/bash
set -eu

# Script Template for local Cloud Function Deployment
# Copy this file to your project root as `deploy.sh` and select the appropriate deployment type below.

# Example HTTP Function deployment:
# bash ./_myapps-common/deploy/deploy_php_http.sh . {CLOUD_FUNCTION_NAME} [ENTRY_POINT]

# Example Event (Pub/Sub) Function deployment:
# bash ./_myapps-common/deploy/deploy_php_event.sh . {CLOUD_FUNCTION_NAME} [ENTRY_POINT]
