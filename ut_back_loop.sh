#!/bin/bash

dir_path=$(dirname "${BASH_SOURCE[0]:-$0}")
output_dir="$dir_path/Backups"
backup_output="$output_dir/ubuntu-touch_$(date +%d.%m.%Y-%H:%M:%S)"

documents="/home/phablet/Documents"
downloads="/home/phablet/Downloads"
home="/home/phablet/"
app_data="/home/phablet/.local/share"
config="/home/phablet/.local/config"
history="/home/phablet/.local/share/history-service"
network="/etc/NetworkManager/system-connections"
waydroid="/var/lib/waydroid"

# Create the backup output directory if it doesn't exist
if [ ! -d "$output_dir" ]; then
    mkdir -p "$output_dir"
    echo "Backup output directory created: $output_dir"
else
    echo "Backup output directory already exists: $output_dir"
fi

# Function to check if the Downloads folder exists on the phone
waydroid_dir() {
    adb shell "[ -d '$waydroid' ]"
    if [ $? -ne 0 ]; then
        echo "Error: Waydroid folder not found on the phone."
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
        "1 - Documents") adb pull "$documents" "$backup_output/Documents" ;;
        "2 - Downloads") adb pull "$downloads" "$backup_output/Downloads" ;;
        "3 - Home")  adb pull "$home" "$backup_output/Home" ;;
    "4 - App data")  adb pull "$app_data" "$backup_output/AppData" ;;
	"5 - Config")  adb pull "$config" "$backup_output/Config" ;;
    "6 - SMS/Calls")  adb pull "$history" "$backup_output/SMS_Calls" ;;
    "7 - Network config")  adb pull "$network" "$backup_output/NetworkConfig" ;;
    "8 - Waydroid")
        waydroid_dir
            if [ $? -eq 0 ]; then
                adb pull "$waydroid" "$backup_output/Waydroid"
            fi
            ;;
    "9 - Exit") exit 1 ;;
    esac
}

# Main loop to display the main screen
while true; do
    show_main_screen

    # Compress the backup files into a tar.gz archive
    archive_file="$backup_output.tar.gz"
    tar -czvf "$archive_file" -C "$output_dir" "$(basename "$backup_output")"

    # Check the exit status of the tar command
    if [ $? -eq 0 ]; then
        echo "Backup archive created: $archive_file"

        # Verify the integrity of the archive
        tar -tvf "$archive_file"
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
