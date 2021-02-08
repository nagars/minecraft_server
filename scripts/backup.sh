#!/bin/bash

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
if [ ! -d boot_server_backup ]
then
	mkdir boot_server_backup
fi

#Generates the server backup path
backup_path=$(cd "${parent_path}/boot_server_backup"; pwd -P);

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
