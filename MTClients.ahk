#Include Class_SQLiteDB.ahk
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

Gui, Add, GroupBox, xp+6 yp+5 w550 h750, Commands
Gui, Add, Edit, xp+5 yp+20 r1 w160 vName, Friendly Name
Gui, Add, Edit, yp+25 r1 w160 vHostname, Hostname
Gui, Add, Edit, yp+25 r1 w160 vUsername, Username
Gui, Add, Edit, yp+25 r1 w160 vPassword, Password
Gui, Add, Button, yp+25 r1 w160 gAdd, Add Client
Gui, Add, Button, yp+25 w160 gUpdate, Update Config
Gui, Add, Button, yp+25 w160 gDelete, Delete Client
Gui, Add, Button, yp+25 w160 gRetrieve, Retrieve Selected
Gui, Add, Button, yp+25 w160 gImport, Import Clients
Gui, Add, Button, yp+25 w160 gExport, Export Clients
Gui, Add, Button, yp+25 w160 gQuit, Quit Editing
Gui, Add, ListView, yp-235 xp+165 w375 h735 -Multi vClients, Name|Hostname|Username|Password

Devices := New SQLiteDB
if !Devices.OpenDB("devices.db", "W", false)
{
  Devices.OpenDB("devices.db")
  Devices.Exec("CREATE TABLE tb_devices(name String, hostname String, username String, password String, tier String, manufacturer String, os String, firmware String, zip String, contactname String, contactemail String, bstatus String, model String);")
}
Devices.GetTable("SELECT * FROM tb_devices;", table)
canIterate := true
while (canIterate == true)
{
  canIterate := table.Next(tableRow)
  name := tableRow[1]
  hostname := tableRow[2]
  username := tableRow[3]
  password := tableRow[4]
  if name
  {
    LV_Add("", name, hostname, username, password)
  }
}
Gui, Show,, Edit MT Clients

return

Clients:

Add:
  GuiControlGet, Name
  GuiControlGet, Hostname
  GuiControlGet, Username
  GuiControlGet, Password
  QUERY := "INSERT INTO tb_devices VALUES ('" . Name . "','" . Hostname . "','" . Username "','" . Password . "');"
  if Devices.Exec(QUERY)
  {
    LV_Add(, Name, Hostname, Username, Password)
  }
  return

Update:
  row := LV_GetNext()
  LV_GetText(oldhostname, row, 2)
  GuiControlGet, Name
  GuiControlGet, Hostname
  GuiControlGet, Username
  GuiControlGet, Password
  newName := Name
  newHostname := Hostname
  newUsername := Username
  newPassword := Password
  QUERY := "UPDATE tb_devices SET name = '" . newName . "' WHERE hostname = '" . oldhostname . "';"
  Devices.Exec(QUERY)
  QUERY := "UPDATE tb_devices SET username = '" . newUsername . "' WHERE hostname = '" . oldhostname . "';"
  Devices.Exec(QUERY)
  QUERY := "UPDATE tb_devices SET password = '" . newPassword . "' WHERE hostname = '" . oldhostname . "';"
  Devices.Exec(QUERY)
  LV_Modify(row,"",newName,oldhostname,NewUsername,newPassword)
Delete:
  row:= LV_GetNext()
  LV_GetText(DelHostname, RowNumber, 2)
  QUERY := "DELETE FROM tb_devices WHERE hostname='" . DelHostname . "';"
  if (Devices.Exec(QUERY))
  {
    LV_Delete(RowNumber)
  }
  return
Retrieve:
  row := LV_GetNext()
  LV_GetText(name, row, 1)
  LV_GetText(hostname, row, 2)
  LV_GetText(username, row, 3)
  LV_GetText(password, row, 4)
  GuiControl,, Name, %name%
  GuiControl,, Hostname, %hostname%
  GuiControl,, Username, %username%
  GuiControl,, Password, %password%
  return
Import:
  MsgBox, 4,, This will wipe your current database. Would you like to continue?
    IfMsgBox No
      return
  FileSelectFile, importTarget, 3
  QUERY := "DROP TABLE tb_devices;"
  Devices.Exec(QUERY)
  Devices.Exec("CREATE TABLE tb_devices(name String, hostname String, username String, password String, tier String, manufacturer String, os String, firmware String, zip String, contactname String, contactemail String, bstatus String, model String);")
  Loop, Read, %importTarget%
    {
      importArgs := StrSplit(A_LoopReadLine, ",")
      name := "'" . importArgs[1] . "'"
      hostname := "'" . importArgs[2] . "'"
      username := "'" . importArgs[3] . "'"
      password := "'" . importArgs[4] . "'"
      SQL := "INSERT INTO tb_devices VALUES (" . name . "," . hostname . "," . username . "," . password . ");"
      import := Devices.Exec(SQL)
    }
    LV_Delete()
    Devices.GetTable("SELECT * FROM tb_devices;", table)
    canIterate := true
    while (canIterate = true)
    {
      canIterate := table.Next(tableRow)
      name := tableRow[1]
      hostname := tableRow[2]
      username := tableRow[3]
      password := tableRow[4]
      if name
      {
        LV_Add("", name, hostname, username, password)
      }
    }
    return
Export:
  FileSelectFile, exportTarget, S
  Devices.GetTable("SELECT * FROM tb_devices;", table)
  canIterate := true
  while (canIterate != -1)
  {
    canIterate := table.Next(tableRow)
    name := tableRow[1]
    hostname := tableRow[2]
    username := tableRow[3]
    password := tableRow[4]
    row := name . "," . hostname . "," . username . "," . password . "`n"
    if name
    {
      FileAppend, %row%, %exportTarget%
    }
  }
  return

Quit:
  Devices.CloseDB()
  run, "MTToolbox.ahk"
  ExitApp
  return
return
GuiClose:
GuiEscape:
Devices.CloseDB()
ExitApp
