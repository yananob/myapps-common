#!/bin/bash

GOOGLE_CLOUD_PROJECT=$(gcloud config get core/project 2>/dev/null || echo "")
REGION="${REGION:-us-west1}"
