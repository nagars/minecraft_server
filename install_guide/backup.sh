#!/bin/sh

#Path to server folder directory
server_path=$( cd "$( dirname "${BASH_SOURCE[0]}" )" ; pwd -P)

#echo ${server_path}

#Name of server folder
folder_name="${server_path##*/}"

#echo ${folder_name}

#Extracts parent path (Before main server folder)
parent_path=$(cd ".." ; pwd -P) 

#echo ${parent_path}

#Checks if the backup folder has been made. If not, it makes it.
if [ ! -d server_backup ]
then
	mkdir server_backup
fi

#Generates the server backup path
backup_path=$(cd "${parent_path}/server_backup"; pwd -P);

#echo ${backup_path}

#Check if the server folder for backups exists. If not, it makes it.
if [ ! -d ${folder_name} ]
then
	mkdir ${folder_name}
fi

#echo ${backup_path}/${folder_name}

# Delete older backup
find "${backup_path}/${folder_name}" -type f -name '*.gz' -delete

# Create new backup
tar -cvpzf "${backup_path}/${folder_name}"-$(date +%F-%H-%M).tar.gz ${server_path}
