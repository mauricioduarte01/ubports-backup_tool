#!/bin/bash

dir_path=$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")
output_dir="$dir_path/Backups"
backup_output="$output_dir/ubuntu-touch_$(date +%d.%m.%Y-%H:%M:%S)"

documents="/home/phablet/Documents"
downloads="/home/phablet/Downloads"
home="/home/phablet/"
app_data="/home/phablet/.local/share"
config="/home/phablet/.config"
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

# Function to check if the Waydroid folder exists on the phone
waydroid_dir() {
	adb shell "[ -d '$waydroid' ]"
	if [ $? -ne 0 ]; then
		echo "Error: Waydroid folder not found on the phone."
		sleep 2 # Pause for 2 seconds to show the error message
		return 1
	fi
	return 0
}

OPTIONS=$(
	dialog --backtitle "UBPorts Ubuntu Touch Backup tool" \
		--title "Please select which folder to backup" \
		--clear \
		--nocancel \
		--menu "Choose an option" 0 0 0 \
		"1 - Documents" "- /home/phablet/Documents" \
		"2 - Downloads" "- /home/phablet/Downloads" \
		"3 - Home" "- /home/phablet" \
		"4 - App data" "- .local/share" \
		"5 - Config" "- .local/config" \
		"6 - SMS/Calls" "- .local/share/history-service" \
		"7 - Network config" "- /etc/NetworkManager/system-connections" \
		"8 - Waydroid" "- /var/lib/waydroid" \
		"9 - Exit" "- Exit" \
		3>&1 1>&2 2>&3 3>&-
)

case $OPTIONS in
"1 - Documents") adb pull "$documents" "$backup_output" ;;
"2 - Downloads") adb pull "$downloads" "$backup_output" ;;
"3 - Home") adb pull "$home" "$backup_output" ;;
"4 - App data") adb pull "$app_data" "$backup_output" ;;
"5 - Config") adb pull "$config" "$backup_output" ;;
"6 - SMS/Calls") adb pull "$history" "$backup_output" ;;
"7 - Network config") adb pull "$network" "$backup_output" ;;
"8 - Waydroid")
	waydroid_dir
	if [ $? -eq 0 ]; then
		adb pull "$waydroid" "$backup_output"
	fi
	;;
"9 - Exit") exit 1 ;;
esac

# Compress the backup files into a tar.gz archive
archive_file="$backup_output.tar.gz"
tar -czvf "$archive_file" -C "$backup_output" .

if [ $? -eq 0 ]; then
	echo "Backup archive created: $archive_file"
	rm -rf "$backup_output"
else
	echo "Error: Failed to create the backup archive."
fi

exit
