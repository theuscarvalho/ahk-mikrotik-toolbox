#Include Class_SQLiteDB.ahk
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

Gui, Add, GroupBox, xp+6 yp+5 w650 h750, Commands
Gui, Add, Text, xp+5 yp+15, Friendly Name
Gui, Add, Edit, yp+15 r1 w160 vName,
Gui, Add, Text, yp+25, Hostname
Gui, Add, Edit, yp+15 r1 w160 vHostname,
Gui, Add, Text, yp+25, Username
Gui, Add, Edit, yp+15 r1 w160 vUsername,
Gui, Add, Text, yp+25, Password
Gui, Add, Edit, yp+15 r1 w160 vPassword,
Gui, Add, Text, yp+25, Tier
Gui, Add, DropDownList, Choose1 yp+15 vTier, 0|1|2|3|4|5|6|7|8|9|10
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
Gui, Add, Button, yp+25 w160 gQuit, Quit Editing
Gui, Add, ListView, yp-425 xp+165 w475 h735 -Multi vClients, Name|Hostname|Username|Password|Tier|Zip Code|Contact Name|Contact Email

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
  tier := tableRow[5]
  zip := tableRow[9]
  contactName := tableRow[10]
  contactEmail := tableRow[11]
  if name
  {
    LV_Add("", name, hostname, username, password, tier, zip, contactName, contactEmail)
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
  GuiControlGet, Tier
  GuiControlGet, Zip
  GuiControlGet, ContactName
  GuiControlGet, ContactEmail
  newName := Name
  newHostname := Hostname
  newUsername := Username
  newPassword := Password
  newTier := Tier
  newZip := Zip
  newContactName := ContactName
  newContactEmail := ContactEmail
  QUERY := "UPDATE tb_devices SET name = '" . newName . "' WHERE hostname = '" . oldhostname . "';"
  Devices.Exec(QUERY)
  QUERY := "UPDATE tb_devices SET username = '" . newUsername . "' WHERE hostname = '" . oldhostname . "';"
  Devices.Exec(QUERY)
  QUERY := "UPDATE tb_devices SET password = '" . newPassword . "' WHERE hostname = '" . oldhostname . "';"
  Devices.Exec(QUERY)
  QUERY := "UPDATE tb_devices SET tier = '" . newTier . "' WHERE hostname = '" . oldhostname . "';"
  Devices.Exec(QUERY)
  QUERY := "UPDATE tb_devices SET zip = '" . newZip . "' WHERE hostname = '" . oldhostname . "';"
  Devices.Exec(QUERY)
  QUERY := "UPDATE tb_devices SET contactname = '" . newContactName . "' WHERE hostname = '" . oldhostname . "';"
  Devices.Exec(QUERY)
  QUERY := "UPDATE tb_devices SET contactemail = '" . newContactEmail . "' WHERE hostname = '" . oldhostname . "';"
  Devices.Exec(QUERY)
  LV_Modify(row,"",newName,oldhostname,NewUsername,newPassword,newTier,newZip,newContactName,newContactEmail)
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
  LV_GetText(tier, row, 5)
  LV_GetText(zip, row, 6)
  LV_GetText(contactName, row, 7)
  LV_GetText(contactEmail, row, 8)
  GuiControl,, Name, %name%
  GuiControl,, Hostname, %hostname%
  GuiControl,, Username, %username%
  GuiControl,, Password, %password%
  tier := tier + 1
  GuiControl, Choose, Tier, %tier%
  GuiControl,, Zip, %zip%
  GuiControl,, ContactName, %contactName%
  GuiControl,, ContactEmail, %contactEmail%
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
