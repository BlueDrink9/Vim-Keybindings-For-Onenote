﻿; This script requires vim installed on the computer. It effectively diffs the results of sending the keys below to a new onenote page vs to a new vim document.
; Up and down are specifically lightly tested, as they will definitely do different things under vim.
; This may also be true of e, w and b, due to the way onenote handles words (treating punctuation as a word)

; Results are outputed as the current time and date in %A_ScriptDir%\testlogs

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance Force
#warn
;sendlevel, 1 ; So these commands get triggered by autohotkey.
SetTitleMatchMode 2 ; window title functions will match by containing the match text. 
SetKeyDelay, 50 ; Only affects sendevent, used for sending the test
; (gives vim scrpit time to react).

; Contains clipboard related functions, among others.
#include vim_onenote_library.ahk

TestsFailed := False
LogFileName = %A_Now%.txt ;%A_Scriptdir%\testlogs\%A_Now%.txt

; Initialise the programs
run, cmd.exe /r vim
winwait,  - VIM ; Wait for vim to start
send :imap jj <esc>{return} ; Prepare vim    
;TODO: Check if onenote already open. Or just ignore? multiple windows may cause problems.
;       May be fixed by making the switch specific to the test page.
run, onenote
winwait, - Microsoft OneNote ; Wait for onenote to start
WinActivate, - Microsoft OneNote
WinWaitActive, - Microsoft OneNote
send ^nVim Onenote Test{return} ; Create a new page in onenote, name it, move to text section
WinMaximize,Vim Onenote Test - Microsoft OneNote

run, %A_ScriptDir%/vim_onenote.ahk

; This is the text that all of the tests are run on, fresh.
SampleText =
({return}
This is the first line of the test, and contains a comma and a period.
Second line here
3rd line. The second line is shorter than both 1st and 3rd line.
The fourth line contains     some additional whitespace.
What should I put on the 5th line?A missing space, perhaps
This line 6 should be longer than the line before it and after it to test kj
No line, including 7, can be longer than 80 characters.
This is because onenote wraps automatically, (line 8)
And treats a wrapped line as separate lines (line 9)
)

; Put the comma before each test string to add it to the previous line.
; The test will be send from normal mode, with the cursor at the start of the sample text.
ArrayOfTests := ["" ; Base case, ensures the sample is entered the same between the two.
    ,"iAt start of first lin.{esc}ie{esc}IWord " ; Tests i,I
    ,"ahe {esc}A Also this." ] ; a, A]

RunTests(){
    Global ArrayOfTests
    for index, test in ArrayOfTests
    {
        TestAndCompareOutput(test)
    }
    EndTesting()
}

SwitchToVim(){
    WinActivate,  - VIM
    WinWaitActive,  - VIM
}

SwitchToOnenote(){
    WinActivate,Vim Onenote Test - Microsoft OneNote
    WinWaitActive,Vim Onenote Test - Microsoft OneNote
}

SendTestToOnenoteAndReturnResult(test){
    Global SampleText
    SwitchToOnenote()
    ; Ensure insert mode for the sample text.
    send i{backspace}
    ; Paste sample text. Faster, more reliable.
    SaveClipboard()
    Clipboard :=""
    Clipboard := SampleText
    Clipwait
    msgbox, %clipboard%
    send ^v ; Paste
    RestoreClipboard()
    msgbox you violated the law
    sleep, 1000
    ; Make sure we are in normal mode to start with, at start of text.
    send {esc}
    sleep, 20
    send ^{home} 
    sendevent %test%
    sleep, 1000
    send ^a^a^a ; Ensure we select all of the inserted text.
    output := GetSelectedText()
    ; Delete text ready for next test
    send {backspace}
    return output
}

SendTestToVimAndReturnResult(test){
    Global SampleText
    SwitchToVim()
    ; Ensure insert mode for the sample text.
    send i{backspace}
    send %SampleText%
    sleep, 1000
    ; Make sure we are in normal mode to start with, at start of text.
    send {esc}^{home}
    send %test%
    sleep, 1000
    SaveClipboard()
    clipboard= ; Empty the clipboard for clipwait to work
    send {esc}:`%d{+} ; select all text, cut to system clipboard
    send {return}
    ClipWait
    output := Clipboard
    RestoreClipboard()
    return output
}

TestAndCompareOutput(test){
    global Log
    OnenoteOutput := SendTestToOnenoteAndReturnResult(test)
    VimOutput := SendTestToVimAndReturnResult(test)
    CompareStrings(OnenoteOutput, VimOutput, test)
}

CompareStrings(OnenoteOutput, VIMOutput, CurrentTest){
    Global LogFileName
    Global TestsFailed
    msgbox Strings:`n%OnenoteOutput%`n%VIMOutput%
    file1 := FileOpen("OnenoteOutput", "w")
    file2 := FileOpen("VIMOutput", "w")
    file1.write(OnenoteOutput)
    file2.write(VIMOutput)
    file1.close()
    file2.close()

    ; This line runs the DOS fc (file compare) program and enters the reults in a file.
    ; Could also consider using comp.exe /AL instead, to compare individual characters. Possibly more useful.
    ; Comp sucks. Wow. Using fc, but only shows two lines: the different one and the one after. Hard to see, but it'll do for now.
    DiffResult := ComObjCreate("WScript.Shell").Exec("cmd.exe /q /c fc.exe /LB2 /N OnenoteOutput VIMOutput").StdOut.ReadAll() 
    msgbox %DiffResult%
    IfNotInString, DiffResult, FC: no differences encountered
    {
        msgbox, differences found.
        TestsFailed := True
        LogFile := FileOpen(LogFileName, "w")
        LogFile.Write("Test = `"%CurrentTest%`"`n%DiffResult%`n`n")
        msgbox is the file there? %LogFileName%
        LogFile.Close()
    }
    FileDelete, OnenoteOutput
    FileDelete, VIMOutput
}

; Tidy up, close programs.
EndTesting(){
    Global TestsFailed
    Global LogFileName
    ; Delete the new page in onenote
    SwitchToOnenote()
    send ^+A
    send {delete}
    SwitchToVim()
    send :q{!}
    send {return} ; Exit vim.
   
    msgbox testsfailed: %testsfailed%
    if (TestsFailed == True)
    {
        msgbox,4,,At least one test has failed!`nResults are in %LogFileName%`nOpen log? 
        IfMsgBox Yes
        {
            run %LogFileName%
        }
    }else{
        msgbox, All tests pass!
    }
    ExitApp
}

RunTests()

; All 4 modifier keys + b initiates test.
;^!+#b::SendTestCommands()
