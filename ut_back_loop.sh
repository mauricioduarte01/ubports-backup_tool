#!/bin/bash

dir_path=$(dirname "${BASH_SOURCE[0]:-$0}")
output_file="ubuntu-touch_$(date +%d.%m.%Y-%H:%M:%S)"
backup_output="$dir_path/Backups/$output_file"

documents="/home/phablet/Documents"
downloads="/home/phablet/Downloads"
local_share="/home/phablet/.local/share"

# Create the backup output directory if it doesn't exist
if [ ! -d "$backup_output" ]; then
    mkdir -p "$backup_output"
    echo "Backup output directory created: $backup_output"
else
    echo "Backup output directory already exists: $backup_output"
fi

# Function to check if the Downloads folder exists on the phone
check_downloads_folder() {
    adb shell "[ -d '$downloads' ]"
    if [ $? -ne 0 ]; then
        echo "Error: Downloads folder not found on the phone."
        sleep 2  # Pause for 2 seconds to show the error message
        return 1
    fi
    return 0
}

# Function to display the main screen
show_main_screen() {
    CHOICE=$(dialog --backtitle "UBPorts Ubuntu Touch Backup tool" \
    --title "Please select which folder to backup" \
    --clear \
    --nocancel \
    --menu "Choose an option" 0 0 0 \
               "1 - Documents"      "- /home/phablet/Documents" \
               "2 - Downloads"      "- /home/phablet/Downloads" \
               "3 - Home"           "- /home/phablet" \
               "4 - App data"       "- .local/share" \
               "5 - Config"         "- .local/config" \
               "6 - SMS/Calls"      "- .local/share/history-service" \
               "7 - Network config" "- /etc/NetworkManager/system-connections" \
               "8 - Waydroid"       "- /var/lib/waydroid" \
               "9 - Exit"           "- Exit" \
        3>&1 1>&2 2>&3 3>&-)

    case $CHOICE in
        "1 - Documents") adb pull "$documents" "$backup_output" ;;
        "2 - Downloads")
            check_downloads_folder
            if [ $? -eq 0 ]; then
                adb pull "$downloads" "$backup_output"
            fi
            ;;
        "3 - Home")  adb pull "$local_share" "$backup_output" ;;
        "9 - Exit") exit 1 ;;
    esac
}

# Main loop to display the main screen
while true; do
    show_main_screen

    # Compress the backup files into a tar.gz archive
    archive_file="$backup_output.tar.gz"
    tar -czvf "$archive_file" -C "$backup_output" .

    # Check the exit status of the tar command
    if [ $? -eq 0 ]; then
        echo "Backup archive created: $archive_file"

        # Verify the integrity of the archive
        tar -dvf "$archive_file"
        if [ $? -eq 0 ]; then
            echo "Backup archive verified successfully."
        else
            echo "Error: Backup archive verification failed."
        fi

        rm -rf "$backup_output"  # Remove the uncompressed directory
    else
        echo "Error: Failed to create the backup archive."
    fi
done
