;
; AutoHotkey Version: 1.x
; Language:       English
; Platform:       Win9x/NT
; Author:         A.N.Other <myemail@nowhere.com>
;
; Script Function:
;	Template script (you can customize this template by editing "ShellNew\Template.ahk" in your Windows folder)
;

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

VDKExtract(vdkname,filelist := "")
{
	vdk := FileOpen(vdkname,"r"), lookup := Array()

	Header := {"Version":vdk.Read(8)
				,"_":vdk.ReadUInt()
				,"Files":vdk.ReadUInt()
				,"Dirs":vdk.ReadUInt()
				,"Size":vdk.ReadUInt()
				,"Flist":vdk.ReadUInt()
				,"Append":vdk.ReadUInt()}

	vdk.Seek(Header["Size"]+149)

	Loop, % Header["Files"]
	{
		Fdir := vdk.Read(260), Offset := vdk.ReadUInt(), fsep := InStr(Fdir,"/",,-1), name := SubStr(Fdir,fsep+1)

		if !filelist or InStr(filelist, name)
		{
			boffset := vdk.tell(), vdk.seek(offset)
			bit := vdk.ReadUchar(), fname := vdk.Read(128), usize := vdk.ReadUInt(), zsize := vdk.ReadUInt()

			vdk.seek(8,1)
			len := vdk.Rawread(data,zsize)

			if (t := zlib_Decompress(extracted,data,zsize,usize))
			{
				FileCreateDir, Ext
				temp := FileOpen("Ext\" fname,"w"), temp.seek(0)
				temp.RawWrite(extracted,usize)
				temp.Close()
			}

			vdk.seek(boffset)
		}
	}
}

VDKPack(vdkname,filedir)
{
	_files := 0, _folders := 0, _table := Array(), empty := 1
	vdk := FileOpen(vdkname, "w")

	SetWorkingDir, %filedir%
	Loop, Files,*.*,RDF
	{
		If (A_LoopFileAttrib = "A")
			_files++
		else
			_folders++
	}

	vdk.seek(28)
	parent := vdk.tell()
	Loop, Files,*.*,RD
	{
		dirname := A_LoopFileName

		If empty ; Begin the file with "." and ".."
		{
			current := vdk.tell()
			vdk.WriteUChar(1), vdk.Write(".")
			vdk.seek(127,1)
			vdk.WriteUInt(0), vdk.WriteUInt(0)
			vdk.WriteUInt(current), vdk.WriteUInt(current + 145)

			If (A_LoopFileDir) ; ".."
			{
				start := vdk.tell()
				vdk.WriteUChar(1), vdk.Write("..")
				vdk.seek(126,1)
				vdk.WriteUInt(0), vdk.WriteUInt(0)
				vdk.WriteUInt(parent) ; parent = offset of last iteration
				vdk.WriteUInt(start + 145)
			}
		}

		if A_LoopFileDir
			empty := ""

		start := vdk.tell()

		vdk.WriteUChar(1), vdk.Write(dirname)
		vdk.seek(128 - strlen(dirname),1)
		vdk.WriteUInt(0), vdk.WriteUInt(0)
		vdk.WriteUInt(start + 145)

		noffsetpos := vdk.tell(), vdk.seek(4,1), parent := current

		Loop, Files,%A_LoopFilePath%\*.*
		{
			StringUpper, filepath, A_LoopFilePath
			If (A_Index = 1) ; First elements in dir = ".", ".."
			{
				fcurrent := vdk.tell()
				vdk.WriteUChar(1), vdk.Write(".")
				vdk.seek(127,1)
				vdk.WriteUInt(0), vdk.WriteUInt(0)
				vdk.WriteUInt(fcurrent), vdk.WriteUInt(fcurrent + 145)

				fstart := vdk.tell()
				vdk.WriteUChar(1), vdk.Write("..")
				vdk.seek(126,1)
				vdk.WriteUInt(0), vdk.WriteUInt(0)
				vdk.WriteUInt(parent), vdk.WriteUInt(fstart + 145)
			}

			offset := vdk.tell(), _table[offset] := StrReplace(filepath,"\","/")

			f := FileOpen(filepath, "r"), f.seek(0), size := f.length, f.RawRead(fread, size), f.close()
			If !csize := zlib_Compress(cdata, fread, size,1)
				return

			noffset := A_Index < _files ? offset + 145 + csize : 0

			vdk.WriteUChar(0), vdk.Write(A_LoopFileName)
			vdk.seek(128 - strlen(A_LoopFileName),1)
			vdk.WriteUInt(size), vdk.WriteUInt(csize)
			vdk.WriteUInt(0), vdk.WriteUInt(noffset)
			vdk.RawWrite(cdata,csize)
		}

		end := vdk.tell()
		Loop, Files, %A_LoopFilePath%, D
			noffset := A_LoopFilename != dirname ? end : 0

		vdk.seek(noffsetpos)
		vdk.WriteUInt(noffset)
		vdk.seek(end)
	}

	size := vdk.Tell() - 145, vdk.WriteUInt(_files)

	for offset, pathname in _table
	{
		vdk.Write(pathname)
		vdk.seek(260 - strlen(pathname),1)
		vdk.WriteUInt(offset)
	}

	vdk.Seek(0)
	vdk.Write("VDISK1.1"), vdk.WriteUInt(0)
	vdk.WriteUInt(_files), vdk.WriteUInt(_folders)
	vdk.WriteUInt(size), vdk.WriteUInt(_files * 264 + 4)
	vdk.Close()

	SetWorkingDir, %A_ScriptDir%
}

zlib_Decompress(Byref Decompressed, Byref CompressedData, Byref DataLen, Byref OriginalSize = -1)
{
	OriginalSize := (OriginalSize > 0) ? OriginalSize : DataLen*10 ;should be large enough for most cases
	VarSetCapacity(Decompressed,OriginalSize)
	ErrorLevel := DllCall("zlib1\uncompress", "Ptr", &Decompressed, "UIntP", &OriginalSize, "Ptr", &CompressedData, "UIntP", &DataLen,"Cdecl")
	return ErrorLevel ? 0 : OriginalSize
}

zlib_Compress(Byref Compressed, Byref Data, DataLen, level = -1) {
nSize := DllCall("zlib1\compressBound", "UInt", DataLen, "Cdecl")
VarSetCapacity(Compressed,nSize)

	ErrorLevel := DllCall("zlib1\compress2", "ptr", &Compressed, "UIntP", nSize, "ptr", &Data, "UInt", DataLen, "Int"
               , level    ;level 0 (no compression), 1 (best speed) - 9 (best compression)
               , "Cdecl") ;0 means Z_OK

	return ErrorLevel = 0 ? nSize : 0
}