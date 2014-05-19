; VIM Keybinds for onenote.
;---------------------------------------
;---------------------------------------

;---------------------------------------
; Usage - Run vim_onenote.ahk, or autohotkey vim_onenote.ahk
;---------------------------------------

; Acknolwedgements:
; This is based on a vim autohotkey script which I can no longer find. If you find it, please tell me and I'll add it to the acknolwedgements
;---------------------------------------

; Settings
;---------------------------------------
;#NoTrayIcon ; NoTrayIcon hides the tray icon.
#SingleInstance Force ; SingleInstance makes the script automatically reload.

; The code itself.
;---------------------------------------
;---------------------------------------

Suspend, On ; TBD - Document how this works.

SetTitleMatchMode 2 ;- Mode 2 is window title substring.
#IfWinActive, OneNote ; Only apply this script to onenote.

; ESC enters Command Mode
ESC::
	Suspend, Off
	ToolTip, OneNote Vim Command Mode Active, 0, 0
return

; Return to regular mode.
TypingMode:
	ToolTip
	Suspend, On
return


+i::
    SendInput, {Home}
    Gosub TypingMode

return 

i::Gosub TypingMode
return 

; vi left and right

h::SendInput, {Left}
return 
l::SendInput, {Right}
return 

; vi up and down.
;  Onenote does some magic that blocks up/down processing. See more @ 
; (Onenote 2013) http://www.autohotkey.com/board/topic/74113-down-in-onenote/
; (Onenote 2007) http://www.autohotkey.com/board/topic/15307-up-and-down-hotkeys-not-working-for-onenote-2007/
j::SendInput,^{down}
return 
k::SendInput,^{up}
return 

x::SendInput, {Delete}
return 

+a::
SendInput, {End}
Gosub TypingMode
return 

a::
SendInput, {Right}
Gosub TypingMode
return 

+o::
Send, {home}^{up}{End}{Enter}
Gosub TypingMode
return

o::
Send, {End}{Enter}
Gosub TypingMode
return

u::Send, ^z
return 
^~::Send, ^y
return 
w::
; TBD - Design a more generic way to implement the <command> <motion> pattern. For now hardcode dw. 
if (A_PriorHotkey == "d" and A_TimeSincePriorHotkey < 400)
{
    Send, {ShiftDown}
    ^{Right}
    Send, {Del}
    Send, {Shift}
    return
}
Send, ^{Right}
return 
b::Send, ^{Left}
return 
+4::Send, {End}
return 
0::Send, {Home}
return 
+6::Send, {Home}
return 
+5::Send, ^b
return 
^f::Send, {PgDn}
return 
^b::Send, {PgUp}

;; TBD Design a more generic <command> <motion> pattern, for now implement yy and dd the most commonly used commands.
y::
if (A_PriorHotkey <> "y" or A_TimeSincePriorHotkey > 400)
{
    return
}
Send, {Home}{ShiftDown}{End}
Send, ^c
Send, {Shift}
return 

+d::
Send, {ShiftDown}{End}
Send {Del}
Send, {ShiftUp}
return

d::
if (A_PriorHotkey <> "d" or A_TimeSincePriorHotkey > 400)G
{
    return
}
Send, {Home}{ShiftDown}{End}
Send, {Del}
Send, {Shift}
return 

; TODO handle regular paste , vs paste something picked up with yy
; current behavior assumes yanked with yy.
p::
Send, {End}{Enter}^v
return

; swap case of current letter - doesn't work need to debug.
~::
    ; push clipboard to local variable
    ClipSaved := ClipboardAll

        ; copy 1 charector
        Send, {ShiftDown}{Right}
        Send, ^c
        Send, {Shift}

        ; invert char
        char_to_invert:= Substr(Clipboard, 1, 1)
        if char_to_invert is upper
           inverted_char := Chr(Asc(char_to_invert) + 32)
        else if char_to_invert is lower
           inverted_char := Chr(Asc(char_to_invert) - 32)
        else
           inverted_char := char_to_invert

        ;paste char.
        ClipBoard := inverted_char
        Send ^v{left}{right} 

        ;restore original clipboard
        Clipboard := ClipSaved
        ClipWait
    ClipSaved := ; free memory

return

; z  is the fold fold command.

z::
; multi threading is confusing in autohotkey and is getting triggered when you press the second key in the sequence.
; so turn off the hotkeys while running the input command, and turn them back on. 
; Note, you can only disable hotkeys that are implemented (in this case o)

hotkey o, off
hotkey +o, off
hotkey c, off
    Input, SingleKey, L1
hotkey o, on
hotkey +o, on
hotkey c, on

if SingleKey = c
{
    SendInput, !+-
}
else if SingleKey = o
{
    SendInput, !+{+}
}
return

; Eat all other keys if in command mode.
c::
e::
f::
g::
m::
n::
r::
s::
t::
return

