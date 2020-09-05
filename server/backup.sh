#/bin/sh

server_path=$( cd "$( dirname "${BASH_SOURCE[0]}" )" ; pwd -P)

echo ${server_path}

folder_name="${server_path##*/}"

echo ${folder_name}

parent_path=$(pwd -P)

echo ${parent_path}

if [ ! -d server_backup ]
then
	mkdir server_backup
fi

backup_path=$(cd "${parent_path}/server_backup"; pwd -P);

echo ${backup_path}

if [ ! -d ${folder_name} ]
then
	mkdir ${folder_name}
fi

echo ${backup_path}/${folder_name}

tar -cvpzf "${backup_path}/${folder_name}"-$(date +%F-%H-%M).tar.gz ${server_path}
