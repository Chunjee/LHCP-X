;This is just needed when people don't format their mp3 files properly
;and I need to rename a lot of their files according to what they have in a lua file
;Hardcoded to only work with MP3s, easy to change


SetBatchLines -1 ;Go as fast as CPU will allow
#NoEnv  ;performance and compatibility
#NoTrayIcon
#SingleInstance Force

Memory_Array := []


FileSelectFile, The_SelectedFile , %A_ScriptDir%, 2, Please select the lua file
FileRead, The_MemoryFile, % The_SelectedFile


X = 0
NoMoreJobs := False
  While (!NoMoreJobs) {
  Job := Fn_QuickRegEx(The_MemoryFile,"(_data[\S\s\n\r]+?};)")
    If (Job != "null") {
    ;Remove Job from Bigger Memoryfile
    The_MemoryFile := StrReplace(The_MemoryFile, Job, "")


    ;Grab important Strings
    REG = _data\["([\w\s:\d]+)"
    Command := Fn_QuickRegEx(Job,REG)
    REG = dir.."([\w\d !]+)"
    CurrentFileName := Fn_QuickRegEx(Job,REG)
    Phrase := Fn_QuickRegEx(Job,"\* (.+) \*")
    ;Msgbox, %Command% - %CurrentFileName% - %Phrase%

      If (Command != "null" && Phrase != "null" && CurrentFileName != "null") {
      X++
      Memory_Array[X,"Command"] := Command
      Memory_Array[X,"Phrase"] := Phrase
      Memory_Array[X,"CurrentFilePath"] := A_ScriptDir . "\" . CurrentFileName . ".mp3"
      }
    } Else {
    NoMoreJobs := True
    }
}



;Move and rename all files if possible
  Loop, % Memory_Array.MaxIndex() {
  Phrase := Memory_Array[A_Index,"Phrase"]
  Phrase := StrReplace(Phrase, "?", "^")

  Current := Memory_Array[A_Index,"CurrentFilePath"]
  Destination := A_ScriptDir . "\" . Memory_Array[A_Index,"Command"] . "#" . Phrase . ".mp3"

  ;Msgbox, % Current . "`n" . Destination

  FileMove, %Current%, %Destination%
    If (Errorlevel) {
    Msgbox, % "!!!!!!!!!!Couldn't move " . Memory_Array[A_Index,"CurrentFilePath"]
    }
  }
ExitApp



  ;Quick RegEx for quick matches. Remember to include match parenthesis (\d+).+ Returns matched value
  ;Fn_QuickRegEx(A_LoopRealLine,"(\d+)")
  Fn_QuickRegEx(para_Input,para_RegEx,para_ReturnValue := 1)
  {
  	RegExMatch(para_Input, para_RegEx, RE_Match)
  	If (RE_Match%para_ReturnValue% != "")
  	{
  	ReturnValue := RE_Match%para_ReturnValue%
  	Return %ReturnValue%
  	}
  Return "null"
  }
