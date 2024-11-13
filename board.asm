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

;INCLUDE Irvine32.inc

.data
	;; Data for Irvine
	;outHandle    HANDLE ?
	;cellsWritten DWORD ?
	;xyPos COORD <10,2>

	;; Variables to hold number of stones in each pit
						  ; ?, ?, ?, ?, ?, ?
	p1Pit			DD		1, 2, 3, 4, 5, 6					; Array to hold the pits on player 1''s side
	p2Pit			DD		7, 8, 9,10,11,12					; Array to hold the pits on player 2''s side 
	p1Manc			DD		13									; Number of stones in player 1''s mancala ; ?
	p2Manc			DD		14									; Number of stones in player 2''s mancala ; ?

	;; Message data
	noStone			byte	"No stones in desired pit!",10,0	; Message for when picked pit is empty
	captured		byte	" captured the stones in pit ",0	; Message for when a pit is captured
	p1				byte	"Player 1",0						; Universal string for indicating player 1
	p2				byte	"Player 2",0						; Universal string for indicating player 1
	zero			byte	"0",0								; For when the zero is missing
	space			byte	" ",0								; Space to print

	;; Board Parts
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
	call  writeline				; Write to console
	;call  print
	push  offset boardLeft		; Print left side of second row
	call  writeline				; Write to console
	;call  print
	mov   ebx, p1Pit			; EBX will point to the current value being printed
	mov   ecx, 6				; Counter to stop loop
	mov   ebx, 0
_rowTwo:
	mov   eax, 0
	add   eax, [p1Pit+ebx]
	add   ebx, 4
	push  eax
	call  printNumber
	call  printMid
	dec   ecx
	jnz   _rowTwo
_endRowTwo:
	push  offset boardRight		; Print right side of board for the second row
	call  writeline				; Write to console
	;call  print
	push  offset boardLeftC		; Print left side of third row
	call  writeline				; Write to console
	;call  print
	;mov   eax, p1Manc
	push  p1Manc
	call  printNumber
	push  offset boardCenter
	call  writeline
	;call  print
	;mov   eax, p2Manc
	push  p2Manc
	call  printNumber
	push  offset boardRightC
	call  writeline
	;call  print
	push  offset boardLeft		; Print left side of second row
	call  writeline
	;call  print
	mov   ebx, p2Pit			; EBX will point to the current value being printed
	mov   ecx, 6				; Counter to stop loop
	mov   ebx, 0
_rowFour:
	mov   eax, 0
	add   eax, [p2Pit+ebx]
	add   ebx, 4
	push  eax
	call  printNumber
	call  printMid
	dec   ecx
	jnz   _rowFour
_endRowFour:
	push  offset boardRight
	call  writeline
	;call  print
	push  offset boardBottom
	call  writeline
	;call  print

_exit:
	pop   edx					; Restore working registers
	pop   ecx
	pop   ebx

	ret
printBoard ENDP


;;******************************************************************;
;; Call movePit(active, pit)
;; Parameters:		active	--	Number for the active player
;;					pit		--	Selected pit to move
;; Returns:			state	--	What move resulted in (Fail, Success)
;; Registers Used:	EAX <(s)> {If saved and restored at the end}
;; 
;; Empties selected pit and moves the stones.
;;******************************************************************;
movePit PROC near
_movePit:
	ret
movePit ENDP


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
	jle   _printZero
_printNum:						; Write number to the console
	push  eax
	call  writeNum
	;call  printnum
	jmp   _exit
_printZero:						; Write a space if number has a single digit
	push  eax
	;push  offset zero
	;call  writeline
	;call  writespc
	call  writesp
	pop   eax
	jmp   _printNum
_exit:
	pop   ecx					; Restore Working Registers
	pop   ebx
	pop   eax
	ret
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