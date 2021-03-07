#!/bin/bash

#sets flag to exit upon failure of any command
set -e

while getopts 'v:h' option
do
	case $option in
		(h)
			FLAG='h'
			shift
			;;
		(v)
			FLAG='v'
			shift
			;;
		(*)
			echo -e "Error: Invalid Option Provided\n"
			exit 0
			;;
	esac
done

if [ "$FLAG" = "h" ]
then 
	echo "Minecraft Server Installation Script"
	echo "Usage: ./install_server.sh [Flags] [Server Name]"
	
	echo "[Flags]:"
	echo "          -h: Help"
	echo "              Prints help information regarding usage of this script"
	echo "          -v: Verbose"
	echo "              Prints all command messages to terminal"

	echo "[Server Name]: The name you wish to give to the server you intend to install"
	
	exit 1
fi

#Set a variable with the server name you want and download link on minecrafts website
NAME=${1?Error: No Server Name Provided}
SERVER_DIR=/opt/minecraft/$NAME

if [ "$FLAG" = "v" ]
then
	GEN_OUTPUT=/dev/stdout 
	STATUS_OUTPUT=/dev/null
else
	GEN_OUTPUT=/dev/null
	STATUS_OUTPUT=/dev/stdout
fi

echo "Beginning Installation" 		#-e option permits echo to recognise backslash as a formatting argument
echo "Server Name: $NAME"			
echo -ne "Status: 0%[                                           	     ]  \r"	&> $STATUS_OUTPUT

echo -e "\nInstalling/Updating required packages"			&> $GEN_OUTPUT
#Install Libraries required
if ! apt update 					-y 	&> $GEN_OUTPUT				
then
	echo "Error: Unable to Download update list. Did you forget sudo?"
	exit 0
fi

echo -ne "Status: 5%[=>                                                ]  \r"	&> $STATUS_OUTPUT

if ! apt-get install openjdk-8-jdk 			-y	&> $GEN_OUTPUT	
then
	echo "Error: Unable to install openjdk"
	exit 0
fi

echo -ne "Status: 10%[====>                                             ]  \r"	&> $STATUS_OUTPUT

if ! apt install wget screen default-jdk nmap 		-y	&> $GEN_OUTPUT	
then
	echo "Error: Unable to install screen & nmap"
	exit 0
fi

echo -ne "Status: 15%[=======>                                          ]  \r"	&> $STATUS_OUTPUT

if ! apt-get install jq 				-y	&> $GEN_OUTPUT	
then
	echo "Error: Unable to intall jq"
	exit 0
fi

echo -ne "Status: 20%[=========>                                        ]  \r"	&> $STATUS_OUTPUT

if ! apt-get install wget 				-y	&> $GEN_OUTPUT	
then
	echo "Error: Unable to install wget"
	exit 0
fi

echo -ne "Status: 25%[=========>                                        ]  \r"	&> $STATUS_OUTPUT

echo "Creating New Minecraft User Account"			&> $GEN_OUTPUT
#Checks if the minecraft user account does not already exist
if [ ! -d /opt/minecraft ]
then 
	#Create the minecraft user
	if ! useradd -m -r -d /opt/minecraft minecraft
	then
		echo "Error: Unable to create new minecraft user"
		exit 0
	fi
fi

#Checks if the server folder with the same server name exists
if [ -d $SERVER_DIR ]
then
	#Deletes it if it exists
	rm -r $SERVER_DIR
fi	

#Makes the server folder under the new minecraft user account
mkdir $SERVER_DIR

#Gives minecraft full ownership of the minecraft folder
chown -R minecraft /opt/minecraft
echo -ne "Status: 30%[===================>                              ]  \r"	&> $STATUS_OUTPUT

#Download the latest version_manifest.json
echo "Downloading Latest Server Version Information"				&> $GEN_OUTPUT
if ! wget -q https://launchermeta.mojang.com/mc/game/version_manifest.json	&> $GEN_OUTPUT
then
	echo "Unable to download the server manifest information"
	exit 0
fi

#Get the latest release version number
VER=$(jq -r '.latest.release' version_manifest.json)

#Create the jq command to extract the <latest_release_version>.json url
MANIFEST_JQ=$(echo "jq -r '.versions[] | select(.id == \"$VER\") | .url' version_manifest.json")
#echo $VER.json - jq command: $MANIFEST_JQ

#Query the <latest_release_version>.json url
MANIFEST_URL=$(eval $MANIFEST_JQ)
#echo $VER.json - URL:$MANIFEST_URL
    
#Download the <latest_release_version>.json
if ! wget -q $MANIFEST_URL						&> $GEN_OUTPUT
then
	echo "Unable to download the latest release version information"
	rm *.json
	exit 0
fi

#Create the jq command to extract the latest server download URL from the <latest_release_version>.json
DOWNLOAD_JQ=$(echo "jq -r .downloads.server.url $VER.json")
#echo Latest download jq command - $DOWNLOAD_JQ

#Query and get the latest release server.jar download URL
DOWNLOAD_URL=$(eval $DOWNLOAD_JQ)
#echo Latest download URL: $DOWNLOAD_URL

#Download the latest server
echo "Downloading Server: Version $VER"					&> $GEN_OUTPUT
if ! wget $DOWNLOAD_URL -P $SERVER_DIR					&> $GEN_OUTPUT
then
	echo "Unable to download the server file"
	rm *.json
	exit 0
fi

#Gives minecraft full ownership of the server folder
chown -R minecraft $SERVER_DIR
echo -ne "Status: 60%[=============================>                    ]  \r"	&> $STATUS_OUTPUT

#Stores current directory
SCRIPT_DIR=$(cd "scripts"; pwd -P)

#Moves to server directory
cd $SERVER_DIR

#Create a current_ver.txt file to be used to keep track of current server version
echo $VER > current_ver.txt

#Disabled exit upon error
set +e 

echo "Note: Initial server bootup. Errors upon initial server bootup are expected and should be ignored"	&> $GEN_OUTPUT 
#Run the server for the first time
java -Xmx2048M -Xms2048M -jar $SERVER_DIR/server.jar nogui	&> $GEN_OUTPUT	

#Enable exit upon error
set -e

echo -ne "Status: 90%[============================================>     ]  \r"	&> $STATUS_OUTPUT

#Edit the eula.txt file
sed -i 's/false/true/g' $SERVER_DIR/eula.txt

#Make a folder to house the scripts
mkdir scripts

#Return to install script folder
cd $SCRIPT_DIR

#copy the systemd file for automated startup/backup of the server on bootup
cp minecraft@.service /etc/systemd/system

#Copy the server update script to the server folder
cp update_server.sh $SERVER_DIR/scripts

#Make the scripts executable
chmod +x $SERVER_DIR/scripts/update_server.sh

#Copy the boot backup script to the server folder
cp backup.sh $SERVER_DIR/scripts

#Make the backup script executable
chmod +x $SERVER_DIR/scripts/backup.sh

#Enable the systemd script to run on bootup
systemctl enable minecraft@$NAME

#Delete temporary .json files
cd ..
rm *.json

echo -ne "Status: 100%[=================================================>]  \r\n"	&> $STATUS_OUTPUT

echo "Installation Complete. Enjoy your server!"


