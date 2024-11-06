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
; 
; 
; Routines:
;		start()
;		userInput()
;		checkMove(move)
;		

.386P

.model flat

extern	readline:		 near	; readWrite.asm
extern	charCount:		 near	; readWrite.asm
extern	writeline:		 near	; readWrite.asm
extern	writeln:		 near	; readWrite.asm
extern	writeNum:		 near	; readWrite.asm
extern	writeNumber:	 near	; readWrite.asm
extern	readInt:		 near	; readWrite.asm
extern	exitProgram:	 near	; main.asm
extern	initializeBoard: near	; board.asm
extern	printBoard:		 near	; board.asm
extern	updateStones:	 near	; board.asm


.data

num1			DD		?		; first number for each iteration
num2			DD		?		; second number for each iteration
itr				DD		?		; iterator to make sure only 45 terms are printed
active			DD		?		; Number to represent active player
move			DD		?		; Current move being made
msg				byte	"Hello, World", 10, 0						; ends with line feed (10) and NULL
prompt			byte	"What pit do you choose?: ", 0				; ends with string terminator (NULL or 0)
p1				byte	"Player 1", 0								; Universal string for indicating player 1
p2				byte	"Player 2", 0								; Universal string for indicating player 2
t				byte	"'s turn.", 10, 0							; Line end for prompting which player is active
picked			byte	" picked pit ", 0							; Message confirming movement choice
extra			byte	" ended in their Mancala! Go again.", 10, 0	; Message telling active player they got an extra move
movBnds			byte	"Move out of bounds: Please enter a number between 1 and 6!", 10, 0	; Message to tell off active player
endrd			byte	"  ", 10, 10, 0
error			byte	"Program ran into error, stopping...", 10, 0; Critical error encountered
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
	mov   active, 1				; Initialize active with a 1
	call  initializeBoard

top:
	push  active
	call  printBoard			; Print the board
	mov   move, 0
	call  userInput				; Get user input
	pop   move					; Save move

	push  active
	call  writePlayer			; Write "Player 1" or "Player 2"
	push  offset picked
	call  writeline				; Send a message to the user say the active player has picked their move
	push  move
	call  writeNum				; Repeat the user''s choice back to them
	call  writeln				; End the line

	push  move					; Push move for move check
	call  checkMove				; Check that the move is valid
	pop   eax					; Pop move success state from the stack
	
	cmp   eax, 1				; If the move is valid (=1)
	je    validMove				; Jump to validMove
	jmp   endRound				; Else restart round

validMove:
	call  updateStones			; Update the board
	pop   eax					; Get state

	cmp   eax, 1				; If move was valid and normal
	je    moveValid				; Jump to moveValid
	cmp   eax, 2				; If active player ended in their mancala
	call  writeln				; End the line
	jmp   endRound				; Else restart round

moveValid:
	push  active
	call  switchActive			; Switch the active player
	pop   active				; Pop new active player in active
	jmp   endRound				; Start new round

extraMove:
	push  active
	call  writePlayer			; Write the active player
	push  offset extra			; Tell the active player they got an extra turn
	jmp   endRound				; Start new round

endRound:
	push  offset endrd			; Create space in between the text for different lines
	call  writeline				; Write the line breaks
	jmp   top					; Start the new round

exit:
	ret							; Return to the main program.
start ENDP


;;******************************************************************;
;; Call userInput()
;; Parameters:		None
;; Returns:			Number inputed by user
;; Registers Used:	EAX, EDX
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
	push  offset prompt			; Push the prompt to the stack
	call  readInt				; Get the user input
	pop   eax					; Pop input value from the stack

exit:
	pop   edx					; Pop return address from the stack into EDX
	push  eax					; Push the input value to the stack
	push  edx					; Restore return address to the stack
	ret

errorEncountered:
	push  offset error
	call  writeline
	call  exitProgram
userInput ENDP


;;******************************************************************;
;; Call checkMove(move)
;; Parameters:		move	--	number of the pit the player chose
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
	push  edx					; Restore return address to the stack

	 ; Check that the number is valid
_check:
	cmp   eax, 1
	jl    _invalid				; If the move is less than 1, the move is invalid
	cmp   eax, 6
	jg    _invalid				; If the move is more than 6, the move is invalid
	jmp   _valid					; If the move is between 1 and 6, the move is valid

	 ; Return a 0 if the move was out of bounds
_invalid:
	push  offset movBnds
	call  writeline				; Tell off the player
	pop   edx					; Pop return address from the stack into EDX
	push  0						; Return a 0 in the stack to indicate the move was out of bounds
	push  edx					; Restore return address to the stack
	ret							; Return with a 0 in the stack

	 ; Return a 1 if the move was valid
_valid:
	pop   edx					; Pop return address from the stack into EDX
	push  1						; Return a 1 in the stack to indicate the move was valid
	push  edx					; Restore return address to the stack
	ret							; Return with a 1 in the stack
checkMove ENDP

;;******************************************************************;
;; Call switchActive(active)
;; Parameters:		active	--	number for current active player
;; Returns:			newActive	--	number for new active player
;; Registers Used:	EAX, EDX
;; 
;; Toggle between player 1 and player 2
;;******************************************************************;
switchActive PROC near
_switchActive:
	pop   edx					; Pop return address from the stack into EDX
	pop   eax					; Pop player number into EAX
	push  edx					; Restore return address to the stack

	cmp	  eax, 1				; If player 1 is wanted
	je    _play1				; Jump to play1
	cmp   eax, 2				; If player 2 is wanted
	je    _play2				; Jump to play2
	jmp   _errorEncountered		; Else jump to errorEncountered

_play1:
	pop   edx					; Pop return address from the stack into EDX
	push  2						; Push 2 to the stack
	push  edx					; Restore return address to the stack
	ret							; Return with player 2 as new active player

_play2:
	pop   edx					; Pop return address from the stack into EDX
	push  1						; Push 1 to the stack
	push  edx					; Restore return address to the stack
	ret							; Return with player 1 as new active player

_errorEncountered:
	push  offset error
	call  writeline
	call  exitProgram
switchActive ENDP


;;******************************************************************;
;; Call writePlayer(player)
;; Parameters:		player	--	player to print
;; Returns:			Nothing
;; Registers Used:	EAX, EDX
;; 
;; Write "Player 1" or "Player 2" depending on what player is wanted
;;******************************************************************;
writePlayer PROC near
_writePlayer:
	pop   edx					; Pop return address from the stack into EDX
	pop   eax					; Pop player number into EAX
	push  edx					; Restore return address to the stack
	
	cmp	  eax, 1				; If player 1 is wanted
	je    _play1					; Jump to play1
	cmp   eax, 2				; If player 2 is wanted
	je    _play2					; Jump to play2
	jmp   _errorEncountered		; Else jump to errorEncountered

_play1:
	push  offset p1
	call  writeline
	ret

_play2:
	push  offset p2
	call  writeline
	ret

_errorEncountered:
	push  offset error
	call  writeline
	call  exitProgram
writePlayer ENDP

END