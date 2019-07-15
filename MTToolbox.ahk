; Author: Jonah Verner
; Organization: Lake Country Technology
; Version: 0.1
; Database Structure
; Table: tb_devices
; Keys: Device Name, hostname, username, password

#Include Class_SQLiteDB.ahk
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

Gui, Add, GroupBox, xp+6 yp+5 w470 h250, Commands
Gui, Add, Button, xp+5 yp+20 w120 gEdit, Edit Clients
Gui, Add, Button, yp+25 w120 gCommand, Run Command
Gui, Add, Button, yp+25 w120 gFirmware, Update Firmware
Gui, Add, Button, yp+25 w120 gRouterOS, Update RouterOS
Gui, Add, Button, yp+25 w120 gBackup, Run Manual Backup
Gui, Add, Button, yp+25 w120 gReboot, Reboot
Gui, Add, ListView, yp-135 xp+125 w335 h235, Name|Hostname
if !FileExist("backupconfig.txt")
{
  MsgBox, Configuration file not found, it is now being created
  newFile := FileOpen(backupconfig.txt, "w")
  newFile.Close()
}
Devices := New SQLiteDB
Devices.OpenDB("devices.db")
Devices.GetTable("SELECT * FROM tb_devices;", table)
canIterate := true
while (canIterate !=-1)
{
  canIterate := table.Next(tableRow)
  name := tableRow[1]
  hostname := tableRow[2]
  if name
  {
    LV_Add("", name, hostname)
  }
}
Global Args := []

Loop, %0%
	Args.Push(%A_Index%)

Loop %0%
{
	If (ObjHasValue(Args, "-backup"))
		AutoBackup()
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

Gui, Show,, MikroTik Toolbox
LV_ModifyCol(1, "AutoHdr")
return

AutoBackup()
{
  Global Devices
  Devices.GetTable("SELECT * FROM tb_devices;", table)
  canIterate := true
  while (canIterate !=-1)
  {
    canIterate := table.Next(tableRow)
    name := tableRow[1]
    hostname := tableRow[2]
    if name
    {
      BackupRouter(hostname)
      formattime, date, , MM-dd-yyyy_HH-mm
      cloudFile := "CloudPrint_" . date . ".txt"
      LogCommand(hostname, "/ip cloud print", cloudFile)
    }
  }
  Devices.CloseDB()
  ExitApp
}

GetCreds(type, hostname)
{
  Global Devices
  QUERY := "SELECT " . type . " FROM tb_devices WHERE hostname='" . hostname . "';"
  Devices.Query(QUERY, resultQuery)
  resultQuery.Next(resultRow)
  result := resultRow[1]
  return result
}

LogCommand(hostname, command, filename)
{
  Global Devices
  name := GetCreds("name", hostname)
  username := GetCreds("username", hostname)
  password := GetCreds("password", hostname)
  directory := "backups\" . name . "\"
  FileCreateDir, %directory%
  fileName := directory . filename
  runCMD := "echo y  | plink.exe -ssh " . hostname . " -l " . username . " -pw " . password . " " . command . " > " . """" . fileName . """"
  run, %comspec% /c %runCMD%
}

BackupRouter(hostname)
{
  Global Devices
  name := GetCreds("name", hostname)
  username := GetCreds("username", hostname)
  password := GetCreds("password", hostname)
  formattime, date, , MM-dd-yyyy_HH-mm
  directory := "backups\" . name . "\"
  FileCreateDir, %directory%
  fileName := directory . date . ".txt"
  runCMD := "echo y  | plink.exe -ssh " . hostname . " -l " . username . " -pw " . password . " -m """ . "scripts/backup.txt" . """" " > " . """" . fileName . """"
  run, %comspec% /c %runCMD%
}

SingleCommand(hostname, command)
{
  username := GetCreds("username", hostname)
  password := GetCreds("password", hostname)
  runCMD := "echo y  | plink.exe -ssh " . hostname . " -l " . username . " -pw " . password . " " . command
  run, %comspec% /c %runCMD%
}

MultiCommand(hostname, filePath)
{
  username := GetCreds("username", hostname)
  password := GetCreds("password", hostname)
  runCMD := "echo y | plink.exe -ssh " . hostname . " -l " . username . " -pw " . password . " -m """ . filePath . """"
  run, %comspec% /c %runCMD%
}

Edit:
  run, "MTClients.ahk"
  Devices.CloseDB()
  ExitApp
return
Delete:
loop
{
  RowNumber := LV_GetNext()
  if not RowNumber
  {
    break
  }
  LV_GetText(DelHostname, RowNumber, 2)
  QUERY := "DELETE FROM tb_devices WHERE hostname='" . DelHostname . "';"
  if (Devices.Exec(QUERY))
  {
    LV_Delete(RowNumber)
  }
}
return
Command:
FileSelectFile, commandTarget
loop % LV_GetCount("S")
{
  if not RowNumber
  {
    Rownumber := 0
  }
  RowNumber := LV_GetNext(RowNumber)
  LV_GetText(hostname, RowNumber, 2)
  MultiCommand(hostname, commandTarget)
}
return
Firmware:
loop % LV_GetCount("S")
{
  if not RowNumber
  {
    Rownumber := 0
  }
  RowNumber := LV_GetNext(RowNumber)
  LV_GetText(hostname, RowNumber, 2)
  SingleCommand(hostname, "/system routerboard upgrade")
}
return
RouterOS:
loop % LV_GetCount("S")
{
  if not RowNumber
  {
    Rownumber := 0
  }
  RowNumber := LV_GetNext(RowNumber)
  LV_GetText(hostname, RowNumber, 2)
  SingleCommand(hostname, "/system package update install")
}
return
backup:
loop % LV_GetCount("S")
{
  if not RowNumber
  {
    Rownumber := 0
  }
  RowNumber := LV_GetNext(RowNumber)
  LV_GetText(hostname, RowNumber, 2)
  BackupRouter(hostname)
}
Rownumber := 0
return
reboot:
loop % LV_GetCount("S")
{
  if not RowNumber
  {
    Rownumber := 0
  }
  RowNumber := LV_GetNext(RowNumber)
  LV_GetText(hostname, RowNumber, 2)
  SingleCommand(hostname, "/system reboot")
}
return

GuiClose:
GuiEscape:
Devices.CloseDB()
ExitApp
