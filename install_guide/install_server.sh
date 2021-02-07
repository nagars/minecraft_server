#!/bin/bash

#sets flag to exit upon failure of any command
set -e

while getopts 'v:h:' option
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
			echo "Error: Invalid Option Provided\n"
			exit 0
			;;
	esac
done

if [ "$FLAG" = "h" ]
then 
	echo "Minecraft Server Installation Script"
	echo -e "Usage: ./install_server.sh [Flags] [Server Name] [Download Link]\n"
	
	echo "[Flags]:"
	echo "          -h: Help"
	echo -e "              Prints help information regarding usage of this script\n"
	echo "          -v: Verbose"
	echo -e "              Prints all command messages to terminal\n"

	echo -e "[Server Name]: The name you wish to give to the server you intend to install\n"
	echo -e "[Download Link]: The download link of the java server found on minecraft.net [https://www.minecraft.net/en-us/download/server/]\n"
	exit 1
fi

#Set a variable with the server name you want and download link on minecrafts website
NAME=${1?Error: No Server Name Provided}
DLINK=${2?Error: No Server Download Link Provided}
SERVER_DIR=/opt/minecraft/$NAME

if [ "$FLAG" = "v" ]
then
	OUTPUT=/dev/stdout 
else
	OUTPUT=/dev/null
fi

echo -e "Beginning Installation"
echo -e "Server Name: $NAME\n"
echo -ne "Status: 0%[                                                  	]  \r"

#Install Libraries required
if ! apt update 					-y 	&> $OUTPUT				
then
	echo -ne "Error: Unable to Download update list. Did you forget sudo? \n"
	exit 0
fi
echo -ne "Status: 5%[=>                                                 ]  \r"

if ! apt-get install openjdk-8-jdk 			-y	&> $OUTPUT	
then
	echo -ne "Error: Unable to install openjdk \n"
	exit 0
fi
echo -ne "Status: 10%[====>                                            	]  \r"

if ! apt install wget screen default-jdk nmap 		-y	&> $OUTPUT	
then
	echo -ne "Error: Unable to install screen & nmap \n"
	exit 0
fi
echo -ne "Status: 15%[=======>                                        	]  \r"

if ! apt-get install jq 				-y	&> $OUTPUT	
then
	echo -ne "Error: Unable to intall jq \n"
	exit 0
fi
echo -ne "Status: 20%[=========>                                        ]  \r"

if ! apt-get install wget 				-y	&> $OUTPUT	
then
	echo -ne "Error: Unable to install wget \n"
	exit 0
fi
echo -ne "Status: 25%[=========>                                        ]  \r"

#Checks if the minecraft user account does not already exist
if [ ! -d /opt/minecraft ]
then 
	#Create the minecraft user
	if ! useradd -m -r -d /opt/minecraft minecraft
	then
		echo -ne "Error: Unable to create new minecraft user \n"
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
echo -ne "Status: 30%[===================>                              ]  \r"

#Download the mineraft server
if ! wget $DLINK -P $SERVER_DIR					&> $OUTPUT
then
	echo -ne "Unable to download the server file. Check the link maybe? \n"
	exit 0
fi

#Gives minecraft full ownership of the server folder
chown -R minecraft $SERVER_DIR
echo -ne "Status: 60%[=============================>                    ]  \r"

#Stores current directory
CURR_DIR=$(pwd)

#Moves to server directory
cd $SERVER_DIR

#Disabled exit upon error
set +e 

#Run the server for the first time
java -Xmx1024M -Xms1024M -jar $SERVER_DIR/server.jar nogui	&> $OUTPUT	

#Enable exit upon error
set -e

echo -ne "Status: 90%[============================================>     ]  \r"

#Edit the eula.txt file
sed -i 's/false/true/g' $SERVER_DIR/eula.txt

#Make a folder to house the scripts
mkdir scripts

#Return to install folder
cd $CURR_DIR

#copy the systemd file for automated startup/backup of the server on bootup
cp minecraft@.service /etc/systemd/system

#Copy the server update script to the server folder
cp update_server.sh $SERVER_DIR/scripts

#Copy the update backup script to the server folder
cp update_backup.sh $SERVER_DIR/scripts

#Make the scripts executable
chmod +x $SERVER_DIR/scripts/update_server.sh
chmod +x $SERVER_DIR/scripts/update_backup.sh

#Copy the boot backup script to the server folder
cp backup.sh $SERVER_DIR/scripts

#Make the backup script executable
chmod +x $SERVER_DIR/scripts/backup.sh

#Enable the systemd script to run on bootup
systemctl enable minecraft@$NAME

echo -ne "Status: 100%[==================================================]  \r\n"

echo -e "Installation Complete. Enjoy your server!"


