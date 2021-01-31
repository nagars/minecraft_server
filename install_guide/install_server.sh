#!/bin/bash

#sets flag to exit upon failure of any command
set -e

#Set a variable with the name you want and download link provided 
NAME=${1?Error: No Server Name Provided}
DLINK=${2?Error: No Server Download Link Provided}
SERVER_DIR=/opt/minecraft/$NAME
SUPPRESS_OUTPUT=/dev/null

echo -e "Beginning Installation"
echo -e "Server Name: $NAME"
echo -ne "Status: 0%[                                                  ]  \r"

#Install Libraries required
#echo -e "\e[1;32m Installing required libraries \e[0m"
apt update 					-y 	&> $SUPPRESS_OUTPUT				
echo -ne "Status: 5%[=>                                                 ]  \r"
apt-get install openjdk-8-jdk 			-y	&> $SUPPRESS_OUTPUT	
echo -ne "Status: 10%[====>                                            	]  \r"
apt install wget screen default-jdk nmap 	-y	&> $SUPPRESS_OUTPUT	
echo -ne "Status: 15%[=======>                                        	]  \r"
apt-get install jq 				-y	&> $SUPPRESS_OUTPUT	
echo -ne "Status: 20%[=========>                                        ]  \r"
apt-get install wget 				-y	&> $SUPPRESS_OUTPUT	
#echo -e "\e[1;32m Finished \e[0m \n"
echo -ne "Status: 25%[=========>                                        ]  \r"

#echo -e "\e[1;32m Creating minecraft user account and server folder \e[0m"
#Checks if the minecraft user account does not already exist
if [ ! -d /opt/minecraft ]
then 
	#Create the minecraft user
	useradd -m -r -d /opt/minecraft minecraft
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
#echo -e "\e[1;32m Finished \e[0m \n"
echo -ne "Status: 30%[===================>                              ]  \r"

#echo -e "\e[1;32m Downloading server files \e[0m"
#Download the mineraft server
wget $DLINK -P $SERVER_DIR		&> $SUPPRESS_OUTPUT

#Gives minecraft full ownership of the server folder
chown -R minecraft $SERVER_DIR
#echo -e "\e[1;32m Finished \e[0m \n"
echo -ne "Status: 60%[=============================>                    ]  \r"

#echo -e "\e[1;32m Initial server run [Standby][Ignore Failure Messages] \e[0m"
#Stores current directory
CURR_DIR=$(pwd)

#Moves to server directory
cd $SERVER_DIR

#Disabled exit upon error
set +e 

#Run the server for the first time
java -Xmx1024M -Xms1024M -jar $SERVER_DIR/server.jar nogui	&> $SUPPRESS_OUTPUT	

#Enable exit upon error
set -e
#echo -e "\e[1;32m Finished \e[0m \n"
echo -ne "Status: 90%[============================================>     ]  \r"

#Edit the eula.txt file
sed -i 's/false/true/g' $SERVER_DIR/eula.txt

#Return to install folder
cd $CURR_DIR

#echo -e "\e[1;32m Copy essential scripts to the server folder \e[0"
#copy the systemd file for automated startup/backup of the server on bootup
cp minecraft@.service /etc/systemd/system

#Copy the server update script to the server folder
cp update_server.sh $SERVER_DIR

#Copy the update backup script to the server folder
cp update_backup.sh $SERVER_DIR

#Make the scripts executable
chmod +x $SERVER_DIR/update_server.sh
chmod +x $SERVER_DIR/update_backup.sh

#Copy the boot backup script to the server folder
cp backup.sh $SERVER_DIR

#Make the backup script executable
chmod +x backup.sh
#echo -e "\e[1;32m Finished \e[0m \n"

#Enable the systemd script to run on bootup
systemctl enable minecraft@$NAME
echo -ne "Status: 100%[==================================================]  \r\n"

echo -e "Installation Complete. Enjoy your server!"


