#!/bin/bash
error_output=$(source .npa_publisher_cronjob_env 2>&1)
source_exit_code=$?

if [ $source_exit_code -ne 0 ]; then
    /usr/bin/logger "Failed to source .npa_publisher_cronjob_env, error code: $source_exit_code"
    /usr/bin/logger "Error output: $error_output"
fi

# Force set the PATH again to avoid any issue
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin

# Load the explicit proxy settings written by the Publisher Wizard (no-op when none is configured).
# The image pull below runs as a child process of this script and only inherits its environment
# (on RHEL the pull is performed by podman-docker, which has no daemon that could be configured).
if [ -f ./proxy_settings.sh ]; then
    source ./proxy_settings.sh
fi

/usr/bin/logger "npa_auto_upgrade_script_env right after sourcing: $(/usr/bin/env)"
/usr/bin/logger "Which docker and cat right after sourcing: $(/usr/bin/which docker) $(/usr/bin/which cat)"

WAIT_TIME_AFTER_BOOT_UP_IN_MIN=5

uptime_in_sec=`cat /proc/uptime | grep -o '^[0-9]\+'`
uptime_in_minute=$((${uptime_in_sec} / 60))

if [ $uptime_in_minute -lt $WAIT_TIME_AFTER_BOOT_UP_IN_MIN ]; then
    /usr/bin/logger "Skip triggering npa_publisher_wizard -upgrade_unattended. Neet to wait ${WAIT_TIME_AFTER_BOOT_UP_IN_MIN} minutes after bootup."
    exit 1
fi

if pgrep -f "npa_publisher_wizard -upgrade_unattended*" > /dev/null
then
    /usr/bin/logger "Another npa_publisher_wizard -upgrade_unattended is running. Skip this time."
    exit 1
fi

if [ -f ./trigger_upgrade ]; then 
    /usr/bin/logger "Trigger npa_publisher_wizard -upgrade_unattended!" 
    
    # Change to parent directory (from /home/ubuntu/resources to /home/ubuntu)
    # This matches production behavior and allows wizard to find resources/trigger_upgrade
    cd ..
    
    # Copy wizard from container if absent
    if [ ! -f ./npa_publisher_wizard ]; then
        /usr/bin/logger "Wizard binary not found, copying from container"
        docker run -v $(pwd):/home/host_home --rm --entrypoint cp new_edge_access:latest /home/npa_publisher_wizard /home/host_home/npa_publisher_wizard
        if [ $? -eq 0 ]; then
            /usr/bin/logger "Successfully copied wizard binary from container"
        else
            /usr/bin/logger "Failed to copy wizard binary from container"
            exit 1
        fi
    fi
    
    sha_value=$(/usr/bin/sha256sum ./npa_publisher_wizard)
    /usr/bin/logger "SHA256 sum of wizard $sha_value for auto upgrade"
    /usr/bin/logger "npa_auto_upgrade_script_env before running wizard: $(/usr/bin/env)"
    /usr/bin/logger "Which docker and cat before running wizard: $(/usr/bin/which docker) $(/usr/bin/which cat)"

    ./npa_publisher_wizard -upgrade_unattended
    exit_code=$?

    if [ $exit_code -ne 0 ]; then
        /usr/bin/logger "npa_publisher_wizard -upgrade_unattended failed with exit status $exit_code."
    fi
fi
