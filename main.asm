; MASM Template
; Jonathan Burgener
; Thursday, September 9, 2024
; Create a template for Assembly programs
; 
; Revised: JB, 30 October, 2024 - Updated processes

.386P
.model	flat
extern	_ExitProcess@4:		near
extern	initialize_console:	near
extern	start:		near
extern  charCount:	near
extern  writeline:	near


.data
	exitmsg 	byte	10,10,10,"Hello World!",0 ; Exit message


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
	call initialize_console
	call start
	call exit
main ENDP


;;******************************************************************;
;; Call exit()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	EAX
;; 
;; Exits the program with a message to the user.
;;******************************************************************;
exit PROC near
_exit:
	 ; Write an exit message for the user
	;push  offset exitmsg
	;call  charCount
	;push  eax
	push  offset exitmsg
	call  writeline

	 ; ExitProcess(uExitCode)
	push  5
	call  _ExitProcess@4
exit ENDP

END

;;******************************************************************;
;; Call routineName(param)
;; Parameters:		param - Parameters in stack in reverse order
;; Returns:			What does it return
;; Registers Used:	EAX <(s)> {If saved and restored at the end}
;; 
;; Description
;;******************************************************************;