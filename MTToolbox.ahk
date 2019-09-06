#Include Class_SQLiteDB.ahk
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

;Variables for logging
formattime, date, , MM-dd-yy
ifNotExist, logs\
  FileCreateDir, logs\
logFile := "logs\" date . ".txt"

;Opens database and creates a new one if it does not currently exist
Devices := New SQLiteDB
if !Devices.OpenDB("devices.db", "W", false)
{
  Devices.OpenDB("devices.db")
  Devices.Exec("CREATE TABLE tb_devices(name String, hostname String, username String, password String, winport String, manufacturer String, os String, firmware String, zip String, contactname String, contactemail String, bstatus String, model String, port String, bGroup String, uid String);")
}
Devices.CloseDB()
CheckDBVersion()

;Deletes buffer and recreates directory on startup
FileRemoveDir buffer\, 1
FileCreateDir buffer

;The following loop and function handle processing of any command line flags.
Global Args := []
Loop, %0%
	Args.Push(%A_Index%)

Loop %0%
{
  If (ObjHasValue(Args, "-group"))
  {
    AutoRunGroup()
    break
  }
  If (ObjHasValue(Args, "-backupDB"))
  {
    BackupDB()
    ExitApp
  }
  If (ObjHasValue(Args, "-backup"))
  {
    writeLog("has initiated an automatic backup", "INFO")
		AutoRun("backup")
  }
  If (ObjHasValue(Args, "-firmware"))
  {
    writeLog("has initiated an automatic firmware upgrade", "WARNING")
		AutoRun("firmware")
  }
  If (ObjHasValue(Args, "-ros"))
  {
    writeLog("has initiated an automatic routerOS upgrade", "WARNING")
		AutoRun("rOS")
  }
}
ObjHasValue(Obj, Value, Ret := 0) {
	For Key, Val in Obj {
		If IsObject(Val) {
			If ObjHasValue(Val, Value)
				Return True
		} Else {
			If (InStr(Val, Value))
				If (Ret)
					Return Val
				Else
					Return True
		}
	}
	Return False
}

DrawMain:
  Gui, Main:Default
  Gui, Main:Add, GroupBox, xp+6 yp+5 w1000 h750, Commands
  Gui, Main:Add, Button, xp+5 yp+20 w120 gEdit, Edit Clients
  Gui, Main:Add, Button, yp+25 w120 gCommand, Run Command
  Gui, Main:Add, Button, yp+25 w120 gFirmware, Update Firmware
  Gui, Main:Add, Button, yp+25 w120 gRouterOS, Update RouterOS
  Gui, Main:Add, Button, yp+25 w120 gBackup, Run Manual Backup
  Gui, Main:Add, Button, yp+25 w120 gReboot, Reboot
  Gui, Main:Add, Button, yp+25 w120 gWinbox, Winbox Session
  Gui, Main:Add, Button, yp+25 w120 gPutty, SSH Session
  Gui, Main:Add, Button, yp+25 w120 gCopyHost, Copy Hostname
  Gui, Main:Add, ListView, yp-210 xp+125 w865 h735, Name|Hostname|Backup Status|OS Version|uid|Group
  OpenDB()
  Devices.GetTable("SELECT * FROM tb_devices;", table)
  canIterate := true
  while (canIterate == true)
  {
    canIterate := table.Next(tableRow)
    name := tableRow[1]
    hostname := tableRow[2]
    bStatus := tableRow[12]
    os := tableRow[7]
    group := tableRow[15]
    uid := tableRow[16]
    if name
    {
      LV_Add("", name, hostname, bStatus, os, uid, group)
    }
  }
  ;Wait to draw GUI until after flags are processed
  Gui, Main:Show,, MikroTik Toolbox
  ;Format the columns
  LV_ModifyCol(1, "AutoHdr")
  LV_ModifyCol(2, "AutoHdr")
  LV_ModifyCol(3, "AutoHdr")
  LV_ModifyCol(4, "AutoHdr")
  LV_ModifyCol(5, 0)
  LV_ModifyCol(6, "AutoHdr")
  LV_ModifyCol(1, "Sort")
  Devices.CloseDB()
  return

Edit:
  Gui, Main:Destroy
  Gui, Edit:Default
  writeLog("has clicked the edit clients button", "INFO")
  Gui, Edit:Add, GroupBox, xp+6 yp+5 w1000 h750, Commands
  Gui, Edit:Add, Text, xp+5 yp+15, Friendly Name
  Gui, Edit:Add, Edit, yp+15 r1 w160 vName,
  Gui, Edit:Add, Text, yp+25, Hostname
  Gui, Edit:Add, Edit, yp+15 r1 w160 vHostname,
  Gui, Edit:Add, Text, yp+25, SSH Port
  Gui, Edit:Add, Edit, yp+15 r1 w160 vPort,22
  Gui, Edit:Add, Text, yp+25, Username
  Gui, Edit:Add, Edit, yp+15 r1 w160 vUsername,
  Gui, Edit:Add, Text, yp+25, Password
  Gui, Edit:Add, Edit, yp+15 r1 w160 vPassword,
  Gui, Edit:Add, Text, yp+25, Winbox Port
  Gui, Edit:Add, Edit, yp+15 r1 w160 vWinport,8291
  Gui, Edit:Add, Text, yp+25, Group
  Gui, Edit:Add, Edit, yp+15 r1 w160 vGroup,none
  Gui, Edit:Add, Text, yp+25, Zip Code
  Gui, Edit:Add, Edit, yp+15 r1 w160 vZip,
  Gui, Edit:Add, Text, yp+25, Contact Name
  Gui, Edit:Add, Edit, yp+15 r1 w160 vContactName,
  Gui, Edit:Add, Text, yp+25, Contact Email
  Gui, Edit:Add, Edit, yp+15 r1 w160 vContactEmail,
  Gui, Edit:Add, Button, yp+25 r1 w160 gAdd, Add Client
  Gui, Edit:Add, Button, yp+25 w160 gUpdate, Update Config
  Gui, Edit:Add, Button, yp+25 w160 gDelete, Delete Client
  Gui, Edit:Add, Button, yp+25 w160 gRetrieve, Retrieve Selected
  Gui, Edit:Add, Button, yp+25 w160 gBlank, Blank Fields
  Gui, Edit:Add, Button, yp+25 w160 gBackupDB, Back Up Database
  Gui, Edit:Add, Button, yp+25 w160 gRestoreDB, Restore Database
  Gui, Edit:Add, Button, yp+25 w160 gQuit, Quit Editing
  Gui, Edit:Add, ListView, yp-580 xp+165 w825 h735 -Multi vClients, Name|Hostname|SSH Port|Username|Password|Winbox Port|Group|Zip Code|Contact Name|Contact Email|uid
  OpenDB()
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
    group := tableRow[15]
    uid := tableRow[16]
    if name
    {
      LV_Add("", name, hostname, port, username, password, winport, group, zip, contactName, contactEmail, uid)
    }
  }
  LV_ModifyCol(11, 0)
  LV_ModifyCol(1, "AutoHdr")
  LV_ModifyCol(1, "Sort")
  Gui, Edit:Show,, Edit MT Clients
  Devices.CloseDB()
  return

Command:
  writeLog("has clicked the command button", "INFO")
  FileSelectFile, commandTarget
  RowNumber := 0
  loop % LV_GetCount("S")
  {
    if not RowNumber
    {
      Rownumber := 0
    }
    RowNumber := LV_GetNext(RowNumber)
    LV_GetText(uid, RowNumber, 5)
    MultiCommand(uid, commandTarget)
  }
  return
Firmware:
  writeLog("has clicked the upgrade firmware button", "INFO")
  MsgBox, 4,, Are you sure you want to update firmware?
    IfMsgBox No
      return
  RowNumber := 0
  loop % LV_GetCount("S")
  {
    if not RowNumber
    {
      Rownumber := 0
    }
    RowNumber := LV_GetNext(RowNumber)
    LV_GetText(uid, RowNumber, 5)
    SingleCommand(uid, "/system routerboard upgrade")
  }
  MsgBox, Firmware upgrade commands have been sent, please reboot the routers to complete upgrade.
  return
RouterOS:
  writeLog("has clicked the upgrade routerOS button", "INFO")
  MsgBox, 4,, Are you sure you want to update these routers? This will automatically reboot them.
    IfMsgBox No
      return
  RowNumber := 0
  loop % LV_GetCount("S")
  {
    if not RowNumber
    {
      Rownumber := 0
    }
    RowNumber := LV_GetNext(RowNumber)
    LV_GetText(uid, RowNumber, 5)
    SingleCommand(uid, "/system package update install")
  }
  return
backup:
  writeLog("has clicked the backup button", "INFO")
  RowNumber := 0
  loop % LV_GetCount("S")
  {
    if not RowNumber
    {
      Rownumber := 0
    }
    RowNumber := LV_GetNext(RowNumber)
    LV_GetText(uid, RowNumber, 5)
    BackupRouter(uid)
  }
  return
reboot:
  writeLog("has clicked the reboot button", "INFO")
  MsgBox, 4,, Are you sure you want to reboot these routers?
    IfMsgBox No
      return
  RowNumber := 0
  loop % LV_GetCount("S")
  {
    if not RowNumber
    {
      Rownumber := 0
    }
    RowNumber := LV_GetNext(RowNumber)
    LV_GetText(uid, RowNumber, 5)
    SingleCommand(uid, "/system reboot")
  }
  return
winbox:
  writeLog("has started a Winbox session", "WARNING")
  RowNumber := 0
  loop % LV_GetCount("S")
  {
    if not RowNumber
    {
      Rownumber := 0
    }
    RowNumber := LV_GetNext(RowNumber)
    LV_GetText(uid, RowNumber, 5)
    winport := GetCreds("winport", uid)
    username := GetCreds("username", uid)
    password := GetCreds("password", uid)
    hostname := GetCreds("hostname", uid)
    runCMD := "winbox " . hostname . ":" . winport . " " . username . " " . password
    run, %comspec% /c %runCMD% ,,hide
  }
  return
Putty:
  writeLog("has started a putty session", "WARNING")
  RowNumber := 0
  loop % LV_GetCount("S")
  {
    if not RowNumber
    {
      Rownumber := 0
    }
    RowNumber := LV_GetNext(RowNumber)
    LV_GetText(uid, RowNumber, 5)
    sshport := GetCreds("port", uid)
    username := GetCreds("username", uid)
    password := GetCreds("password", uid)
    hostname := GetCreds("hostname", uid)
    clipboard := password
    MsgBox, Password has been copied to clipboard.
    runCMD := "putty.exe -ssh " . username . "@" . hostname . " " . port
    run, %comspec% /c %runCMD% ,,hide
  }
  return
CopyHost:
  RowNumber := 0
  loop % LV_GetCount("S")
  {
    if not RowNumber
    {
      Rownumber := 0
    }
    RowNumber := LV_GetNext(RowNumber)
    LV_GetText(uid, RowNumber, 5)
    hostname := GetCreds("hostname", uid)
    writeLog("has copied the hostname " . hostname . "to their clipboard", "INFO")
    clipboard := hostname
    MsgBox, Hostname has been copied to clipboard.
  }
  return
Add:
  toAdd := []
  GuiControlGet, Name
  toAdd.Push(Name)
  GuiControlGet, Hostname
  toAdd.Push(Hostname)
  GuiControlGet, Username
  toAdd.Push(Username)
  GuiControlGet, Password
  toAdd.Push(Password)
  GuiControlGet, Winport
  toAdd.Push(Winport)
  GuiControlGet, Group
  toAdd.Push(Group)
  GuiControlGet, Zip
  toAdd.Push(Zip)
  GuiControlGet, ContactName
  toAdd.Push(ContactName)
  GuiControlGet, ContactEmail
  toAdd.Push(ContactEmail)
  GuiControlGet, Port
  toAdd.Push(Port)
  FormatTime, uid, ,yyMMddHHmmss
  comma := ","
  apostrophe := "'"
  space := " "
  for k, v in toAdd
  {
    if !v
    {
      MsgBox, You have a blank field, router not stored.
      return
    }
    if (k = 6)
    {
      IfInString, Group, -
      {
        MsgBox, Illegal Character '-' in group name
        return
      }
      IfInString, Group, %space%
      {
        MsgBox, Space is an illegal character in group name
        return
      }
    }
    IfInString, v, %comma%
    {
      MsgBox, Illegal Character ',' in a field
      return
    }
    IfInString, v, %apostrophe%
    {
      MsgBox, Illegal Character ''' in a field
      return
    }
  }
  OpenDB()
  QUERY := "INSERT INTO tb_devices VALUES ('" . Name . "','" . Hostname . "','" . Username . "','" . Password . "','" . Winport . "','MikroTik', '0', '0', '" . Zip . "', '" . ContactName . "', '" . ContactEmail . "', 'fail', '0', '" . Port . "', '" . group . "', '" . uid . "');"
  if Devices.Exec(QUERY)
  {
    LV_Add(, Name, Hostname, Port, Username, Password, Winport, Group, Zip, ContactName, ContactEmail, uid)
  }
  toLog := "has added client " . Name . " to the database."
  writeLog(toLog, "INFO")
  Devices.CloseDB()
  return
Update:
  toUpdate := []
  row := LV_GetNext()
  LV_GetText(uid, row, 11)
  GuiControlGet, Name
  toUpdate.Push(Name)
  GuiControlGet, Hostname
  toUpdate.Push(Hostname)
  GuiControlGet, Username
  toUpdate.Push(Username)
  GuiControlGet, Password
  toUpdate.Push(Password)
  GuiControlGet, Winport
  toUpdate.Push(Winport)
  GuiControlGet, Group
  toUpdate.Push(Group)
  GuiControlGet, Zip
  toUpdate.Push(Zip)
  GuiControlGet, ContactName
  toUpdate.Push(ContactName)
  GuiControlGet, ContactEmail
  toUpdate.Push(ContactEmail)
  GuiControlGet, Port
  toUpdate.Push(Port)
  comma := ","
  apostrophe := "'"
  space := " "
  for k, v in toUpdate
  {
    if !v
    {
      MsgBox, You have a blank field, router config not updated.
      return
    }
    if (k = 6)
    {
      IfInString, v, -
      {
        MsgBox, Illegal Character '-' in group name
        return
      }
      IfInString, Group, %space%
      {
        MsgBox, Space is an illegal character in group name
        return
      }
    }
    IfInString, v, %comma%
    {
      MsgBox, Illegal Character ',' in a field
      return
    }
    IfInString, v, %apostrophe%
    {
      MsgBox, Illegal Character ''' in a field
      return
    }
  }
  newName := Name
  newHostname := Hostname
  newUsername := Username
  newPassword := Password
  newWinport := Winport
  newGroup := Group
  newZip := Zip
  newContactName := ContactName
  newContactEmail := ContactEmail
  newPort := Port
  OpenDB()
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
  QUERY := "UPDATE tb_devices SET bGroup = '" . newGroup . "' WHERE uid = '" . uid . "';"
  Devices.Exec(QUERY)
  QUERY := "UPDATE tb_devices SET zip = '" . newZip . "' WHERE uid = '" . uid . "';"
  Devices.Exec(QUERY)
  QUERY := "UPDATE tb_devices SET contactname = '" . newContactName . "' WHERE uid = '" . uid . "';"
  Devices.Exec(QUERY)
  QUERY := "UPDATE tb_devices SET contactemail = '" . newContactEmail . "' WHERE uid = '" . uid . "';"
  Devices.Exec(QUERY)
  QUERY := "UPDATE tb_devices SET port = '" . newPort . "' WHERE uid = '" . uid . "';"
  Devices.Exec(QUERY)
  LV_Modify(row,"",newName,newHostname,newPort,newUsername,newPassword,newWinport,newGroup,newZip,newContactName,newContactEmail,uid)
  toLog := "has updated client " . Name . " in the database."
  writeLog(toLog, "WARNING")
  Devices.CloseDB()
  return
Delete:
  MsgBox, 4,, Are you sure you want to delete this router from the database?
    IfMsgBox No
      return
  row := LV_GetNext()
  LV_GetText(name, row, 1)
  LV_GetText(hostname, row, 2)
  LV_GetText(port, row, 3)
  LV_GetText(username, row, 4)
  LV_GetText(password, row, 5)
  LV_GetText(winport, row, 6)
  LV_GetText(group, row, 7)
  LV_GetText(zip, row, 8)
  LV_GetText(contactName, row, 9)
  LV_GetText(contactEmail, row, 10)
  LV_GetText(DelUid, row, 11)
  OpenDB()
  QUERY := "DELETE FROM tb_devices WHERE uid='" . DelUid . "';"
  if (Devices.Exec(QUERY))
  {
    LV_Delete(row)
  }
  toLog := "has deleted a client with the following info - Name: " . name . " Hostname: " . hostname . " SSH Port: " . port . " Username: " . username . " Password: " . password . " Winbox Port: " . winport . " Group: " . group . " Zip Code: " . zip . " Contact Name: " . contactName . " Contact Email Address: " . contactEmail
  writeLog(toLog, "CRITICAL")
  Devices.CloseDB()
  return
Retrieve:
  row := LV_GetNext()
  LV_GetText(name, row, 1)
  LV_GetText(hostname, row, 2)
  LV_GetText(port, row, 3)
  LV_GetText(username, row, 4)
  LV_GetText(password, row, 5)
  LV_GetText(winport, row, 6)
  LV_GetText(group, row, 7)
  LV_GetText(zip, row, 8)
  LV_GetText(contactName, row, 9)
  LV_GetText(contactEmail, row, 10)
  GuiControl,, Name, %name%
  GuiControl,, Hostname, %hostname%
  GuiControl,, Port, %port%
  GuiControl,, Username, %username%
  GuiControl,, Password, %password%
  GuiControl,, Winport, %winport%
  GuiControl,, Group, %group%
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
  GuiControl,, Group,none
  GuiControl,, Zip,
  GuiControl,, ContactName,
  GuiControl,, ContactEmail,
  return
BackupDB:
  BackupDB()
  return
RestoreDB:
  Gui, Edit:Destroy
  RestoreDB()
  GoSub, Edit
  return
Quit:
  writeLog("has opened the toolbox", "INFO")
  Gui, Edit:Destroy
  Gosub, DrawMain
  return
return

EditGuiClose:
EditGuiEscape:
MainGuiClose:
MainGuiEscape:
Devices.CloseDB()
ExitApp

;Function WriteLog: Writes log with format <severity> <time> - <local user> <text>
;Parameters: String text, String severity
;Returns: None
writeLog(text, severity)
{
  Global computerUser
  Global logFile
  formattime, logtime, ,HHmm
  text := severity . " " . logtime . " - " . A_UserName . " " . text . "`n"
  FileAppend, %text%, %logFile%
  return
}

;Function AutoRunGroup: Determines if a group has been specified in Args and then runs AutoRun with those arguments
;Parameters: None
;Returns: None
AutoRunGroup()
{
  Global Args
  Global 0
  groupPos := 1
  checkFor := "-group"
  breakNext := false
  targetGroup := -2
  for k, v in Args
  {
    if breakNext
    {
      targetGroup := v
      break
    }
    if (v = checkFor)
    {
      breakNext := true
    }
  }
  if (targetGroup = -2)
  {
    writeLog("has attempted to run commands on a group but an error occurred", "WARNING")
    return
  }
  Loop %0%
  {
    If (ObjHasValue(Args, "-backup"))
    {
      toLog := "has initiated an automatic backup on group " . targetGroup
      writeLog(toLog, "INFO")
  		AutoRun("backup", targetGroup)
    }
    If (ObjHasValue(Args, "-firmware"))
    {
      toLog := "has initiated an automatic firmware upgrade on group " . targetGroup
      writeLog(toLog, "WARNING")
  		AutoRun("firmware", targetGroup)
    }
    If (ObjHasValue(Args, "-ros"))
    {
      toLog := "has initiated an automatic routerOS upgrade" . targetGroup
      writeLog(toLog, "WARNING")
  		AutoRun("rOS", targetGroup)
    }
  }
  return
}

;Function Autorun - Automatically runs a specified command on a target group (all if not specified)
;Parameters: String command, String group
;Returns: None
AutoRun(command, targetGroup := -1)
{
  checkBackup := "backup"
  checkFirmware := "firmware"
  checkROS := "rOS"
  checkGroup := -1
  Global Devices
  OpenDB()
  if (targetGroup = checkGroup)
  {
    Devices.GetTable("SELECT * FROM tb_devices;", table)
  }
  else
  {
    Devices.GetTable("SELECT * FROM tb_devices WHERE bGroup='" . targetGroup . "';", table)
  }
  canIterate := true
  while (canIterate !=-1)
  {
    canIterate := table.Next(tableRow)
    name := tableRow[1]
    uid := tableRow[16]
    if name
    {
      if (command = checkBackup)
      {
        bufferDir := BackupRouter(uid)
        ClearBuffer(bufferDir)
      }
      else if (command = checkFirmware)
      {
        SingleCommand(uid, "/system routerboard upgrade")
      }
      else if (command = checkROS)
      {
        SingleCommand(uid, "/system package update install")
      }
    }
  }
  Devices.CloseDB()
  ExitApp
}

; Function CheckAlive
; Parameters: String uid, String name
; Returns: Boolean alive
CheckAlive(uid, name)
{
  hostname := GetCreds("hostname", uid)
  alive := false
  runCMD := "ping " . hostname . " >> ""buffer\" . name . ".txt"""
  run, %comspec% /c %runCMD% ,,hide
  Sleep 5000
  fileName := "buffer\" . name . ".txt"
  patternSearch := "time"
  Loop, read, %fileName%
  {
    IfInString, A_LoopReadLine, %patternSearch%
    {
      alive := true
    }
  }
  FileDelete, %fileName%
  return alive
}

; Function GetCreds
; Parameters: String type, String uid. type must be a valid key in the database and uid should be the uid of a device in the database
; Returns: String result. Will give whatever information is requested (username, password, etc.)
GetCreds(type, uid)
{
  Global Devices
  OpenDB()
  QUERY := "SELECT " . type . " FROM tb_devices WHERE uid='" . uid . "';"
  Devices.Query(QUERY, resultQuery)
  resultQuery.Next(resultRow)
  result := resultRow[1]
  Devices.CloseDB()
  return result
}

; Function ClearBuffer. Deletes the contents of the buffer folder.
; Parameters: String directory
; Returns: Boolean. True if directory deleted false if not deleted.
ClearBuffer(directory)
{
  try
  {
    FileRemoveDir, %directory%, 1
  }
  catch 1
  {
    return false
  }
  return true
}

; Function BackupRouter. Backs up router using command stored in \scripts\backup.txt.
; Parameters: String uid
; Returns: String. Contains buffer directory used for clearing later
BackupRouter(uid)
{
  Global Devices
  hostname := GetCreds("hostname", uid)
  name := GetCreds("name", uid)
  directory := "backups\"
  commands := "scripts/backup.txt"
  bufferDir := "buffer\" . name . "\"
  ifNotExist, %directory%
    FileCreateDir, %directory%
  formattime, date, , MM-dd-yyyy_HHmm
  directory := directory . name . "\"
  ifNotExist, %directory%
    FileCreateDir, %directory%
  fileName := directory . date . ".txt"
  errorCheck1 := "buffer\" . name . ".txt"
  errorCheck2 := bufferDir . "1-1.txt"
  if CheckAlive(uid, name)
  {
    LogMultiCommand(uid, fileName, commands, bufferDir)
  }
  OpenDB()
  if FileExist(fileName)
  {
    QUERY := "UPDATE tb_devices SET bstatus = 'Success' WHERE uid = '" . uid . "';"
    Devices.Exec(QUERY)
    foundPos := 0
    Loop, read, %fileName%
      {
        line := A_LoopReadLine
        foundPos := InStr(line, "RouterOS", true)
        if foundPos
        {
          foundPos := foundPos + 9
          routerVersion := SubStr(line, foundPos)
          break
        }
      }
    if foundPos
    {
      QUERY := "UPDATE tb_devices SET os = '" . routerVersion . "' WHERE uid = '" . uid . "';"
      Devices.Exec(QUERY)
    }
    else
    {
      QUERY := "UPDATE tb_devices SET os = 'Failed Fetch' WHERE uid = '" . uid . "';"
      Devices.Exec(QUERY)
      QUERY := "UPDATE tb_devices SET bstatus = 'Bad Credentials' WHERE uid ='" . uid . "';"
      Devices.Exec(QUERY)
    }
  }
  else if FileExist(errorCheck1)
  {
    QUERY := "UPDATE tb_devices SET bstatus = 'Timeout' WHERE uid = '" . uid . "';"
    Devices.Exec(QUERY)
  }
  else if FileExist(errorCheck2)
  {
    QUERY := "UPDATE tb_devices SET bstatus = 'Could not establish connection' WHERE uid = '" . uid . "';"
    Devices.Exec(QUERY)
  }
  else
  {
    QUERY := "UPDATE tb_devices SET bstatus = 'Unknown Error' WHERE uid = '" . uid . "';"
    Devices.Exec(QUERY)
  }
  toLog := "has backed up router with name " . name
  writeLog(toLog, "INFO")
  Devices.CloseDB()
  return %bufferDir%
}

; Function LogCommand. Executes a command on a MikroTik device and logs the output.
; Parameters: String uid, String command, String filename. filename must be a valid Windows File Name.
; Returns: None.
LogCommand(uid, command, filename)
{
  Global Devices
  OpenDB()
  name := GetCreds("name", uid)
  username := GetCreds("username", uid)
  password := GetCreds("password", uid)
  hostname := GetCreds("hostname", uid)
  port := GetCreds("port", uid)
  directory := "backups\" . name . "\"
  FileCreateDir, %directory%
  fileName := directory . filename
  runCMD := "echo y  | plink.exe -ssh -P" . port . " " . hostname . " -l " . username . " -pw " . password . " " . command . " > " . """" . fileName . """"
  run, %comspec% /c %runCMD% ,,hide
  toLog := "has run command " . command . " on router with name " . name
  writeLog(toLog, "WARNING")
  Devices.CloseDB()
  return
}

; Function LogMultiCommand
; Parameters: String uid, String saveTarget, String commandFile
; Returns: None
LogMultiCommand(uid, saveTarget, commandFile, bufferDir)
{
  username := GetCreds("username", uid)
  password := GetCreds("password", uid)
  name := GetCreds("name", uid)
  port := GetCreds("port", uid)
  hostname := GetCreds("hostname", uid)
  buffer := bufferDir
  ifNotExist, %buffer%
    FileCreateDir, %buffer%
  line := 1
  Loop, read, %commandFile%
  {
    bufferFile := buffer . line . ".txt"
    runCMD := "echo y  | plink.exe -ssh -P " . port . " " . hostname . " -l " . username . " -pw " . password . " " . A_LoopReadLine . " > " . """" . bufferFile . """"
    run, %comspec% /c %runCMD% ,,hide
    line++
  }
  toCheck := buffer . "1.txt"
  copy := buffer . "1-1.txt"
  tries := 1
  Sleep 3000
  Loop
  {
    FileCopy, %toCheck%, %copy%
    FileDelete, %toCheck%
    if !FileExist(toCheck)
    {
      break
    }
    else
    {
      FileDelete, %copy%
      sleep 500
    }
    if tries > 60
    {
      FileDelete, %copy%
      break
    }
    tries++
  }
  filesToSearch := buffer . "*.txt"
  Loop, Files, %filesToSearch% ;Find all txt files, do not include subfolders
  {
    Loop, read, %A_LoopFileFullPath%, %saveTarget% ;Read each file
      {
        FileAppend, %A_LoopReadLine%`n
      }
  }
  toLog := "has run commands from file " . commandFile . " on router with name " . name
  writeLog(toLog, "WARNING")
  return
}

; Function SingleCommand. Runs a single command on a MikroTik without logging.
; Parameters: String uid, String command
; Returns: None.
SingleCommand(uid, command)
{
  name := GetCreds("name", uid)
  username := GetCreds("username", uid)
  password := GetCreds("password", uid)
  port := GetCreds("port", uid)
  hostname := GetCreds("hostname", uid)
  runCMD := "echo y  | plink.exe -ssh -P " . port . " " . hostname . " -l " . username . " -pw " . password . " " . command
  run, %comspec% /c %runCMD% ,,hide
  toLog := "has run command " . command . " on router with name " . name
  writeLog(toLog, "WARNING")
  return
}

; Function MultiCommand. Runs series of commands determined by the contents of a file.
; Parameters: String uid, String filePath. filePath must be a path to a file, can be in relation to the working directory or a full path.
; Returns: None.
MultiCommand(uid, filePath)
{
  name := GetCreds("name", uid)
  username := GetCreds("username", uid)
  password := GetCreds("password", uid)
  port := GetCreds("port", uid)
  hostname := GetCreds("hostname", uid)
  runCMD := "echo y | plink.exe -ssh -P " . port . " " . hostname . " -l " . username . " -pw " . password . " -m """ . filePath . """"
  run, %comspec% /c %runCMD% ,,hide
  toLog := "has run commands from file " . filePath . " on router with name " . name
  writeLog(toLog, "WARNING")
  return
}

; Function BackupDB. Backs up DB to either csv or txt file. CSV file recommended for easy browing by external applications
; Parameters: None. 
; Returns: None.
BackupDB()
{
  Global Devices
  OpenDB()
  directory := "backups\DB\"
  ifNotExist, %directory%
    FileCreateDir, %directory%
  formattime, date, , MM-dd-yyyy_HHmm
  exportTarget := directory . date . ".csv"
  Devices.GetTable("SELECT * FROM tb_devices;", table)
  canIterate := true
  while (canIterate != -1)
  {
    canIterate := table.Next(tableRow)
    name := tableRow[1]
    hostname := tableRow[2]
    username := tableRow[3]
    password := tableRow[4]
    winport := tableRow[5]
    manufacturer := tableRow[6]
    os := tableRow[7]
    firmware := tableRow[8]
    zip := tableRow[9]
    contactname := tableRow[10]
    contactemail := tableRow[11]
    bstatus := tableRow[12]
    model := tableRow[13]
    port := tableRow[14]
    bgroup := tableRow[15]
    uid := tableRow[16]
    if tableRow.MaxIndex() = 16
    {
      row := name . "," . hostname . "," . username . "," . password . "," . winport . "," . manufacturer . "," . os . "," . firmware . "," . zip . "," . contactname . "," . contactemail . "," . bstatus . "," . model . "," . port . "," . bgroup . "," . uid . "`n"
    }
    else if tableRow.MaxIndex() = 4
    {
      row := name . "," . hostname . "," . username . "," . password . "`n"
    }
    else
    {
      row := "Error `n"
    }
    if name
    {
      FileAppend, %row%, %exportTarget%
    }
  }
  toLog := "has backed up the database to file " . exportTarget
  writeLog(toLog, "WARNING")
  Devices.CloseDB()
  return
}

; Function RestoreDB. Retores database from either csv or txt file.
; Parameters: None.
; Returns: None.
RestoreDB()
{
  Global Devices
  OpenDB()
  MsgBox, 4,, This will wipe your current database. Would you like to continue?
  IfMsgBox No
    ExitApp
  writeLog("has started importing a backup configuration", "WARNING")
  FileSelectFile, importTarget, 3,,,Backups (*.txt; *.csv)
  FileReadLine, targetLine, %importTarget%, 1
  lineArr := StrSplit(targetLine, ",")
  numCol := LineArr.MaxIndex()
  if numCol = 16
  {
    QUERY := "DROP TABLE tb_devices;"
    Devices.Exec(QUERY)
    Devices.Exec("CREATE TABLE tb_devices(name String, hostname String, username String, password String, winport String, manufacturer String, os String, firmware String, zip String, contactname String, contactemail String, bstatus String, model String, port String, bGroup String, uid String);")
    Loop, Read, %importTarget%
    {
      importArgs := StrSplit(A_LoopReadLine, ",")
      name := "'" . importArgs[1] . "'"
      hostname := "'" . importArgs[2] . "'"
      username := "'" . importArgs[3] . "'"
      password := "'" . importArgs[4] . "'"
      winport := "'" . importArgs[5] . "'"
      manufacturer := "'" . importArgs[6] . "'"
      os := "'" . importArgs[7] . "'"
      firmware := "'" . importArgs[8] . "'"
      zip := "'" . importArgs[9] . "'"
      contactname := "'" . importArgs[10] . "'"
      contactemail := "'" . importArgs[11] . "'"
      bstatus := "'" . importArgs[12] . "'"
      model := "'" . importArgs[13] . "'"
      port := "'" . importArgs[14] . "'"
      bgroup := "'" . importArgs[15] . "'"
      uid := "'" . importArgs[16] . "'"
      SQL := "INSERT INTO tb_devices VALUES (" . name . "," . hostname . "," . username . "," . password . "," . winport . "," . manufacturer . "," . os . "," . firmware . "," . zip . "," . contactname . "," . contactemail . "," . bstatus . "," . model . "," . port . "," . bGroup . "," . uid . ");"
      import := Devices.Exec(SQL)
    }
    toLog := "has imported a database from file " . importTarget
    writeLog(toLog, "CRITICAL")
  }
  else if numCol = 4
  {
    QUERY := "DROP TABLE tb_devices;"
    Devices.Exec(QUERY)
    Devices.Exec("CREATE TABLE tb_devices(name String, hostname String, username String, password String);")
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
    toLog := "has imported a database from file " . importTarget
    writeLog(toLog, "CRITICAL")
  }
  else
  {
    MsgBox, Unknown error when restoring from backup.
  }
  CheckDBVersion()
  Devices.CloseDB()
  return
}

; Function CheckDBVersion. Checks which version of the database is being used and upgrades to latest revision if necessary.
; Parameters: None.
; Returns: None.
CheckDBVersion()
{
  Global Devices
  OpenDB()
  Devices.GetTable("SELECT * FROM tb_devices;", table)
  table.Next(tableRow)
  dbSize := tableRow.MaxIndex()
  if dbSize = 4
  {
    BackupDB()
    Devices.GetTable("SELECT * FROM tb_devices;", table)
    canIterate := true
    ifExist, conversionbuffer.txt
      FileDelete, conversionbuffer.txt
    while (canIterate == true)
    {
      canIterate := table.Next(tableRow)
      name := tableRow[1]
      hostname := tableRow[2]
      username := tableRow[3]
      password := tableRow[4]
      row := name . "," . hostname . "," . username . "," . password . "`n"
      if name
      {
        FileAppend, %row%, conversionbuffer.txt
      }
    }
    ifNotExist, conversionbuffer.txt
      MsgBox, Buffer creation failed, aborting!
    ifNotExist, conversionbuffer.txt
      return
    QUERY := "DROP TABLE tb_devices;"
    Devices.Exec(QUERY)
    Devices.Exec("CREATE TABLE tb_devices(name String, hostname String, username String, password String, winport String, manufacturer String, os String, firmware String, zip String, contactname String, contactemail String, bstatus String, model String, port String, bGroup String, uid String);")
    uid := 1
    Loop, Read, conversionbuffer.txt
    {
      importArgs := StrSplit(A_LoopReadLine, ",")
      name := "'" . importArgs[1] . "'"
      hostname := "'" . importArgs[2] . "'"
      username := "'" . importArgs[3] . "'"
      password := "'" . importArgs[4] . "'"
      SQL := "INSERT INTO tb_devices VALUES (" . name . "," . hostname . "," . username . "," . password . ", '8291', 'MikroTik', '0', '0', '1', 'John Doe', 'null@null', 'fail', '0', '22', 'none', '" . uid . "');"
      import := Devices.Exec(SQL)
      uid++
    }
    writeLog("has upgraded the database from version legacy to version 1", "CRITICAL")
    MsgBox, Database converted!
  }
  Devices.CloseDB()
  return
}

; Function OpenDB. Opens the database used by the toolbox.
; Parameters: None.
; Returns: None.
OpenDB()
{
  Global Devices
  Devices.OpenDB("devices.db")
  return
}