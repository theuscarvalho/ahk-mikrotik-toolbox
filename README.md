# ahk-mikrotik-toolbox
MSP oriented toolbox for managing Mikrotik routers and switches.

### Dependencies: ###
- [AHK-just-me's Class_SQLiteDB library](https://github.com/AHK-just-me/Class_SQLiteDB)
- [SQLite](https://www.sqlite.org/download.html)

## Usage ##
For first time usage, you will have to import a database. My apologies, I just haven't gotten around to having it get automatically created quite yet. The format for doing so is a text file formatted with one device per line with the format friendlyname,hostname,username,password

Importing is done through the edit clients script or by clicking edit clients in the toolbox script.

Automatic backups can be done by using Windows task scheduler run the script with the flag `-backup`

Other than that, things can pretty much explain themselves, and I will be putting more effort into documenting things as I go.
