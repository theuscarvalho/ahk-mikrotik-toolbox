# ahk-mikrotik-toolbox
MSP oriented toolbox for managing Mikrotik routers and switches.

### Dependencies: ###
- [AHK-just-me's Class_SQLiteDB library](https://github.com/AHK-just-me/Class_SQLiteDB)
- [SQLite](https://www.sqlite.org/download.html)

## Usage ##
Command Line Flags:
`-backup` - Automatically backs up all routers in the database using the commands found in /scripts/backup.txt
(More will be added in the future)

GUI:
Everything should be fairly self explanatory. The database import uses the format friendly_name,hostname,username,password with one device per line.

## Screenshots ##
![MTToolbox](https://i.imgur.com/EaJ7dHd.png)
![Client Editing](https://i.imgur.com/k50qqrb.png)
