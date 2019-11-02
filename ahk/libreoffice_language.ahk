; Change current LibreOffice document language to British English.
; works in Finnish locale.

^!l:: ; ctrl-alt-L
SetTitleMatchMode, 2 ; Partial titles OK
; Only run if we're currently in a LibreOffice Writer window
IfWinNotActive, LibreOffice Writer ahk_class SALFRAME
    Return
; Go to menu bar
Send, !y ; T[y]ökalut
Send, i ; K[i]eli
Send, o ; K[o]ko tekstille
Send, l ; [L]isää...
WinActivate, Kieliasetukset ahk_class SALSUBFRAME
Send, !l ; [L]änsimainen:
Send, {Home} ; beginning of the list
Send, b ; first language that begins with b
Send, {Down}
Send, {Down}
Send, {Down}
Send, {Down}
Send, {Down}
Send, {Down} ; I think we've reached "brittienglanti"
Send, {Enter} ; OK
Return