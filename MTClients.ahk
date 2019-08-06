#Include Class_SQLiteDB.ahk
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

Gui, Add, GroupBox, xp+6 yp+5 w1000 h750, Commands
Gui, Add, Text, xp+5 yp+15, Friendly Name
Gui, Add, Edit, yp+15 r1 w160 vName,
Gui, Add, Text, yp+25, Hostname
Gui, Add, Edit, yp+15 r1 w160 vHostname,
Gui, Add, Text, yp+25, Port
Gui, Add, Edit, yp+15 r1 w160 vPort,22
Gui, Add, Text, yp+25, Username
Gui, Add, Edit, yp+15 r1 w160 vUsername,
Gui, Add, Text, yp+25, Password
Gui, Add, Edit, yp+15 r1 w160 vPassword,
Gui, Add, Text, yp+25, Winbox Port
Gui, Add, Edit, yp+15 r1 w160 vWinport,8291
Gui, Add, Text, yp+25, Zip Code
Gui, Add, Edit, yp+15 r1 w160 vZip,
Gui, Add, Text, yp+25, Contact Name
Gui, Add, Edit, yp+15 r1 w160 vContactName,
Gui, Add, Text, yp+25, Contact Email
Gui, Add, Edit, yp+15 r1 w160 vContactEmail,
Gui, Add, Button, yp+25 r1 w160 gAdd, Add Client
Gui, Add, Button, yp+25 w160 gUpdate, Update Config
Gui, Add, Button, yp+25 w160 gDelete, Delete Client
Gui, Add, Button, yp+25 w160 gRetrieve, Retrieve Selected
Gui, Add, Button, yp+25 w160 gBlank, Blank Fields
Gui, Add, Button, yp+25 w160 gQuit, Quit Editing
Gui, Add, ListView, yp-490 xp+165 w825 h735 -Multi vClients, Name|Hostname|SSH Port|Username|Password|Winbox Port|Zip Code|Contact Name|Contact Email|uid

Devices := New SQLiteDB
if !Devices.OpenDB("devices.db", "W", false)
{
  Devices.OpenDB("devices.db")
  Devices.Exec("CREATE TABLE tb_devices(name String, hostname String, username String, password String, winport String, manufacturer String, os String, firmware String, zip String, contactname String, contactemail String, bstatus String, model String, port String, group String, uid String);")
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
  winport := tableRow[5]
  zip := tableRow[9]
  contactName := tableRow[10]
  contactEmail := tableRow[11]
  port := tableRow[14]
  uid := tableRow[16]
  if name
  {
    LV_Add("", name, hostname, port, username, password, winport, zip, contactName, contactEmail, uid)
  }
}
LV_ModifyCol(10, 0)
LV_ModifyCol(1, "AutoHdr")
LV_ModifyCol(1, "Sort")
Gui, Show,, Edit MT Clients

return

Clients:

Add:
  GuiControlGet, Name
  GuiControlGet, Hostname
  GuiControlGet, Username
  GuiControlGet, Password
  GuiControlGet, Winport
  GuiControlGet, Zip
  GuiControlGet, ContactName
  GuiControlGet, ContactEmail
  GuiControlGet, Port
  FormatTime, uid, ,yyMMddHHmmss
  if !Name or !Hostname or !Username or !Password or !Zip or !ContactName or !ContactEmail or !Port
  {
    MsgBox, You have a blank field, router not stored.
    return
  }
  QUERY := "INSERT INTO tb_devices VALUES ('" . Name . "','" . Hostname . "','" . Username . "','" . Password . "','" . Winport . "','MikroTik', '0', '0', '" . Zip . "', '" . ContactName . "', '" . ContactEmail . "', 'fail', '0', '" . Port . "', 'none', '" . uid . "');"
  if Devices.Exec(QUERY)
  {
    LV_Add(, Name, Hostname, Port, Username, Password, Winport, Zip, ContactName, ContactEmail, uid)
  }
  return

Update:
  row := LV_GetNext()
  LV_GetText(uid, row, 10)
  GuiControlGet, Name
  GuiControlGet, Hostname
  GuiControlGet, Username
  GuiControlGet, Password
  GuiControlGet, Winport
  GuiControlGet, Zip
  GuiControlGet, ContactName
  GuiControlGet, ContactEmail
  GuiControlGet, Port
  {
    MsgBox, You have a blank field, router config not updated.
    return
  }
  newName := Name
  newHostname := Hostname
  newUsername := Username
  newPassword := Password
  newWinport := Winport
  newZip := Zip
  newContactName := ContactName
  newContactEmail := ContactEmail
  newPort := Port
  QUERY := "UPDATE tb_devices SET hostname = '" . newHostname . "' WHERE uid = '" . uid . "';"
  Devices.Exec(QUERY)
  QUERY := "UPDATE tb_devices SET name = '" . newName . "' WHERE uid = '" . uid . "';"
  Devices.Exec(QUERY)
  QUERY := "UPDATE tb_devices SET username = '" . newUsername . "' WHERE uid = '" . uid . "';"
  Devices.Exec(QUERY)
  QUERY := "UPDATE tb_devices SET password = '" . newPassword . "' WHERE uid = '" . uid . "';"
  Devices.Exec(QUERY)
  QUERY := "UPDATE tb_devices SET winport = '" . newWinport . "' WHERE uid = '" . uid . "';"
  Devices.Exec(QUERY)
  QUERY := "UPDATE tb_devices SET zip = '" . newZip . "' WHERE uid = '" . uid . "';"
  Devices.Exec(QUERY)
  QUERY := "UPDATE tb_devices SET contactname = '" . newContactName . "' WHERE uid = '" . uid . "';"
  Devices.Exec(QUERY)
  QUERY := "UPDATE tb_devices SET contactemail = '" . newContactEmail . "' WHERE uid = '" . uid . "';"
  Devices.Exec(QUERY)
  QUERY := "UPDATE tb_devices SET port = '" . newPort . "' WHERE uid = '" . uid . "';"
  Devices.Exec(QUERY)
  LV_Modify(row,"",newName,newHostname,newPort,newUsername,newPassword,newWinport,newZip,newContactName,newContactEmail,uid)
  return
Delete:
MsgBox, 4,, Are you sure you want to delete this router from the database?
  IfMsgBox No
    return
  row := LV_GetNext()
  LV_GetText(DelUid, row, 10)
  QUERY := "DELETE FROM tb_devices WHERE uid='" . DelUid . "';"
  if (Devices.Exec(QUERY))
  {
    LV_Delete(row)
  }
  return
Retrieve:
  row := LV_GetNext()
  LV_GetText(name, row, 1)
  LV_GetText(hostname, row, 2)
  LV_GetText(port, row, 3)
  LV_GetText(username, row, 4)
  LV_GetText(password, row, 5)
  LV_GetText(winport, row, 6)
  LV_GetText(zip, row, 7)
  LV_GetText(contactName, row, 8)
  LV_GetText(contactEmail, row, 9)
  GuiControl,, Name, %name%
  GuiControl,, Hostname, %hostname%
  GuiControl,, Port, %port%
  GuiControl,, Username, %username%
  GuiControl,, Password, %password%
  GuiControl,, Winport, %winport%
  GuiControl,, Zip, %zip%
  GuiControl,, ContactName, %contactName%
  GuiControl,, ContactEmail, %contactEmail%
  return
Blank:
  GuiControl,, Name,
  GuiControl,, Hostname,
  GuiControl,, Port,22
  GuiControl,, Username,
  GuiControl,, Password,
  GuiControl,, Winport,8291
  GuiControl,, Zip,
  GuiControl,, ContactName,
  GuiControl,, ContactEmail,
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
