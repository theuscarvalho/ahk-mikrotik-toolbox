; Author: Jonah Verner
; Organization: Lake Country Technology
; Database Structure
; Table: tb_devices
; Keys: Device Name, hostname, username, password

#Include Class_SQLiteDB.ahk
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

;Opens database and creates a new one if it does not currently exist
Devices := New SQLiteDB
if !Devices.OpenDB("devices.db", "W", false)
{
  Devices.OpenDB("devices.db")
  Devices.Exec("CREATE TABLE tb_devices(name String, hostname String, username String, password String);")
}
Devices.GetTable("SELECT * FROM tb_devices;", table)

;Draw GUI
Gui, Add, GroupBox, xp+6 yp+5 w470 h250, Commands
Gui, Add, Button, xp+5 yp+20 w120 gEdit, Edit Clients
Gui, Add, Button, yp+25 w120 gCommand, Run Command
Gui, Add, Button, yp+25 w120 gFirmware, Update Firmware
Gui, Add, Button, yp+25 w120 gRouterOS, Update RouterOS
Gui, Add, Button, yp+25 w120 gBackup, Run Manual Backup
Gui, Add, Button, yp+25 w120 gReboot, Reboot
Gui, Add, ListView, yp-135 xp+125 w335 h235, Name|Hostname

;Loop to populate the listview
canIterate := true
while (canIterate == true)
{
  canIterate := table.Next(tableRow)
  name := tableRow[1]
  hostname := tableRow[2]
  if name
  {
    LV_Add("", name, hostname)
  }
}

;The following loop and function handle processing of any command line flags.
;Currently the only flag that is handled is -backup
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

;Wait to draw GUI until after flags are processed
Gui, Show,, MikroTik Toolbox
LV_ModifyCol(1, "AutoHdr")
return

;Automatically backs up all devices and their /ip cloud info then exits the application
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
    }
  }
  Devices.CloseDB()
  ExitApp
}

; Function GetCreds
; Parameters: String type, String hostname. type must be a valid key in the database and hostname should be the hostname of a device in the database
; Returns: String result. Will give whatever information is requested (username, password, etc.)
GetCreds(type, hostname)
{
  Global Devices
  QUERY := "SELECT " . type . " FROM tb_devices WHERE hostname='" . hostname . "';"
  Devices.Query(QUERY, resultQuery)
  resultQuery.Next(resultRow)
  result := resultRow[1]
  return result
}

; Function LogCommand. Executes a command on a MikroTik device and logs the output.
; Parameters: String hostname, String command, String filename. filename must be a valid Windows File Name.
; Returns: None.
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
  run, %comspec% /c %runCMD% ,,hide
}

; Function BackupRouter. Backs up router using command stored in \scripts\backup.txt.
; Parameters: String hostname
; Returns: None.
BackupRouter(hostname)
{
  directory := "backups\"
  ifNotExist, %directory%
    FileCreateDir, %directory%
  Global Devices
  commands := "scripts/backup.txt"
  bufferDir := "buffer"
  name := GetCreds("name", hostname)
  username := GetCreds("username", hostname)
  password := GetCreds("password", hostname)
  formattime, date, , MM-dd-yyyy_HH-mm
  directory := directory . name . "\"
  ifNotExist, %directory%
    FileCreateDir, %directory%
  ifNotExist, %bufferDir%
    FileCreateDir, %bufferDir%
  fileName := directory . date . ".txt"
  line := 1
  Loop, read, %commands%
  {
    bufferFile := "\" . bufferDir . line . ".txt"
    runCMD := "echo y  | plink.exe -ssh " . hostname . " -l " . username . " -pw " . password . " " . A_LoopReadLine . " > " . """" . bufferFile . """"
    MsgBox, %runCMD%
    run, %comspec% /c %runCMD% ,,hide
    line++
  }
  Loop, %bufferDir%\*.txt, , 0 ;Find all txt files, do not include subfolders
  {
	  Loop, read, %A_LoopFileFullPath%, %fileName% ;Read each file
		  {
			  FileAppend, %A_LoopReadLine%`n
		  }
  }
  FileDelete, %bufferDir%\*.txt
}

; Function SingleCommand. Runs a single command on a MikroTik without logging.
; Parameters: String hostname, String command
; Returns: None.
SingleCommand(hostname, command)
{
  username := GetCreds("username", hostname)
  password := GetCreds("password", hostname)
  runCMD := "echo y  | plink.exe -ssh " . hostname . " -l " . username . " -pw " . password . " " . command
  run, %comspec% /c %runCMD% ,,hide
}

; Function MultiCommand. Runs series of commands determined by the contents of a file.
; Parameters: String hostname, String filePath. filePath must be a path to a file, can be in relation to the working directory or a full path.
; Returns: None.
MultiCommand(hostname, filePath)
{
  username := GetCreds("username", hostname)
  password := GetCreds("password", hostname)
  runCMD := "echo y | plink.exe -ssh " . hostname . " -l " . username . " -pw " . password . " -m """ . filePath . """"
  run, %comspec% /c %runCMD% ,,hide
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
