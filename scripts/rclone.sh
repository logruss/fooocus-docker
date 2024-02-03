#!/bin/bash

# Script Name: Data Management Script for Rclone
# Description: This script automates the process of setting up and managing data directories
#              using Rclone. It checks for and installs Rclone and fuse3 if they are not present.
#              The script can optionally mount directories, and download specific models based on the given action,
#              and also backup outputs to a remote server.
#
# Usage:
#   ./rclone.sh [--mount] [--backup] [model names]
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
#     --mount    - Optionally mount the 'outputs' directory.
#     --backup   - Backup '/Fooocus/outputs' and move it to the remote server '/outputs' folder.
#     loras-only - Skips downloading any checkpoints and performs only specified actions.
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


should_mount=false
should_backup=false
exclusive_action=""
declare -a model_names

# Parse command-line options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --mount) should_mount=true; exclusive_action="mount"; ;;
        --backup) should_backup=true; exclusive_action="backup"; ;;
        loras-only) exclusive_action="loras-only"; ;;
        *) model_names+=("$1") ;;
    esac
    shift
done

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
    apt-get install -y fuse3 | bash > /dev/null 2>&1
    echo "fuse3 installed successfully."
}

# Ensure Rclone and fuse3 are installed before proceeding
while ! is_rclone_installed || ! is_fuse3_installed; do
    ! is_rclone_installed && install_rclone
    ! is_fuse3_installed && install_fuse3
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

backup_outputs() {
    local archive_name="outputs_$(date +%Y%m%d_%H%M%S).tar.gz"
    tar -czvf "${FOOOCUS_DIR}/${archive_name}" -C "${OUTPUTS_DIR}" .
    execute_rclone move "${FOOOCUS_DIR}/${archive_name}" "${REMOTE}:outputs"
    echo "Backup of outputs completed."
}


# Create rclone.conf
create_rclone_conf
# Create directories
create_dir "${LORAS_DIR}"
create_dir "${OUTPUTS_DIR}"
create_dir "${CHECKPOINTS_DIR}"


case $exclusive_action in
    mount)
        if ! mountpoint -q "${OUTPUTS_DIR}"; then
            echo "Mounting ${OUTPUTS_DIR} directory..."
            execute_rclone mount "${REMOTE}:outputs" "${OUTPUTS_DIR}" --daemon
            echo "${OUTPUTS_DIR} directory mounted successfully."
        else
            echo "${OUTPUTS_DIR} directory is already mounted."
        fi
        ;;
    backup)
        backup_outputs
        ;;
    loras-only)
        echo "Executing 'loras-only' action."
        download_folder "loras" "${LORAS_DIR}"
        ;;
    *)
        # Default action: download "loras" and handle model downloads
        echo "Default action: downloading 'loras' folder and handling model downloads."
        download_folder "loras" "${LORAS_DIR}"
        handle_model_downloads
        ;;
esac

# Exit with success
echo "Script completed at $(date)"
exit 0

