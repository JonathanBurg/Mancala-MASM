;; Main Control Program
;; Jonathan Burgener
;; 30 October, 2024
;; Manages user input and uses board and boardController to move and print the board
;; Revised: JB, 6 November 2024 - Added move check
;; Revised: JB, 23 November 2024 - Added instructions. Added controls to exit program, 
;;										start new game, or pull up instructions. Split
;;										up start proccess to smaller proccesses
;; 
;; Register names:
;; Register names are NOT case sensitive eax and EAX are the same register
;; x86 uses 8 registers. EAX (Extended AX register has 32 bits while AX is
;;	the right most 16 bits of EAX). AL is the right-most 8 bits.
;; Writing into AX or AL effects the right most bits of EAX.
;;		EAX - caller saved register - usually used for communication between
;;				caller and callee.
;;		EBX - Callee saved register
;;		ECX - Caller saved register - Counter register 
;;		EDX - Caller Saved register - data, I use it for saving and restoring
;;				the return address
;;		ESI - Callee Saved register - Source Index
;;		EDI - Callee Saved register - Destination Index
;;		ESP - Callee Saved register - stack pointer
;;		EBP - Callee Saved register - base pointer
;; 
;; 
;; Routines:
;;		start()
;;		userInput()
;;		checkMove(move)
;;		

INCLUDE Irvine32.inc

exitProgram		proto			; main.asm
initializeBoard	proto			; board.asm
printBoard		proto			; board.asm
updateStones	proto			; board.asm
movePit			proto			; board.asm
getCaptPit		proto			; board.asm (for post processing)
charCount		proto			; readWrite.asm
writeLine		proto			; readWrite.asm
writeln			proto			; readWrite.asm
writeNum		proto			; readWrite.asm
writeNumber		proto			; readWrite.asm
readInteger		proto			; readWrite.asm
readIntegerC	proto			; readWrite.asm
pauseProgram	proto			; readWrite.asm
clearConsole	proto			; readWrite.asm
setForeground	proto			; readWrite.asm
setBackground	proto			; readWrite.asm
writePlayer		proto			; readWrite.asm
writePlayers	proto			; readWrite.asm


.data

num1			DD		?		; first number for each iteration
num2			DD		?		; second number for each iteration
itr				DD		?		; iterator to make sure only 45 terms are printed
active			DD		?		; Number to represent active player
move			DD		?		; Current move being made
roundNum		DD		?		; Round count
msg				byte	"Hello, World", 10, 0						; ends with line feed (10) and NULL
prompt			byte	"What pit do you choose?: ", 0				; ends with string terminator (NULL or 0)
turn			byte	" turn!", 10, 0								; Line end for prompting which player is active
picked			byte	" picked pit ", 0							; Message confirming movement choice
extra			byte	" ended in their Mancala! Go again.", 10, 0	; Message telling active player they got an extra move
captured		byte	" captured a pit ", 0						; Message telling active player they captured a pit
movBnds			byte	"Move out of bounds: Please enter a number between 1 and 6!", 10, 0	; Message to tell off active player
invldInput		byte	"Move is invalid. Please enter a number between 1 and 6!", 10,
						"For additional help, enter 12.", 10, 0
noStones		byte	"Selected pit is empty. Please select a different pit!", 10, 0
round			byte	"Round ", 0									; Message to give round count
endrd			byte	"  ", 10, 10, 0
roundBuffer		byte	"======================== ", 0
error			byte	"Program ran into error, stopping...", 10, 0; Critical error encountered
invalidPlayer	byte	"Player number is invalid!", 10, 0			; Error if the player number was invalid
checkRestart	byte	"Are you sure you want to start a new game?", 10, "(1 to continue, 0 to cancel): ", 0
gameRestarted	byte	"Game Restarted!", 10, 10, 0				; Message saying a new game has been started
gameWin			byte	" won the game! GG!", 10, 0					; Message for a player winning
gameTie			byte	"Game ended in a Tie!", 10, 0				; Message saying the game tied
newGmPrompt		byte	"Start new game? (1 for yes): ", 0			; Prompt to start a new game or not
results			byte	?		; buffer to print vars
numCharsToRead	dword	1024
bufferAddr		dword	?
retAddrDump		DD		?		; Value to dump return addresses into to keep stack managable to prevent a stack daisy chain from creating a stack overflow.


;; Instructions on how to play the game.
;; Under multiple variables because the text is too long.
instructions	byte	"Thanks for choosing Mancala for your game today!", 10,
						"In case you dont know how to play, here is a quick rundown of the rules:", 10, 10,
						"   This game is a turn-based, two player game. There are six pits on each players' ", 10,
						"   side and a Mancala (large pit) on either side. At the start, the 6 pits on each ", 10,
						"   side have 4 stones each, and the mancalas are empty.", 10, 10, 0
instructions2	byte	"   Decide who goes first.", 10, 10,
						"   Each turn the active player picks up all the stones in one of their own pits. ", 10,
						"   Starting with the next pit over (counter-clockwise), drop one stone in each pit ", 10,
						"   including your own Mancala and skipping your opponents Mancala.", 10,
						"      ", 249, " If the last stone is dropped in your own Mancala, you get to play again.", 10, 0
instructions3	byte	"      ", 249, " If the last stone is dropped into an empty pit on your own side and there", 10,
						"            are stones in the pit opposite the pit where you dropped the last stone,", 10,
						"            then you get to capture your own stone and all the stones in the", 10,
						"            opposite pit and place them all in your own Mancala.", 10, 0
instructions4	byte	"      ", 249, " Otherwise, play transfers to the other player.", 10, 10,
						"   When all the pits on one side are empty, the game ends and the other player gets ", 10, 
						"   to take all of the stones on their own side and place those stones into their own ", 10,
						"   Mancala. The winner is whoever has the most stones in their Mancala.", 10, 10, 0
inputCodes		byte	"Input Codes:", 10,
						"   10: Exit Program", 10,
						"   11: Restart Game", 10,
						"   12: See these instructions", 10, 0


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
	call  seeInstructions		; Pull up instructions
	call  startGame				; Start a game

;; End the program
_exit:
	ret							; Return to the main program.
start ENDP


;;******************************************************************;
;; Call startGame()
;; Parameters:		None
;; Returns:			Return address removed
;; Registers Used:	None
;; 
;; Starts a new game of Mancala. Used at start of program and when
;; a restart is initialized.
;;******************************************************************;
startGame PROC near
_startGame:
	pop   retAddrDump			; Clear return address
	mov   active, 1				; Initialize active with a 1
	mov   roundNum, 1			; Set round count to 1
	call  initializeBoard		; Set up board
	call  newRound
startGame ENDP


;;******************************************************************;
;; Call newRound()
;; Parameters:		None
;; Returns:			Return address removed
;; Registers Used:	None
;; 
;; Starts a new round with the round number and printing the board.
;;******************************************************************;
newRound PROC near
_newRound:
	;; Print border at top
	pop   retAddrDump			; Remove return address from stack
	call  writeln				; Start new line
	 ; Write left side of border
	cmp   active, 1				; Set color depending on active player
	je    _play1Left
	jmp   _play2Left
_play1Left:
	push  14					; Number for light cyan
	jmp   _writeLeft			; Continue
_play2Left:
	push  15					; Number for light magenta
	jmp   _writeLeft			; Continue
_writeLeft:
	call  setForeground			; Set text color
	push  offset roundBuffer	; Print left side of buffer
	call  writeLine
	 ; Write round number
	cmp   active, 1				; Set color depending on active player
	je    _play1
	jmp   _play2
_play1:
	push  7						; Number for blue
	jmp   _writeBorder			; Continue
_play2:
	push  4						; Number for red
	jmp   _writeBorder			; Continue
_writeBorder:
	call  setForeground			; Set text color
	push  offset round			; Print round message
	call  writeLine
	push  roundNum				; Print round number
	call  writeNumber
	 ; Write border on left side
	cmp   active, 1				; Set color depending on active player
	je    _play1Right
	jmp   _play2Right
_play1Right:
	push  14					; Number for light cyan
	jmp   _writeRight			; Continue
_play2Right:
	push  15					; Number for light magenta
	jmp   _writeRight			; Continue
_writeRight:
	call  setForeground			; Set text color
	push  offset roundBuffer	; Print right side of buffer
	call  writeLine
	call  writeln				; Start a new line
	;; Print the board
	push  active
	call  printBoard			; Print the board
	inc   roundNum				; Increment round number
	;; Start round
	call  gameRound				; Do actions
newRound ENDP


;;******************************************************************;
;; Call gameRound()
;; Parameters:		none
;; Returns:			Return address removed
;; Registers Used:	None (how did I manage that?)
;; 
;; Controls the flow of a round
;;******************************************************************;
gameRound PROC near
_gameRound:
	pop   retAddrDump			; Clear return address
	mov   move, 0
	call  userInput				; Get user input
	pop   move					; Save move
	cmp   move, 9				; If input is not a pit
	jg    _alternateInstructions; Go to alternate instructions handling

;; Check if move is valid
_checkMove:
	push  move					; Push move for move check
	call  checkMove				; Check that the move is valid. If move is invalid, program cant return to here
	jmp   _normalMove			; Else it is a normal move

;; If input is not a normal move
_alternateInstructions:
	cmp   move, 12				; Check if move is greater than 12
	jg    _checkMove			; If move is higher than 12, move is not valid.
	call  extraInput			; Proccess input

;; Input is not an extra control input
_normalMove:
	push  active
	call  writePlayer			; Write "Player 1" or "Player 2"
	push  offset picked
	call  writeLine				; Send a message to the user say the active player has picked their move
	push  move
	call  writeNum				; Repeat the user''s choice back to them
	call  writeln				; End the line

	; Process move
	push  move
	push  active
	call  movePit				; Returns with state in EAX

	call  postProcessing

	; No return address
gameRound ENDP


;;******************************************************************;
;; Call ExtraInput(inputVal)
;; Parameters:		inputVal --	Value from user input (move)
;; Returns:			Return address removed
;; Registers Used:	EAX
;; 
;; Processes addition action options for starting a new game (11), 
;; ending the program (10), and seeing the instructions (12).
;;******************************************************************;
extraInput PROC near
_extraInput:
	pop   retAddrDump			; Remove return address from stack
	cmp   move, 10				; If input is 10
	je    _exit					; Exit program
	cmp   move, 11				; If input is 11
	je    _restartGame			; Restart Game
	cmp   move, 12				; If the input is 12
	je    _instructions			; Pull up instructions

;; End program
_exit:
	call  exitProgram

;; Show the game instructions to the players
_instructions:
	call  seeInstructions		; Present the instructions
	push  active				; Push the active player number
	call  printBoard			; Print the board
	call  gameRound				; Continue round

;; Confirm if user wants to restart game
_restartGame:
	call  clearConsole			; Clear console
	push  offset checkRestart	; Send message to user to confirm restart
	call  readInt				; Get confirmation input from user
	call  clearConsole			; Clear the console
	pop   eax					; Pop confirmation into EAX
	cmp   eax, 1				; Check if response is a yes
	je    _restartConfirmed		; If yes, restart game
	push  active
	call  printBoard			; If no, Print the board
	call  gameRound				;	 and continue round

;; Restart game after confirmation from user
_restartConfirmed:
	push  offset gameRestarted	; Print restart status
	call  writeLine				; Write to console
	call  startGame				; Start a new game
	call  exitProgram			; Just in case
extraInput ENDP


;;******************************************************************;
;; Call invalidInput()
;; Parameters:		None
;; Returns:			Return address removed
;; Registers Used:	None
;; 
;; Input was invalid, so tell off the player and go back to start of
;; round.
;;******************************************************************;
invalidInput PROC near
_invalidInput:
	pop   retAddrDump			; remove return address
	push  offset invldInput		; Tell off user
	call  writeLine				; Write to console
	call  gameRound				; Restart round
invalidInput ENDP


;;******************************************************************;
;; Call postProcessing(state)
;; Parameters:		state	--	State move ended with
;; Returns:			Return address removed
;; Registers Used:	EAX
;; 
;; Processes the different return codes from the board.
;; States:
;;		1 - Move success
;;		2 - Extra Move
;;		3 - Invalid Active Player Number
;;		4 - Empty Pit
;;		5 - Invalid Pit Number
;;		6 - Captured Pit
;;		7 - Game Over, player 1 wins
;;		8 - Game Over, player 2 wins
;;		9 - Game Over, Tie
;;******************************************************************;
postProcessing PROC near
_postProcessing:
	pop  retAddrDump			; Remove return address
	pop  eax					; Pop state into EAX

	cmp   eax, 1				; If move was valid and normal,
	je    _moveNormal			;	 Jump to moveValid
	cmp   eax, 2				; If active player ended in their mancala,
	je    _extraMove			;	 Active player gets another move
	cmp   eax, 3				; If the player number was not valid,
	je    _invalidPlayerNum		;	 Jump to invalidPlayerNum
	cmp   eax, 4				; If the selected pit was empty,
	je    _emptyPit				;	 Have the player select another pit
	cmp   eax, 5				; If the pit number was invalid,
	je    _capturedPit			;	 Have the player select another pit
	cmp   eax, 6				; If the active player captured a pit,
	je    _capturedPit			;	 Praise them then continue as if it were a normal move
	cmp   eax, 7				; If Player 1 won the game,
	je    _player1Win			;	 congratuate them, then start a new game or exit
	cmp   eax, 8				; If Player 2 won the game,
	je    _player2Win			;	 congratuate them, then start a new game or exit
	cmp   eax, 9				; If the game ends in a tie,
	je    _noWinner				;	 Console the players, then start a new game or exit
	call  exitProgram			; Else, exit the program

;; Return state 1 - Move success
;; Normal Move, start next round after switching active player
_moveNormal:
	call  writeln				; Start new line
	call  writeln				; Ditto
	push  active
	call  printBoard			; Print the board
	push  active				; Push active player
	call  switchActive			; Switch the active player
	pop   active				; Pop new active player in active
	call  pauseProgram			; Create pause
	call  newRound				; Start new round

;; Return state 2 - Extra Move
;; If last stone placed ended, start new round without switching active player
_extraMove:
	call  writeln				; Start a new line
	push  active
	call  writePlayer			; Write the active player
	push  offset extra			; Tell the active player they got an extra turn
	call  writeLine
	push  active
	call  printBoard			; Print the board
	call  gameRound				; Give extra move

;; Return state 3 - Invalid Active Player Number (Fatal Error)
_invalidPlayerNum:
	push  offset invalidPlayer	; Send a message that the player number was lost
	call  writeLine				; Write to console
	push  offset error			; Print a message saying an error was encountered
	call  writeLine				; Write to console
	call  exitProgram			; End program (Fatal error)

;; Return state 4 - Empty Pit
;; The selected pit was empty, not a big problem, just go back to input.
_emptyPit:
	push  offset noStones		; Tell user there are no stones in the selected pit
	call  writeLine
	call  gameRound				; Restart round

;; Return state 6 - Captured Pit
;; If a pit is captured, inform player then continue like a normal move
_capturedPit:
	call  writeln				; Start a new line
	push  active
	call  writePlayer			; Write the active player
	push  offset captured		; Print that the active player captured a pit
	call  writeLine
	call  getCaptPit			; Get the index of the captured pit (pit number kept in stack to be written to console)
	call  writeNumber			; Write the number
	call  writeln				; Start a new line
	jmp   _moveNormal			; End post processing like a normal move

;; Return state 7 - Game Over, player 1 wins
;; Player 1 won the game. Check if user wants to start a new game.
_player1Win:
	call  clearConsole			; Clear the console
	push  1						; Push Player 1 as active so players can see end result
	call  printBoard			; Print the board
	push  1						; Tell writePlayer which player to write
	call  writePlayer			; Write "Player 1" to console
	push  offset gameWin		; Write win message
	call  writeLine				; Write to console
	jmp   _newGameAsk			; Ask if user wants to start a new game

;; Return state 8 - Game Over, player 2 wins
;; Player 2 won the game. Check if user wants to start a new game.
_player2Win:
	call  clearConsole			; Clear the console
	push  1						; Push Player 1 as active so players can see end result
	call  printBoard			; Print the board
	push  2						; Tell writePlayer which player to write
	call  writePlayer			; Write "Player 2" to console
	push  offset gameWin		; Write win message
	call  writeLine				; Write to console
	jmp   _newGameAsk			; Ask if user wants to start a new game

;; Return state 9 - Game Over, Tie
;; Game ended in a tie. Check if user wants to start a new game.
_noWinner:
	call  clearConsole			; Clear the console
	push  1						; Push Player 1 as active so players can see end result
	call  printBoard			; Print the board
	push  offset gameTie		; Write tied game message
	call  writeLine				; Write to console
	jmp   _newGameAsk			; Ask if user wants to start a new game

;; Ask user whether to start a new game
_newGameAsk:
	push  offset newGmPrompt	; Push prompt
	call  readInt				; Get user confirmation
	pop   eax					; User response
	cmp   eax, 1				; Check if response is an affirmative
	je    _startNewGame			; If yes, start a new game
	call  exitProgram			; Else, end the program

;; Start a new game
_startNewGame:
	call clearConsole			; Clear the console
	call startGame				; Start a new game
postProcessing ENDP


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
	jl    _errorEncountered
	cmp   active, 2
	jg    _errorEncountered

	push  TRUE					; Push TRUE for possesive
	push  active				; Tell writePlayer what player to write
	call  writePlayers			; Write "Player #'s" to console

_endPrompt:
	push  offset turn			; Write "Turn, what pit do you choose?: " to finish the prompt
	call  writeLine
	push  12					; Number for light green
	call  setForeground			; Set text color to light green
	push  green					; Push Irvine number for green
	push  offset prompt			; Push the prompt to the stack
	call  readIntegerC			; Get the user input
	pop   eax					; Pop input value from the stack

_exit:
	pop   edx					; Pop return address from the stack into EDX
	push  eax					; Push the input value to the stack
	push  edx					; Restore return address to the stack
	ret

_errorEncountered:
	call  writeln
	push  2
	call  writeNumber
	call  writeln
	push  offset error
	call  writeLine
	call  exitProgram
userInput ENDP


;;******************************************************************;
;; Call checkMove(move)
;; Parameters:		move	--	number of the pit the player chose
;; Returns:			Nothing
;; Registers Used:	EAX, EBX, EDX
;; 
;; Check if the move is within the bounds of the player''s side
;; If move is not valid, return address is removed from stack to
;; keep stack size managable from an over abundance of calls to the
;; caller
;;******************************************************************;
checkMove PROC near
_checkMove:
	pop   edx					; Pop return address from the stack into EDX
	pop   eax					; Pop pit number into EAX
	push  edx					; Restore return address to the stack

;; Check that the number is valid
_check:
	cmp   eax, 1
	jl    _invalid				; If the move is less than 1, the move is invalid
	cmp   eax, 6
	jg    _invalid				; If the move is more than 6, the move is invalid
	jmp   _valid				; If the move is between 1 and 6, the move is valid

;; Return a 0 if the move was out of bounds
_invalid:
	pop   edx					; Remove return address from stack
	call  invalidInput			; Restart round
	call  exitProgram			; Preventing the stack from overflowing

;; Return a 1 if the move was valid
_valid:
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

;; Return with player 2 as active player
_play1:
	pop   edx					; Pop return address from the stack into EDX
	push  2						; Push 2 to the stack
	push  edx					; Restore return address to the stack
	ret							; Return with player 2 as new active player

;; Return with player 1 as active player
_play2:
	pop   edx					; Pop return address from the stack into EDX
	push  1						; Push 1 to the stack
	push  edx					; Restore return address to the stack
	ret							; Return with player 1 as new active player

;; Report a fatal error
_errorEncountered:
	call  writeln				; Start new line
	push  3						; Error location, for debugging
	call  writeNumber			; Write location to console
	call  writeln				; Start new line
	push  offset error			; Report a fatal error
	call  writeLine				; Write error to console
	call  exitProgram			; End the program
switchActive ENDP


;;******************************************************************;
;; Call seeInstructions()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	None
;; 
;; Clears screen and displays the game instructions.
;; Waits for input from user, then clears the screen again.
;;******************************************************************;
seeInstructions PROC near
_seeInstructions:
	call  clearConsole			; Clear the console to fit instructions
	 ;; Write instructions to the console
	push  offset instructions
	call  writeLine
	push  offset instructions2
	call  writeLine
	push  offset instructions3
	call  writeLine
	push  offset instructions4
	call  writeLine
	 ;; Inform user of codes to get help and to exit the program
	push  offset inputCodes		
	call  writeLine				; Write to console

	call  pauseProgram			; Wait for user to press enter
	call  clearConsole			; Clear the console

	ret							; Return to caller
seeInstructions ENDP

END