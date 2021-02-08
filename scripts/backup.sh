#!/bin/bash

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

#Creates a boot_server_backup folder by default
BACKUP_FOLDER_NAME="boot_server_backup"

#Checks if -u flag was given. Creates an update_server_backup folder instead
if [ "$FLAG" = "u" ]
then
	BACKUP_FOLDER_NAME="update_server_backup"
fi

#Path to server script folder directory
server_script_path=$( cd "$( dirname "${BASH_SOURCE[0]}" )" ; pwd -P)

#Path to server folder directory
server_path=$(cd "$server_script_path"; cd ".."; pwd -P)

#Name of server folder
server_folder_name="${server_path##*/}" 

#Extracts parent path (Before main server folder)
parent_path=$(cd "${server_path}"; cd ".." ;  pwd -P) 

#Return to parent folder
cd ${parent_path}

#Checks if the backup folder has been made. If not, it makes it.
if [ ! -d ${BACKUP_FOLDER_NAME} ]
then
	mkdir ${BACKUP_FOLDER_NAME}
fi

#Generates the server backup path
backup_path=$(cd "${parent_path}/${BACKUP_FOLDER_NAME}"; pwd -P);

#Enters backup folder
cd ${backup_path}

#Check if the server folder for backups exists. If not, it makes it.
if [ ! -d ${server_folder_name} ]
then
	mkdir ${server_folder_name}
fi

#Enters server folder in backups directory
cd ${server_folder_name}

#Deletes older backup
find "${backup_path}/${server_folder_name}/" -type f -name '*.gz' -delete

#Creates new backup
tar -cvpzf "${server_folder_name}"-$(date +%F-%H-%M).tar.gz --absolute-names ${server_script_path} > /dev/null
