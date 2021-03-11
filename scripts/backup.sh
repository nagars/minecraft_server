#!/bin/bash

#Description: Creates a backup of the server in a seperate backup folder. 'u' flag changes backup folder directory for update backups. Else folder directory is for boot backups.

#Checks for options provided
while getopts 'uh' option
do
	case $option in
		(h)
			FLAG='h'
			shift
			;;
		(u)
			FLAG='u'
			shift
			;;
		(*)
			echo "Error: Invalid Option Provided"
			exit 0
			;;
	esac
done

if [ "$FLAG" = "h" ]
then
	echo "Minecraft Server Backup Script"
	echo "Usage: ./backup.sh [Flags]"

	echo "[Flags]:"
	echo "		-h: Help"
	echo "		Prints help informatino regarding usage of this script"
	echo " 		-u: Update"
	echo "		Generates an alternate backup directory named "update_server_backup""
	
	exit 1
fi

#Creates a boot_server_backup folder by default
BACKUP_FOLDER_NAME="boot_server_backup"

#Checks if -u flag was given. Creates an update_server_backup folder instead
if [ "$FLAG" = "u" ]
then
	BACKUP_FOLDER_NAME="update_server_backup"
fi

#Path to server script folder directory
SERVER_SCRIPT_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" ; pwd -P)

#Path to server folder directory
SERVER_PATH=$(cd "$SERVER_SCRIPT_PATH"; cd ".."; pwd -P)

#Name of server folder
SERVER_FOLDER_NAME="${SERVER_PATH##*/}" 

#Extracts parent path (Before main server folder)
PARENT_PATH=$(cd "${SERVER_PATH}"; cd ".." ;  pwd -P) 

#Return to parent folder
cd ${PARENT_PATH}

#Checks if the backup folder has been made. If not, it makes it.
if [ ! -d ${BACKUP_FOLDER_NAME} ]
then
	mkdir ${BACKUP_FOLDER_NAME}
fi

#Generates the server backup path
BACKUP_PATH=$(cd "${PARENT_PATH}/${BACKUP_FOLDER_NAME}"; pwd -P);

#Enters backup folder
cd ${BACKUP_PATH}

#Check if the server folder for backups exists. If not, it makes it.
if [ ! -d ${SERVER_FOLDER_NAME} ]
then
	mkdir ${SERVER_FOLDER_NAME}
fi

#Searches for and deletes older backup 
find "${BACKUP_PATH}/${SERVER_FOLDER_NAME}/" -type f -name '*.gz' -delete

#Enter server parent folder
cd ${PARENT_PATH}

#Create new backup of server folder
tar -cpzf "${SERVER_FOLDER_NAME}"-$(date +%F-%H-%M).tar.gz  ${SERVER_FOLDER_NAME} > /dev/null 

#Move the backup to the server backup folder
mv *.gz ${BACKUP_PATH}/${SERVER_FOLDER_NAME}

