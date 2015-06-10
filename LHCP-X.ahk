;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Description
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
; Expandable LHCP
; Accepts any string as argument. Include a "||" in front of string to play any file that includes that string.
; Run without a command lie argument it will launch its own GUI


;~~~~~~~~~~~~~~~~~~~~~
;Compile Options
;~~~~~~~~~~~~~~~~~~~~~
SetBatchLines -1 ;Go as fast as CPU will allow
The_Version = v0.1.1
Startup()
Sb_InstalledFiles()


;Dependencies
#Include %A_ScriptDir%\Functions
#Include sort_arrays
#Include util_arrays
#Include util_misc
#Include json_obj
#Include Socket.ahk
#Include Json.ahk


;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
;StartUp
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
Clips_Dir := A_ScriptDir . "\Data\Clips"
DataBase_Loc := A_ScriptDir . "\Data\LHCP_DataBase.json"

;;Always load settings
	SettingsFile := A_ScriptDir . "\Data\Settings.ini"
	Settings := Ini_Read(SettingsFile)
	If (Settings.Server.LHCP_Channel = "") {
	;Msgbox, There was a problem reading your LHCP Channel
	}

;;Always load pre-existing LHCP DataBase
FileCreateDir, % Clips_Dir
	If (FileExist(DataBase_Loc)) {
	FileRead, MemoryFile, % DataBase_Loc
	LHCP_Array := Fn_JSONtooOBJ(MemoryFile)
	MemoryFile := ;BLANK
	}
	;If the DB does not exists or has very few entries
	If (!FileExist(DataBase_Loc) || LHCP_Array.MaxIndex() < 2) {
	;Rethink this
	LHCP_Array := Fn_GenerateDB()
	}


;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
;MAIN
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
CLI_Arg = %1%
	;;Create GUI if run with no cli-arguments
	If (!CLI_Arg) {
	Sb_BuildGUI()
	Gui, +Enable
	Fn_HardCodedGlobals()
	LHCP_Array := Fn_GenerateDB()
	Return
	}

	;launched with CLI argument
	If (CLI_Arg) {
		If (CLI_Arg = "jason") {
		Fn_GenerateDB()
		}
		If (CLI_Arg = "stop") {
		Sb_CloseAllInstances()
		Exitapp
		}
		If (InStr(CLI_Arg,"|")) {
		StringReplace, CLI_Arg, CLI_Arg, `|,, All
		Temp_Array := []
		X = 0
			Loop, % LHCP_Array.MaxIndex() {
				If(InStr(LHCP_Array[A_Index,"Command"],CLI_Arg) || InStr(LHCP_Array[A_Index,"Phrase"],CLI_Arg)) {
				X ++
				Temp_Array[X,"Command"] := LHCP_Array[A_Index,"Command"]
				Temp_Array[X,"Phrase"] := LHCP_Array[A_Index,"Phrase"]
				Temp_Array[X,"FilePath"] := LHCP_Array[A_Index,"FilePath"]
				}
			}
		;Choose random out of possible matches and play it
		Random, Rand, 1, Temp_Array.MaxIndex()
		SoundPlay, % Temp_Array[Rand,"FilePath"], 1
		;Msgbox, % Rand . "    " . Temp_Array[Rand,"FilePath"]
		ExitApp
		} Else {
			Loop, % LHCP_Array.MaxIndex() {
				If (CLI_Arg = LHCP_Array[A_Index,"Command"]) {
				SoundPlay, % LHCP_Array[A_Index,"FilePath"], 1
				ExitApp
				}
			}
		}
	ExitApp
	}





;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Buttons & Hotkeys
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

^F7::
Reload

;~~~~~~~~~~~~~~~~~~~~~
;Download All Files, build new DB
;~~~~~~~~~~~~~~~~~~~~~
Button-AutoUpdate:
;Create Dir
FileCreateDir, % Clips_Dir

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

	CurrentFile := Clips_Dir . "\" . FinalFileName
	StringReplace, CurrentFile, CurrentFile, `n,, All
	StringReplace, CurrentFile, CurrentFile, `r,, All
		;Download if not in collection
		If (!FileExist(CurrentFile)) {
		UrlDownloadToFile, %DropboxURL2%, %CurrentFile%
		}
	TotalDownloaded ++
	vProgressBar := 100 * (TotalDownloaded / Txt_Array.MaxIndex())
	GuiControl,, ProgressBar1, %vProgressBar%
	}
;DONE - Generate new DB and set progressbar to 0
LHCP_Array := Fn_GenerateDB()
GuiControl,, ProgressBar1, 0

;DEPRECIATED - Ask user if the want to delete any unofficial files
;;;MessageWindow()
Return


;~~~~~~~~~~~~~~~~~~~~~
; Open Selection GUI
;~~~~~~~~~~~~~~~~~~~~~
Button-SectionGUI:
Sb_SelectionGUI()
Return


;~~~~~~~~~~~~~~~~~~~~~
;Delete unneeded
;~~~~~~~~~~~~~~~~~~~~~
DeleteUnofficial:
FileDelete, %Clips_Dir%\LHCP_pkg.lua
;UrlDownloadToFile, https://dl.dropboxusercontent.com/u/268814505/LHCP/LHCP_pkg.lua, %Clips_Dir%\LHCP_pkg.lua
DeletedFiles_Counter = 0
Gui, 2: Destroy
Sb_BuildGUI()
	Loop, %Clips_Dir%/*.* ;*/
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
		FileDelete, %Clips_Dir%\%CurrentFileName%
		}

	}
	Fn_EmbeddedLUAMaker()
	Fn_CatalogueFiles()
;Msgbox, The database has been created.
Fn_LoadtoMemory(DataBaseFile)
Msgbox, Your LHCP folder has been cleaned of %DeletedFiles_Counter% files.
Return



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
;Hotkeys
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/


;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; GUI
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

Sb_BuildGUI()
{
global

Gui, Add, Button, x292 y20 w100 h30 gButton-AutoUpdate, Auto-Update
Gui, Add, Button, x292 y50 w100 h30 gButton-SectionGUI, Selection GUI
;Gui, Add, Button, x292 y70 w70 h30 gFolderSelect, Select WoW Dir
;Gui, Add, Button, x362 y70 w30 h30 gBuildDataBase, Build DB
;Gui, Add, CheckBox, x333 y10 w100 h20 Checked1 gSwitchOnOff, On
Gui, Add, Picture, x2 y10 w290 h56 , %A_ScriptDir%\Data\LHCP-X.png
Gui, Add, Text, x82 y90 w160 h20 , Chunjee - DownloadMob.com
Gui, Add, Text, x2 y90, %The_Version%
Gui, Add, Progress, cBlack x6 y70 w270 h10 vProgressBar1, 100

;Show basic GUI after created
Gui, Show, x400 y100 h107 w400, LHCP-X
}



Sb_SelectionGUI()
{
global

Gui, submit ;Hide old GUI

Gui, Selection: Add, Picture, x4 y0 w200 h30 , %A_ScriptDir%\Data\LHCP-X.png
Gui, Selection: Add, Edit, x2 y40 w596 h20 gUserInput vGUI_UserInput, !
Gui, Selection: Add, ListView, x2 y70 w596 h536 Grid +ReDraw gDoubleClick vGUI_Listview, Command|Length|Phrase|


;Gui, Selection: Add, Button, x400 y4 w100 h30 gButton-Disable, ToggleSelected
;Gui, Selection: Add, Button, x500 y4 w100 h30 gButton-EnableAll, Enable All

;Switch Selection GUI to default for Listview stuff
Gui, Selection:Default
	;Spit all 
	Loop, % LHCP_Array.MaxIndex() {
		If (LHCP_Array[A_Index,"Disabled"] = 1) {
		Status = ✓
		} Else {
		Status =
		}
	LV_Add("",LHCP_Array[A_Index,"Command"],LHCP_Array[A_Index,"SecLength"],LHCP_Array[A_Index,"Phrase"])
	}
;Show basic GUI after created
Gui, Selection: Show, h600 w600, LHCP-X
;Gui, Selection: +owner
LV_ModifyCol()
}


DoubleClick:
;Play file or send it to chat
	If A_GuiEvent = DoubleClick
	{
	;Get the text from the row's 2nd field. Command
	LV_GetText(RowText, A_EventInfo, 2)
	RowText = %RowText% ;Remove spaces
		If (RowText != "") {
		;Send to LHCP Channel
		Chat("#LHCP-XBeta", "/" . RowText)
		;IRC.SendPRIVMSG("#LHCP-XBeta", Rowtext)
		Return
		}
	}
Return


UserInput:
;Update Listview to reflect what user entered
Gui, Submit, NoHide
LV_Delete()

	Loop, % LHCP_Array.MaxIndex() {
		If(InStr(LHCP_Array[A_Index,"Command"],GUI_UserInput) || InStr(LHCP_Array[A_Index,"Phrase"],GUI_UserInput)) {
		LV_Add("",LHCP_Array[A_Index,"Command"],LHCP_Array[A_Index,"SecLength"],LHCP_Array[A_Index,"Phrase"])
		}
	}
Return


Button-Disable:
;Disable or enables selected file
Return


Button-EnableAll:
;Enables all files
Return

SelectionGuiClose:
GuiClose:
Sb_CloseAllInstances()
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

Gui, WarningWindow: Add, Text, x12 y10 w450 h90 , LHCP-X has finished downloading %Number_FilesGrabbed% "official" soundsclips. Would you like to delete any non-official clips in your addon folder? The other option will generate a new LHCP_pkg.lua using the official clips plus any mp3/wav files you have in the folder. `n`nKeep in mind that your files need to follow this format: `ncommand#words to say.mp3
Gui, WarningWindow: Add, Button, x112 y100 w350 h70 gDeleteUnofficial, Just delete any extra soundfiles (Recommended)
Gui, WarningWindow: Add, Button, x12 y100 w90 h70 gGenerateLUA, Generate a new LCHP_pkg.lua
Gui, WarningWindow: Show, x267 y143 h184 w479, Finished downloading all files.

Gui, WarningWindow: +owner
Return
}



;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;DEPRECIATING GUI STUFF
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; FUNCTIONS
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

Fn_GenerateDB()
{
global LHCP_Array
;Need Existing LHCP_Array so we can update it without re-reading everything from scratch
TempArray := []
	
	Total_mp3s = 0
	Loop, %A_ScriptDir%\Data\Clips\*#*.mp3 , 1
	{
	Total_mp3s ++
	}
	
	;Loop all mp3 files
	Loop, %A_ScriptDir%\Data\Clips\*#*.mp3 , 1
	{
	Command := Fn_QuickRegEx(A_LoopFileName,"(.+)#")
	Phrase := Fn_QuickRegEx(A_LoopFileName,"#(.+)")
	
	;Get clip length from existing array if at all possible
		
	Length := Fn_id3return_length(A_LoopFileFullPath,object="msg")
	
		;Convert Length to seconds only
		{
		Hours := 120 * Fn_QuickRegEx(Length,"(\d+):")
		Minutes := 60 * Fn_QuickRegEx(Length,":(\d+):")
		Seconds := Fn_QuickRegEx(Length,":(\d+)$")
		Length := Hours + Minutes + Seconds
			If (Length < 1) {
			Length = 1 ;Assign length of 1 if  less than 1
			}
		}
	
		;Only remember correctly formatted mp3's
		If (Command != "null" && Phrase != "null") {
		TempArray[A_Index,"FilePath"] := A_LoopFileFullPath
		TempArray[A_Index,"Command"] := Command
		TempArray[A_Index,"Phrase"] := Phrase
		TempArray[A_Index,"SecLength"] := Length
		}
	Fn_UpdateProgressBar("ProgressBar1",A_Index,Total_mp3s)
	}
	
	Fn_UpdateProgressBar("ProgressBar1","0","0")
	;Write out the newley created Array and return it for the MAIN
	;MemoryFile := Fn_JSONfromOBJ(TempArray)
	FileDelete, %A_ScriptDir%\Data\LHCP_DataBase.json
	FileAppend, % Fn_JSONfromOBJ(TempArray), %A_ScriptDir%\Data\LHCP_DataBase.json
	Return % TempArray
}


Fn_UpdateProgressBar(para_ProgressBarVar,para_Current,para_Max)
{
global
	Percent := (para_Current / para_Max) * 100
	Percent := Fn_PercentCheck(Percent)
		If (para_Current = 0 && para_Max = 0) {
		Percent = 0
		}
GuiControl,, %para_ProgressBarVar%, %Percent% ;Change the progressbar percentage
;Return %para_Current%
}


Fn_PercentCheck(para_Input)
{
;Checks to ensure that the input var is not under 1 or over 100, essentially for percentages
para_Input := Ceil(para_Input)
	If (para_Input >= 100)
	{
	Return 100
	}
	If (para_Input <= 1)
	{
	Return 1
	}
Return %para_Input%
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

	Loop, %Clips_Dir%/*.* 														;Comment */
	{
	TotalFilestoRead += 1
	}

TotalFilesCompleted = 0
	Loop, %Clips_Dir%/*.mp3 														;Cycle for mp3s */
	{
	StringTrimRight, FileName, A_LoopFileName, 4 ;Cut off the .mp3 or .wav

	;Set Array to Blank in case file is not formatted correctly.
	LHCP_Array1 =
	LHCP_Array2 =

	StringSplit, LHCP_Array, FileName, #, ;If # ever stops working, switch to %A_Tab%
	StringReplace, LHCP_Array2, LHCP_Array2, `^, `?, All

	filepath = %Clips_Dir%\%A_LoopFileName%
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

	Loop, %Clips_Dir%/*.wav														;Cycle for wav */
	{
	StringTrimRight, FileName, A_LoopFileName, 4 ;Cut off the .mp3 or .wav

	;Set Array to Blank in case file is not formatted correctly.
	LHCP_Array1 =
	LHCP_Array2 =

	StringSplit, LHCP_Array, FileName, #, ;If # ever stops working, switch to %A_Tab%
	StringReplace, LHCP_Array2, LHCP_Array2, `^, `?, All

	filepath = %Clips_Dir%\%A_LoopFileName%
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


Fn_HardCodedGlobals()
{
global

OnCheck = 1
MaxClipLength = 30
MasterList_Loc = %A_ScriptDir%\Data\LHCP_MasterList.ini
;;;DependenciesList = %A_ScriptDir%\Data\dependencies.ini
;;;Leeroy_Dir = %WoW_Dir%\Interface\AddOns\LeeroyHillCatsPower
}


Sb_CloseAllInstances()
{
;Close all instances of LHCP-X
	Loop, 10
	{
	Process, Close, LHCP-X.exe
	}
ExitApp
}



Fn_EmbeddedLUAMaker()
{
global

LuaFileName = LHCP_pkg.lua
FileDelete, %Clips_Dir%\%LuaFileName%


Loop, %Clips_Dir%/*.* ;Count all files in folder*/
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


), %Clips_Dir%/%LuaFileName%





Loop, %Clips_Dir%/*.mp3 														;Cycle for mp3s */
{
StringTrimRight, FileName_FM, A_LoopFileName, 4 ;Cut off the .mp3 or .wav

;Set Array to Blank in case file is not formatted correctly.
LHCP_Array1 =
LHCP_Array2 =
LHCP_Array3 =

filepath = %Clips_Dir%\%A_LoopFileName%
Fn_id3read_length(filepath,object="msg")



;FileReadLine, TXT_Line, %Clips_Dir%\data\aegs.txt, %QuoteNumber%
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

), %Clips_Dir%/%LuaFileName%

					}

TotalWrittentoFile += 1
vProgressBar := 100 * (TotalWrittentoFile / TotalFiles_FM)
GuiControl,, ProgressBar1, %vProgressBar%
}
Loop, %Clips_Dir%/*.wav														;Cycle for wavs */
{
StringTrimRight, FileName_FM, A_LoopFileName, 4 ;Cut off the .mp3 or .wav

;Set Array to Blank in case file is not formatted correctly.
LHCP_Array1 =
LHCP_Array2 =
LHCP_Array3 =

filepath = %Clips_Dir%\%A_LoopFileName%
Fn_id3read_length(filepath,object="msg")



;FileReadLine, TXT_Line, %Clips_Dir%\data\aegs.txt, %QuoteNumber%
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

), %Clips_Dir%/%LuaFileName%
					}

Fn_ProgressBar()
}

;Msgbox, Finished creating %LuaFileName%
}

Fn_ProgressBar()
{
global
;lol wat
}


Fn_id3return_length(filename,object="msg")
{

objShell := ComObjCreate("Shell.Application")
SplitPath,filename , ename,edir
oDir := objShell.NameSpace(eDir)
oMP3 := oDir.ParseName(eName)
Length := oDir.GetDetailsOf(oMP3, 27)
Return %Length%
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


Chat(Channel, Text)
{
	TCP := new SocketTCP()
	TCP.Connect("localhost", 26656)
	TCP.SendText(Channel "," Text)
}

class IRC
{
	static _ := IRC := new IRC() ; Automatically initialize base object
	__Call(Name, Params*)
	{
		TCP := new SocketTCP()
		TCP.Connect("localhost", 26656)
		TCP.SendText(Json_FromObj({MethodName: Name, Params: Params}))
		return Json_ToObj(TCP.recvText()).return
	}
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


Startup()
{
#NoEnv ;performance and compatibility
#NoTrayIcon
#SingleInstance Off
}


Sb_InstalledFiles()
{
global

;FileInstall, Source, Dest [, Overwrite = 1
FileCreateDir, %A_ScriptDir%\Data\
FileCreateDir, %A_ScriptDir%\Data\Clips
FileInstall, LHCP-X.png, %A_ScriptDir%\Data\LHCP-X.png, 1
}