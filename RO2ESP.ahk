#SingleInstance force
#Include /RagnarokVCR/Localization/RO2ESP/Class_SQLiteDB.ahk
#Include /RagnarokVCR/Localization/RO2ESP/VDKmodule.ahk

center := (A_ScreenWidth - 270) / 2

Menu, Tray, NoStandard ; remove standard Menu items
Menu, Tray, Tip, RO2ESP
Menu, Tray, Click, 1
Menu, Tray, Add, &Gu�a de Referencia, helper
Menu, Tray, Add, &Nuevo Cliente, runner
Menu, Tray, Add, &Cerrar, GuiClose
Menu, Tray, Default, &Gu�a de Referencia

Gui, Add, Text, x90 y10 w50 vstringvdk,
Gui, Add, Text, x17 y55 w270 h30 vmsg, Preparando RO2ESP, espera un momento...
Gui, Add, Text, x260 y10 w60 vupdate,
Gui, Add, Text, x70 y30 w60 vlink,
Gui, Add, Button, x15 y120 guninstall, Desinstalar
Gui, Add, Button, Default x225 y120 ghelper, Gu�a de Referencia
Gui, Add, Button, x225 y85 wp hidden guiget vuiget, Descargar gr�ficos

Gui, Font, bold
Gui, Add, Text, x15 y10 w50, Traducci�n:
Gui, Add, Text, x205 y10 w50, Versi�n:
Gui, Add, Text, x17 y30 w30, Gr�ficos:
Gui, Add, Progress, x15 y85 hidden w200 h20 -Smooth vMyProgress, 0

; Generated using SmartGUI Creator 4.0
Gui, Show, x%center% y10 h150 w350, RO2 en Espa�ol por Raikuha

FileGetTime actual, %A_ScriptName%
Fileinstall, sqlite3.dll, sqlite3.dll
Fileinstall, zlib1.dll, zlib1.dll
UrlDownloadToFile, http://tiny.cc/RO2INI, version.ini

IniRead, state, version.ini, Version, Launcher, %A_SPACE%

If (state > actual)
	GuiControl,,msg, Hay una nueva versi�n de RO2ESP.`nVisita el link en RO2ESP.ini.

; Initial setup
	IfNotExist Data\1\TRADUCCION.VDK
	{
		FileDelete RO2ESP.ini
		GuiControl,,stringvdk,Ausente
	}
	else GuiControl,,stringvdk, Presente

	IfNotExist Data\1\GRAFICOS.VDK
	{
		IniWrite, Originales, version.ini, Version, Graficos
		GuiControl,,link, Originales
		GuiControl,Show,uiget
	}
	else GuiControl,,link, Traducidos

	If FileExist("Data\1\MAPS.VDK")
		FileMove, Data\1\MAPS.VDK, Data\1\MINIMAP.VDK, 1 ; Restore minimap
	If FileExist("Data\1\ENGLISH.VDK")
		FileMove, Data\1\ENGLISH.VDK, Data\1\STRING.VDK, 1 ; Restore strings

	IniRead, maps, RO2ESP.ini, Version, Graficos, %A_SPACE%

	If !FileExist("Desinstalar_RO2ESP.bat")
		FileAppend,
		(
			@echo off
			dir /b /s
			move /Y "%A_ScriptDir%\Data\1\MAPS.VDK" "%A_ScriptDir%\Data\1\MINIMAP.VDK"
			move /Y "%A_ScriptDir%\Data\1\ENGLISH.VDK" "%A_ScriptDir%\Data\1\STRING.VDK"
			del "%A_ScriptDir%\Data\1\TRADUCCION.VDK"
			del "%A_ScriptDir%\Data\1\GRAFICOS.VDK"
			del "%A_ScriptDir%\sqlite3.dll"
			del "%A_ScriptDir%\zlib1.dll"
			del "%A_ScriptDir%\Guia.DB"
			del "%A_ScriptDir%\RO2Esp.ini"
			rmdir "%A_ScriptDir%\Ext"
			del "%A_ScriptFullPath%"
			del "%A_ScriptDir%\Desinstalar_RO2ESP.bat"
		), %A_ScriptDir%\Desinstalar_RO2ESP.bat

	If !maps
		IfNotExist Data\1\GRAFICOS.VDK
		{
			MsgBox,4,Paquete de gr�ficos,Est� disponible un paquete opcional que traduce mapas`ny gr�ficos del juego, �deseas descargarlo? (Peso: 45Mb).
			IfMsgBox Yes
			{
			uiget:
				GuiControl,Hide,uiget
				GuiControl,,msg, Descargando el paquete de gr�ficos...
				Run RO2Client.exe ; We call the launcher before applying our mods
				Download("Data\1\GRAFICOS.VDK","http://tiny.cc/RO2MAPS", "GRAFICOS.VDK")
				GuiControl,,msg, Gr�ficos descargados correctamente.
				IniWrite, Traducidos, RO2ESP.ini, Version, Graficos
				reload
			return
			}
		}

	GuiControlGet,maps,,link
	IniWrite,%link%, version.ini, Version, Graficos

Process, Exist, Launcher2.exe ; We check if the launcher is already running
if !ErrorLevel ; Game isn't running, we have to load it.
{
	Process, Exist, Rag2.exe ; Check if a previous instance of the game is running
	If ErrorLevel ; The game is up, so we have to bypass the patcher
		Run Shipping\Rag2.exe /IP=login.playragnarok2.com /FROM=-FromLauncher /STARTER=1 /LANGCODE=1
	else
		Run RO2Client.exe ; We call the launcher before applying our mods
}

	; Let's check the version, or if we have goods at all.
	IniRead, version, version.ini, Version, STRING.VDK, %A_SPACE%
	IniRead, last, RO2ESP.ini, Version, STRING.VDK, %A_SPACE%

	if !last or (version > last)
	{
		GuiControl,,msg, Descargando una nueva traducci�n...
		Download("STRING.VDK","http://tiny.cc/RO2TEXT", "STRING.VDK")
	}

	IfExist STRING.VDK
		FileMove, STRING.VDK, Data\1\TRADUCCION.VDK ,1 ; Updating translation

	FileCopy, Data\1\STRING.VDK, Data\1\ENGLISH.VDK ,1 ; Back up strings

	; We create a DB for reference
	SetTimer, CreateGuide, -100 

	GuiControl,, stringvdk,Presente

	FormatTime, version, %version%, ShortDate
	GuiControl,,update, %version%

	FileMove, version.ini, RO2ESP.ini, 1

	If FileExist("STRING.VDK")
	{
		IniRead, logs, RO2ESP.ini, Changelog,, %A_SPACE%
		MsgBox,,Nuevos Cambios - %version%, %logs%
	}

	GuiControl,,msg, Preparando archivos...

	Loop ; We force a stop until the launcher finishes updating or whatever.
	{
		WinGetText, ready, Ragnarok2 Launcher
		if ready contains Update has been completed.
		break
	}

	FileCopy, Data\1\TRADUCCION.VDK, Data\1\STRING.VDK, 1 ;Apply translation

	IfExist Data\1\GRAFICOS.VDK
	{
		FileMove, Data\1\MINIMAP.VDK, Data\1\MAPS.VDK ; Back up minimap
		FileCopy, Data\1\GRAFICOS.VDK, Data\1\MINIMAP.VDK, 1 ; Apply translated graphics
	}

	;Compatibility with other languages multi clients
	IniRead, lang, RO2_option.ini, NATION_CODE, LANGUAGE, %A_SPACE%
	IniWrite, 1, RO2_option.ini, NATION_CODE, LANGUAGE

	GuiControl,,msg, Traducci�n aplicada. Ya puedes jugar.

	Process, Wait, Rag2.exe ; Wait for the game to be running
	IniWrite, %lang%, RO2_option.ini, NATION_CODE, LANGUAGE

	IfExist NewRO2ESP.exe
		FileMove, NewRO2ESP.exe, RO2ESP.exe, 1

	Gui, Cancel
	TrayTip , RO2ESP, RO2ESP permanece abierto para que puedas acceder a la`nGu�a de Referencia y abrir otros clientes de RO2., 10
	Process, WaitClose, Rag2.exe
		FileRemoveDir,Ext,1
		FileRemoveDir,Ext
		ExitApp
return

GuiClose:
	FileRemoveDir,Ext,1
	FileRemoveDir,Ext
	ExitApp

runner:
	Run Shipping\Rag2.exe /IP=login.playragnarok2.com /FROM=-FromLauncher /STARTER=1 /LANGCODE=1
return

uninstall:
	MsgBox, 4,Desintalar RO2ESP, �Deseas desinstalar RO2ESP completamente?
	IfMsgBox Yes
	{
		Run Desinstalar_RO2ESP.bat,,hide 
		ExitApp
	}
return


2GuiClose:
	DB.Close()
	Gui, 2:destroy
return
	
helper:
; Example: Tab control:
Gui, 2:New, +HwndGuiHwnd, Gu�a de Referencia
Gui, %GuiHwnd%:Default
Gui, Add, Button, x10 y6 default vbutton gReader, Buscar
Gui, Add, Edit, x+5 y7 vid w200
Gui, Add, Text, x+10 yp+3, Page:
Gui, Add, Edit, x+5 gReader yp-3 limit6 vpage Number w50
Gui, Add, UpDown, 0x80 vpager Range1-1, 1
Gui, Add, Text, x+10 yp+3 w50 vpagecount, of 1
Gui, Add, Tab2, xm w520 h400 gReader vlist, Objetos|Habilidades|NPCs|Lugares ; Tab2 vs. Tab requires v1.0.47.05.
Gui, Add, ListView, vObjetos r20 w500, Ingl�s|Espa�ol
Gui, Tab, 2
Gui, Add, ListView, vHabilidades r20 w500, Ingl�s|Espa�ol
Gui, Tab, 3
Gui, Add, ListView, vNPCs r20 w500, Ingl�s|Espa�ol
Gui, Tab, 4
Gui, Add, ListView, vLugares r20 w500, Ingl�s|Espa�ol
Gui, Tab  ; i.e. subsequently-added controls will not belong to the tab control.
Gui, Show, x%center% y190 h500 w550, Gu�a de Referencia

	While FileExist("Guia.DB-journal")
		sleep 250

	DBFileName := A_ScriptDir . "\Guia.DB"
	DB := new SQLiteDB

	If !DB.OpenDB(DBFileName)
	{
		MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode
		ExitApp
	}
GoSub Reader
return

Reader:
	Gui, Submit, NoHide

	If (A_GuiControl != "pager")
		GuiControl,,pager,1

	Table := {"Objetos":"string_item_name","Habilidades":"string_skill_name","NPCs":"string_npc_name","Lugares":"string_mapinfo"}

	Gui, ListView, %list%
	LV_Delete()

	SQL := "SELECT Original, Traducido FROM " Table[list] (id ? " WHERE Traducido LIKE '%" id "%' or Original LIKE '%" id "%'" : "") " ORDER BY ID"
	If !DB.GetTable(SQL, Guide)
		MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode "`n" SQL

	MaxPage := Guide.RowCount > 20 ? Ceil(Guide.RowCount / 20) : 1

	GuiControl,,pagecount,of %MaxPage%
	GuiControl, +Range1-%MaxPage%, pager

	Start := (page - 1) * 20
	Loop, 20
	{
		Row := Start + A_Index
		If !(Results := Guide.Rows[Row])
			break

		LV_Add("", Results[1],Results[2])  ; this adds each line to the last created listview
		LV_ModifyCol()
	}
return

CreateGuide:
	DBFileName := A_ScriptDir . "\Guia.DB"
	DB := new SQLiteDB

	If !DB.OpenDB(DBFileName)
	{
		MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode
		ExitApp
	}

	Filelist = string_item_name.tbl,string_npc_name.tbl,string_mapinfo.tbl,string_skill_name.tbl

	Files := Array()

	VDKExtract("Data\1\ENGLISH.vdk",Filelist)
	Loop, Files, Ext\*.*
	{
		table := StrReplace(A_LoopFilename,".tbl"), id_%table% := Array(), Files.Push(table)
		string := FileOpen(A_LoopFilePath,"r"), string.ReadLine()

		Loop
		{
			If string.AtEOF
				break

			data := StrSplit(string.ReadLine(),A_Tab)
			linefeed := RegexReplace(data[2],"^\s+|\s+$")

			id_%table%[data[1]] := StrReplace(linefeed,"""")
		}
	}

	VDKExtract("Data\1\TRADUCCION.vdk",Filelist)
	Loop, Files, Ext\*.*
	{
		table := StrReplace(A_LoopFilename,".tbl"), str_%table% := Array(), num_%table% := Array()
		string := FileOpen(A_LoopFilePath,"r"), string.ReadLine()

		Loop
		{
			If string.AtEOF
				break

			data := StrSplit(string.ReadLine(),A_Tab)
			linefeed := RegexReplace(data[2],"^\s+|\s+$"), iddata := RegexReplace(data[1],"^\s+|\s+$")

			if (eng := id_%table%[data[1]])
				str_%table%[eng] := StrReplace(linefeed,""""), num_%table%[eng] := iddata
		}
	}

	DB.Exec("BEGIN TRANSACTION")
	for pos, name in Files
	{
		for original, traducido in str_%name%
		{
			if !Original
				Original := "NULL"

			if !Traducido
				Traducido := "NULL"

			if (Original != Traducido)
				buffer .= "(" num_%name%[original] ",'" StrReplace(Original,"'","''") "','" StrReplace(Traducido,"'","''") "'),"
		}

		If !DB.Exec("DROP TABLE IF EXISTS " name)
			MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode

		If !DB.Exec("CREATE TABLE " name " (ID,Original, Traducido, UNIQUE(ID,Original,Traducido));")
			MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode

		If !DB.Exec("INSERT OR IGNORE INTO " name " VALUES " SubStr(Buffer,1,-1))
			MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode
		buffer := "", %name% := ""
	}

	DB.Exec("END TRANSACTION")
	DB.Exec("VACUUM")
	DB.Close()
return

Download(path_p, dLocation_p, filename_p)
{  global path, dLocation, FullFileName, FullSize
   path = %path_p%
   dLocation = %dLocation_p%
   FullFileName = %filename_p%
   FullSize := HttpQueryInfo(dLocation, 5) / (1024 * 1024) ; get download file size in mbytes
   SetTimer, GetSize, 20
   UrlDownloadToFile, %dLocation%, %path%
   SetTimer, GetSize, Off
   GuiControl,Hide, MyProgress
   GuiControl,,MyProgress, 0
   Return
}

GetSize:
   FileOpen(path, "r")
   FileGetSize, FSize, %path%, M ; Get local file size in mb
   UpdateSize := Floor((FSize / FullSize) * 100) ; get percentage
   IfEqual, FSize, FullSize, Return
   IfNotEqual, ErrorLevel, 1
      GuiControl,Show, MyProgress
      GuiControl,, MyProgress, %UpdateSize%
      GuiControl,, msg,% UpdateSize "% descargado - " FullFileName
Return


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; HttpQueryInfo Function ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Source: post by olfen "DllCall: HttpQueryInfo - Get HTTP headers"
;                       http://www.autohotke...4567.html#64567
;
; For flag info, see: http://msdn.microsof...351(VS.85).aspx

HttpQueryInfo(URL, QueryInfoFlag=21, Proxy="", ProxyBypass="") {
hModule := DllCall("LoadLibrary", "str", dll := "wininet.dll")

; Adapt for build by 0x150||ISO
ver := ( A_IsUnicode && !RegExMatch( A_AhkVersion, "\d+\.\d+\.4" ) ? "W" : "A" )
InternetOpen := dll "\InternetOpen" ver
HttpQueryInfo := dll "\HttpQueryInfo" ver
InternetOpenUrl := dll "\InternetOpenUrl" ver

If (Proxy != "")
AccessType=3
Else
AccessType=1

io_hInternet := DllCall( InternetOpen
, "str", ""
, "uint", AccessType
, "str", Proxy
, "str", ProxyBypass
, "uint", 0) ;dwFlags
If (ErrorLevel != 0 or io_hInternet = 0) {
DllCall("FreeLibrary", "uint", hModule)
return, -1
}

iou_hInternet := DllCall( InternetOpenUrl
, "uint", io_hInternet
, "str", url
, "str", ""
, "uint", 0
, "uint", 0x80000000
, "uint", 0)
If (ErrorLevel != 0 or iou_hInternet = 0) {
DllCall("FreeLibrary", "uint", hModule)
return, -1
}

VarSetCapacity(buffer, 1024, 0)
VarSetCapacity(buffer_len, 4, 0)

Loop, 5
{
  hqi := DllCall( HttpQueryInfo
  , "uint", iou_hInternet
  , "uint", QueryInfoFlag
  , "uint", &buffer
  , "uint", &buffer_len
  , "uint", 0)
  If (hqi = 1) {
    hqi=success
    break
  }
}

IfNotEqual, hqi, success, SetEnv, res, timeout

If (hqi = "success") {
p := &buffer
Loop
{
  l := DllCall("lstrlen", "UInt", p)
  VarSetCapacity(tmp_var, l+1, 0)
  DllCall("lstrcpy", "Str", tmp_var, "UInt", p)
  p += l + 1
  res := res . tmp_var
  If (*p = 0)
  Break
}
}

DllCall("wininet\InternetCloseHandle",  "uint", iou_hInternet)
DllCall("wininet\InternetCloseHandle",  "uint", io_hInternet)
DllCall("FreeLibrary", "uint", hModule)

return, res
}