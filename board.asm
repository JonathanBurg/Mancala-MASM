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


.data
	p1Pit			DD		4, 4, 4, 4, 4, 4					; Array to hold the pits on player 1''s side ; ?, ?, ?, ?, ?, ?
	p2Pit			DD		4, 4, 4, 4, 4, 4					; Array to hold the pits on player 2''s side ; ?, ?, ?, ?, ?, ?
	p1Manc			DD		0									; Number of stones in player 1''s mancala ; ?
	p2Manc			DD		0									; Number of stones in player 2''s mancala ; ?
	noStone			byte	"No stones in desired pit!",10,0	; Message for when picked pit is empty
	captured		byte	" captured the stones in pit ",0	; Message for when a pit is captured
	p1				byte	"Player 1",0						; Universal string for indicating player 1
	p2				byte	"Player 2",0						; Universal string for indicating player 1

 ;; Board Parts
	boardTop		byte	"TODO",10,0								; Top border of the board
	boardLeft		byte	"TODO",0								; Left Side, 2nd and 4th rows
	boardLeftC		byte	"TODO",0								; Left Side, 3rd row
	boardCenter		byte	"TODO",0								; Inner most border, 3rd row
	boardMid		byte	"TODO",0								; Inside for 2nd and 4th rows
	boardRight		byte	"TODO",10,0								; Right side end for 2nd and 4th rows
	boardRightC		byte	"TODO",10,0								; Right side end for 3rd row
	boardBottom		byte	"TODO",10,0								; Bottom border of the board

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
exit:
	ret
printBoard ENDP


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