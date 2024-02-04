#!/bin/bash

# Script Name: Generalized File Download Script
# Description: This script downloads files from provided URLs using curl.
#              It conditionally includes an API token for authorization if provided.
#
# Usage:
#   ./model_download.sh [-u "<URL1> <URL2>"] [-t API_TOKEN] [-d WORKING_DIR]
#
# Arguments:
#     -u --urls       A space-separated list of URLs to files (optional if MODELS_URLS env is set)
#     -t --token      Optional API token for URLs that require authorization (optional if M_API_TOKEN env is set)
#     -d --dir        The working directory for the script (default: /, optional if WORKING_DIR env is set)

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

source $SCRIPT_DIR"/helpers.sh"

# Initialize from command-line arguments or environment variables
WORKING_DIR=${WORKING_DIR:-"/"}
MODELS_URLS=${MODELS_URLS:-""}
M_API_TOKEN=${M_API_TOKEN:-""}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -u|--urls) MODELS_URLS="$2"; shift ;;
        -t|--token) M_API_TOKEN="$2"; shift ;;
        -d|--dir) WORKING_DIR="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

FOOOCUS_DIR_DIR="${WORKING_DIR}/Fooocus"
CHECKPOINTS_DIR="${FOOOCUS_DIR_DIR}/models/checkpoints"

# Ensure the models directory exists
create_dir "${CHECKPOINTS_DIR}"

# Check if URLs have been provided either via command line or environment
if [ -z "$MODELS_URLS" ]; then
    echo "Error: URLs must be provided via -u/--urls argument or MODELS_URLS environment variable."
    exit 1
fi

# Download model files
echo "Starting model download at $(date)"
for model_url in $MODELS_URLS; do
    if [ -n "$M_API_TOKEN" ]; then
        download_file "$CHECKPOINTS_DIR" "$model_url" "$M_API_TOKEN"
    else
        download_file "$CHECKPOINTS_DIR" "$model_url"
    fi
done

echo "Model download completed at $(date)"
exit 0
