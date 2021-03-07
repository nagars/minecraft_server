#!/bin/bash

#Reference https://gitlab.com/peaz/minecraft_server_update_script/blob/master/update_server.sh
# https://www.atpeaz.com/using-a-script-to-update-the-minecraft-server-jar/

#Move to server folder
cd ".."

# Read the current version of the local server
CURRENT_VER=$(cat current_ver.txt)
echo "Current Version: $CURRENT_VER"

# Download the latest version_manifest.json
wget -q https://launchermeta.mojang.com/mc/game/version_manifest.json

# Get the latest release version number
VER=$(jq -r '.latest.release' version_manifest.json)
echo "Latest Version: $VER"

if [ $CURRENT_VER != $VER ] 
then
   
    echo "Running script to create a new update backup"
    #Path to server script folder directory
    server_script_path=$( cd "$( dirname "${BASH_SOURCE[0]}" )" ; pwd -P)

    #Calls back up script with updates flag
    bash $server_script_path/backup.sh -u

    # Create the jq command to extract the <latest_release_version>.json url
    MANIFEST_JQ=$(echo "jq -r '.versions[] | select(.id == \"$VER\") | .url' version_manifest.json")

    # Query the <latest_release_version>.json url
    MANIFEST_URL=$(eval $MANIFEST_JQ)
    
    # Download the <latest_release_version>.json
    wget -q $MANIFEST_URL

    # Create the temp script to extract the latest server download URL from the <latest_release_version>.json
    DOWNLOAD_JQ=$(echo "jq -r .downloads.server.url $VER.json")

    # Query and get the latest release server.jar download URL
    DOWNLOAD_URL=$(eval $DOWNLOAD_JQ)
 
    # Delete current server version
    echo "Deleting obsolete server version"
    rm server.jar

    #Download the latest server
    echo "Downloading Server: Version $VER"
    wget $DOWNLOAD_URL

    # update the current_ver.txt to the latest release version number 
    echo $VER > current_ver.txt

    # Delete the json files
    echo "Cleaning up temporary files"
    rm *.json

    echo "You have the latest $VER version of server.jar now!"
else
    echo "Current server version is the latest already!"
    rm *.json
fi

