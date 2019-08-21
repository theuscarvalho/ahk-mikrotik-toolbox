# ahk-mikrotik-toolbox
MSP focused toolbox for managing MikroTik routers and switches.

### Dependencies: ###
- [Winbox](https://mikrotik.com/download)

## Usage ##
Command Line Flags:

`-backup` - Automatically backs up all routers in the database using the commands found in /scripts/backup.txt

'-backupDB' Automatically backs up the SQLite database to backups\DB

`-firmware` - Automatically updates the RouterBoard firmware of each router in the database

`-ros` - Automatically updates all RouterOS packages on each router in the database and reboots

`-group <group>` - Selects a grouping of routers to execute commands on (Optional)

## Screenshots ##
![MTToolbox](https://i.imgur.com/QIpE5fk.png)
![Client Editing](https://i.imgur.com/AnFntYR.png)
