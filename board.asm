; Output Module
; Jonathan Burgener
; 1 November, 2024
; Prints the board

.386P

.model flat

extern	writeline:	 near
extern	readline:	 near
extern	charCount:	 near
extern	writeNumber: near
extern	writeNum:	 near


.data

.code

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
exit:
	ret
printBoard ENDP


;;******************************************************************;
;; Call updateStones(side1,side2,mancala1,mancala2)
;; Parameters:		side1	--	The six pits on player 1''s side
;; 					side2	--	The six pits on player 2''s side
;;					mancala1 --	Player 1''s mancala
;;					mancala2 --	Player 2''s mancala
;; Returns:			None
;; Registers Used:	EAX <(s)> {If saved and restored at the end}
;; 
;; Updates the amount of stones in each pit
;;******************************************************************;
updateStones PROC near
_updateStones:
	; TODO
exit:
	ret
updateStones ENDP
END
