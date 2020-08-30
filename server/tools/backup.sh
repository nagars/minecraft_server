#!/bin/bash

function rcon {
  /opt/minecraft/tools/mcrcon/mcrcon -H 127.0.0.1 -P 25575 -p creative "$1"
}

rcon "save-off"
rcon "save-all"
tar -cvpzf /opt/minecraft/backups/creative/server-$(date +%F-%H-%M).tar.gz /opt/minecraft/creative/
rcon "save-on"

## Delete older backups
find /opt/minecraft/backups/creative/ -type f -mtime +7 -name '*.gz' -delete
