; MASM Template
; Jonathan Burgener
; Thursday, September 9, 2024
; Create a template for Assembly programs

.386P
.model flat

extern	_ExitProcess@4:	near
extern	charCount:		near
extern	writeline:		near
extern	initialize_console:	near

.data
	exitmsg		byte	10, 10, "Hello World!", 0	; ends with line feed (10) and NULL

.code

main PROC near
_main:
	call	initialize_console
	call	exitProgram

main ENDP

; Exit program with message
exitProgram PROC near
_exitProgram:
	; Write an exit message for the user
	push  offset exitmsg
	call  charCount
	push  eax
	push  offset exitmsg
	call  writeline
	
	 ; ExitProcess(uExitCode)
	push  0
	call  _ExitProcess@4
exitProgram ENDP
	
END