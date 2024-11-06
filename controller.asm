; Main Control Program
; Jonathan Burgener
; 30 October, 2024
; Manages user input and uses board and boardController to move and print the board
; Revised: JB, 6 November 2024 - Added move check
; 
; Register names:
; Register names are NOT case sensitive eax and EAX are the same register
; x86 uses 8 registers. EAX (Extended AX register has 32 bits while AX is
;	the right most 16 bits of EAX). AL is the right-most 8 bits.
; Writing into AX or AL effects the right most bits of EAX.
;		EAX - caller saved register - usually used for communication between
;				caller and callee.
;		EBX - Callee saved register
;		ECX - Caller saved register - Counter register 
;		EDX - Caller Saved register - data, I use it for saving and restoring
;				the return address
;		ESI - Callee Saved register - Source Index
;		EDI - Callee Saved register - Destination Index
;		ESP - Callee Saved register - stack pointer
;		EBP - Callee Saved register - base pointer

.386P

.model flat

extern	writeline:	 near
extern	readline:	 near
extern	charCount:	 near
extern	writeNumber: near
extern	writeNum:	 near
extern	exitProgram: near
extern	printBoard:	 near


.data

num1			DD		?		; first number for each iteration
num2			DD		?		; second number for each iteration
itr				DD		?		; iterator to make sure only 45 terms are printed
active			DD		?		; Number to represent active player
msg				byte	"Hello, World", 10, 0					; ends with line feed (10) and NULL
prompt			byte	"What pit do you choose?: ", 10, 0		; ends with string terminator (NULL or 0)
p1				byte	"Player 1",0							; Universal string for indicating player 1
p2				byte	"Player 2",0							; Universal string for indicating player 2
t				byte	"'s turn.",10,0							; Line end for prompting which player is active
movBnds			byte	"Move out of bounds: Please enter a number between 1 and 6!",10,0
endln			byte	"    ", 10, 0
error			byte	"Program ran into error, stopping...",10,0
termBuffer		byte	", ",0
results			byte	?		; buffer to print vars
numCharsToRead	dword	1024
bufferAddr		dword	?


.code

;;******************************************************************;
;; Call start()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	EAX
;; 
;; Library calls used for input from and output to the console
;; This is the entry procedure that does all of the testing.
;;******************************************************************;
start PROC near
_start:
	 ; Do Something
	 mov  active, 1				; Initialize active with a 1

top:
	 call userInput				; Get user input
exit:
	ret							; Return to the main program.
start ENDP


;;******************************************************************;
;; Call userInput()
;; Parameters:		None
;; Returns:			Number inputed by user
;; Registers Used:	
;; 
;; Gets input from the user to determine what move is desired
;;******************************************************************;
userInput PROC near
_userInput:
	 ; Check who the active player is.
	cmp   active, 1
	je    pl1
	jl    errorEncountered
	cmp   active, 2
	je    pl2
	jg    errorEncountered
	

	
pl1:
	 ; Write "Player 1" to console
	push  offset p1
	call  writeline
	jmp   endPrompt

pl2:
	 ; Write "Player 2" to console
	push  offset p2
	call  writeline
	jmp   endPrompt

endPrompt:
	push  offset t				; Write "'s Turn, what pit do you choose?: " to finish the prompt
	call  writeline


exit:
	ret

errorEncountered:
	push  offset error
	call  writeline
	call  exitProgram
userInput ENDP


;;******************************************************************;
;; Call checkMove(move, active)
;; Parameters:		move	--	number of the pit the player chose
;;					active	--	number for the active player
;; Returns:			state	--	value to indicate what occured
;; Registers Used:	EAX, EBX, EDX
;; 
;; Check if the move is within the bounds of the player''s side
;; 
;; State:
;;		0: Move failed
;;		1: Move was a success
;;******************************************************************;
checkMove PROC near
_checkMove:
	pop   edx					; Pop return address from the stack into EDX
	pop   eax					; Pop pit number into EAX
	pop   ebx					; Pop active player into EBX
	push  edx					; Restore return address to the stack

	 ; Check that the number is valid
check:
	cmp   eax, 1
	jl    invalid				; If the move is less than 1, the move is invalid
	cmp   eax, 6
	jg    invalid				; If the move is more than 6, the move is invalid
	jmp   valid					; If the move is between 1 and 6, the move is valid

	 ; Return a 0 if the move was out of bounds
invalid:
	push  offset movBnds
	pop   edx					; Pop return address from the stack into EDX
	push  0						; Return a 0 in the stack to indicate the move was out of bounds
	push  edx					; Restore return address to the stack
	ret							; Return with a 0

	 ; Update the board and return a 1 if the move was valid, 0 if there were no stones left in pit
valid:
	push  ebx
	push  eax
	call  updateBoard			; Update the board
	pop   eax					; Pop success value into eax
	pop   edx					; Pop return address from the stack into EDX
	push  eax					; Return with success value in stack
	push  edx					; Restore return address to the stack
	ret							; Return
checkMove ENDP


END