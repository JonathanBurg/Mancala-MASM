; Main Program
; Jonathan Burgener
; 30 October, 2024
; Controls the flow of the program
; 
; 
; Routines:
;		main()
;		exitProgram()

.386P
.model	flat

extern	_ExitProcess@4:		near
extern	initialize_console:	near
extern	start:				near
extern	charCount:			near
extern	writeLine:			near


.data
	exitmsg 		byte	10,10,10,"Hello World!",0	; Exit message


.code

;;******************************************************************;
;; Call main()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	None
;; 
;; Starts the program and transfers control to start
;;******************************************************************;
main PROC near
_main:
	call  initialize_console
	call  start
	call  exitProgram			; Exit the program with exit code 5
main ENDP


;;******************************************************************;
;; Call exitProgram()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	EAX, EDX
;; 
;; Exits the program with a message to the user.
;;******************************************************************;
exitProgram PROC near
_exitProgram:
	 ; Write an exit message for the user
	push  offset exitmsg
	call  writeLine

	 ; ExitProcess(uExitCode)
	push  5						; Push exit code 5
	call  _ExitProcess@4
exitProgram ENDP

END

;;******************************************************************;
;; Call routineName(param)
;; Parameters:		param	--	Parameters in stack in reverse order
;; Returns:			retVal	--	What does it return
;; Registers Used:	EAX <(s)> {If saved and restored at the end}
;; 
;; Description
;;******************************************************************;