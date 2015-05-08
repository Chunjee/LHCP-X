#NoTrayIcon
#SingleInstance force

SetWorkingDir %A_ScriptDir%
Working_Directory = %A_WorkingDir%


;~~~~~~~~~~~~~~~~~~~~~
;In Progress
;~~~~~~~~~~~~~~~~~~~~~

LuaFileName = LHCP_pkg.lua
FileDelete, %A_WorkingDir%\%LuaFileName%
Day:= %A_Now%
Day+=1, d
FormatTime, Day,%Day%, dddd
TotalFiles = 0


Loop, %A_WorkingDir%/*.* ;Count all files in folder*/		
{
TotalFiles += 1
}

BuildGUI()

FileAppend,
(
local dir = "Interface\\AddOns\\LHCP_Mudabu\\"

if not LeeroyHillCatsPower_data
  or type(LeeroyHillCatsPower_data) ~= "table" then
	LeeroyHillCatsPower_data = {};
end


), %A_WorkingDir%/%LuaFileName%





Loop, %A_WorkingDir%/*.mp3 														;Cycle for mp3s */
{
StringTrimRight, FileName, A_LoopFileName, 4 ;Cut off the .mp3 or .wav
;Msgbox, %FileName%
;Set Array to Blank in case file is not formatted correctly.
LHCP_Array1 = 
LHCP_Array2 = 
LHCP_Array3 = 

filepath = %A_WorkingDir%\%A_LoopFileName%
Fn_id3read(filepath,object="msg")



;FileReadLine, TXT_Line, %A_WorkingDir%\data\aegs.txt, %QuoteNumber%
StringSplit, LHCP_Array, FileName, #, ; Omits periods.   If # ever stops working, switch to %A_Tab%
;Msgbox, %LHCP_Array1% ~ %LHCP_Array2% ~ %LHCP_Array3%

;Command = %LHCP_Array1%

;take space out of command variable ~~~~~~~~WORK IN PROGRESS~~~~~~~~~~~~~
;StringReplace, Command, Command, %A_SPACE%, , All
;StringReplace, LHCP_Array1, LHCP_Array1, %A_SPACE%, , All
;FileMove, %A_WorkingDir%\%A_LoopFileName%, %A_WorkingDir%\%Command%#%LHCP_Array2%#%LHCP_Array3%

;Replace all ^ with question marks
StringReplace, LHCP_Array2, LHCP_Array2, `^, `?, All


	;Length Stuff in here
	{
	;Example length returns  "00:01:12"
	SoundLength_Array1 = ;hour
	SoundLength_Array2 = ;min
	SoundLength_Array3 = ;sec
	;Msgbox, %length%
	StringSplit, SoundLength_Array, length, :, 
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
	["file"] = dir.."%FileName%",
	["duration"] = %SoundLength_Array3%.0,
};

), %A_WorkingDir%/%LuaFileName%

					}
	
Fn_ProgressBar()
}
Loop, %A_WorkingDir%/*.wav														;Cycle for wavs */
{
StringTrimRight, FileName, A_LoopFileName, 4 ;Cut off the .mp3 or .wav

;Set Array to Blank in case file is not formatted correctly.
LHCP_Array1 = 
LHCP_Array2 = 
LHCP_Array3 = 

filepath = %A_WorkingDir%\%A_LoopFileName%
Fn_id3read(filepath,object="msg")



;FileReadLine, TXT_Line, %A_WorkingDir%\data\aegs.txt, %QuoteNumber%
StringSplit, LHCP_Array, FileName, #, ; Omits periods.   If # ever stops working, switch to %A_Tab%
;Msgbox, %LHCP_Array1% ~ %LHCP_Array2% ~ %LHCP_Array3%

;Replace all ^ with question marks
StringReplace, LHCP_Array2, LHCP_Array2, `^, `?, All


;Command = %LHCP_Array1%
;take space out of command variable ~~~~~~~~WORK IN PROGRESS~~~~~~~~~~~~~
;StringReplace, Command, Command, %A_SPACE%, , All
;StringReplace, LHCP_Array1, LHCP_Array1, %A_SPACE%, , All
;FileMove, %A_WorkingDir%\%A_LoopFileName%, %A_WorkingDir%\%Command%#%LHCP_Array2%#%LHCP_Array3%

	
	
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
	["file"] = dir.."%FileName%",
	["duration"] = %SoundLength_Array3%.0,
};

), %A_WorkingDir%/%LuaFileName%
					}

Fn_ProgressBar()
}

;Msgbox, Finished creating %LuaFileName%

ExitApp





;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
;Functions
;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\

Fn_ProgressBar()
{
global

Sleep 4
TotalWrittentoFile += 1
vProgressBar := 100 * (TotalWrittentoFile / TotalFiles)
GuiControl,, UpdateProgress, %vProgressBar%
}

BuildGUI()
{
Global
;Gui, Show, x130 y90 h100 w200, LHCP-FileMaker
;Gui, Add, Text, x100 y3, Progress
;Gui, Add, Progress, x2 y20 w190 h10 vUpdateProgress, 1
;Gui, Add, GroupBox, x2 y20 w190 h20 , Progress
;Gui, Show, x127 y87 h608 w489, Scratch Detector


Gui, Add, GroupBox, x2 y20 w370 h40 , Progress
Gui, Add, Progress, x12 y40 w350 h10 vUpdateProgress, 1
Gui, Add, Text, x120 y3 w350 h20 , by Chunjee - DownloadMob.com
; Generated using SmartGUI Creator 4.0
Gui, Show, x127 y87 h75 w387, LHCP-FileMaker
Return
Return
}

GuiClose:
ExitApp


InsertTitle(Text)
{
FileAppend,
(
%Text%
), %A_WorkingDir%/%LuaFileName%
}
return

F6::
ListVars
return


InsertBlank(void)
{
FileAppend,
(


), %A_WorkingDir%/%LuaFileName%
}
return



Fn_id3read(filename,object="msg")
{
global

objShell := ComObjCreate("Shell.Application")
	
SplitPath,filename , ename,edir

oDir := objShell.NameSpace(eDir)
oMP3 := oDir.ParseName(eName)
  
comments := oDir.GetDetailsOf(oMP3, 24)
Length := oDir.GetDetailsOf(oMP3, 27)

return 1
}