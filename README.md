# Important Note
Sometime ago, I decided to setup my own minecraft server. Mostly I wanted to make a server my friends and I could play on but also to just understand how to set up a server on linux. I decided to set it up on my brother's old laptop. This leads me to the main point: 
**This project was designed to be a learning experience. Please bear that in mind if you decide to use it to setup your own server.**. 

I have included references to sites I used at the end. Cheers!

## Table of Contents
1. Introduction
    1. Coding Concepts Used
    2. Hardware Used
2. Instructions - Getting started
    1. Libraries required
    2. Setting up the server
    3. Connecting to your server
    4. Server Properties
    5. Possible Issues
3.  Instructions - Automated Features
    1. Automated Start-up
    2. Automated Server Backups
    3. Automated Server Update & Backups
4. References
5. Future Scope


## Introduction
This project was made post update 1.16 of minecraft. I setup 2 servers on my laptop. One is a Survival server and the other a creative one designed to handle up to 15 players each. My servers are designed to make a backup upon bootup of the laptop. This backup happens every bootup regardless of potential updates. I wanted to protect my world from corruption in case the laptop failed for any reason.

Afterwards, they query minecraft's website to check for any updates. If an update is found, they create a backup and install the update automatically. This backup is done on the off chance that my world gets corrupted during the transition from an older version of minecraft to the latest. Once complete, the servers starts up.

These features can be considered unnecessary but I implemented them more to learn than anything.

**I cover how to setup the survival server here. The creative server is just a repeat of these instructions.**

### Coding concepts used
Don't worry if you have no idea about these. I didn't either. I'll try and explain each bash script and systemd file. 

- bash
    
    It stands for Bourne Again Shell. Basically it is used to write scripts that can be used to perform various tasks on your computer automatically. We will used to create backup and update scripts

- systemd

    systemd files or units are text files that can create and manipulate various services running on your computer at bootup. The systemd file here runs on bootup to call the backup and update scripts and start the server.
    
- vi/vim

    vi comes standard with most linux distributions. It's basically a text editor like notepad but which runs on the command line. vim is vi but with a lot more features. Knowing how to use this is actually quite essential to write the text files in terminal.
    
- Terminal / Command line

    Knowing basic terminal commands is essential here. Traversing directories, creating directories, taking ownership of folders etc. Thankfully there are a lot of online resources like [this](https://www.geeksforgeeks.org/basic-shell-commands-in-linux/).

### Hardware Used
I have listed the specs of the laptop used to run the two servers. Mojang already provides a good reference of resources required to run a server [here](https://minecraft.gamepedia.com/Server/Requirements).

- 64 bit Intel Core i5 @ 2.3 Ghz
- 16 GB Ram
- OS: Ubuntu 20.04

## Instructions - Getting Started
So lets run through how to get your server running for the first time.

### Libraries required
Open up a terminal window (ctrl + alt + t). Type in the following:

```bash
sudo apt-get update
sudo apt upgrade
sudo apt-get install openjdk-8-jdk
sudo apt install wget screen default-jdk nmap
sudo apt-get install jq
```
So let's explain each line.
`sudo apt-get update` basically fetches a list of updates to various software and libraries that can be downloaded and installed.

`sudo apt upgrade` installs said updates.

`sudo apt-get install openjdk-8-jdk` openjdk is an open source java runtime environment required by the server. This command installs it.

`sudo apt install wget screen default-jdk nmap` This will install **screen** which will give us access to the serial console of the server. This will allow us to write commands to the server similar to how we would do it through the in-game chat. **nmap** is a network debug tool that can be used later for debugging.

`sudo apt-get install jq` will install **jq**. To check the latest update version, we will download a json file from Mojang. jq is used to interpret that.

### Setting up the server
This involves two main operations. First we will create a separate user account for your servers. Then we will download and run it for the first time.

#### The minecraft user account

```bash
sudo useradd -m -r -d /opt/minecraft minecraft
sudo mkdir /opt/minecraft/survival
sudo chown -R minecraft /opt/minecraft
```
`sudo useradd -m -r -d /opt/minecraft minecraft` creates a new user account named minecraft. All your servers will come under this account.

`sudo mkdir /opt/minecraft/survival` makes a folder named **survival** in the opt/minecraft directory. For each server, you will have to create a new folder here.

`sudo chown -R minecraft /opt/minecraft` gives the minecraft user account ownership of this minecraft folder where all your servers lie.

####  Setting up the server
You can find the server on your browser from their website [here](https://www.minecraft.net/en-us/download/server). There are two ways to get it to your server folder:

| Option 1                 | Option 2              |
| :----------------------: | :-------------------: |
| Once downloaded, navigate to your download folder in terminal, then copy it from your download folder to your server folder (/opt/minecraft/survival) using  `cp (FILE_NAME).jar /opt/minecraft/survival` | Alternatively, you can download it directly in to your server folder through the terminal by copying the download link. The command `wget <link> /opt/mineraft/survival` will download the .jar file into your server folder. |

Dont worry about .jar. It means its just a compressed file.

Next, let's run your server for the first time. **Spoiler alert: It will not run.** 

In your server folder, run `java -Xmx1024M -Xms1024M -jar (FILE_NAME).jar nogui` to run your server. Some points to note:

- `-Xmx1024M -Xms1024M` specify how much RAM to reserve for the server. In this case, 1GB. I recommend adjusting this according to you hardware resources available.

- `nogui` ensures that the GUI does not run, i.e. no graphical application will run in your screen. 

Anyway, your server fails to start. You will notice in the folder that a eula.txt has been created. **Edit it and set eula to true.** Use `vi eula.txt ` to open the editor and make the adjustments.

Try running the server again. It should work fine this time. If you want to see some runtime information, shutdown the server and restart it with the command `java -Xmx1024M -Xms1024M -jar (FILE_NAME).jar gui`. Notice `nogui` is missing. A screen with information such as memory used etc. regarding your new server session will come up. 

**Congratulations! Your server is running!**

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

1. **Linux Permissions:** At some point during this setup you might encounter a permissions denied message. You may need to become a super user using `sudo su`.
2. **Timeout Issue:** When connecting to my server through my router, I often got a timeout error from the server due to missing packets. After some research I found 2 possible issues.
    1. **Antivirus:** You may have to add minecraft to your antivirus exceptions list
    2. **Router:** I found my router was throttling my connection to my server for some reason. My work around? I enabled my wifi hotspot on my computer and had my server connect to it automatically. This created my laptops personal LAN and it works splendidly.
    
## Instructions - Automated Features
Let's move on to automating the starting, stopping, updating and backup of our server.

### Automated Start-up
Included in the **install_guide** folder is a file called **minecraft@.service**. This is a systemd file that is executed upon boot-up of the computer. It's primary job is to call the scripts to backup and update the server and finally start the server.

Copy this file to your system folder(/etc/systemd/system/) using `cp minecraft@.service /etc/systemd/system` in terminal. 

To ensure that it runs on boot-up, run `sudo systemctl enable minecraft@survival` in terminal. **Make sure your server name matches the folder name of your server**

Some basic systemctl commands that will help with troubleshooting are listed here:
 1. `sudo systemctl start minecraft@survival` will start your server through command line.
 2. `sudo systemctl status minecraft@survival` will return information regarding the current status of your server. It will report failures if any.
 3. `sudo systemctl stop minecraft@survival` will shutdown your server.
 
**Note: Running the script at this step will fail as the backup and update scripts are not in place.** If you want to test it out anyway, please comment out lines 18 & 21 in the minecraft@.service file. The script will only have start and server shutdown functionality now.
 
### Automated Server Backups
This involves the backup of your server before every bootup. The backup will be placed in a folder called **boot_server_backups** in the /opt/minecraft folder. 

Copy the backup.sh script to your server directory using `cp backup.sh /opt/minecraft/survival`.

`chmod +x backup.sh` will make the script executable allowing to the systemd script to run it.

### Automated Server Update & Backups
This involves the backup of your server before every update. It will first check for a new version of the server. If there is one, it will back up and then update the server. The backup is placed in a folder called **update_server_backups** in the /opt/minecraft folder.

Copy the update_server.sh script to your server directory using `cp update_server.sh /opt/minecraft/survival`.
Copy the update_backup.sh script to your server directory using `cp update_backup.sh /opt/minecraft/survival`.

`chmod +x update_server.sh` will make the script executable allowing to the systemd script to run it.
`chmod +x update_backup.sh` will make the script executable allowing to the systemd script to run it.

**And thats it. Congratulations! You're all done!**
If you are interested in understanding more about what's going on under the hood, I recommend opening up the scripts. The comments should help you get an idea of the logic.

## References
I am including various repositories, blogs and websites I found very helpful in figuring all this out. You will find a lot of similarities between my methods and theirs.

- [How to setup Minecraft server on Ubuntu 18.04 Bionic Beaver Linux](https://linuxconfig.org/how-to-setup-minecraft-server-on-ubuntu-18-04-bionic-beaver-linux) by Lubos Rendek

- [How to Install Minecraft Server on Ubuntu 18.04](https://linuxize.com/post/how-to-install-minecraft-server-on-ubuntu-18-04/)

- [Backing Up Your Minecraft Server in Ubuntu](http://www.scaine.net/site/2013/08/backing-up-your-minecraft-server-in-ubuntu%EF%BB%BF%EF%BB%BF/) by scaine

- [Using a script to update the Minecraft server.jar](https://www.atpeaz.com/using-a-script-to-update-the-minecraft-server-jar/) by By Ken NG

## Future Scope
Many will point out that all this can be done by a single script. To reiterate, the point of this exercise was for me to learn and understand. It is labourious by design. That being said, the next step for me at least is to write a bash script to do all this. I am not sure when I will find time between work and other responsibilities but I hope to have it done within a month. Let's see.

Another avenue I am looking at is using port forwarding to have friends access my server through the internet. Still, no concrete plans there.

Thank you so much for checking this out. Any feedback or constructive criticism would be very much appreciated. Thanks!
