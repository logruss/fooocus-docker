#!/bin/bash

# Script Name: Data Management Script for Rclone
# Description: This script automates the process of setting up and managing data directories
#              using Rclone. It checks for and installs Rclone and fuse3 if they are not present.
#              The script can mount directories, and download specific models based on the given action.
#
# Usage:
#   ./setup.sh [action]
#
# Required Environment Rclone Variables:
#     REMOTE    - The remote name for Rclone
#     SFTP_HOST - The SFTP host address
#     SFTP_USER - The SFTP username
#     SFTP_PASS - The SFTP password
#
# Required Environment Variables:
#     WORKING_DIR - The working directory for the script default: /
#
#   Actions:
#     loras-only  - Skips downloading any checkpoints and performs only mounting and loras setup.
#     (no action) - Performs standard operations including default model download.
#
#   Standard operations include checking/installing Rclone and fuse3, creating necessary directories,
#   mounting the 'outputs' directory, and managing model downloads in 'checkpoints' directory.
#
# Prerequisites:
#   - This script requires 'curl' for installation processes.
#

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

source $SCRIPT_DIR"/helpers.sh"

# Check if WORKING_DIR is set and not empty, if not set a default value
WORKING_DIR=${WORKING_DIR:-"/"}

# Now you can use $WORKING_DIR in your script
echo "Working directory is set to $WORKING_DIR"

# Data directory
FOOOCUS_DIR="${WORKING_DIR}/Fooocus"

# Fooocus directories to be created
OUTPUTS_DIR="${FOOOCUS_DIR}/outputs"
LORAS_DIR="${FOOOCUS_DIR}/models/loras"
CHECKPOINTS_DIR="${FOOOCUS_DIR}/models/checkpoints"

# Function to check if Rclone is installed
is_rclone_installed() {
    command -v rclone >/dev/null 2>&1
}

# Function to install Rclone
install_rclone() {
    echo "Installing Rclone..."
    curl https://rclone.org/install.sh | bash > /dev/null 2>&1
    echo "Rclone installed successfully."
}

# Function to check if fuse3 is installed
is_fuse3_installed() {
    dpkg -l | grep fuse3
}

# Function to install fuse3
install_fuse3() {
    echo "Installing fuse3..."
    apt-get update | bash > /dev/null 2>&1
    apt-get apt-utils | bash > /dev/null 2>&1
    apt-get install -y fuse3 | bash > /dev/null 2>&1
    echo "fuse3 installed successfully."
}

# Ensure Rclone and fuse3 are installed before proceeding
while ! is_rclone_installed || ! is_fuse3_installed; do
    if ! is_rclone_installed; then
        install_rclone
    fi
    if ! is_fuse3_installed; then
        install_fuse3
    fi
    sleep 20
done

# Main execution
echo "Starting script at $(date)"

# Function to create directory if it does not exist
create_rclone_conf() {
    local remote_name=$REMOTE

    if [ -z "$remote_name" ]; then
        echo "Error: REMOTE environment variable is not set."
        return 1
    fi

    if [ -f "rclone.conf" ]; then
        echo "Skiping: rclone.conf already exists."
        return 1
    fi

    cat <<EOF > $SCRIPT_DIR"/rclone.conf"
[$remote_name]
type = sftp
disable_hashcheck = true
shell_type = unix
EOF

    echo "rclone.conf created with remote name: $remote_name"
}

# Function to execute Rclone command
execute_rclone() {
    local action=$1
    local source=$2
    local destination=$3
    local daemon=$4

    rclone --config="${SCRIPT_DIR}/rclone.conf" \
            --sftp-host="${SFTP_HOST}" \
            --sftp-user="${SFTP_USER}" \
            --sftp-pass="${SFTP_PASS}" \
            ${action} "${source}" "${destination}" ${daemon}
}

# Function to download model
download_model() {
    local model_name=$1
    local model_path="${CHECKPOINTS_DIR}/${model_name}"

    if [ -f "${model_path}" ]; then
        echo "${model_name} already exists. Skipping download."
    else
        echo "Starting download of ${model_name}..."
        execute_rclone copy "${REMOTE}:checkpoints/${model_name}" "${CHECKPOINTS_DIR}"
    fi
}

download_folder() {
    local folder_name=$1
    local folder_destination=$2

    echo "Starting downloading ${folder_name} folder from remote into ${folder_destination}..."
    execute_rclone copy "${REMOTE}:${folder_name}" "${folder_destination}"
}


handle_model_downloads() {
    if [ $# -eq 0 ]; then
        # No arguments provided, check environment variable
        if [ -n "$CHECKPOINTS_TO_DOWNLOAD" ]; then
            # If CHECKPOINTS_TO_DOWNLOAD is set and not empty
            echo "Downloading models specified in CHECKPOINTS_TO_DOWNLOAD environment variable"
            for model in $CHECKPOINTS_TO_DOWNLOAD; do
                download_model "$model"
            done
        else
            echo "No models specified for download."
        fi
    else
        # Arguments are provided, use them as model names
        for model in "$@"; do
            download_model "$model"
        done
    fi
}

# Create rclone.conf
create_rclone_conf
# Create directories
create_dir "${LORAS_DIR}"
create_dir "${OUTPUTS_DIR}"
create_dir "${CHECKPOINTS_DIR}"

# Mount outputs directory
# Mount only current data directory if it is not already mounted
if ! mountpoint -q "${OUTPUTS_DIR}"; then
    echo "Mounting ${OUTPUTS_DIR} directory..."
    execute_rclone mount "${REMOTE}:outputs" "${OUTPUTS_DIR}" --daemon
    echo "${OUTPUTS_DIR} directory mounted successfully."
else
    echo "${OUTPUTS_DIR} directory is already mounted."
fi

# Handle different actions
if [ "$1" = "loras-only" ]; then
    echo "Skipping checkpoint downloads as per 'loras-only' action."
    download_folder "loras" "${LORAS_DIR}"
else
    # If the first argument is not 'loras-only', download them and assume all arguments are model names
    download_folder "loras" "${LORAS_DIR}"
    handle_model_downloads "$@"
fi

# Exit with success
echo "Script completed at $(date)"
exit 0

