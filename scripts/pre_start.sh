#!/usr/bin/env bash

source helpers.sh

export PYTHONUNBUFFERED=1

echo "Template version: ${TEMPLATE_VERSION}"

if [[ -e "/workspace/template_version" ]]; then
    EXISTING_VERSION=$(cat /workspace/template_version)
else
    EXISTING_VERSION="0.0.0"
fi

sync_apps() {
    # Sync venv to workspace to support Network volumes
    echo "Syncing venv to workspace, please wait..."
    # We can't remove the source files here otherwise it breaks Fooocus
    rsync -rlptDu /venv/ /workspace/venv/

    # Sync Fooocus to workspace to support Network volumes
    echo "Syncing Fooocus to workspace, please wait..."
    rsync -rlptDu /Fooocus/ /workspace/Fooocus/

    echo "${TEMPLATE_VERSION}" > /workspace/template_version

    # Use rclone to sync or mount data from remote storage
    if [ "$USE_RCLONE" = "enabled" ]; then
        echo "Starting Rclone script"
        execute_script "rclone.sh" "Running Rclone script, downloading predefined laras and checkpoints, please wait..."
    fi

    # Download models from URLs
    if [ -n "$MODELS_URLS" ]; then
        echo "Starting model download script"
        execute_script "model_download.sh" "Running model download script, please wait..."
    fi
}

fix_venvs() {
    # Fix the venv to make it work from /workspace
    echo "Fixing venv..."
    /fix_venv.sh /venv /workspace/venv
}

if [ "$(printf '%s\n' "$EXISTING_VERSION" "$TEMPLATE_VERSION" | sort -V | head -n 1)" = "$EXISTING_VERSION" ]; then
    if [ "$EXISTING_VERSION" != "$TEMPLATE_VERSION" ]; then
        sync_apps
        fix_venvs

        # Create logs directory
        mkdir -p /workspace/logs
    else
        echo "Existing version is the same as the template version, no syncing required."
    fi
fi

if [[ ${DISABLE_AUTOLAUNCH} ]]
then
    echo "Auto launching is disabled so the application will not be started automatically"
    echo "You can launch it manually:"
    echo ""
    echo "   cd /workspace/Fooocus"
    echo "   deactivate && source /workspace/venv/bin/activate"
    echo "   python3 entry_with_update.py --listen --port 3001"
else
    echo "Starting Fooocus"
    export HF_HOME="/workspace"
    source /workspace/venv/bin/activate
    cd /workspace/Fooocus

    if [[ ${PRESET} ]]
    then
        echo "Starting Fooocus using preset: ${PRESET}"
        nohup python3 entry_with_update.py --listen --port 3001 --preset ${PRESET} > /workspace/logs/fooocus.log 2>&1 &
    else
        echo "Starting Fooocus using defaults"
        nohup python3 entry_with_update.py --listen --port 3001 > /workspace/logs/fooocus.log 2>&1 &
    fi

    echo "Fooocus started"
    echo "Log file: /workspace/logs/fooocus.log"
    deactivate
fi

echo "All services have been started"
