#Include Class_SQLiteDB.ahk
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

Gui, Add, GroupBox, xp+6 yp+5 w200 h300, DB Utility
Gui, font, bold
Gui, Add, Text, xp+5 yp+15, Database Conversion
Gui, font, normal
Gui, Add, Text, yp+15, Source Database Version
Gui, Add, Radio, vSourceLegacy, Legacy
Gui, Add, Radio, vSourceOne, 1
Gui, Add, Text, yp+20, Target Database Version
Gui, Add, Radio, vTargetLegacy, Legacy
Gui, Add, Radio, vTargetOne, 1
Gui, Add, Button, yp+20 Default w80 gConvert, Convert

Gui, font, bold
Gui, Add, Text, yp+25, Database Backup and Restore
Gui, font, normal
Gui, Add, Text, yp+15, Database Version
Gui, Add, Radio, vBRLegacy, Legacy
Gui, Add, Radio, vBROne, 1
Gui, Add, Button, yp+20 Default w80 gBackup, Backup
Gui, Add, Button, yp+25 Default w80 gRestore, Restore

Gui, Show

return

Convert:
Gui, Submit, NoHide
MsgBox, 4,, Have you taken a backup? It is highly recommended that you do that first.
  IfMsgBox No
    return
if (SourceLegacy)
{
  if (TargetLegacy)
  {
    MsgBox, You cannot convert the database to the same scheme as source.
  }
  else if (TargetOne)
  {
    Devices := New SQLiteDB
    if !Devices.OpenDB("devices.db", "W", false)
    {
      MsgBox, Database not found. Cancelling conversion.
      return
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
    Devices.Exec("CREATE TABLE tb_devices(name String, hostname String, username String, password String, tier String, manufacturer String, os String, firmware String, zip String, contactname String, contactemail String, bstatus String, model String);")
    Loop, Read, conversionbuffer.txt
      {
        importArgs := StrSplit(A_LoopReadLine, ",")
        name := "'" . importArgs[1] . "'"
        hostname := "'" . importArgs[2] . "'"
        username := "'" . importArgs[3] . "'"
        password := "'" . importArgs[4] . "'"
        SQL := "INSERT INTO tb_devices VALUES (" . name . "," . hostname . "," . username . "," . password . ", '0', 'MikroTik', '0', '0', '0', 'John Doe', 'null@null', 'fail', '0');"
        import := Devices.Exec(SQL)
      }
  }
  else MsgBox, Unexpected Error!
}
else if (SourceOne)
{
  if (TargetOne)
  {
    MsgBox, You cannot convert the database to the same scheme as source.
  }
  else if (TargetLegacy)
  {
    MsgBox, 4,, Are you sure you want to downgrade your database version?
      IfMsgBox No
        return
    Devices := New SQLiteDB
    if !Devices.OpenDB("devices.db", "W", false)
    {
      MsgBox, Database not found. Cancelling conversion.
      return
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
    Devices.Exec("CREATE TABLE tb_devices(name String, hostname String, username String, password String);")
    Loop, Read, conversionbuffer.txt
      {
        importArgs := StrSplit(A_LoopReadLine, ",")
        name := "'" . importArgs[1] . "'"
        hostname := "'" . importArgs[2] . "'"
        username := "'" . importArgs[3] . "'"
        password := "'" . importArgs[4] . "'"
        SQL := "INSERT INTO tb_devices VALUES (" . name . "," . hostname . "," . username . "," . password . ");"
        import := Devices.Exec(SQL)
      }
  }
}
else MsgBox, Unexpected error!
ifExist, conversionbuffer.txt
  FileDelete, conversionbuffer.txt
Devices.CloseDB()
return

Backup:
Gui, Submit, NoHide
Devices := New SQLiteDB
if !Devices.OpenDB("devices.db", "W", false)
{
  MsgBox, Database not found. Cancelling conversion.
  return
}
if (BROne)
{
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
    tier := tableRow[5]
    manufacturer := tableRow[6]
    os := tableRow[7]
    firmware := tableRow[8]
    zip := tableRow[9]
    contactname := tableRow[10]
    contactemail := tableRow[11]
    bstatus := tableRow[12]
    zip := tableRow[13]
    row := name . "," . hostname . "," . username . "," . password . "," . tier . "," . manufacturer . "," . os . "," . firmware . "," . zip . "," . contactname . "," . contactemail . "," . bstatus . "," . model . "`n"
    if name
    {
      FileAppend, %row%, %exportTarget%
    }
  }
}
else if (BRLegacy)
{
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
}
else MsgBox, Error! No Option Selected!
Devices.CloseDB()
return

Restore:
Devices := New SQLiteDB
if !Devices.OpenDB("devices.db", "W", false)
{
  MsgBox, Database not found. Cancelling conversion.
  return
}
Gui, Submit, NoHide
MsgBox, 4,, This will wipe your current database. Would you like to continue?
  IfMsgBox No
    return
if (BROne)
{
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
      tier := "'" . importArgs[5] . "'"
      manufacturer := "'" . importArgs[6] . "'"
      os := "'" . importArgs[7] . "'"
      firmware := "'" . importArgs[8] . "'"
      zip := "'" . importArgs[9] . "'"
      contactname := "'" . importArgs[10] . "'"
      contactemail := "'" . importArgs[11] . "'"
      bstatus := "'" . importArgs[12] . "'"
      model := "'" . importArgs[13] . "'"
      SQL := "INSERT INTO tb_devices VALUES (" . name . "," . hostname . "," . username . "," . password . "," . tier . "," . manufacturer . "," . os . "," . firmware . "," . zip . "," . contactname . "," . contactemail . "," . bstatus . "," . model . ");"
      import := Devices.Exec(SQL)
    }
}
else if (BRLegacy)
{
  FileSelectFile, importTarget, 3
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
}
else MsgBox, Error! No option selected!
Devices.CloseDB()
return

GuiClose:
GuiEscape:
ExitApp
