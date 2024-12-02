;; Output Module
;; Jonathan Burgener
;; 1 November, 2024
;; Prints and controls the board
;; Revised: JB, 6 November 2024 - Added stubs for printing, updating, and initializing the board
;; Revised: JB, 14 November 2024 - Adding controls for changing the board based on input from controller.asm
;; Revised: JB, 23 November 2024 - Added check for win state

INCLUDE Irvine32.inc

writeLine		proto			; readWrite.asm
charCount		proto			; readWrite.asm
writeNumber		proto			; readWrite.asm
writeNum		proto			; readWrite.asm
writeSp			proto			; readWrite.asm
writeln			proto			; readWrite.asm
writePlayer		proto			; readWrite.asm
writeTab		proto			; readWrite.asm
setBackground	proto			; readWrite.asm
setForeground	proto			; readWrite.asm
exitProgram		proto			; main.asm


.data
	;; Data for Irvine
	;outHandle    HANDLE ?
	;cellsWritten DWORD ?
	;xyPos COORD <10,2>

	;; Variables to hold number of stones in each pit
	p1Pit			DD		?, ?, ?, ?, ?, ?					; Array to hold the pits on player 1''s side
	p2Pit			DD		?, ?, ?, ?, ?, ?					; Array to hold the pits on player 2''s side 
	p1Manc			DD		?									; Number of stones in player 1''s mancala
	p2Manc			DD		?									; Number of stones in player 2''s mancala

	;; Intermediate variables for processing
	p1Colors		DD		?, ?, ?, ?, ?, ?, ?					; Colors for the board on player 1''s side
	p2Colors		DD		?, ?, ?, ?, ?, ?, ?					; Colors for the board on player 2''s side
	actColor		DD		?
	inactColor		DD		?
	heldStones		DD		?									; Stones left to place
	mainPit			DD		?									; Buffer to hold active player''s pits
	secPit			DD		?									; Buffer to hold inactive player''s pits
	actManc			DD		?									; Number of stones in active player''s mancala
	inactManc		DD		?									; Number of stones in the inactive player''s mancala (for printing board)
	active			DD		?									; Number for active player
	mainP			DD		?									; Active Player
	inactP			DD		?									; Inactive Player
	retVal			DD		?									; Return state
	captPit			DD		?									; Last pit a stone was placed in. For a capture stone
	pitCount		DD		?									; Number of pits that stones have been placed in

	;; Message strings
	noStone			byte	"No stones in desired pit!", 10, 0	; Message for when picked pit is empty
	captured		byte	" captured the stones in pit ", 0	; Message for when a pit is captured
	p1				byte	"Player 1", 0						; Universal string for indicating player 1
	p2				byte	"Player 2", 0						; Universal string for indicating player 1
	zero			byte	"0", 0								; For when the zero is missing
	space			byte	" ", 0								; Space to print
	error			byte	"Program ran into error, stopping...", 10, 0 ; Critical error encountered

	;; Board Parts
	;;		Since Visual Studios doesn''t appreciate Unicode, all non UTF-8 characters are 
	;;		represented by extended ASCII codes
	boardTop		byte	201, 205, 205, 205, 205, 203, 205, "6", 205, 205, 209, 205, "5", 205, 
							205, 209, 205, "4", 205, 205, 209, 205, "3", 205, 205, 209, 205, "2", 
							205, 205, 209, 205, "1", 205, 205, 209, 205, 205, 205, 205, 187, 0	
																; Top border of the board
	boardLeft		byte	186, "    ", 186, " ", 0			; Left Side, 2nd and 4th rows
	boardLeftC		byte	186, " ", 0							; Left Side, 3rd row
	boardCenter		byte	" ", 204, 205, 205, 205, 205, 216, 205, 205, 205, 205, 216, 205, 205, 
							205, 205, 216, 205, 205, 205, 205, 216, 205, 205, 205, 205, 216, 205, 
							205, 205, 205, 181, " ", 0			; Inner most border, 3rd row
	boardMid		byte	" ", 179, " ", 0					; Inside for 2nd and 4th rows
	boardRight		byte	"   ", 186, 0						; Right side end for 2nd and 4th rows
	boardRightC		byte	" ", 186, 0							; Right side end for 3rd row
	boardBottom		byte	200, 205, 205, 205, 205, 202, 205, 205, "1", 205, 207, 205, 205, "2", 
							205, 207, 205, 205, "3", 205, 207, 205, 205, "4", 205, 207, 205, 205, 
							"5", 205, 207, 205, 205, "6", 205, 207, 205, 205, 205, 205, 188, 0
																; Bottom border of the board
	boardTab		byte	"	", 0							; Buffer on left side to push board towards center of screen.
	indent			byte	"					", 0			; Buffer to position label for main active player
	borderColor		equ		3
.code

;;******************************************************************;
;; Call initializeBoard()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	
;; 
;; Initializes the variables for the board.
;;******************************************************************;
initializeBoard PROC near
_initializeBoard:
	; Get the Console standard output handle:
	;INVOKE GetStdHandle,STD_OUTPUT_HANDLE
	;mov outHandle,eax

	 ; Set amount of stones in the mancala''s to zero
	mov   eax, 0
	mov   p1Manc, eax
	mov   p2Manc, eax

	 ; Set amount of stones in each pit to four
	mov   eax, 4				; Set number of stones to put in each pit to four
	mov   ecx, 1				; Set counter to 1
	mov   ebx, 0				; Use EBX as an address offset

 ;; Set amount of stones in each pit
_initializeSides:
	mov   [p1Pit+bx], eax		; Set amount of stones in the pit in p1Pit to 4
	mov   [p2Pit+bx], eax		; Set amount of stones in the pit in p2Pit to 4
	inc   ecx					; Increment the counter
	inc   ebx					; Increment offset to next pit
	cmp   ecx, 6				; Make sure counter has not reached 6.
	jle   _initializeSides		; Jump back to top of loop

	call  resetColors			; Set the colors for the board

_exit:
	;mov   ebx, [p1Pit]			; Double checking memory to see if I can tell if the arrays were initialized properly
	;mov   ebx, [p2Pit]
	ret
initializeBoard ENDP


;;******************************************************************;
;; Call resetColors()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	EAX (s), EBX (s), ECX (s)
;; 
;; Resets the colors for the pits in the board
;;******************************************************************;
resetColors PROC near
_resetColors:
	;; Save Working registers
	push  eax
	push  ebx
	push  ecx

	;; Set colors for the board
	mov   eax, 0				; Clear EAX
	mov   ebx, offset p1Colors	; Put address of p1Colors into EBX
	mov   ecx, 6				; Set counter to 6
_setP1Colors:
	mov   eax, 14				; Set color number to 14 for Light Cyan
	mov   [ebx], al				; Add color to p1Colors
	inc   ebx
	dec   ecx
	jnz   _setP1Colors			; If counter is not zero, jump back to the top

	mov   eax, 7				; Set color number to 7 for blue
	mov   [ebx], al				; Add color to p1Colors
	mov   eax, 0				; Clear EAX
	mov   ebx, offset p2Colors	; Put address of p1Colors into EBX
	mov   ecx, 6				; Set counter to 6
_setP2Colors:
	mov   eax, 15				; Set color number to 15 for Light Magenta
	mov   [ebx], al				; Add color to p2Colors
	inc   ebx					; Increment address offset
	dec   ecx					; Decrement counter
	jnz   _setP2Colors			; If counter is not zero, jump back to the top

	mov   eax, 4				; Set color number to 4 for red
	mov   [ebx], al				; Add color to p2Colors

	;; Restore working registers
	pop   ecx
	pop   ebx
	pop   eax
	ret
resetColors ENDP


;;******************************************************************;
;; Call printBoard(active)
;; Parameters:		active	--	number for active player
;; Returns:			None
;; Registers Used:	EAX, EBX (s), ECX (s), EDX
;; 
;; Prints the board
;;******************************************************************;
printBoard PROC near
_printBd:
	; Remove parameters from the stack
	pop   edx					; pop return address from the stack into EDX
	pop	  eax					; Pop active player to EAX
	push  edx					; Restore return address to the stack

	 ; Save working registers
	push  ebx
	push  ecx
	push  edx

	mov   ebx, offset p1Pit		; Used to find address of Arrays. For debugging
	mov   ebx, offset p2Pit		; Ditto
	mov   ebx, 0				; Clear EBX

	 ; Set active player
	cmp   eax, 1				; Check if the active player is Player 1
	je    _p1Active				; If Player 1 is active, jump to _p1Active
	jmp   _p2Active				; Else, jump to _p2Active to set Player 2 as active

;; Set Player 1 as the active player
_p1Active:
	push  offset p2Colors		; Push Player 2''s color set
	push  offset p1Colors		; Push Player 1''s color set
	push  offset p2Pit			; Push Player 2''s side
	push  offset p1Pit			; Push Player 1''s side
	call  copySides				; Set mainPit as p1Pit and secPit as p2Pit
	mov   eax, p1Manc			; Cant move between memory
	mov   actManc, eax			; Set active mancala to Player 1
	mov   eax, p2Manc			; Cant move between memory
	mov   inactManc, eax		; Set inactive mancala to Player 2
	mov   mainP, 1				; Set main player to Player 1
	mov   inactP, 2				; Set inactive player to Player 2
	jmp   _printBoard			; Start printing the board

;; Set Player 2 as the active player
_p2Active:
	push  offset p1Colors		; Push Player 1''s color set
	push  offset p2Colors		; Push Player 2''s color set
	push  offset p1Pit			; Push player 1''s side
	push  offset p2Pit			; Push player 2''s side
	call  copySides				; Set mainPit as p2Pit and secPit as p1Pit
	mov   eax, p2Manc			; Cant move between memory
	mov   actManc, eax			; Set active mancala to Player 2
	mov   eax, p1Manc			; Cant move between memory
	mov   inactManc, eax		; Set inactive mancala to Player 1
	mov   mainP, 2				; Set main player to Player 2
	mov   inactP, 1				; Set inactive player to Player 1
	jmp   _printBoard			; Start printing the board

;; Start printing the board
_printBoard:
	call  writeTab				; Add a tab
	call  writeSp				; Write a space
	push  inactP				; Print inactive player
	call  writePlayer			; Write to console
	call  writeTab				; Add a tab
	push  0						; 5 for yellow
	call  setBackground			; Set background to yellow
	push  borderColor			; Color for borders
	call  setForeground			; Set text color for borders
	push  offset boardTop		; Print the top of the board
	call  writeLine				; Write to console
	;call  print				; Irvine call
	call  writeTab				; Add an indent
	push  offset boardLeft		; Print left side of second row
	call  writeLine				; Write to console
	;call  print				; Irvine call
	mov   ecx, 6				; Counter to stop loop
	mov   ebx, secPit			; Put address of the array into EBX
	add   ebx, 5				; Start at last index in secPit
	mov   edx, inactColor		; Put address of color array into EDX
	add   edx, 5				; Start at last index in inactColor
	push  edx					; Save color address in stack

 ;; Loop to print the second row (Inactive player''s side)
_rowTwo:
	pop   edx					; Pop color address from stack
	mov   eax, 0				; Clear EAX
	mov   al, [edx]				; Get color for the pit from actColor
	dec   edx					; Decrement color address
	push  edx					; Save color address
	push  eax					; Push color to the stack
	call  setForeground			; Set the text color
	mov   eax, 0				; Clear EAX
	add   al, [ebx]				; Put amount of stones in the pit into EAX
	;add   ebx, 4				; Increment the address offset
	dec   ebx					; Increment the address offset
	push  eax					; Push the amount of stones to print it
	call  printNumber			; Print the amount of stones
	call  printMid				; Print the border between pits
	dec   ecx					; Decrement the counter
	jnz   _rowTwo				; If the counter is not zero, go back to start of the loop

 ;; End the second row and print the third row
_endRowTwo:
	pop   edx					; Clear color address from stack
	push  borderColor			; Color for borders
	call  setForeground			; Set text color for borders
	push  offset boardRight		; Print right side of board for the second row
	call  writeLine				; Write to console
	call  writeTab				; Add a tab

	push  offset boardLeftC		; Print left side of third row
	call  writeLine				; Write to console

	mov   eax, 0				; Clear EAX
	mov   ebx, inactColor		; Put address of inactive color in EBX
	add   ebx, 6				; Add 6 to the address
	mov   al, [ebx]				; Get color for the pit from actColor
	push  eax					; Push color to the stack
	call  setForeground			; Set the text color
	push  inactManc				; Push amount of stones in the inactive player''s mancala
	call  printNumber			; Print the amount of stones in the inactive player''s mancala

	push  borderColor			; Color for borders
	call  setForeground			; Set text color to for borders
	push  offset boardCenter	; Push string holding central horizontal border that separates the two sides of the board
	call  writeLine				; Print the central border

	mov   eax, 0				; Clear EAX
	mov   ebx, actColor			; Put address of active color in EBX
	add   ebx, 6				; Offset address by 6
	mov   eax, [ebx]			; Get color for the pit from actColor
	push  eax					; Push color to the stack
	call  setForeground			; Set the text color
	push  actManc				; Push the amount of stones in the active player''s mancala
	call  printNumber			; Print the amount of stones in the active player''s mancala

	push  borderColor			; Color for borders
	call  setForeground			; Set text color for borders
	push  offset boardRightC	; Push the right side border of the third row
	call  writeLine				; Print the right side border

	call  writeTab				; Add a tab
	;call  print
	push  offset boardLeft		; Print left side of second row
	call  writeLine				; Write to console
	;call  print
	mov   ecx, 6				; Counter to stop loop
	mov   ebx, mainPit			; Put address of the active side into EBX
	mov   edx, actColor			; Put address of color array into EDX
	push  edx					; Save color address on stack

 ;; Loop to print the fourth row
_rowFour:
	pop   edx					; Pop color address from stack
	mov   eax, 0				; Clear EAX
	mov   al, [edx]				; Get color for the pit from actColor
	inc   edx					; Increment color address
	push  edx					; Save color address
	push  eax					; Push color to the stack
	call  setForeground			; Set the text color
	mov   eax, 0				; Clear EAX
	add   al, [ebx]				; Move the amount of stones in the pit into EAX
	;add   ebx, 4				; Increment address offset
	inc   ebx					; Increment the address offset
	push  eax					; Push amount of stones in the pit
	call  printNumber			; Print amount of stones in the pit
	call  printMid				; Print border separating each pit
	dec   ecx					; Decrement the counter
	jnz   _rowFour				; If the counter is not zero, jump back to the top of the loop

 ;; End the fourth row and print the final row
_endRowFour:
	pop   edx					; Clear color address from stack
	push  offset boardRight		; Print the end of the fourth row
	call  writeLine				; Print the end of the row
	call  writeTab				; Add a tab
	;call  print
	push  offset boardBottom	; Print the bottom border of the board
	call  writeLine				; Write to console
	push  1						; 1 for White
	call  setForeground			; Set text color to white
	push  0						; 0 for Black
	call  setBackground			; Set background color to black
	call  writeln				; Start a new line
	push  offset indent
	call  writeLine				; Indent to position player string
	push  mainP					; Print active player
	call  writePlayer			; Write to console
	call  writeln				; Start a new line
	;call  print

_exit:
	 ; Restore working registers
	pop   edx
	pop   ecx
	pop   ebx
	call  resetColors			; Reset colors
	ret
printBoard ENDP




;;******************************************************************;
;; Call copySides(mainSide,inactSide, mainColors, inactColors)
;; Parameters:		mainSide --	Array for active side
;;					inactSide -- Array for inactive side
;; Returns:			Nothing
;; Registers Used:	EAX <(s)> {If saved and restored at the end}
;; 
;; Copies the arrays for the pits to mainPit and secPit
;;******************************************************************;
copySides PROC near
_copySides:
	pop   edx					; Pop return address from the stack into EDX [++]
	pop   mainPit
	pop   secPit
	pop   actColor
	pop   inactColor
	push  edx					; Restore return address to the stack [--]
	;mov   edi, offset mainPit	; Put address of main pit into EDI
	;mov   ecx, 0				; Clear counter

 ;; Loop to copy the main side
;_copyMain:
	
	ret
copySides ENDP


;;******************************************************************;
;; Call movePit(active, pit)
;; Parameters:		active	--	Number for the active player
;;					pit		--	Selected pit to move
;; Returns:			state	--	What move resulted in (Fail, Success)
;; Registers Used:	EAX, EBX, ECX, EDX
;; 
;; Empties selected pit and moves the stones.
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
movePit PROC near
_movePit:
	pop   edx					; Pop return address from the stack into EDX [++]
	pop   ebx					; Pop active player number into EBX [++]
	pop   eax					; Pop selected pit into EAX [++]
	push  edx					; Restore return address to the stack [--]
	mov   active, ebx			; Store active player in active

	call  resetColors			; Reset board colors

	cmp   ebx, 1				; Check if Player 1 is the active player
	je    _p1Active				; Jump to _p1Active if Player 1 is active
	cmp   ebx, 2				; Check if Player 2 is the active player
	je    _p2Active				; Jump to _p2Active if Player 2 is active
	jmp    _badActive			; Jump to _badActive if the active number is invalid

 ;; Set player 1 as active player
_p1Active:
	push  offset p2Colors		; Push player 2 colors [--]
	push  offset p1Colors		; Push player 1 Colors [--]
	push  offset p2Pit			; Push player 2''s side [--]
	push  offset p1Pit			; Push player 1''s side [--]
	call  copySides				; Set mainPit as p1Pit and secPit as p2Pit [--] [+*5]
	mov   edx, p1Manc
	mov   actManc, edx			; Store address of p1Manc in actManc
	jmp   _pitCheck				; Move stones

 ;; Set player 2 as active player
_p2Active:
	push  offset p1Colors		; Push player 1 Colors [--]
	push  offset p2Colors		; Push player 2 colors [--]
	push  offset p1Pit			; Push player 1''s side [--]
	push  offset p2Pit			; Push player 2''s side [--]
	call  copySides				; Set mainPit as p2Pit and secPit as p1Pit [--] [+*5]
	mov   edx, p2Manc
	mov   actManc, edx			; Store address of p2Manc in actManc
	jmp   _pitCheck				; Move stones

 ;; Move stones
_pitCheck:
	push  eax					; Save EAX for later [--]
	push  mainPit				; Push address of active side pits to check move [--]
	push  eax					; Push pit to check pit number [--]
	call  checkPit				; [--]  [+*3]
	pop   ebx					; Pop move check state into EBX [++]
	pop   eax					; [++]
	cmp   ebx, 1				; Check if move is valid
	je    _makeMove				;	If so, make move
	cmp   ebx, 4				; Check if pit is empty
	je    _emptyPit				;	If so, return with a return value of 4
	jmp	  _badPitCheck			; Else, Pit check came back bad

 ;; Make Move
_makeMove:
	mov   ecx, eax				; Store pit number in ECX for loop
	dec   ecx					; Decrease ECX by 1 to get the correct memory address
	; Set color of selected pit to green
	mov   ebx, actColor			; Put address of color array into EBX
	add   ebx, ecx				; Increment actColor to selected pit
	mov   eax, 6				; Put 6 into EAX for green
	mov   [ebx], al				; Set color of selected pit to green
	inc   ebx					; Increment address
	push  ebx					; Save address
	; Clear selected pit
	mov   ebx, mainPit			; Put address into EBX
	add   ebx, ecx				; Increment mainPit to selected pit
	mov   eax, 0				; Clear EAX
	add   al, [ebx]				; Put number of stones in the pit into EAX
	mov   heldStones, eax		; Store number of stones in heldStones
	sub   [ebx], al				; Clear starting pit
	inc   ecx					; Increment counter
	mov   edx, ecx				; Set last stone placed location to the pit
	inc   ebx					; Increment address
	jmp   _placeMainSideLoop	; Start loop to place stones

 ;; Start loop of adding stones to pits on the active player''s side
_placeMainSide:
	pop   ebx					; Pop color address from other side
	push  actColor				; Push address of array of colors
	mov   ebx, mainPit			; Put pit address into EBX
	mov   ecx, 1				; Reset counter to 1
	jmp   _placeMainSideLoop	; Start loop

 ;; Add stones to pits on active player''s side
_placeMainSideLoop:
	mov   eax, 1				; Set number of stones to add to 1
	cmp   heldStones, 0			; Check if there are no more held stones
	jle   _loopExit				; If there are no more held stones, exit the loop
	cmp   ecx, 6				; Check if the counter reached the maximum pit number
	jge   _placeMancala			; If max pit was passed, move to the Mancala
	add   [ebx], al				; Increment the amount of stones in the pit
	dec   heldStones			; Decrement the amount of stones held
	inc   edx					; Increment area counter (between 1 and 6)
	inc   ecx					; Increment the counter
	inc   ebx					; Increment the address
	 ; Set Color
	mov   eax, ebx				; Put address of pits in EAX
	pop   ebx					; Pop color array address into EBX
	push  eax					; Store address of pits
	mov   eax, 12				; Set color number to 12 for light green
	mov   [ebx], al				; Set color of pit to light green
	inc   ebx					; Increment color address
	mov   eax, ebx				; Put color array address in EAX
	pop   ebx					; Pop pit address into EBX
	push  eax					; Store color array address
	 ; Adjust last stone placed location
	cmp   edx, 13				; Check if the area counter reached the maximum
	jg    _restartArea			;	If so, reset the area
	jmp   _placeMainSideLoop	; Jump back to top of loop

;; Adjust area back to 1 after the stone placement loops back into the active side
_restartArea:
	mov   edx, 1				; Reset area to 1
	jmp   _placeMainSideLoop	; Go back to placing stones in the main side

 ;; Add a stone to the active player''s mancala
_placeMancala:
	mov   eax, 1				; Get ready to add 1 to the active player''s mancala (can''t add literal to memory directly)
	add   [actManc], eax		; Add a stone to the Mancala
	pop   ebx					; Pop color array address into EBX
	mov   eax, 12				; Set color number to 12 for light green
	mov   [ebx], al				; Set color of pit to light green
	inc   edx					; Increment area counter (should be 7)
	dec   heldStones			; Decrement amount of held stones
	jnz   _placeOtherSide		; Start adding stones to inactive side if the number of held stones is not zero
	jmp   _exitLoops			; If there are no more held stones, exit the loop

 ;; Start loop to add stones to the inactive player''s pits
_placeOtherSide:
	push  inactColor			; Store color array address
	mov   ebx, secPit			; Put address of the inactive player''s pits into EBX
	mov   ecx, 1				; Reset counter to 1
	jmp   _placeOtherSideLoop	; Start loop

 ;; Add stones to the pits on the inactive player''s side
_placeOtherSideLoop:
	mov   eax, 1				; Set number of stones to 1
	cmp   heldStones, 0			; Check if there are no more held stones
	jle   _loopExit				; If there are no more held stones, exit the loop
	cmp   ecx, 7				; Check if the counter reached the maximum pit number
	jge   _placeMainSide		; If max pit was passed, move to the main side
	add   [ebx], al				; Increment the amount of stones in the pit
	dec   heldStones			; Decrement the amount of stones held
	inc   edx					; Increment area counter (between 8 and 13)
	inc   ecx					; Increment the counter
	inc   ebx					; Increment address

	 ; Set Color
	mov   eax, ebx				; Put address of pits in EAX
	pop   ebx					; Pop color array address into EBX
	push  eax					; Store address of pits
	mov   eax, 12				; Set color number to 12 for light green
	mov   [ebx], al				; Set color of pit to light green
	inc   ebx					; Increment color address
	mov   eax, ebx				; Put color array address in EAX
	pop   ebx					; Pop pit address into EBX
	push  eax					; Store color array address

	jmp   _placeOtherSideLoop	; Jump back to top of loop

 ;; Stack adjustment
_loopExit:
	pop   ebx					; Remove color address from stack

 ;; Move from loops and do post proccessing
_exitLoops:
	 ; Store working registers
	push  eax

	push  edx					; Push num for last area placed in [--]
	call  endPit				; Check edge cases
	pop   ebx					; Pop return value from endPit into EBX
	pop   eax					; Ditto
	jmp   _moveMade				; Time to return

 ;; Set return value to state from 
_moveMade:
	pop   edx					; Pop return address from the stack into EDX
	push  ebx					; Push return state from endPit
	push  edx					; Restore return address to the stack
	jmp   _exit					; Return to controller

 ;; Return to controller
_exit:
	ret							; Return with state in stack

 ;; Invalid number for active
_badActive:
	pop   edx					; Pop return address from the stack into EDX
	push  4						; Push 4 as state for invalid active player number
	push  edx					; Restore return address to the stack
	jmp   _exit					; Return to controller

 ;; Pit Check had an issue with the move
_badPitCheck:
	pop   edx					; Pop return address from the stack into EDX
	push  ebx					; Push state from checkMove
	push  edx					; Restore return address to the stack
	jmp   _exit					; Return to controller

_emptyPit:
	pop   edx					; Pop return address from the stack into EDX
	push  4						; Set return value to 4
	push  edx					; Restore return address to the stack
	jmp   _exit					; Return to controller

 ;; Any major error occured
_critError:
	call  writeln				; Start new line
	push  1						; Number to identify location of error for debugging
	call  writeNumber			; write location number
	call  writeln				; Start new line
	push  offset error			; Send error message to user
	call  writeLine				; Write to console
	call  exitProgram			; End the program immediately
movePit ENDP


;;******************************************************************;
;; Call checkPit(pit, addr)
;; Parameters:		pit		--	Selected pit
;;					addr	--	Address of side of board to check
;; Returns:			state	--	Whether pit is valid
;; Registers Used:	EAX, EBX, EDX
;; 
;; Checks pit in the side of the board to see if the pit is:
;;		valid (state: 1), empty (state: 4), or invalid pit (state: 5)
;;******************************************************************;
checkPit PROC near
_checkPit:
	pop   edx					; Pop return address from the stack into EDX
	pop   eax					; Pop pit into EAX
	pop   ebx					; Pop addr into EBX
	push  edx					; Restore return address to the stack

	 ; Check if pit number is valid
	cmp   eax, 1				; Check if pit is less than the minimum (1)
	jl    _invalid				; If so, jump to _invalid
	cmp   eax, 6				; Check if pit is more than the maximum (6)
	jg    _invalid				; If so, jump to _invalid

	 ; Check that the selected pit is not empty
	mov   edx, eax				; Set EDX as address offset
	sub   edx, 1				; Subtract EDX by 1, so the first pit is not skipped over
	add   ebx, edx				; Increment address
	mov   eax, 0				; Clear EAX
	mov   al, [ebx]				; Put number of stones in the pit into EAX
	cmp   eax, 0				; Check if the number of stones is 0
	jle   _empty				; If there are no stones, return empty state
	jmp   _valid				; Else, return success state

 ; Valid pit that is not empty
_valid:
	pop   edx					; Pop return address from the stack into EDX
	push  1						; Push state of 1 (valid address)
	push  edx					; Restore return address to the stack
	ret							; Return with state in stack

 ; Empty pit
_empty:
	pop   edx					; Pop return address from the stack into EDX
	push  4						; Push state of 4 (empty pit)
	push  edx					; Restore return address to the stack
	ret							; Return with state in stack

 ;; Invalid pit number
_invalid:
	pop   edx					; Pop return address from the stack into EDX
	push  5						; Push state of 5 (invalid pit)
	push  edx					; Restore return address to the stack
	ret							; Return with state in stack
checkPit ENDP


;;******************************************************************;
;; Call endPit(counter, area)
;; Parameters:		counter	--	Index of the last pit a stone was 
;;									added to
;;					area	--	Last area a stone was added to:
;;									1 = Active player''s side
;;									2 = Active player''s mancala
;;									3 = Inactive player''s side
;; Returns:			result	--	Result of move (edge cases)
;; Registers Used:	EAX <(s)> {If saved and restored at the end}
;; 
;;		1 - Normal Move
;;		2 - Extra Move
;;		3 - Invalid Active Player Number
;;		4 - Empty Pit
;;		5 - Invalid Pit Number
;;		6 - Captured Pit
;;		7 - Game Over, player 1 wins
;;		8 - Game Over, player 2 wins
;;		9 - Game Over, Tie
;;******************************************************************;
endPit PROC near
_endPit:
	mov   ebx, esi				; Save stack pointer in EBX
	pop   edx					; Pop return address from the stack into EDX
	pop   ecx					; Pop area into ECX
	push  edx					; Restore return address to the stack

	cmp   ecx, 7				; Check area the last stone was placed in
	jl    _checkCapture			; If the area is less than 7, then the last stone was placed on the active
								;		players side, and as such may have captured a pit
	je    _inManc				; If the area is 7, then the last stone was placed in the mancala, extra move
	jg    _normalMove			; If the last stone was placed on the inactive player''s side, then no edge
								;		case can occur.


 ;; Check if a pit is captured
_checkCapture:
	sub   ecx, 1				; Allow checking the first pit (ECX was less or equal to 6)
	mov   eax, mainPit			; Put address of the pits in EAX
	add   eax, ecx				; Add index to address
	mov   edx, 0				; Clear EDX
	mov   dl, [eax]				; Load number of stones in the pit into EDX
	cmp   edx, 1				; Check if last pit only has 1 stone
	je    _capture

 ;; No edge case. Last stone placed in a normal, non-empty pit
_normalMove:
	push  1						; Set return value to 1
	jmp   _checkEnd

 ;; Last stone ended ended in empty pit on active player''s side. 
 ;;		Stones in opposing pit are captured.
_capture:
	mov   heldStones, 1			; Take stone from pit
	mov   edx, 0				; Cant load a literal into a memory space
	mov   [eax], dl				; Clear pit that the last stone was placed in

	; Find index of pit on opposing side
	mov   eax, ecx				; Move counter to EAX
	mov   ecx, 6				; Set ECX to 6 to find index of pit on opposite side
	sub   ecx, eax				; Subtract counter from 6 to get index in ECX
	mov   captPit, ecx			; Store captured pit index in captPit (for post processing)
	dec   ecx					; Adjust index to get the correct address (not skip pit 1)
	mov   eax, secPit			; Put address of opposing side into EAX
	add   eax, ecx				; Get address of pit to capture

	mov   cl, [eax]				; Use ECX as buffer
	add   heldStones, ecx		; Add number of stones captured to heldStones
	mov   ecx, 0				; Set ECX to zero
	mov   [eax], cl				; Clear stones from pit

	mov   eax, heldStones		; Move captured stones to EAX
	add   actManc, eax			; Add captured stones to the active player''s mancala

	push  6						; Set return state to 6
	jmp   _checkEnd				; Return

 ;; Last stone was placed in the mancala. Active player gets to 
 ;;		go again.
_inManc:
	push  2						; Set return state to 2
	jmp   _checkEnd

_checkEnd:
	call  setManc				; Update mancalas
	call  checkGameOver			; Check if there are no more moves
	pop   eax					; Pop return value from other checks into EAX
	cmp   retVal, 1				; Is the return state anything but 1
	jne   _retState				;	If so return with a value of 7, 8, or 9
	 ; Else:
	mov   retVal, eax			; Set the return value as the value from other checks
	jmp   _retState				; Jump to end

 ;; Return to caller
_retState:
	mov   esi, ebx				; Fix stack pointer
	pop   edx					; Pop return address from the stack into EDX
	;pop   ecx					; Extra parameter from an unknown location to remove
	push  retVal				; Push return state
	push  edx					; Restore return address to the stack
	ret							; Return to caller
endPit ENDP


;;******************************************************************;
;; Call checkGameOver()
;; Parameters:		None
;; Returns:			retVal	--	Return state
;; Registers Used:	EAX (s), EBX (s), ECX (s), EDX, EBP (s), ESP (s)
;; 
;; Checks if all the pits on a side are empty.
;; If so, clears board and declares winner.
;; Return states
;;		1 - No change
;;		7 - Game Over, Player 1 wins
;;		8 - Game Over, Player 2 wins
;;		9 - Game Over, Tie
;;******************************************************************;
checkGameOver PROC near
_checkGameOver:
	;; Save working registers
	push  eax
	push  ebx
	push  ecx
	push  edx
	push  ebp					; Save base pointer
	mov   ebp, esp				; Save stack pointer in EBP

	;; Clear registers
	mov   eax, 0
	mov   ebx, 0
	mov   ecx, 0
	mov   edx, 0

	;; Check first side
	mov   ebx, offset p1Pit		; Load the first side into EBX
	mov   ecx, 6				; Use ECX as a pointer

;; Check Player 1''s side to see if it is empty
_checkSideOne:
	mov   eax, 0				; Clear EAX
	mov   al, [ebx]			; Load stones in pit into EAX
	add   edx, eax				; Add amount of stones to EDX
	inc   ebx					; Increment to next pit
	dec   ecx					; Decrement counter
	jnz   _checkSideOne			; If ECX is not zero, jump to start of loop

	;; Check if the there are no stones in side one
	cmp   edx, 0
	je    _endGame				; If there are no more stones, end the game

	;; Check second side
	mov   ebx, offset p2Pit		; Load the second side into EBX
	mov   ecx, 6				; Use ECX as a pointer
	mov   edx, 0				; Clear stone counter

;; Check Player 2''s side to see if it is empty
_checkSideTwo:
	mov   eax, 0				; Clear EAX
	mov   al, [ebx]			; Load stones in pit into EAX
	add   edx, eax				; Add amount of stones to EDX
	inc   ebx					; Increment to next pit
	dec   ecx					; Decrement counter
	jnz   _checkSideTwo			; If ECX is not zero, jump to start of loop

	;; Check if the there are no stones in side two
	cmp   edx, 0
	je    _endGame				; If there are no more stones, end the game

	mov   edx, 1				; Cant load a literal directly into memory
	mov   retVal, edx			; Set return value to 1 for game not being over
	jmp   _exit					; Neither side is empty so return to caller

;; Move all leftover stones on each side to their respective mancala
_endGame:
	mov   ebx, offset p1Pit		; Load Player 1''s side into EBX
	mov   ecx, 6				; Set ECX as counter
	mov   edx, 0				; Clear EDX for stone count

;; Clear Player 1''s side
_clearSideOne:
	mov   eax, 0				; Clear EAX
	mov   al, [ebx]				; Load stones in pit into EAX
	add   edx, eax				; Add amount of stones to EDX
	mov   eax, 0				; Clear EAX
	mov   [ebx], al				; Clear stones in the pit
	inc   ebx					; Increment to next pit
	dec   ecx					; Decrement counter
	jnz   _clearSideOne			; If ECX is not zero, jump to start of loop

	add   p1Manc, edx			; Add stones to Player 1''s Mancala

	;; Get ready to clear Player 2''s side
	mov   ebx, offset p2Pit		; Load Player 2''s side into EBX
	mov   ecx, 6				; Set ECX as counter
	mov   edx, 0				; Clear EDX for stone count

;; Clear Player 2''s side
_clearSideTwo:
	mov   eax, 0				; Clear EAX
	mov   al, [ebx]				; Load stones in pit into EAX
	add   edx, eax				; Add amount of stones to EDX
	mov   eax, 0				; Clear EAX
	mov   [ebx], al				; Clear stones in the pit
	inc   ebx					; Increment to next pit
	dec   ecx					; Decrement counter
	jnz   _clearSideTwo			; If ECX is not zero, jump to start of loop

	add   p2Manc, edx			; Add stones to Player 2''s Mancala

	mov   eax, p1Manc			; Cant directly compare memory spaces
	cmp   eax, p2Manc
	jg    _player1Win			; If player 1 has more stones in their mancala, they win
	jl    _player2Win			; If player 2 has more stones in their mancala, they win
	jmp   _tie					; If there is an equal amount of stones in both mancalas, game is a tie

;; Set player 1 as the winner
_player1Win:
	mov   eax, 7				; Cant load literal directly into memory
	mov   retVal, eax			; Set return state to 7 for player 1 win
	jmp   _exit					; Return

;; Set player 2 as the winner
_player2Win:
	mov   eax, 8				; Cant load literal directly into memory
	mov   retVal, eax			; Set return state to 8 for player 2 win
	jmp   _exit					; Return

;; Game ended in a tie
_tie:
	mov   eax, 9				; Cant load literal directly into memory
	mov   retVal, eax			; Set return state to 9 for a tie
	jmp   _exit					; Return

;; Return to caller
_exit:
	;; Restore working registers
	mov   esp, ebp
	pop   ebp
	pop   edx
	pop   ecx
	pop   ebx
	pop   eax

	ret							; Return to caller
checkGameOver ENDP


;;******************************************************************;
;; Call setManc()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	EAX (s)
;; 
;; Updates amount of stones in the active player''s mancala
;;******************************************************************;
setManc PROC near
_setManc:
	push  eax					; Store EAX
	cmp   active, 1				; Check if Player 1 is active
	je    _restoreP1Manc		; Restore Player 1''s mancala
	jmp   _restoreP2Manc		; Restore Player 2''s mancala

_restoreP1Manc:
	mov   eax, actManc			; Cant move directly between memory
	mov   p1Manc, eax			; Set amount of stones in p1Manc
	pop   eax					; Restore EAX
	ret							; Return to caller

_restoreP2Manc:
	mov   eax, actManc			; Cant move directly between memory
	mov   p2Manc, eax			; Set amount of stones in p2Manc
	pop   eax					; Restore EAX
	ret							; Return to caller
setManc ENDP


;;******************************************************************;
;; Call printNumber(number)
;; Parameters:		number	--	number to write to console
;; Returns:			Nothing
;; Registers Used:	EAX, EBX (s), ECX (s), EDX
;; 
;; Writes a number to the console. Writes a space to the console
;; before the number for a single digit number.
;;******************************************************************;
printNumber PROC near
_printNumber:
	pop   edx					; Pop return address from the stack into EDX
	pop   eax					; Pop number from the stack into EAX
	push  edx					; Restore return address to the stack
	push  eax					; Save working registers
	push  ebx					; Ditto
	push  ecx					; Ditto
	cmp   eax,9
	jle   _printSpace

 ;; Print the number
_printNum:						; Write number to the console
	push  eax
	call  writeNum
	;call  printnum
	jmp   _exit

 ;; Write a space if number has a single digit
_printSpace:
	push  eax
	;push  offset zero
	;call  writeLine
	;call  writespc
	call  writeSp
	pop   eax
	cmp   eax, 0
	je    _printZero
	jmp   _printNum

 ;; Print a zero if the number is zero
_printZero:
	push  offset zero			; Push zero to print
	call  writeLine				; Write zero
	jmp   _exit

 ;; Return to caller
_exit:
	pop   ecx					; Restore Working Registers
	pop   ebx
	pop   eax
	ret							; Return
printNumber ENDP


;;******************************************************************;
;; Call printMid()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	EAX (s), EBX (s), ECX (s), EDX (s)
;; 
;; Writes a border to the console between pits
;;******************************************************************;
printMid PROC near
_printMid:
	 ; Save working registers
	push  eax
	push  ebx
	push  ecx
	push  edx

	push  borderColor			; Color for borders
	call  setForeground			; Set text color for borders

	 ; Print intermediate border
	;push  brown				; Push brown as color for the border
	push  offset boardMid		; Push address of border
	;call  printline			; Write border to console in brown text
	call  writeLine				; Write border to console

	; Restore Working Registers
	pop   edx
	pop   ecx
	pop   ebx
	pop   eax

	ret
printMid ENDP


;;******************************************************************;
;; Call getCaptPit()
;; Parameters:		None
;; Returns:			pit	--	Index of the latest captured pit
;; Registers Used:	EDX
;; 
;; Retrieves the index of the last captured pit.
;; For post processing in controller.asm
;;******************************************************************;
getCaptPit PROC near
_getCaptPit:
	pop   edx					; Pop return address from the stack into EDX
	push  captPit				; Push index of the captured pit
	push  edx					; Restore return address to the stack
	ret							; Return with index of captured pit
getCaptPit ENDP


;;******************************************************************;
;; Call updateStones(side1,side2,mancala1,mancala2)
;; Parameters:		side1	--	The six pits on player 1''s side
;; 					side2	--	The six pits on player 2''s side
;;					mancala1 --	Player 1''s mancala
;;					mancala2 --	Player 2''s mancala
;; Returns:			state	--	State of movement
;; Registers Used:	EDX
;; 
;; Updates the amount of stones in each pit
;;******************************************************************;
updateStones PROC near
_updateStones:
	; TODO
_exit:
	pop   edx					; Pop return address from the stack into EDX
	push  1						; Push return value
	push  edx					; Restore return address to the stack
	ret
updateStones ENDP


;;******************************************************************;
;; Call writespc()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	EDX
;; 
;; Writes a space to the console using Irvine
;;******************************************************************;
;writespc PROC near
;_writespc:
;	push  offset space
;	call  print
;	ret
;writespc ENDP


;;******************************************************************;
;; Call print(addr)
;; Parameters:		addr	--	Address of string to print
;; Returns:			Nothing
;; Registers Used:	EAX, EDX
;; 
;; Writes a string to the standard console using Irvine
;;******************************************************************;
;print PROC near
;_print:
;	pop   edx					; Pop return address from the stack into EDX
;	pop   eax					; Pop addr into EAX
;	push  edx					; Restore return address to the stack
;
;	push  white					; Push white for the text color (default)
;	push  eax					; Push string address
;	call  printline				; Write the string
;
;	ret
;print ENDP


;;******************************************************************;
;; Call print(addr, color)
;; Parameters:		addr	--	Address of string to print
;;					color	--	Number to represent desired color
;; Returns:			Nothing
;; Registers Used:	EAX, EBX, EDX
;; 
;; Writes a string to the standard console with color using Irvine
;; Colors:
;;	black (0), white (1), gray (2), brown (3), red (4), yellow (5), 
;;	green (6), blue (7), cyan (8), magenta (9), lightGray (10), 
;;	lightRed (11), lightGreen (12), lightBlue (13), lightCyan (14), 
;;	and lightMagenta (15)
;;******************************************************************;
;printline PROC near
;_printline:
;	pop   ebx					; Pop return address from the stack into EBX
;	pop   eax					; Pop addr into EAX
;	pop   edx					; Pop color number into EDX
;	push  ebx					; Restore return address to the stack
;
;	call  SetTextColor			; Set the color
;	call  WriteString			; Write the string to the standard console
;
;	mov   eax, white			; Set the color to White
;	call  SetTextColor			; Reset the color
;
;	ret
;printline ENDP


;;******************************************************************;
;; Call printnum(num)
;; Parameters:		addr	--	Integer to print
;; Returns:			Nothing
;; Registers Used:	EAX, EDX
;; 
;; Writes an integer to the standard console using Irvine
;;******************************************************************;
;printnum PROC near
;_printnum:
;	pop   edx					; Pop return address from the stack into EDX
;	pop   eax					; Pop addr into EAX
;	push  edx					; Restore return address to the stack
;
;	push  white					; Push white for the text color (default)
;	push  eax					; Push string address
;	call  printint				; Write the string
;
;	ret
;printnum ENDP


;;******************************************************************;
;; Call printint(num, color)
;; Parameters:		num		--	Number to Write
;;					color	--	Number to represent desired color
;; Returns:			Nothing
;; Registers Used:	EAX, EBX, EDX
;; 
;; Writes an integer to the standard console with color using Irvine
;; Colors:
;;	black (0), white (1), gray (2), brown (3), red (4), yellow (5), 
;;	green (6), blue (7), cyan (8), magenta (9), lightGray (10), 
;;	lightRed (11), lightGreen (12), lightBlue (13), lightCyan (14), 
;;	and lightMagenta (15)
;;******************************************************************;
;printint PROC near
;_printint:
;	pop   ebx					; Pop return address from the stack into EBX
;	pop   eax					; Pop addr into EAX
;	pop   edx					; Pop color number into EDX
;	push  ebx					; Restore return address to the stack
;
;	call  SetTextColor			; Set the color
;	call  WriteInt				; Write the string to the standard console
;
;	mov   eax, white			; Set the color to White
;	call  SetTextColor			; Reset the color
;
;	ret
;printint ENDP

END