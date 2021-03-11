# Important Note
Sometime ago, I decided to setup my own minecraft server. Mostly I wanted to make a server my friends and I could play on but also to just understand how to set up a server on linux. I decided to set it up on my brother's old laptop. This leads me to the main point: 
**This project was designed to be a learning experience. Please bear that in mind if you decide to use it to setup your own server.**. 

I have included references to sites I used at the end. Cheers!

## Table of Contents
1. Introduction
    1. Coding Concepts Used
    2. Hardware Used
    3. Instructions
2. Installation Script 
    1. Libraries required
    2. Setting up the server 
    3. Automation
3.  Systemd script
4.  Backup Script
5.  Update Script
6.  Connecting to your server
    1. Server Properties
    2. Possible Issues
7. References
8. Future Scope


## Introduction
This project was made post update 1.16 of minecraft. I setup 2 servers on my laptop. One is a Survival server and the other a creative one designed to handle up to 15 players each. My servers are designed to make a backup upon bootup of the laptop. This backup happens every bootup regardless of potential updates. I wanted to protect my world from corruption in case the laptop failed for any reason.

Afterwards, they query minecraft's website to check for any updates. If an update is found, they create another backup in a different directory and install the update automatically. This backup is done on the off chance that my world gets corrupted during the transition from an older version of minecraft to the latest. Once complete, the servers starts up.

These features can be considered unnecessary but I implemented them more to learn than anything.

### Coding concepts used
Don't worry if you have no idea about these. I didn't either. I'll try and explain each bash script and systemd file. 

- bash
    
    It stands for Bourne Again Shell. Basically it is used to write scripts that can be used to perform various tasks on your computer automatically. Shell scripting forms the core of this project

- systemd

    systemd files or units are text files that can create and manipulate various services running on your computer at bootup. The systemd file here runs on bootup to call the backup and update scripts and start the server.
    
- vi/vim

    vi comes standard with most linux distributions. It's basically a text editor like notepad but which runs on the command line. vim is vi but with a lot more features. Knowing how to use this is actually quite essential for software development on Linux. A simple cheat sheet of commands can be found [here](https://www.cs.cmu.edu/~15131/f17/topics/vim/vim-cheatsheet.pdf)
    
- Terminal / Command line

    Knowing basic terminal commands is essential here. Traversing directories, creating directories, taking ownership of folders etc. Thankfully there are a lot of online resources like [this](https://www.geeksforgeeks.org/basic-shell-commands-in-linux/).

- json files

    json stands for Javascript Object Notation. It is a popular format to store data structures. It allows for the storage of a lot of information in a well structured manner to enable ease of access to said information. We will use it to access information on the latest minecraft release versions as well as the url's to download said server versions.
    
### Hardware Used
I have listed the specs of the laptop used to run the two servers. Mojang already provides a good reference of resources required to run a server [here](https://minecraft.gamepedia.com/Server/Requirements).

- 64 bit Intel Core i5 @ 2.3 Ghz
- 16 GB Ram
- OS: Ubuntu 20.04

### Instructions 
You will find an installation script called "install_server.sh".
Here is the command: `sudo ./install_server.sh "Server_Name"`.

There are two additonal options you can run the command with:

- `sudo ./install_server.sh -h` will print help messages regarding the usage of this script.

- `sudo ./install_server.sh -v "Server_Name"` will run the script in verbose mode. Instead of a simple status bar showing progress, it will show intricate details of whats going on.

Thats all! The remaining portion of this article gives a breakdown of the scripts and what they are doing.

## Installation Script
The installation script forms the heart of this project. It installs the necessary libraries, copies the update and backup scripts to appropriate folders, downloads the minecraft server, creates a minecraft user account and implements the systmd scripts.

### Libraries required
The following code in the script implements the libraries required to install and run the server and scripts.

```bash
apt update
apt upgrade
apt install openjdk-8-jdk
apt install wget screen default-jdk nmap
apt install jq
```
So let's explain each line.
`apt update` basically fetches a list of updates to various software and libraries that can be downloaded and installed.

`apt upgrade` installs said updates.

`apt install openjdk-8-jdk` openjdk is an open source java runtime environment required by the server. This command installs it.

`apt install wget screen default-jdk nmap` This will install **screen** which will give us access to the serial console of the server. This will allow us to write commands to the server similar to how we would do it through the in-game chat. **nmap** is a network debug tool that can be used later for debugging.

`apt install jq` will install **jq**. To check the latest update version, we will download a json file from Mojang. jq is used to interpret that.

### Setting up the server
This involves two main operations. First we will create a separate user account for your servers. Then we will download and run it for the first time.

#### The minecraft user account

```bash
useradd -m -r -d /opt/minecraft minecraft
mkdir /opt/minecraft/$NAME
chown -R minecraft /opt/minecraft
```
`useradd -m -r -d /opt/minecraft minecraft` creates a new user account named minecraft. All your servers will come under this account.

`mkdir /opt/minecraft/$NAME` makes a folder in the opt/minecraft directory with a server name stored in the variable called "NAME" assigned earlier in the script. For each server, a new folder is created here.

`chown -R minecraft /opt/minecraft` gives the minecraft user account ownership of this minecraft folder where all your servers lie.

####  Downloading the server
This is where things get a little complicated.

```bash
wget -q https://launchermeta.mojang.com/mc/game/version_manifest.json
VER=$(jq -r '.latest.release' version_manifest.json)
MANIFEST_JQ=$(echo "jq -r '.versions[] | select(.id == \"$VER\") | .url' version_manifest.json")
MANIFEST_URL=$(eval $MANIFEST_JQ)
wget -q $MANIFEST_URL
DOWNLOAD_JQ=$(echo "jq -r .downloads.server.url $VER.json")
DOWNLOAD_URL=$(eval $DOWNLOAD_JQ)
wget $DOWNLOAD_URL -P $SERVER_DIR	
```
`wget -q https://launchermeta.mojang.com/mc/game/version_manifest.json` downlaods the version_manifest.json file. This files contains information on various release versions of the minecraft server, including information on the latest release version. 

`VER=$(jq -r '.latest.release' version_manifest.json)` searches the version_manifest.json file for the element called "release" within a structure called "latest". Effectively it searches for the latest release version and returns it into a variable called "VER".

`MANIFEST_JQ=$(echo "jq -r '.versions[] | select(.id == \"$VER\") | .url' version_manifest.json")` searches for the download url of another .json file continaing information specific to the server version we wish to download. Let's break it down further:

`echo "jq -r '.versions[] ` searches for the structure called "versions". Once found `select(.id == \"$VER\")` searches the "id" element within the "versions" structure. It keeps searching till it find an id matching the "VER" variable value. Remember, we found the latest minecraft version and placed it in the "VER" variable earlier. Finally, `.url' version_manifest.json"` accesses the "url" element within the "id" structure. This is url of the .json file of the latest server we wish to download. 

`MANIFEST_URL=$(eval $MANIFEST_JQ)` executes the command above and places the server .json file download url in the variable "MANIFEST_URL".

`wget -q $MANIFEST_URL` downloads the server .json based on the url extracted.

`DOWNLOAD_JQ=$(echo "jq -r .downloads.server.url $VER.json")` searches the server specific .json file for the element "url" in the "server" structure found within the "downloads" structure. 

`DOWNLOAD_URL=$(eval $DOWNLOAD_JQ)` executes the above command and placed the download url for the server in a variable called "DOWNLOAD_URL".

`wget $DOWNLOAD_URL -P $SERVER_DIR` used the download link to download the server into the directory mentioned in the "SERVER_DIR" variable. We previously set it to the directory we want to install our server in.

With that done, we now have our server file called "server.jar". Dont worry about .jar. It means its just a compressed file.

#### Running the Server for the first time

Next, let's run your server for the first time. **Spoiler alert: It will not run.** 

```bash
java -Xmx1024M -Xms1024M -jar $SERVER_DIR/server.jar nogui
sed -i 's/false/true/g' $SERVER_DIR/eula.txt
```

`java -Xmx1024M -Xms1024M -jar server.jar nogui` runs your server. Some points to note:

- `-Xmx1024M -Xms1024M` specify how much RAM to reserve for the server. In this case, 1GB. Since this is for the initial server bootup, it doesnt matter. Later on, in the systemd file, you can adjust it according to your hardware specs.

- `nogui` ensures that the GUI does not run, i.e. no graphical application will run in your screen. 

Anyway, your server fails to start. In the folder, a eula.txt has been created. This text file has a line "eula=false".

`sed -i 's/false/true/g' $SERVER_DIR/eula.txt` edits the eula.txt and sets "eula=true". This indicates that you accept the terms and conditions for using this server.

Next time we run the server, it will work fine.

**Congratulations! Your server is installed!**

### Automation
Here we move the systmd file to the appropriate folder and enable it to be called on bootup of the laptop. We move the backup and update scripts to a folder called "Scripts" in the server folder.

```bash
cp minecraft@.service /etc/systemd/system
cp update_server.sh $SERVER_DIR/scripts
chmod +x $SERVER_DIR/scripts/update_server.sh
cp backup.sh $SERVER_DIR/scripts
chmod +x $SERVER_DIR/scripts/backup.sh
systemctl enable minecraft@$NAME
```
`cp minecraft@.service /etc/systemd/system` copies the systmd file to the system directory.

`systemctl enable minecraft@$NAME` will enable this script to be run on bootup for the server whose name is stored in the variable "NAME" assigned previously in the script.

`cp update_server.sh $SERVER_DIR/scripts` Copies the update_server script to the scripts folder in the server directory.

`cp backup.sh $SERVER_DIR/scripts` Copies the backup script to the scripts folder in the server directory.

`chmod +x $SERVER_DIR/scripts/update_server.sh` Tells linux that update_server is a script that can be executes like a program.

`chmod +x $SERVER_DIR/scripts/backup.sh` Tells linux that backup is a script that can be executes like a program.

### Systemd script
This script is called on bootup. It runs the backup and update scripts and then runs the server. Upon shutdown, it runs commands to shutdown the server safely first.

```Bash
ExecStartPre=/bin/bash /opt/minecraft/%i/backup.sh
ExecStartPre=/bin/bash /opt/minecraft/%i/update_server.sh
ExecStart=/usr/bin/screen -DmS mc-%i /usr/bin/java -Xmx6G -Xms6G -jar server.jar gui
```

`ExecStartPre=/bin/bash /opt/minecraft/%i/backup.sh` Runs the backup script.

`ExecStartPre=/bin/bash /opt/minecraft/%i/update_server.sh` Runs the server update script.

`ExecStart=/usr/bin/screen -DmS mc-%i /usr/bin/java -Xmx6G -Xms6G -jar server.jar nogui` Boots the server. Note: My implementation allocates 6GB ram. You will have to edit this command based on your hardware requirements. This file can be found in the directory `/etc/systemd/system`. 

Call the following command to edit this file in vim directly: `vim /etc/systemd/system/minecraft@.service` and edit it accordingly. 

```Bash
ExecStop=/usr/bin/screen -p 0 -S mc-%i -X eval 'stuff "say Shutown request approved. Server is shutting down in 15 seconds..."\015'
ExecStop=/bin/sleep 15
ExecStop=/usr/bin/screen -p 0 -S mc-%i -X eval 'stuff "save-all"\015'
ExecStop=/usr/bin/screen -p 0 -S mc-%i -X eval 'stuff "stop"\015'
```
`ExecStop=/usr/bin/screen -p 0 -S mc-%i -X eval 'stuff "say Shutown request approved. Server is shutting down in 15 seconds..."\015'` Prints a messsage in the game that the server is shutting down within 15 seconds to alert any users on the server.

`ExecStop=/bin/sleep 15` Pauses the shutdown process for 15 seconds.

`ExecStop=/usr/bin/screen -p 0 -S mc-%i -X eval 'stuff "save-all"\015'` Calls the command to save any changes on the server since bootup.

`ExecStop=/usr/bin/screen -p 0 -S mc-%i -X eval 'stuff "stop"\015'` Calls the command to shutdown the server.

### Backup Script
The backup script copies the current server folder, compresses it and places it in a backup directory with the server name. By default this script generates a folder called "boot_server_backup' for every backup made on bootup. With the 'u' option, it creates a folder called "update_server_backup" to be used by the update server script.

The initial section of the script involves creating the backup folder. The core commands to generate the backup are as follows:

`find "${BACKUP_PATH}/${SERVER_FOLDER_NAME}/" -type f -name '*.gz' -delete` Searches for a file of type ".gz" in the server backup directory and deletes it. ".gz" refers to a compressed file which in our case is a copy of the server folder. This is used to delete an older backup before saving a new backup of the server.

`tar -cpzf "${SERVER_FOLDER_NAME}"-$(date +%F-%H-%M).tar.gz  ${SERVER_FOLDER_NAME}` Generates a compressed copy of the current server folder. It appends the current date and time to the name of the server folder when naming this new compressed file. It stores this file in the server backup directory.

### Update Script
The update script follows similar steps to the install script to check for a new server update. It then calls the backup script with the 'u' option to generate a backup of the server. It then follows similar steps as in the install script to update the server. (Refer to **Downloading the server**)

### Connecting to your server
Now that it's running, lets login! Let's run through a checklist to make sure your hardware is setup.

1. Make sure both your server and computer are on a LAN. This can include connecting to the same router via wifi and/or ethernet though ofcourse ethernet is preferred. 
2. Identify the IP address of your server. You can do this by typing `hostname -I` on your server terminal or by checking your router's manager, generally having the IP: 192.168.0.1
3. Go to your minecraft client, access multiplayer and put in this IP. You should be good to go from here. 

### Server Properties
There are several options to adjust your server to your liking. They can be found in the **server.properties** file in your server folder. More information can be found [here](https://minecraft.gamepedia.com/Server.properties)

One of particular importance is the port setting. By default the server port is 25565. However, if you have multiple servers running, they will each require a different port number. The IP address will be common since they are running on the same host computer. As an example:

- Server 1 can have port id 25565
- Server 2 can have port id 25564

And yet they can both share the same IP say 192.168.137.62

Thus if you want to connect to one through your minecraft client, type the IP of each server as: {Host Computer IP Address}:{Server Port ID}

### Possible Issues
Here are 2 issues I encountered

1. **Linux Permissions:** At some point during this setup you might encounter a permissions denied message. Remember to call the script using `sudo` to gain super user privilges for the script.
2. **Timeout Issue:** When connecting to my server through my router, I often got a timeout error from the server due to missing packets. After some research I found 2 possible issues.
    1. **Antivirus:** You may have to add minecraft to your antivirus exceptions list
    2. **Router:** I found my router was throttling my connection to my server for some reason. My work around? I enabled my wifi hotspot on my computer and had my server connect to it automatically. This created my laptops personal LAN and it works splendidly.
    
**And thats it. Congratulations! You're all done!**
If you are interested in understanding more about what's going on under the hood, I recommend opening up the scripts. The comments should help you get a better idea of the logic.

## References
I am including various repositories, blogs and websites I found very helpful in figuring all this out. You will find a lot of similarities between my methods and theirs.

- [How to setup Minecraft server on Ubuntu 18.04 Bionic Beaver Linux](https://linuxconfig.org/how-to-setup-minecraft-server-on-ubuntu-18-04-bionic-beaver-linux) by Lubos Rendek

- [How to Install Minecraft Server on Ubuntu 18.04](https://linuxize.com/post/how-to-install-minecraft-server-on-ubuntu-18-04/)

- [Backing Up Your Minecraft Server in Ubuntu](http://www.scaine.net/site/2013/08/backing-up-your-minecraft-server-in-ubuntu%EF%BB%BF%EF%BB%BF/) by scaine

- [Using a script to update the Minecraft server.jar](https://www.atpeaz.com/using-a-script-to-update-the-minecraft-server-jar/) by By Ken NG

## Future Scope
Currently this server is only accessible through LAN. An avenue I am looking at is using port forwarding to have friends access my server through the internet. Still, no concrete plans there.

Thank you so much for checking this out. Any feedback or constructive criticism would be very much appreciated!
