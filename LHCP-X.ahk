;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Description
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
; Expandable LHCP
; Accepts any string as argument. Include a "||" in front of string to play any file that includes that string.
; Returns full message of file being played.


;~~~~~~~~~~~~~~~~~~~~~
;Compile Options
;~~~~~~~~~~~~~~~~~~~~~
#NoEnv ;performance and compatibility
#NoTrayIcon
#SingleInstance, Off

VERSIONNAME = v0.0
Startup()
;Sb_InstalledFiles()


;Dependencies
#Include %A_ScriptDir%\Functions
#Include sort_arrays
#Include util_arrays
#Include util_misc
#Include json_obj
#Include Socket.ahk
#Include Json.ahk



FileCreateDir, %A_ScriptDir%\Data\
DataBase_Loc = %A_ScriptDir%\Data\LHCP_DataBase.json


class IRC
{
	static _ := IRC := new IRC() ; Automatically initialize base object
	__Call(Name, Params*)
	{
		TCP := new SocketTCP()
		TCP.Connect("localhost", 26656)
		TCP.SendText(Json_FromObj({MethodName: Name, Params: Params}))
		return Json_ToObj(TCP.recvText()).return
		return
	}
}


;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
;StartUp
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

CLI_Arg = %1%
	;Create GUI and offer updates if run with no cli-arguments
	If (!CLI_Arg) {
	Fn_BuildGUI()
	Gui, +Enable
	Fn_HardCodedGlobals()
	Fn_LoadtoMemory(DataBaseFile)
	Fn_GenerateDB()
	Return
	}

	;launched with CLI argument
	If (CLI_Arg) {
		;Load pre-existing DataBase
		If (FileExist(DataBase_Loc)) {
		FileRead, MemoryFile, % DataBase_Loc
		LHCP_Array := Fn_JSONtooOBJ(MemoryFile)
		MemoryFile := ;BLANK
		} Else {
		LHCP_Array := Fn_GenerateDB()
		}

		SettingsFile := A_ScriptDir . "\Settings.ini"
		Settings := Ini_Read(SettingsFile)

		If (CLI_Arg = "jason") {
		Fn_GenerateDB()
		}
		If (CLI_Arg = "stop") {
			Loop, 10
			{
			Process, Close, LHCP-X.exe
			}
		Exitapp
		}
		If (InStr(CLI_Arg,"||")) {
		ExitApp
		Temp_Array := []
		X = 0
			Loop, LHCP_Array.MaxIndex() {
				If(InStr(CLI_Arg,LHCP_Array[A_Index,"Phrase"])) {
				X++
				Temp_Array[]
				}
			}


		} Else {
			Loop, % LHCP_Array.MaxIndex() {
				If(CLI_Arg = LHCP_Array[A_Index,"Command"]) {
				;Chat(StrReplace(Settings.Server.LHCP_Channel, "#"), LHCP_Array[A_Index, "Phrase"])
				SoundPlay, % LHCP_Array[A_Index,"FilePath"], 1
				ExitApp
				}
			}
		}
	ExitApp
	}





;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Buttons
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

^F7::
Reload

;~~~~~~~~~~~~~~~~~~~~~
;Download All Files, build new DB
;~~~~~~~~~~~~~~~~~~~~~
AutoUpdate:

;Create Dir
LHCP_Dir = %A_ScriptDir%\Data\Files
FileCreateDir, %LHCP_Dir%


;Download Master List and load to memory
MasterFile_Loc = %A_ScriptDir%\Data\LHCP_MasterList.txt
FileDelete, %MasterFile_Loc%
sleep 100
UrlDownloadToFile, https://dl.dropboxusercontent.com/u/268814505/LHCP/LHCP_MasterList.ini, %MasterFile_Loc%
FileRead, The_MemoryFile, %MasterFile_Loc%

;Load into Array
Txt_Array := StrSplit(The_MemoryFile,"`r`n")

;Set Progressbar to 0%


TotalDownloaded = 0
GuiControl,, ProgressBar1, 1
	Loop, % Txt_Array.MaxIndex() {


	FinalFileName := Txt_Array[A_Index]
	DropboxURL := Txt_Array[A_Index]
	StringReplace, DropboxURL, DropboxURL, %A_Space%, `%20, All
	StringReplace, DropboxURL, DropboxURL, #, `%23, All
	StringReplace, DropboxURL, DropboxURL, `,, `%2C, All
	StringReplace, DropboxURL, DropboxURL, `^, `%5E, All
	StringReplace, DropboxURL, DropboxURL, `%, `%, All
	DropboxURL2 = https://dl.dropboxusercontent.com/u/268814505/LHCP/%DropboxURL%

	CurrentFile := LHCP_Dir . "\" . FinalFileName
	StringReplace, CurrentFile, CurrentFile, `n,, All
	StringReplace, CurrentFile, CurrentFile, `r,, All
		;Download if not in collection
		If (!FileExist(CurrentFile)) {
		UrlDownloadToFile, %DropboxURL2%, %CurrentFile%
		TotalDownloaded ++
		}


	vProgressBar := 100 * (TotalDownloaded / Txt_Array.MaxIndex())
	GuiControl,, ProgressBar1, %vProgressBar%
	}
GuiControl,, ProgressBar1, 100
LHCP_Array := Fn_GenerateDB()

;DEPRECIATED - Ask user if the want to delete any unofficial files
;;;MessageWindow()
Return


DeleteUnofficial:
FileDelete, %LHCP_Dir%\Data\LHCP_pkg.lua
;UrlDownloadToFile, https://dl.dropboxusercontent.com/u/268814505/LHCP/LHCP_pkg.lua, %LHCP_Dir%\LHCP_pkg.lua
DeletedFiles_Counter = 0
Gui, 2: Destroy
Fn_BuildGUI()
	Loop, %LHCP_Dir%/*.* ;*/
	{
	CurrentFileName = %A_LoopFileName%
	DELETETHISFILE = 1
		Loop, read, %MasterFile%
		{

			If CurrentFileName = %A_LoopReadLine%
			{
			DELETETHISFILE += 1
			}
		}

		If (DELETETHISFILE = 1)
		{
		;Msgbox, %CurrentFileName% Marked for deletion.
		DeletedFiles_Counter += 1
		FileDelete, %LHCP_Dir%\%CurrentFileName%
		}

	}
	Fn_EmbeddedLUAMaker()
	Fn_CatalogueFiles()
;Msgbox, The database has been created.
Fn_LoadtoMemory(DataBaseFile)
Msgbox, Your LHCP folder has been cleaned of %DeletedFiles_Counter% files.
Return


GenerateLUA:
Gui, 2: Destroy
Fn_BuildGUI()
Fn_EmbeddedLUAMaker()
FileDelete, %DataBaseFile%
Fn_CatalogueFiles()
Fn_LoadtoMemory(DataBaseFile)
Msgbox, Completed Generation a new LHCP_pkg.lua
Return


FolderSelect:
FileSelectFolder, OutputVar, *%WoW_Dir%, , Select Your World of Warcraft folder
IniWrite, %OutputVar%, %A_ScriptFullPath%:Stream:$DATA, Settings, EmbVar
IniRead, WoW_Dir, %A_ScriptFullPath%:Stream:$DATA, Settings, EmbVar,error

Fn_HardCodedGlobals()
;Continue down and make DataBase

BuildDataBase:
;Msgbox, LHCP-Helper will index all the clips in your folder. Please wait 2 mins for finished message.
FileDelete, %DataBaseFile%
Fn_CatalogueFiles()
;Msgbox, The database has been created.
Fn_LoadtoMemory(DataBaseFile)
Return



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
;Hotkeys
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

#IfWinActive World of War
; Only activates anything below this when in "World of Warcraft" is active.
~[::
Fn_OnChecker()
SendInput {Enter}
Sleep 30
SendInput [
Input, USERINPUT, V T20, {Enter}{Escape}], ww
;Sends input to game window and ScrotChat when you press Shift+Enter. Visible and case sensitive. Ends when you press Enter or Escape
	If ErrorLevel = Match
	{
	Return
	}
	If ErrorLevel = EndKey:Escape
	{
	SendInput {Escape} ;remove this line if Escape causes problems with your game. in Wow it exits chatbox.
	Return
	}
	;If ErrorLevel = EndKey:
	;NOTE ABOUT ENTER HERE
	{
	ArrayHauler()
	UserInputlength := StrLen(USERINPUT)
	UserInputlength += 10
	sleep 100
		If (Buffer != "")
		{
		SendInput {Backspace %UserInputlength%}/%Buffer%
		}
		else
		{
		SendInput {Escape}
		}
	;ControlSend, , %ScrotChat%{Return}, Chat
	Return
	}
Return

+]::
Fn_OnChecker()
CallCounter += 1
	If (CallCounter > CallMax)
	{
	CallCounter = 1
	}
Buffer := LHCPArray[CallCounter]
SendInput {Enter}
Sleep 30
SendInput /%Buffer%
Return


;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; FUNCTIONS
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

Fn_GenerateDB()
{
TempArray := []

	;Loop all mp3 files
	Loop, %A_ScriptDir%\Data\Files\*.mp3 , 1
	{
	Command := Fn_QuickRegEx(A_LoopFileName,"([ !\w]+)#")
	Phrase := Fn_QuickRegEx(A_LoopFileName,"#([ !\w]+)")
		If (Command != "null" && Phrase != "null") {
		TempArray[A_Index,"FilePath"] := A_LoopFileFullPath
		TempArray[A_Index,"Command"] := Command
		TempArray[A_Index,"Phrase"] := Phrase
		}
	}
	;Write out the newley created Array and return it for the MAIN
	;MemoryFile := Fn_JSONfromOBJ(TempArray)
	FileDelete, %A_ScriptDir%\Data\LHCP_DataBase.json
	FileAppend, % Fn_JSONfromOBJ(TempArray), %A_ScriptDir%\Data\LHCP_DataBase.json
	Return % TempArray
}



Fn_OnChecker()
{
global

	If (OnCheck = 0)
	{
	Exit
	}

}

Fn_LoadtoMemory(filename)
{
global
TotalDBLines = 0
MemoryDB := []
X = 0
	Loop, read, %filename%
	{
	Temp = %A_LoopReadLine%
	;Msgbox, %A_LoopReadLine%
	MemoryDB.Insert(Temp)
	}
	TotalDBLines := MemoryDB.MaxIndex()
}


ArrayHauler()
{
global

TempArray := []
LHCPArray := []
;Msgbox, %TotalDBLines%
X = 0
	Loop, %TotalDBLines%
	{
	X += 1
	Searchable := MemoryDB[x]
		;Msgbox, %Searchable%
		IfInString, Searchable, %USERINPUT%
		{
		StringReplace, Searchable, Searchable, !, , All
		StringSplit, field_array, Searchable, #, ; Omits periods.   If # ever stops working, switch to %A_Tab%
		;Msgbox, %field_array1% ~ %field_array2%
		TempArray.Insert(field_array1)
		}

	}
	TotalSize := TempArray.MaxIndex() ;gets current size of temp array. This will eventually be 0 when it is empty
	;msgbox, %TotalSize%
	Loop, %TotalSize%
	{
	CurrentSize := TempArray.MaxIndex()
	;Msgbox, %CurrentSize%
	Random, Rand, 1, %CurrentSize%
	Buffer := TempArray[Rand]
	TempArray.Remove(Rand,Rand)
	LHCPArray.Insert(Buffer)
	}
	;replace this later with Fn_TryAgain
	CallMax := LHCPArray.MaxIndex()
	CallCounter = 1
	Buffer := LHCPArray[CallCounter]
}



Fn_CatalogueFiles()
{
global

	Loop, %LHCP_Dir%/*.* 														;Comment */
	{
	TotalFilestoRead += 1
	}

TotalFilesCompleted = 0
	Loop, %LHCP_Dir%/*.mp3 														;Cycle for mp3s */
	{
	StringTrimRight, FileName, A_LoopFileName, 4 ;Cut off the .mp3 or .wav

	;Set Array to Blank in case file is not formatted correctly.
	LHCP_Array1 =
	LHCP_Array2 =

	StringSplit, LHCP_Array, FileName, #, ;If # ever stops working, switch to %A_Tab%
	StringReplace, LHCP_Array2, LHCP_Array2, `^, `?, All

	filepath = %LHCP_Dir%\%A_LoopFileName%
	MP3Comments =
	Fn_id3read_length(filepath,object="msg")
	MP3Comments = %Comments%

		{ ;Length Stuff in here
		;Example length returns  "00:01:12"
		;SoundLength_Array1 = ;hour
		;SoundLength_Array2 = ;min
		;SoundLength_Array3 = ;sec
		StringSplit, SoundLength_Array, length, :, . ; Omits periods.   If # ever stops working, switch to %A_Tab%

		SoundLength_Array1 := SoundLength_Array1 * 3600
		SoundLength_Array2  := SoundLength_Array2 * 60
		SoundLength_Array3 := SoundLength_Array1 + SoundLength_Array2 + SoundLength_Array3

			; Sometimes weird files report no length or 0 seconds. If that is the case, assign it a length of 1
			If (SoundLength_Array3 = 0 || SoundLength_Array3 = "")
			{
			SoundLength_Array3 = 1
			}

			; Don't allow any clips over MAXCLIPLENGTH in the database file
			If (SoundLength_Array3 <= MaxClipLength && InStr(A_LoopFileName,"#"))
			{
			Fn_WriteMP3ToTxt()
			}

		}
	TotalFilesCompleted += 1
	vProgressBar := 100 * (TotalFilesCompleted / TotalFilestoRead)
	GuiControl,, ProgressBar1, %vProgressBar%
	}

	Loop, %LHCP_Dir%/*.wav														;Cycle for wav */
	{
	StringTrimRight, FileName, A_LoopFileName, 4 ;Cut off the .mp3 or .wav

	;Set Array to Blank in case file is not formatted correctly.
	LHCP_Array1 =
	LHCP_Array2 =

	StringSplit, LHCP_Array, FileName, #, ;If # ever stops working, switch to %A_Tab%
	StringReplace, LHCP_Array2, LHCP_Array2, `^, `?, All

	filepath = %LHCP_Dir%\%A_LoopFileName%
	MP3Comments =
	Fn_id3read_commentslength(filepath,object="msg")
	MP3Comments = %comments%

		{ ;Length Stuff in here
		;Example length returns  "00:01:12"
		SoundLength_Array1 = ;hour
		SoundLength_Array2 = ;min
		SoundLength_Array3 = ;sec
		StringSplit, SoundLength_Array, length, :, . ; Omits periods.   If # ever stops working, switch to %A_Tab%
		;Msgbox, %SoundLength_Array1% - %SoundLength_Array2% - %SoundLength_Array3%

		SoundLength_Array1 := SoundLength_Array1 * 3600
		SoundLength_Array2  := SoundLength_Array2 * 60
		SoundLength_Array3 := SoundLength_Array1 + SoundLength_Array2 + SoundLength_Array3

			If (SoundLength_Array3 = 0 || SoundLength_Array3 = "")
			{
			SoundLength_Array3 = 1
			}

			If (SoundLength_Array3 <= MaxClipLength && InStr(A_LoopFileName,"#"))
			{
			Fn_WriteWAVToTxt()
			}

		}

	}
GuiControl,, ProgressBar1, 0
}



Fn_WriteMP3ToTxt()
{
global


FileAppend,
(
%LHCP_Array1%   -%SoundLength_Array3%-   %LHCP_Array2%#%MP3Comments%

), %DataBaseFile%

}


Fn_WriteWAVToTxt()
{
global


FileAppend,
(
%LHCP_Array1%   -%SoundLength_Array3%-   %LHCP_Array2%#

), %DataBaseFile%

}


CountLines(filename)
{
global

	Loop, read, %A_WorkingDir%\data\%filename%
	{
	TotalQuoteLines += 1
	}
}



;TestString = This is a test.
;StringSplit, word_array, TestString, %A_Space%, .  ; Omits periods.
;MsgBox, The 4th word is %word_array4%.



Fn_HardCodedGlobals()
{
global

OnCheck = 1
MaxClipLength = 30
MasterList_Loc = %A_ScriptDir%\Data\LHCP_MasterList.ini
LHCP_Dir = %A_ScriptDir%\Data\Files
;;;DependenciesList = %A_ScriptDir%\Data\dependencies.ini
;;;Leeroy_Dir = %WoW_Dir%\Interface\AddOns\LeeroyHillCatsPower
}


;
;GUI
;

Fn_BuildGUI()
{
global

Gui, Add, Button, x292 y30 w100 h30 gAutoUpdate, Auto-Update
;Gui, Add, Button, x292 y70 w70 h30 gFolderSelect, Select WoW Dir
;Gui, Add, Button, x362 y70 w30 h30 gBuildDataBase, Build DB
;Gui, Add, CheckBox, x333 y10 w100 h20 Checked1 gSwitchOnOff, On
Gui, Add, Picture, x2 y10 w290 h56 , %A_ScriptDir%\Data\LHCP-X.png
Gui, Add, Text, x82 y90 w160 h20 , Chunjee - DownloadMob.com
Gui, Add, Text, x2 y90, %VERSIONNAME%
Gui, Add, Progress, cBlack x6 y70 w270 h10 vProgressBar1, 100
; Generated using SmartGUI Creator 4.0
Gui, Show, x375 y140 h107 w400, LHCP-X
}


GuiClose:
ExitApp

SwitchOnOff:
If (OnCheck = 1)
{
OnCheck = 0
}
else
{
OnCheck = 1
}
Return



MessageWindow()
{
global

Gui, 2: Add, Text, x12 y10 w450 h90 , LHCP-X has finished downloading %Number_FilesGrabbed% "official" soundsclips. Would you like to delete any non-official clips in your addon folder? The other option will generate a new LHCP_pkg.lua using the official clips plus any mp3/wav files you have in the folder. `n`nKeep in mind that your files need to follow this format: `ncommand#words to say.mp3
Gui, 2: Add, Button, x112 y100 w350 h70 gDeleteUnofficial, Just delete any extra soundfiles (Recommended)
Gui, 2: Add, Button, x12 y100 w90 h70 gGenerateLUA, Generate a new LCHP_pkg.lua
Gui, 2: Show, x267 y143 h184 w479, Finished downloading all files.

Gui, 2:+owner
Return
}



Fn_EmbeddedLUAMaker()
{
global

LuaFileName = LHCP_pkg.lua
FileDelete, %LHCP_Dir%\%LuaFileName%


Loop, %LHCP_Dir%/*.* ;Count all files in folder*/
{
TotalFiles_FM += 1
}

FileAppend,
(
local dir = "Interface\\AddOns\\LHCP_Mudabu\\"

if not LeeroyHillCatsPower_data
  or type(LeeroyHillCatsPower_data) ~= "table" then
	LeeroyHillCatsPower_data = {};
end


), %LHCP_Dir%/%LuaFileName%





Loop, %LHCP_Dir%/*.mp3 														;Cycle for mp3s */
{
StringTrimRight, FileName_FM, A_LoopFileName, 4 ;Cut off the .mp3 or .wav

;Set Array to Blank in case file is not formatted correctly.
LHCP_Array1 =
LHCP_Array2 =
LHCP_Array3 =

filepath = %LHCP_Dir%\%A_LoopFileName%
Fn_id3read_length(filepath,object="msg")



;FileReadLine, TXT_Line, %LHCP_Dir%\data\aegs.txt, %QuoteNumber%
StringSplit, LHCP_Array, FileName_FM, #, %A_Space% ; Omits periods.   If # ever stops working, switch to %A_Tab%
;Msgbox, %LHCP_Array1% ~ %LHCP_Array2% ~ %LHCP_Array3%

;Replace all ^ with question marks
StringReplace, LHCP_Array2, LHCP_Array2, `^, `?, All

	;Length Stuff in here
	{
	;Example length returns  "00:01:12"
	SoundLength_Array1 = ;hour
	SoundLength_Array2 = ;min
	SoundLength_Array3 = ;sec
	;Msgbox, %length%
	StringSplit, SoundLength_Array, length, :, . ; Omits periods.   If # ever stops working, switch to %A_Tab%
	;Msgbox, %SoundLength_Array1% - %SoundLength_Array2% - %SoundLength_Array3%

	SoundLength_Array1 := SoundLength_Array1 * 3600
	SoundLength_Array2  := SoundLength_Array2 * 60
	SoundLength_Array3 := SoundLength_Array1 + SoundLength_Array2 + SoundLength_Array3
		If (SoundLength_Array3 = 0 || SoundLength_Array3 = "")
		{
		SoundLength_Array3 = 1
		}

	}


	IfInString, A_LoopFileName, #
					{

FileAppend,
(

LeeroyHillCatsPower_data["%LHCP_Array1%"] = {
	["text"] = "* %LHCP_Array2% *",
	["file"] = dir.."%FileName_FM%",
	["duration"] = %SoundLength_Array3%.0,
};

), %LHCP_Dir%/%LuaFileName%

					}

TotalWrittentoFile += 1
vProgressBar := 100 * (TotalWrittentoFile / TotalFiles_FM)
GuiControl,, ProgressBar1, %vProgressBar%
}
Loop, %LHCP_Dir%/*.wav														;Cycle for wavs */
{
StringTrimRight, FileName_FM, A_LoopFileName, 4 ;Cut off the .mp3 or .wav

;Set Array to Blank in case file is not formatted correctly.
LHCP_Array1 =
LHCP_Array2 =
LHCP_Array3 =

filepath = %LHCP_Dir%\%A_LoopFileName%
Fn_id3read_length(filepath,object="msg")



;FileReadLine, TXT_Line, %LHCP_Dir%\data\aegs.txt, %QuoteNumber%
StringSplit, LHCP_Array, FileName_FM, #, %A_Space% ; If # ever stops working, switch to %A_Tab%
;Msgbox, %LHCP_Array1% ~ %LHCP_Array2% ~ %LHCP_Array3%

;Replace all ^ with question marks
StringReplace, LHCP_Array2, LHCP_Array2, `^, `?, All



	{ ;Length Stuff in here
	;Example length returns  "00:01:12"
	SoundLength_Array1 = ;hour
	SoundLength_Array2 = ;min
	SoundLength_Array3 = ;sec
	;Msgbox, %length%
	StringSplit, SoundLength_Array, length, :, . ; Omits periods.   If # ever stops working, switch to %A_Tab%
	;Msgbox, %SoundLength_Array1% - %SoundLength_Array2% - %SoundLength_Array3%

	SoundLength_Array1 := SoundLength_Array1 * 3600
	SoundLength_Array2  := SoundLength_Array2 * 60
	SoundLength_Array3 := SoundLength_Array1 + SoundLength_Array2 + SoundLength_Array3

		If (SoundLength_Array3 = 0 || SoundLength_Array3 = "")
		{
		SoundLength_Array3 = 1
		}
	}

	IfInString, A_LoopFileName, #
					{
FileAppend,
(

LeeroyHillCatsPower_data["%LHCP_Array1%"] = {
	["text"] = "* %LHCP_Array2% *",
	["file"] = dir.."%FileName_FM%",
	["duration"] = %SoundLength_Array3%.0,
};

), %LHCP_Dir%/%LuaFileName%
					}

Fn_ProgressBar()
}

;Msgbox, Finished creating %LuaFileName%
}

Fn_ProgressBar()
{
global



}

;~~~~~~~~~~~~~~~~~~~~~
; Other Peoples Functions: Credits to Respective Owners
;~~~~~~~~~~~~~~~~~~~~~


;ID3read by Seidenweber and Trubbleguy
Fn_id3read_length(filename,object="msg")
{
global

objShell := ComObjCreate("Shell.Application")

SplitPath,filename , ename,edir

oDir := objShell.NameSpace(eDir)
oMP3 := oDir.ParseName(eName)

;size := oDir.GetDetailsOf(oMP3, 1)
;Type := oDir.GetDetailsOf(oMP3, 2)
;fileformat := oDir.GetDetailsOf(oMP3, 9)
;Artist := oDir.GetDetailsOf(oMP3, 13)
;album := oDir.GetDetailsOf(oMP3, 14)
;year := oDir.GetDetailsOf(oMP3, 15)
;genre := oDir.GetDetailsOf(oMP3, 16)
;rating := oDir.GetDetailsOf(oMP3, 19)
;Title := oDir.GetDetailsOf(oMP3, 21)
;Comments := oDir.GetDetailsOf(oMP3, 24)
;Track := oDir.GetDetailsOf(oMP3, 26)
Length := oDir.GetDetailsOf(oMP3, 27)
;bitrate := oDir.GetDetailsOf(oMP3, 28)
;subtitle := oDir.GetDetailsOf(oMP3, 196)
;albumartist := oDir.GetDetailsOf(oMP3, 217)

;dtsa:= album "-" track "- " title " - " artist

return 1
}

Fn_id3read_commentslength(filename,object="msg")
{
global

objShell := ComObjCreate("Shell.Application")

SplitPath,filename , ename,edir

oDir := objShell.NameSpace(eDir)
oMP3 := oDir.ParseName(eName)

;size := oDir.GetDetailsOf(oMP3, 1)
;Type := oDir.GetDetailsOf(oMP3, 2)
;fileformat := oDir.GetDetailsOf(oMP3, 9)
;Artist := oDir.GetDetailsOf(oMP3, 13)
;album := oDir.GetDetailsOf(oMP3, 14)
;year := oDir.GetDetailsOf(oMP3, 15)
;genre := oDir.GetDetailsOf(oMP3, 16)
;rating := oDir.GetDetailsOf(oMP3, 19)
;Title := oDir.GetDetailsOf(oMP3, 21)
Comments := oDir.GetDetailsOf(oMP3, 24)
;Track := oDir.GetDetailsOf(oMP3, 26)
Length := oDir.GetDetailsOf(oMP3, 27)
;bitrate := oDir.GetDetailsOf(oMP3, 28)
;subtitle := oDir.GetDetailsOf(oMP3, 196)
;albumartist := oDir.GetDetailsOf(oMP3, 217)

;dtsa:= album "-" track "- " title " - " artist

return 1
}



;DownloadToFile by Bentschi
Fn_DownloadToFile(url, filename)
{
    static a := "AutoHotkey/" A_AhkVersion
    if (!(o := FileOpen(filename, "w")) || !DllCall("LoadLibrary", "str", "wininet") || !(h := DllCall("wininet\InternetOpen", "str", a, "uint", 1, "ptr", 0, "ptr", 0, "uint", 0, "ptr")))
        return 0
    c := s := 0
    if (f := DllCall("wininet\InternetOpenUrl", "ptr", h, "str", url, "ptr", 0, "uint", 0, "uint", 0x80003000, "ptr", 0, "ptr"))
    {
        while (DllCall("wininet\InternetQueryDataAvailable", "ptr", f, "uint*", s, "uint", 0, "ptr", 0) && s>0)
        {
            VarSetCapacity(b, s, 0)
            DllCall("wininet\InternetReadFile", "ptr", f, "ptr", &b, "uint", s, "uint*", r)
            c += r
            o.rawWrite(b, r)
        }
        DllCall("wininet\InternetCloseHandle", "ptr", f)
    }
    DllCall("wininet\InternetCloseHandle", "ptr", h)
    o.close()
    return c
}




VERSIONNAME = v0.0
Startup()
{
SetBatchLines -1 ;Go as fast as CPU will allow
#NoEnv ;performance and compatibility
#NoTrayIcon
#SingleInstance Off
}


Chat(Channel, Text)
{
	;IRC.Chat(Channel, Text)
	TCP := new SocketTCP()
	TCP.Connect("localhost", 26656)
	TCP.SendText(Channel "," Text)
}

Ini_Read(FileName)
{
	FileRead, File, %FileName%
	return File ? Ini_Reads(File) : ""
}

Ini_Reads(FileName)
{
	static RegEx := "^\s*(?:`;.*|(.*?)(?:\s+`;.*)?)\s*$"
	Section := Out := []
	Loop, Parse, FileName, `n, `r
	{
		if !(RegExMatch(A_LoopField, RegEx, Match) && Line := Match1)
			Continue
		if RegExMatch(Line, "^\[(.+)\]$", Match)
			Out[Match1] := (Section := [])
		else if RegExMatch(Line, "^\s*(.+?)\s*=\s*(.*?)\s*$", Match)
			Section[Match1] := Match2
	}
	return Out
}
