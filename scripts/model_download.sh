#!/bin/bash

# Script Name: Generalized File Download Script
# Description: This script downloads files from provided URLs using curl.
#              It conditionally includes an API token for authorization if provided.
#
# Usage:
#   ./model_download.sh
#
# Required Environment Variables:
#     MODELS_URLS - A space-separated list of URLs to files
# Optional Environment Variables:
#     M_API_TOKEN  - Optional API token for URLs that require authorization
#     WORKING_DIR - The working directory for the script (default: /workspace)
#

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

source $SCRIPT_DIR"/helpers.sh"

# Set the working directory
WORKING_DIR=${WORKING_DIR:-"/"}

FOOOCUS_DIR_DIR="${WORKING_DIR}/Fooocus"
CHECKPOINTS_DIR="${FOOOCUS_DIR_DIR}/models/checkpoints"

# Ensure the models directory exists
create_dir "${CHECKPOINTS_DIR}"

# Check for required environment variables
if [ -z "$MODELS_URLS" ]; then
    echo "Error: MODELS_URLS environment variable is required."
    exit 1
fi

# Download model files
echo "Starting Hugging Face model download at $(date)"
for model_url in $MODELS_URLS; do
    download_file "$CHECKPOINTS_DIR" "$model_url"
done

echo "Model download completed at $(date)"
exit 0
