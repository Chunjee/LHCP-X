#NoEnv  ; Recommended for performance and compatibility
;#NoTrayIcon
#SingleInstance force
SetWorkingDir %A_ScriptDir%
DataBaseFile = %A_ScriptDir%\LHCP_MasterList.ini
FileDelete, %A_ScriptDir%\LHCP_MasterList.ini

Loop, %A_ScriptDir%/*.* ;*/
{	
	IfNotInString, A_LoopFileName, .ahk
	{
FileAppend,
(
%A_LoopFileName%

), %DataBaseFile%
	}
}	
ExitApp