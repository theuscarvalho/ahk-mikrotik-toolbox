# ahk-mikrotik-toolbox
MSP focused toolbox for managing MikroTik routers and switches.

### Dependencies: ###
- [SQLite](https://www.sqlite.org/download.html)
- [Plink](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html)
- [Winbox](https://mikrotik.com/download)

## Usage ##
Command Line Flags:

`-backup` - Automatically backs up all routers in the database using the commands found in /scripts/backup.txt

`-firmware` - Automatically updates the RouterBoard firmware of each router in the database

`-ros` - Automatically updates all RouterOS packages on each router in the database and reboots

`-group <group>` - Selects a grouping of routers to execute commands on (Optional)

## Screenshots ##
![MTToolbox](https://i.imgur.com/8fuSMfj.png)
![Client Editing](https://i.imgur.com/w7hPvHd.png)
![DB Utility](https://i.imgur.com/4iJ2upu.png)
