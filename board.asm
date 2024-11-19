; Output Module
; Jonathan Burgener
; 1 November, 2024
; Prints and controls the board
; Revised: JB, 6 November 2024 - Added stubs for printing, updating, and initializing the board
; Revised: JB, 14 November 2024 - Adding controls for changing the board based on input from controller.asm

.386P

.model flat

extern	writeline:	 near
extern	readline:	 near
extern	charCount:	 near
extern	writeNumber: near
extern	writeNum:	 near
extern	writesp:	 near
extern	writeln:	 near
extern	exitProgram: near	; main.asm

;INCLUDE Irvine32.inc

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
	heldStones		DD		?									; Stones left to place
	mainPit			DD		?									; Buffer to hold active player''s pits
	secPit			DD		?									; Buffer to hold inactive player''s pits
	actManc			DD		?									; Number of stones in active player''s mancala
	inactManc		DD		?									; Number of stones in the inactive player''s mancala (for printing board)
	active			DD		?									; Number for active player

	;; Message strings
	noStone			byte	"No stones in desired pit!",10,0	; Message for when picked pit is empty
	captured		byte	" captured the stones in pit ",0	; Message for when a pit is captured
	p1				byte	"Player 1",0						; Universal string for indicating player 1
	p2				byte	"Player 2",0						; Universal string for indicating player 1
	zero			byte	"0",0								; For when the zero is missing
	space			byte	" ",0								; Space to print
	error			byte	"Program ran into error, stopping...", 10, 0 ; Critical error encountered

	;; Board Parts
	;;		Since Visual Studios doesn''t appreciate Unicode, all non UTF-8 characters are 
	;;		represented by extended ASCII codes
	boardTop		byte	10, 10, "	", 201, 205, 205, 205, 205, 203, 205, "6", 205, 205, 209, 
							205, "5", 205, 205, 209, 205, "4", 205, 205, 209, 205, "3", 205, 205, 
							209, 205, "2", 205, 205, 209, 205, "1", 205, 205, 209, 205, 205, 205, 
							205, 187, 10, 0						; Top border of the board
	boardLeft		byte	"	", 186, "    ", 186, " ", 0		; Left Side, 2nd and 4th rows
	boardLeftC		byte	"	", 186, " ", 0					; Left Side, 3rd row
	boardCenter		byte	" ", 204, 205, 205, 205, 205, 216, 205, 205, 205, 205, 216, 205, 205, 
							205, 205, 216, 205, 205, 205, 205, 216, 205, 205, 205, 205, 216, 205, 
							205, 205, 205, 181, " ", 0			; Inner most border, 3rd row
	boardMid		byte	" ", 179, " ", 0					; Inside for 2nd and 4th rows
	boardRight		byte	"   ", 186, 10 , 0					; Right side end for 2nd and 4th rows
	boardRightC		byte	" ", 186, 10, 0						; Right side end for 3rd row
	boardBottom		byte	"	", 200, 205, 205, 205, 205, 202, 205, 205, "1", 205, 207, 205, 
							205, "2", 205, 207, 205, 205, "3", 205, 207, 205, 205, "4", 205, 207, 
							205, 205, "5", 205, 207, 205, 205, "6", 205, 207, 205, 205, 205, 205, 
							188, 10, 10, 0						; Bottom border of the board

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
	cmp   ecx, 6				; Check if the counter reached the maximum pit number
	jg    _exit					; If max pit was passed, move to the Mancala
	mov   [p1Pit+bx], eax		; Set amount of stones in the pit in p1Pit to 4
	mov   [p2Pit+bx], eax		; Set amount of stones in the pit in p2Pit to 4
	inc   ecx					; Increment the counter
	inc   ebx					; Increment offset to next pit
	jmp   _initializeSides		; Jump back to top of loop

_exit:
	;mov   ebx, [p1Pit]			; Double checking memory to see if I can tell if the arrays were initialized properly
	;mov   ebx, [p2Pit]
	ret
initializeBoard ENDP


;;******************************************************************;
;; Call printBoard(active)
;; Parameters:		active	--	number for active player
;; Returns:			None
;; Registers Used:	
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
	push  offset p2Pit			; Push player 2''s side
	push  offset p1Pit			; Push player 1''s side
	call  copySides				; Set mainPit as p1Pit and secPit as p2Pit
	mov   eax, p1Manc			; Cant move between memory
	mov   actManc, eax			; Set active mancala to Player 1
	mov   eax, p2Manc			; Cant move between memory
	mov   inactManc, eax		; Set inactive mancala to Player 2
	jmp   _printBoard			; Start printing the board

;; Set Player 2 as the active player
_p2Active:
	mov   ebx, offset p1Pit		; Used to find address of Arrays. For debugging
	mov   ebx, offset p2Pit		; Ditto
	mov   ebx, 0				; Clear EBX

	push  offset p1Pit			; Push player 1''s side
	push  offset p2Pit			; Push player 2''s side
	call  copySides				; Set mainPit as p2Pit and secPit as p1Pit
	mov   eax, p2Manc			; Cant move between memory
	mov   actManc, eax			; Set active mancala to Player 2
	mov   eax, p1Manc			; Cant move between memory
	mov   inactManc, eax		; Set inactive mancala to Player 1
	jmp   _printBoard			; Start printing the board

;; Start printing the board
_printBoard:
	push  offset boardTop		; Print the top of the board
	call  writeline				; Write to console
	;call  print				; Irvine call
	push  offset boardLeft		; Print left side of second row
	call  writeline				; Write to console
	;call  print				; Irvine call
	mov   ecx, 6				; Counter to stop loop
	mov   ebx, secPit			; Put address of the array into EBX
	add   ebx, 5				; Start at last index in secPit

 ;; Loop to print the second row (Inactive player''s side)
_rowTwo:
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
	push  offset boardRight		; Print right side of board for the second row
	call  writeline				; Write to console
	;call  print
	push  offset boardLeftC		; Print left side of third row
	call  writeline				; Write to console
	;call  print
	;mov   eax, p1Manc
	push  inactManc				; Push amount of stones in the inactive player''s mancala
	call  printNumber			; Print the amount of stones in the inactive player''s mancala
	push  offset boardCenter	; Push string holding central horizontal border that separates the two sides of the board
	call  writeline				; Print the central border
	;call  print
	;mov   eax, p2Manc
	push  actManc				; Push the amount of stones in the active player''s mancala
	call  printNumber			; Print the amount of stones in the active player''s mancala
	push  offset boardRightC	; Push the right side border of the third row
	call  writeline				; Print the right side border
	;call  print
	push  offset boardLeft		; Print left side of second row
	call  writeline
	;call  print
	mov   ecx, 6				; Counter to stop loop
	mov   ebx, mainPit			; Put address of the active side into EBX

 ;; Loop to print the fourth row
_rowFour:
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
	push  offset boardRight		; Print the end of the fourth row
	call  writeline				; Print the end of the row
	;call  print
	push  offset boardBottom	; Print the bottom border of the board
	call  writeline
	;call  print

_exit:
	 ; Restore working registers
	pop   edx
	pop   ecx
	pop   ebx

	ret
printBoard ENDP

;;******************************************************************;
;; Call copySides(mainSide,inactSide)
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
;; Registers Used:	EAX, EBX, ECX (s), EDX
;; 
;; Empties selected pit and moves the stones.
;; States:
;;		1 - Move success
;;		2 - Extra Move
;;		3 - Invalid Active Player Number
;;		4 - Empty Pit
;;		5 - Invalid Pit Number
;;		6 - Captured Pit
;;******************************************************************;
movePit PROC near
_movePit:
	pop   edx					; Pop return address from the stack into EDX [++]
	pop   ebx					; Pop active player number into EBX [++]
	pop   eax					; Pop selected pit into EAX [++]
	push  edx					; Restore return address to the stack [--]
	push  ecx					; Save ECX [--]
	mov   active, ebx			; Store active player in active

	cmp   ebx, 1				; Check if Player 1 is the active player
	je    _p1Active				; Jump to _p1Active if Player 1 is active
	cmp   ebx, 2				; Check if Player 2 is the active player
	je    _p2Active				; Jump to _p2Active if Player 2 is active
	jmp    _badActive			; Jump to _badActive if the active number is invalid

 ;; Set player 1 as active player
_p1Active:
	push  offset p2Pit			; Push player 2''s side
	push  offset p1Pit			; Push player 1''s side
	call  copySides				; Set mainPit as p1Pit and secPit as p2Pit
	mov   edx, p1Manc
	mov   actManc, edx			; Store address of p1Manc in actManc
	jmp   _pitCheck				; Move stones

 ;; Set player 2 as active player
_p2Active:
	push  offset p1Pit			; Push player 1''s side
	push  offset p2Pit			; Push player 2''s side
	call  copySides				; Set mainPit as p2Pit and secPit as p1Pit
	mov   edx, p2Manc
	mov   actManc, edx			; Store address of p2Manc in actManc
	jmp   _pitCheck				; Move stones

 ;; Move stones
_pitCheck:
	push  mainPit
	push  eax					; Save EAX for later [--]
	push  mainPit				; Push address of active side pits to check move [--]
	push  eax					; Push pit to check pit number [--]
	call  checkPit				; [--]  [+*3]
	pop   ebx					; Pop move check state into EBX [++]
	pop   eax
	cmp   ebx, 1				; Check if move is valid
	je    _makeMove				; Make move if it is valid
	jmp	  _badPitCheck			; Pit check came back bad

 ;; Make Move
_makeMove:
	mov   ebx, mainPit			; Put address into EBX
	mov   ecx, eax				; Store pit number in ECX for loop
	sub   ecx, 1
	add   ebx, ecx				; Increment mainPit to selected pit
	mov   eax, 0				; Clear EAX
	add   al, [ebx]				; Put number of stones in the pit into EAX
	mov   heldStones, eax		; Store number of stones in heldStones
	sub   [ebx], al				; Clear starting pit
	inc   ecx					; Increment counter to next pit
	inc   ebx					; Increment address
	jmp   _placeMainSideLoop	; Start loop to place stones

 ;; Start loop of adding stones to pits on the active player''s side
_placeMainSide:
	mov   ebx, mainPit
	mov   edx, 1				; Use EDX to hold which place was last
	mov   ecx, 1				; Reset counter to 1
	jmp   _placeMainSideLoop	; Start loop

 ;; Add stones to pits on active player''s side
_placeMainSideLoop:
	mov   eax, 1				; Set number of stones to 1
	cmp   heldStones, 0			; Check if there are no more held stones
	jle   _exitLoops			; If there are no more held stones, exit the loop
	cmp   ecx, 6				; Check if the counter reached the maximum pit number
	jge   _placeMancala			; If max pit was passed, move to the Mancala
	add   [ebx], al				; Increment the amount of stones in the pit
	dec   heldStones			; Decrement the amount of stones held
	inc   ecx					; Increment the counter
	inc   ebx					; Increment the address
	jmp   _placeMainSideLoop	; Jump back to top of loop

 ;; Add a stone to the active player''s mancala
_placeMancala:
	mov   edx, 2				; Set last placed location to 2
	mov   eax, 1				; Get ready to add 1 to the active player''s mancala (can''t add literal to memory directly)
	add   [actManc], eax		; Add a stone to the Mancala
	dec   heldStones			; Decrement amount of held stones
	jnz   _placeOtherSide		; Start adding stones to inactive side if the number of held stones is not zero
	jmp   _exitLoops			; If there are no more held stones, exit the loop

 ;; Start loop to add stones to the inactive player''s pits
_placeOtherSide:
	mov   ebx, secPit
	mov   edx, 3				; Set last placed location to 3
	mov   ecx, 1				; Reset counter to 1
	jmp   _placeOtherSideLoop	; Start loop

 ;; Add stones to the pits on the inactive player''s side
_placeOtherSideLoop:
	mov   eax, 1				; Set number of stones to 1
	cmp   heldStones, 0			; Check if there are no more held stones
	jle   _exitLoops			; If there are no more held stones, exit the loop
	cmp   ecx, 6				; Check if the counter reached the maximum pit number
	jge   _placeMainSide		; If max pit was passed, move to the main side
	add   [ebx], al				; Increment the amount of stones in the pit
	dec   heldStones			; Decrement the amount of stones held
	inc   ecx					; Increment the counter
	inc   ebx
	jmp   _placeOtherSideLoop	; Jump back to top of loop

 ;; Move from loops and do post proccessing
_exitLoops:
	 ; Store working registers
	push  eax
	push  ecx
	push  edx

	push  edx					; Push num for last area placed in [--]
	push  ecx					; Push counter [--]
	call  endPit				; Check edge cases
	call  setManc				; Update mancala
	pop   ebx					; Pop return value from endPit into EBX
	pop   edx					; Restore working registers
	pop   ecx					; Ditto
	pop   eax					; Ditto
	jmp   _moveMade				; Time to return

 ;; Set return value to state from 
_moveMade:
	pop   ecx					; Restore ECX
	pop   edx					; Pop return address from the stack into EDX
	push  ebx					; Push return state from endPit
	push  edx					; Restore return address to the stack
	jmp   _exit					; End proccess

 ;; Return to controller
_exit:
	ret							; Return with state in stack

 ;; Invalid number for active
_badActive:
	pop   ecx					; Restore ECX from start of process
	pop   edx					; Pop return address from the stack into EDX
	push  4						; Push 4 as state for invalid active player number
	push  edx					; Restore return address to the stack
	jmp   _exit					; End proccess

 ;; Pit Check had an issue with the move
_badPitCheck:
	pop   ecx					; Restore ECX from start of process
	pop   edx					; Pop return address from the stack into EDX
	push  ebx					; Push state from checkMove
	push  edx					; Restore return address to the stack
	jmp   _exit					; End proccess

 ;; Any major error occured
_critError:
	call  writeln
	push  1
	call  writeNumber
	call  writeln
	push  offset error
	call  writeline
	call  exitProgram			; End the program immediately
movePit ENDP

;;******************************************************************;
;; Call checkPit(pit, addr)
;; Parameters:		pit		--	Selected pit
;;					addr	--	Address of side of board to check
;; Returns:			state	--	Whether pit is valid
;; Registers Used:	EAX, EBX, EDX
;; 
;; Checks pit in the side of the board to see if the pit is 
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
	mov   eax, ebx				; Put number of stones in the pit into EAX
	cmp   eax, 0				; Check if the number of stones is 0
	jle   _empty				; If there are no stones, return empty state
	jmp   _valid				; Else, return success state

 ; Valid pit that is not empty
_valid:
	pop   edx					; Pop return address from the stack into EDX
	push  1						; Push state of 1 (valid address)
	push  edx					; Restore return address to the stack
	jmp   _exit					; Return

 ; Empty pit
_empty:
	pop   edx					; Pop return address from the stack into EDX
	push  4						; Push state of 4 (empty pit)
	push  edx					; Restore return address to the stack
	jmp   _exit					; Return

 ;; Invalid pit number
_invalid:
	pop   edx					; Pop return address from the stack into EDX
	push  5						; Push state of 5 (invalid pit)
	push  edx					; Restore return address to the stack
	jmp   _exit					; Return

_exit:
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
;;******************************************************************;
endPit PROC near
_endPit:
	; TODO
	mov   ebx, esi				; Save stack pointer in EBX
	pop   edx					; Pop return address from the stack into EDX
	pop   ecx					; Pop counter into ECX
	pop   eax					; Pop area into EAX
	push  edx					; Restore return address to the stack
	mov   edx, eax				; Put area into EDX
	sub   ecx, 1				; Adjust counter

	cmp   edx, 2				; Check if the last stone was placed in the mancala
	je    _inManc
	cmp   edx, 3				; Check if the last stone was placed on the other side
	je    _normalMove

_checkCapture:
	mov   eax, mainPit			; Put address of the pits in EAX
	add   eax, ecx				; Add index to address
	mov   edx, 1				; Cant compared a literal and a memory space
	cmp   [eax], edx			; Check if last pit only has 1 stone
	je    _capture

 ;; No edge case. Last stone placed in a normal, non-empty pit
_normalMove:
	mov   eax, 1
	jmp   _retState

 ;; Last stone ended ended in empty pit on active player''s side. 
 ;;		Stones in opposing pit are captured.
_capture:
	mov   heldStones, 1			; Take stone from pit
	mov   edx, 0				; Cant load a literal into a memory space
	mov   [eax], edx			; Clear pit

	; Find index of pit on opposing side
	mov   eax, ecx				; Move counter to EAX
	mov   ecx, 7				; Set ECX to 7 so result of subtraction is >= 1
	sub   ecx, eax				; Subtract counter from 7 to get index in ECX
	mov   eax, secPit			; Put address of opposing side into EAX
	add   eax, ecx				; Get address of pit to capture

	mov   cl, [eax]				; Use ECX as buffer
	add   heldStones, ecx		; Add number of stones captured to heldStones
	mov   ecx, 0				; Set ECX to zero
	mov   [eax], cl				; Clear stones from pit

	mov   eax, heldStones		; Move captured stones to EAX
	add   actManc, eax			; Add captured stones to the active player''s mancala

	mov   eax, 6				; Set return state to 6
	jmp   _retState

 ;; Last stone was placed in the mancala. Active player gets to 
 ;;		go again.
_inManc:
	mov   eax, 2				; Set return state to 2
	jmp   _retState

 ;; Return to caller
_retState:
	mov   esi, ebx				; Fix stack pointer
	pop   edx					; Pop return address from the stack into EDX
	pop   ecx					; Extra parameter from an unknown location to remove
	push  eax					; Push return state
	push  edx					; Restore return address to the stack
	ret							; Return to caller
endPit ENDP


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
	;call  writeline
	;call  writespc
	call  writesp
	pop   eax
	cmp   eax, 0
	je    _printZero
	jmp   _printNum

 ;; Print a zero if the number is zero
_printZero:
	push  offset zero			; Push zero to print
	call  writeline				; Write zero
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

	 ; Print intermediate border
	;push  brown				; Push brown as color for the border
	push  offset boardMid		; Push address of border
	;call  printline			; Write border to console in brown text
	call  writeline				; Write border to console

	; Restore Working Registers
	pop   edx
	pop   ecx
	pop   ebx
	pop   eax

	ret
printMid ENDP


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