# ahk-mikrotik-toolbox
MSP oriented toolbox for managing MikroTik routers and switches.

### Dependencies: ###
- [AHK-just-me's Class_SQLiteDB library](https://github.com/AHK-just-me/Class_SQLiteDB)
- [SQLite](https://www.sqlite.org/download.html)
- [Plink](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html)

## Usage ##
Command Line Flags:

`-backup` - Automatically backs up all routers in the database using the commands found in /scripts/backup.txt

`-firmware` - Automatically updates the RouterBoard firmware of each router in the database

`-ros` - Automatically updates all RouterOS packages on each router in the database and reboots

## Screenshots ##
![MTToolbox](https://i.imgur.com/FGikxMk.png)
![Client Editing](https://i.imgur.com/bSPOjSZ.png)
![DB Utility](https://i.imgur.com/3ArQmT2.png)
