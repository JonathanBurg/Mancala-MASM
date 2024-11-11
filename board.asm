; Output Module
; Jonathan Burgener
; 1 November, 2024
; Prints and controls the board
; Revised: JB, 6 November 2024 - Added stubs for printing, updating, and initializing the board

.386P

.model flat

extern	writeline:	 near
extern	readline:	 near
extern	charCount:	 near
extern	writeNumber: near
extern	writeNum:	 near
extern	writesp:	 near


.data						; ?, ?, ?, ?, ?, ?
	p1Pit			DD		1, 2, 3, 4, 5, 6					; Array to hold the pits on player 1''s side
	p2Pit			DD		7, 8, 9,10,11,12					; Array to hold the pits on player 2''s side 
	p1Manc			DD		13									; Number of stones in player 1''s mancala ; ?
	p2Manc			DD		14									; Number of stones in player 2''s mancala ; ?
	noStone			byte	"No stones in desired pit!",10,0	; Message for when picked pit is empty
	captured		byte	" captured the stones in pit ",0	; Message for when a pit is captured
	p1				byte	"Player 1",0						; Universal string for indicating player 1
	p2				byte	"Player 2",0						; Universal string for indicating player 1
	zero			byte	"0",0								; For when the zero is missing

 ;; Board Parts
	boardTop		byte	10, 10, "	", 201, 205, 205, 205, 205, 203, 205, "6", 205, 205, 209, 
							205, "5", 205, 205, 209, 205, "4", 205, 205, 209, 205, "3", 205, 205, 
							209, 205, "2", 205, 205, 209, 205, "1", 205, 205, 209, 205, 205, 205, 
							205, 187,"?", 10, 0						; Top border of the board
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
	; TODO
	pop   edx					; pop return address from the stack into EDX
	push  eax					; Pop active player to EAX
	push  edx					; Restore return address to the stack
	push  ebx					; Save working registers
	push  ecx					; Ditto
	push  edx					; Ditto
	push  offset boardTop		; Print the top of the board
	call  writeline
	push  offset boardLeft		; Print left side of second row
	call  writeline
	mov   ebx, p1Pit			; EBX will point to the current value being printed
	mov   ecx, 6				; Counter to stop loop
	mov   ebx, 0
_rowTwo:
	mov   eax, 0
	add   eax, [p1Pit+ebx]
	add   ebx, 4
	call  printNum
	call  printMid
	dec   ecx
	jnz   _rowTwo
_endRowTwo:
	push  offset boardRight
	call  writeline
	push  offset boardLeftC
	call  writeline
	mov   eax, p1Manc
	call  printNum
	push  offset boardCenter
	call  writeline
	mov   eax, p2Manc
	call  printNum
	push  offset boardRightC
	call  writeline
	push  offset boardLeft		; Print left side of second row
	call  writeline
	mov   ebx, p2Pit			; EBX will point to the current value being printed
	mov   ecx, 6				; Counter to stop loop
	mov   ebx, 0
_rowFour:
	mov   eax, 0
	add   eax, [p2Pit+ebx]
	add   ebx, 4
	call  printNum
	call  printMid
	dec   ecx
	jnz   _rowFour
_endRowFour:
	push  offset boardRight
	call  writeline
	push  offset boardBottom
	call  writeline

exit:
	ret
printBoard ENDP

printNum PROC near
_printNum:
	push  eax
	push  ebx
	push  ecx
	push  edx
	cmp   eax,9
	jle   _printZero
_printNumber:
	push  eax
	call  writeNum
	jmp   _exit
_printZero:
	push  eax
	;push  offset zero
	;call  writeline
	call  writesp
	pop   eax
	jmp   _printNumber
_exit:
	pop   edx
	pop   ecx
	pop   ebx
	pop   eax
	ret
printNum ENDP

printMid PROC near
_printMid:
	push  eax
	push  ebx
	push  ecx
	push  edx
	push  offset boardMid
	call  writeline
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
exit:
	pop   edx					; pop return address from the stack into EDX
	push  1						; Push return value
	push  edx					; Restore return address to the stack
	ret
updateStones ENDP

END