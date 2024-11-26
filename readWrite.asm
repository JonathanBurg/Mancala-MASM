;; Main Console program
;; Wayne Cook
;; 20 September 2024
;; Show how to do input and output
;; Revised: WWC 14 March 2024 Added new module
;; Revised: WWC 15 March 2024 Added this comment to force a new commit.
;; Revised: WWC 13 September 2024 Minor updates for Fall 2024 semester.
;; Revised: JB   7 October, 2024 - Added module for a new line
;; Revised: JB  17 October, 2024 - Updated headers and added getInt and intStr
;; Revised: JB  20 October, 2024 - Added a version of writeNumber that ends with no space
;; Revised: JB  19 November, 2024 - Changing console input/output to use Irvine
;; Revised: JB  20 November, 2024 - Adding procedure from AG to clear the console and
;;						continuing to convert to Irvine. Updated Documentation.
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
;;		EBP - Callee Saved register - base pointer.386P
;; 
;; 
;; Routines:
;;		initializeConsole()		done
;;		readLine()				done	(Updated name to camelCase)
;;		charCount(string)		No change needed
;;		writeLine(location)			(Updated name to camelCase)
;;		writeln()
;;		writeSp()					(Updated name to camelCase)
;;		writeNum(number)
;;		writeNumber(number)
;;		genNumber()
;;		readInt(prompt)
;;		clearConsole@0()
;; 
;; For Comments:
;;	[--] means -4 bytes from ESP	(Add item to stack)
;;		[-*#] means -(#*4) bytes from ESP
;;	[++] means +4 bytes to ESP		(Remove item from stack)
;;		[+*#] means +(#*4) bytes to ESP
;; Comments on process end Lines:
;;	[ESP+-=bytes added/taken (Net change * 4)], Whether all parameters were
;;			removed from stack [+- net # item removed/added to stack]

;.model flat ; Not included for Irvine
INCLUDE Irvine32.inc

exitProgram		proto	; main.asm 
;; Library calls used for input from and output to the console
;extern  _GetStdHandle@4:near
;extern  _WriteConsoleA@20:near
;extern  _ReadConsoleA@20:near
;extern  _ExitProcess@4: near


.data

;; Data for Irvine
	;outHandle    HANDLE ?
	cellsWritten DWORD ?
	xyPos COORD <10,2>

msg				byte	"Hello, World", 10, 0			; ends with line feed (10) and NULL
prompt			byte	"Please type your name: ", 0	; ends with string terminator (NULL or 0)
results			byte	10,"You typed: ", 0
colorError		byte	10,"Invalid color!",10,0
error			byte	"Program ran into error, stopping...", 10, 0 ; Critical error encountered
continueMsg		byte	10, "Press enter to continue: ", 0
p1				byte	"Player 1", 0	; Universal string for indicating player 1
p2				byte	"Player 2", 0	; Universal string for indicating player 2
possessive		byte	"'s", 0			; For saying that something is a player''s
indent			byte	"	", 0		
newLine			byte	10, 0	; Starts a new line
space			byte	" ", 0	; Creates a space
inputPrompt		dword	?		; Prompt for user input
outputHandle	HANDLE	?		; Output handle writing to consol. uninitslized
inputHandle		HANDLE	?		; Input handle reading from consolee. uninitslized
written			dword	?
retTemp			DD		?		; Temporarily store return address
curTextColor	DD		?		; Current foreground
curBackColor	DD		?		; Current background color
curColor		DD		?		; Current color scheme
;INPUT_FLAG		equ		-10
;OUTPUT_FLAG		equ		-11

;; Reading and writing requires buffers. I fill them with 00h.
readBuffer		byte	1024  DUP(00h)		; Buffer to input strings from console
writeBuffer		byte	1024  DUP(00h)		; Buffer to hold string to write to console
numberBuffer	byte	1024  DUP(00h)		; Buffer to hold the string resulting from converting an integer to a string
numCharsToRead	dword	1024				; Number of characters to read from the console
numCharsRead	dword	?					; Unset or uninitialized. Number of chars read
NULL			equ		0
textColor		DD		?					; Color code for text color

; Needed for clearing the console. Thanks AG!
clear_console byte 1bh, '[', '2', 'J'
clear_scroll_back byte 1bh, '[', '3', 'J'

.code


;;******************************************************************;
;; Call initialize_console()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	EAX
;;	Utilizes Irvine
;; 
;; Initialize Input and Output handles so you only have to do that 
;;		once.
;; This is your first assembly routine
;; 
;; 
;; This process sets up the console by storing the handles to the 
;;		Input and the Output in inputHandle and outputHandle 
;;		respectively. The process gets the output handle by invoking 
;;		GetStdHandle from Irvine with STD_OUTPUT_HANDLE (Irvine) 
;;		which returns the output handle in EAX. Likewize, the input 
;;		handle is retrieved by invoking GetStdHandle from Irvine with 
;;		STD_INPUT_HANDLE (Irvine) which returns the input handle in 
;;		EAX. Since inputHandle and outputHandle are stored in the 
;;		memory, they can be retrieved by other processes to get input 
;;		from inputHandle or write strings to outputHandle. This 
;;		process had no parameters to remove from the stack. This 
;;		process only needs to be called once (preferably when the 
;;		program starts) to set up the handles.
;; 
;; 
;; call initialize_console
;; 
;; Procedure removes all parameters from the stack.
;;******************************************************************;
initialize_console PROC near
	 ; Get the Console standard output handle:
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE
	mov   outputHandle,eax
	
	; Get handle to standard input: 
	INVOKE GetStdHandle, STD_INPUT_HANDLE
	mov   inputHandle,eax

	; Set Initial colors
	mov   eax, white				; Text color
	mov   curTextColor, eax		; Set text color to white
	mov   eax, black				; Background color
	mov   curBackColor, eax		; Set background color to black
	mov   eax, white+(black*16)
	mov   curColor, eax			; Set color scheme to white on black
	call  setTextColor			; Set starting color to white on black


	;; Handles for normal console input/output
	 ; handle = GetStdHandle(-11)
	;push  OUTPUT_FLAG
	;call  _GetStdHandle@4
	;mov   outputHandle, eax
	 ; handle = GetStdHandle(-10)
	;push  INPUT_FLAG
	;call  _GetStdHandle@4
	;mov   inputHandle, eax
	ret							; [++]
initialize_console ENDP			; [ESP+=4], Parameters removed from stack [++]


;;******************************************************************;
;; Call readLine()
;; Parameters:		None
;; Returns:			EAX		--	console input
;; Registers Used:	EAX
;;	Utilizes Irvine
;; 
;; Now the read/write handles are set, read a line
;;******************************************************************;
readLine PROC near
_readLine: 
	; Wait for user input
	INVOKE ReadConsole, inputHandle, ADDR readBuffer,
	  numCharsToRead, ADDR numCharsRead, NULL

	 ; ReadConsole(handle, &buffer, numCharToRead, numCharsRead, null)
	;push  0
	;push  offset numCharsRead
	;push  numCharsToRead
	;push  offset readBuffer
	;push  inputHandle
	;call  _ReadConsoleA@20
	mov   eax, offset readBuffer
	ret							; Returns with console input in EAX
readLine ENDP


;;******************************************************************;
;; Call charCount(string)
;; Parameters:		string	--	String to check length of
;; Returns:			EAX		--	Character Count
;; Registers Used:	EAX, EBX (s), ECX (s), EDX (s)
;; 
;; Not needed for Irvine
;; 
;; All strings need to end with a NULL (0). So I (WWC) do not have to 
;; manually count the number of characters in the line, I wrote this
;; routine.
;;******************************************************************;
charCount PROC near
_charCount:
	pop   [retTemp]				; Save return address
	pop   eax					; Save offset/address of string
	push  [retTemp]				; Put return address back on the stack
	push  ebx					; Save EBX
	push  ecx					; Save ECX
	push  edx					; Save EDX
	mov   ebx, eax				; Move offset/address of string to ebx
	mov   eax, 0				; load counter to 0
	mov   ecx, 0				; Clear ECX register
_countLoop:
	mov   cl,[ebx]				; Look at the character in the string
	cmp   ecx, NULL				; check for end of string.
	je    _endCount
	inc   eax					; Up the count by one
	inc   ebx					; go to next letter
	jmp   _countLoop
_endCount:
	pop   edx
	pop   ecx					; Restore EBX and ECX
	pop   ebx
	ret							; Return with EAX containing character count
charCount ENDP


;;******************************************************************;
;; Call writeLine(location)
;; Parameters:		location --	buffer location of the string to be
;;								printed (put into EDX)
;; Returns:			Nothing
;; Registers Used:	EAX, EDX
;;	Utilizes Irvine
;; 
;; Default proccess to write to console. Sets the text color to
;;	white and writes the string to the console.
;;
;; For all routines, the last item to be pushed on the stack is the
;; return address, save it to a register then save any other 
;; expected parameters in registers, then restore the return address
;; to the stack.
;;******************************************************************;
writeLine PROC near
_writeLine:
	pop   eax					; pop return address from the stack into EAX
	pop   edx					; Pop the buffer location of string to be printed into EDX for WriteString
	push  eax					; Restore return address to the stack
	call  getTextColor			; Debugging. Puts current text color into EAX
	; 0 - Black
	; 1 - Blue
	; 2 - Green
	; 3 - Cyan
	; 4 - Red
	; 5 - Magenta
	; 6 - Brown
	; 7 - Light Gray
	; 8 - Gray
	; 9 - Light Blue
	; A - Light Green
	; B - Light Cyan
	; C - Light Red
	; D - Light Magenta
	; E - Yellow
	; F - White

	;mov   eax, white			; Set color to white and store it in EAX
	;call  SetTextColor			; Set the color using the color code held in EAX
	call  WriteString			; Write the string held in EDX to the standard console
	
	;; Output code for normal console output. Unessesary for Irvine
	;push  ebx
	;push  ebx
	;call  charCount
	;pop   ebx

	 ; WriteConsole(handle, &msg[0], numCharsToWrite, &written, 0)
	;push  0
	;push  offset written
	;push  eax					; return size to the stack for the call to _WriteConsoleA@20 (20 is how many bits are in the call stack)
	;push  ebx					; return the offset of the line to be written
	;push  outputHandle
	;call  _WriteConsoleA@20

	ret
writeLine ENDP


;;******************************************************************;
;; Call printC(addr, color)
;; Parameters:		addr	--	Address of string to print 
;;										(Stored in EDX)
;;					color	--	Number to represent desired color 
;;										(Stored in EAX)
;; Returns:			Nothing
;; Registers Used:	EAX, EBX, EDX
;;	Utilizes Irvine
;; 
;; Writes a string to the standard console with color using Irvine
;; Colors:
;;		Black (0), White (1), Gray (2), Brown (3), Red (4), 
;;		Yellow (5), Green (6), Blue (7), Cyan (8), Magenta (9), 
;;		Light Gray (10), Light Red (11), Light Green (12), 
;;		Light Blue (13), Light Cyan (14), and Light Magenta (15)
;;******************************************************************;
printC PROC near
_printC:
	pop   ebx					; Pop return address from the stack into EBX
	pop   edx					; Pop addr into EDX
	pop   eax					; Pop color number into EAX
	push  ebx					; Restore return address to the stack

	push  eax					; Push color number
	call  setForeground			; Set the color using the color code held in EAX
	call  WriteString			; Write the string held in EDX to the standard console

	mov   eax, white			; Set the color to White
	call  SetTextColor			; Reset the color

	ret
printC ENDP


;;******************************************************************;
;; Call writeln()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	EAX (s), EDX (s)
;; 
;; Writes a line break to the console
;;******************************************************************;
writeln PROC near
_writeln:
	push  eax					; Store EAX [--]
	push  edx					; Store EDX [--]

	 ; Create new line
	push  offset newLine		; [--]
	call  writeline				; [--] [+*2]

	pop   edx					; Restore EDX [++]
	pop   eax					; Restore EAX [++]
	ret							; [++]
writeln ENDP					; [ESP+=4], Parameters removed from stack [++]


;;******************************************************************;
;; Call writeSp()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	EAX (s), EDX (s)
;; 
;; Writes a space to the console
;;******************************************************************;
writeSp PROC near
_writeSp:
	push  eax					; Save Working Registers [--]
	push  edx					; Ditto [--]

	 ; Write a space to the console
	push  offset space			; [--]
	call  writeline				; [--] [+*2]

	pop   edx					; Restore Working Registers [++]
	pop   eax					; Ditto [++]
	ret							; [++]
writeSp ENDP					; [ESP+=4], Parameters removed from stack [++]


;;******************************************************************;
;; Call writeNum(number)
;; Parameters:		number	--	Value to write to console
;; Returns:			Nothing
;; Registers Used:	EAX, EDX
;; 
;; Converts number to and ASCII string, and pushes that string to 
;;		writeLine to write it to the console
;;******************************************************************;
writeNum PROC near
_writeNum:
	pop   edx					; pop return address from the stack into EDX [++]
	pop   eax					; Pop the number to be written. [++]
	push  edx					; Restore return address to the stack [--]

	call  WriteDec				; Write number to console using Irvine routine
	ret
writeNum ENDP


;;******************************************************************;
;; Call writeNumber(number)
;; Parameters:		number	--	Value to write to console
;; Returns:			Nothing
;; Registers Used:	EAX, EDX
;; 
;; Writes number then writes a space after
;;******************************************************************;
writeNumber PROC near
_writeNumber:
	pop   edx					; Pop return address from the stack into EDX [++]
	pop   eax					; Pop number into EAX
	push  edx					; Restore return address to the stack [--]

	call  WriteDec				; Write number to console using Irvine routine
	call  writeSp				; Write a space to the console
	ret
writeNumber ENDP


;;******************************************************************;
;; Call genNumber(number, pointer to ASCII buffer)
;; Parameters:		number - decimal number to be converted to ASCII
;;					pointer to ASCII buffer - Address of buffer where 
;;						to store generated ASCII number
;; Returns:			ASCII buffer in parameters has generated ASCII 
;;						number.
;; Registers Used:	EAX (s), EBX, ECX (s), EDX (s), EBP (s), ESP (s),
;;					EDI (s), ESI (s)
;; ASM: call genNumber@8 for two parameters.
;; 
;; genNumber(number, pointer to ASCII buffer) create the ASCII value
;;	 of a number.
;; To help callers, I will save all registers, except eax, which 
;;	 will be location in number ASCII string to be written. This 
;;	 routine will show the official way to handle the stack and base 
;;	 pointers. It is less effecient, but it preserves all registers.
;; 
;; 
;; This process is used to translate a number to a string of ASCII 
;;		characters. This process is recursive, so care should be 
;;		taken to ensure there is not a stack overflow. This process 
;;		has two parameters: the number to translate, and the pointer 
;;		to a buffer to store the resulting string in. Both parameters 
;;		are accessed using EBP but are not removed from the stack. 
;;		The pointer that ESP contains at the start is stored in EBP 
;;		so that the parameters can be accessed, and so ESP can be 
;;		restored back to its inital value at the end so the return 
;;		address is not buried. Each recursive iteration, EAX is used 
;;		to hold the dividend which is the current number held in the 
;;		stack. If EAX equals 0, the recursive loop will end, EBX is 
;;		used to hold the pointer to the buffer. ECX is used to divide 
;;		the value held in EAX by 10 to remove the least significant 
;;		digit from the number to get ready to translate the next 
;;		digit. The least significant digit removed by the divide is 
;;		stored in EDX. The value in DX is then added to value of the 
;;		ASCII value for '0' to force translate the digit into ASCII. 
;;		The next recursive iteration is then called with the same 
;;		buffer address, but the number is set to the dividend stored 
;;		in EAX. Once the last iteration is reached, each iteration 
;;		will append the character they have stored in DX to the end 
;;		of the buffer, and EBX will be incremented to get ready for 
;;		the next iteration to appends its character. DX will then be
;;		set to a terminating null and appended to EBX. The working 
;;		registers are then restored and ESP is set back to the value 
;;		it had at the start of the routine. Finally the program 
;;		returns to the caller. The parameters are not removed from 
;;		the stack, so ESP needs to be adjusted by adding 8 bytes to 
;;		it. The resultant string will be stored in the buffer that 
;;		was passed to the stack as a parameter for genNumber.
;; 
;; 
;; push  pointer to ASCII buffer
;; push  number
;; call  genNumber
;; add   esp, 8					; Remove the two parameters
;;******************************************************************;
genNumber PROC near			; @8 says there are 2 parameters (8 bytes)on the stack to remove on ret.
_genNumber:
	; Subroutine Prologue
	push  ebp					; Save the old base pointer value. [--]
	mov	  ebp, esp				; Set the new base pointer value to access parameters [EBP = ESP-=4]
	;sub   esp, 4				; Make room for one 4-byte local variable, if needed [--]
	push  edi					; Save the values of registers that the function [--]
	push  esi					; will modify. This function uses EDI and ESI. [--]
	; The eax, ebx, ecx, edx registers do not need to be saved,
	;		but they are for the sake of the calling routine.
	push  eax					; EAX needed as a dividend [--]
	;push  ebx					; Only save if not used as a return value [--]
	push  ecx					; Ditto [--]
	push  edx					; Ditto [--]
	; Subroutine Body
	mov   eax, [ebp+8]			; Move number value to be converted to ASCII
	mov   ebx, [ebp+12]			; The start of the generated ASCII buffer for storage
	mov   ecx, 10				; Set the divisor to ten
	;mov   esi, NULL				; Count number of numbers written
;; The dividend is place in eax, then divide by ecx, the result goes into eax, with the remiander in edx
	cmp   eax, 0				; Stop when the number is 0
	jle   numExit
	mov   edx, 0				; Clear the register for the remainder
	div   ecx					; Do the divide
	add   dx,'0'				; Turn the remainer into an ASCII number
	;push  dx					; Now push the remainder onto the stack
	;inc   esi					; increment number count
;; Do another recursive call;
	push  ebx					; Pass on the start of the number buffer. [--]
	push  eax					; And the number [--]
	call  genNumber				; ******Do the recursion***** [--] [++]
	add   esp, 8				; Remove the two parameters [+*2]
;; Load the number, one digit at a time.
	mov   [ebx], dl				; Add the number to the output sring
	inc   ebx					; go to the next ASCII location
	mov   dl, NULL					; cannot load a literal into an addressed location
	mov   [ebx], dl				; Add a terminating NULL to the end of the number
	
numExit:
	
	; If eax is used as a return value, make sure it is loaded by now.
	; And restore all saved registers
	; Subroutine Epilogue
	pop   edx					; [++]
	pop   ecx					; [++]
	;pop   ebx					; [++]
	pop   eax					; [++]
	pop   esi					; Recover register values [++]
	pop   edi					; [++]
	mov   esp, ebp				; Deallocate local variables [ESP-=4]
	pop   ebp					; Restore the caller''s base pointer value [++]
	ret							; [++]
genNumber ENDP					; [ESP+=4], 2 Parameters left on stack [++]


;;******************************************************************;
;; Call readIntegerC(prompt, color)
;; Parameters:		prompt	--	Prompt for the desired input
;;					color	--	Color to set input to
;; Returns:			input 	--	User inputted value
;; Registers Used:	EAX, EBX (s), ECX (s), EDX
;; 
;; Routine to get user input and convert it to an integer
;; Algorithm written by Wayne Cook
;; Adapted by Jonathan Burgener to fit program
;;******************************************************************;
readIntegerC PROC near
_readIntegerC:
	pop   edx					; Pop return address from the stack into EDX
	pop   inputPrompt			; Pop the number to be written.
	pop   textColor				; Pop color code into textColor
	push  edx					; Restore return address to the stack
	 ; Store working registers
	push  ebx
	push  ecx

	 ; Clear registers
	xor   eax, eax
	xor   ebx, ebx
	xor   ecx, ecx
	xor   edx, edx

	 ; Type a prompt for the user
	push  inputPrompt
	call  writeline

	 ; Get input from console
	mov   eax, textColor
	call  setTextColor			; Set text color to the desired color
	call  readLine				; Get input
	mov   ecx, eax				; Move input text into ECX
	mov   eax, curColor
	call  setTextColor			; Put color back to what it was before

	 ; Take what was read and convert to a number
	mov   eax, 0				; Initialize the number
	mov   ebx, 0				; Make sure upper bits are all zero.
	
	 ; Loop to append each digit in the sequence to the number
findNumberLoop:
	mov   bl, [ecx]				; Load the low byte of the EBX reg with the next ASCII character.
	cmp   bl, '9'				; Make sure it is not too high
	jg    endNumberLoop
	sub   bl, '0'
	cmp   bl, 0					; Or too low
	jl    endNumberLoop
	mov   edx, 10				; Save multiplier for later need
	mul   edx					; Multiply number by 10 to create space to append the digit
	add   eax, ebx				; Add digit to EAX
	inc   ecx					; Go to next location in number
	jmp   findNumberLoop

	 ; Closes routine and restores working registers
endNumberLoop:
	 ; Reset color code
	mov   ecx, white			; Working around memory to memory
	mov   textColor, ecx
	 ; Restore working registers
	pop   ecx
	pop   ebx

	pop   edx					; Pop return address from the stack into EDX
	push  eax					; Push input value to stack
	push  edx					; Restore return address to the stack
	 ; Returns with the input value in the stack
	ret
readIntegerC ENDP


;;******************************************************************;
;; Call readInteger(prompt)
;; Parameters:		prompt	--	Prompt for the desired input
;; Returns:			input 	--	User inputted value
;; Registers Used:	EAX, EDX
;; 
;; Sets color to white and calls readIntC
;;******************************************************************;
readInteger PROC near
_readInteger:
	pop   edx					; Pop return address from the stack into EDX
	pop   eax					; Pop the number to be written.
	push  edx					; Restore return address to the stack

	 ; Read integer from console
	push  curColor				; Push color that text already has
	push  eax					; Push prompt
	call  readIntegerC			; Get input

	 ; Set return value
	pop   eax					; Pop return value into EAX
	pop   edx					; Pop return address from the stack into EDX
	push  eax					; Push input value to stack
	push  edx					; Restore return address to the stack
	ret
readInteger ENDP


;;******************************************************************;
;; Call clearConsole()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	None
;; 
;; Clears the console
;;******************************************************************;
clearConsole PROC near
_clearConsole:
    call Clrscr
	ret
clearConsole ENDP


;;******************************************************************;
;; Call pauseProgram()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	EAX (s)
;; 
;; Pauses the program and waits for input from the user. Finishes by
;; Clearing the screen.
;;******************************************************************;
pauseProgram PROC near
_pauseProgram:
	 ; Write prompt to continue program
	push  offset continueMsg	; Push message
	call  writeLine				; Write prompt

	call  ReadChar				; Wait for input to continue
	ret							; Return to caller
pauseProgram ENDP


;;******************************************************************;
;; Call writePlayers(player, possessive)
;; Parameters:		 player	--	player to print
;;				  possessive	--	boolean over whether to add "'s"
;; Returns:			Nothing
;; Registers Used:	EAX, EDX
;; 
;; Write "Player 1" or "Player 2" depending on what player is wanted
;; Specific for this program
;;******************************************************************;
writePlayers PROC near
_writePlayers:
	pop   edx					; Pop return address from the stack into EDX
	pop   eax					; Pop player number into EAX
	pop   ebx					; Pop possessive into EBX
	push  edx					; Restore return address to the stack
	
	cmp	  eax, 1				; If player 1 is wanted
	je    _play1				;	Jump to play1
	cmp   eax, 2				; If player 2 is wanted
	je    _play2				;	Jump to play2
	jmp   _errorEncountered		; Else jump to errorEncountered

_play1:
	mov   eax, curBackColor		; Get background color
	imul  eax, 16				; Multply background color by 16
	add   eax, 1				; Add number for blue
	call  setTextColor			; Set text color to blue
	push  offset p1				; Push address of string to write
	call  writeLine				; write "Player 1"
	; Add possessive?
	cmp   ebx, TRUE				; Check if possessive is true (1)
	je    _addPossessive		;	If so, add "'s"
	jmp   _return				;	Else, return

_play2:
	mov   eax, curBackColor		; Get background color
	imul  eax, 16				; Multply background color by 16
	add   eax, 4				; Add number for red
	call  setTextColor			; Set text color to red
	push  offset p2				; Push address of string to write
	call  writeLine				; write "Player 2"

	cmp   ebx, TRUE				; Check if possessive is true (1)
	je    _addPossessive		;	If so, add "'s"
	jmp   _return				;	Else, return

_addPossessive:
	push  offset possessive		; Push address of string to write
	call  writeLine				; Write possessive
	jmp   _return				; Time to return

_return:
	mov   eax, curColor			; Put color back to what it was
	call  setTextColor			; Set color
	ret

_errorEncountered:
	push  11
	call  setForeground			; Set the text color to light red
	push  0
	call  setBackground			; Set the background color to black
	call  writeln
	push  4
	call  writeNumber
	call  writeln
	push  offset error
	call  writeLine
	call  exitProgram
writePlayers ENDP


;;******************************************************************;
;; Call writePlayers(player)
;; Parameters:		player	--	player to print
;; Returns:			Nothing
;; Registers Used:	EAX, EDX
;; 
;; Write "Player 1" or "Player 2" depending on what player is wanted
;; Specific for this program
;;******************************************************************;
writePlayer PROC near
_writePlayer:
	pop   edx					; Pop return address from the stack into EDX
	pop   eax					; Pop player number into EAX
	push  edx					; Restore return address to the stack

	push  FALSE					; Push false for the possessive
	push  eax					; Push player number
	call  writePlayers			; Write player
	ret
writePlayer ENDP


writeTab PROC near
_writeTab:
	mov   eax, white			; Clear the background color
	call  setTextColor			
	call  writeln				; Start a new line
	push  offset indent			; Write a indent
	call  writeLine
	mov   eax, curColor
	call  setTextColor
	ret
writeTab ENDP


;;******************************************************************;
;; Call setTextC(textColorNum)
;; Parameters:		textColorNum --	Color to set for text
;; Returns:			Nothing
;; Registers Used:	EAX, EDX
;;	Utilizes Irvine
;; 
;; Sets the color of the foreground text to the color associated with
;;	the input number
;; Colors w/ numbers:
;;		Black (0), White (1), Gray (2), Brown (3), Red (4), 
;;		Yellow (5), Green (6), Blue (7), Cyan (8), Magenta (9), 
;;		Light Gray (10), Light Red (11), Light Green (12), 
;;		Light Blue (13), Light Cyan (14), and Light Magenta (15)
;;******************************************************************;
setForeground PROC near
_setForeground:
	pop   edx					; Pop return address from the stack into EDX [++]
	pop   eax					; Pop color number into EAX [++]
	push  edx					; Restore return address to the stack [--]

	; Make sure color is in the correct range
	cmp   eax, 0
	jl    _invalidColor
	cmp   eax, 15
	jg    _invalidColor

	; Get Irvine''s definition for the color
	push  eax
	call  getColor
	mov   curTextColor, eax		; Save color as foreground color

	; Set color scheme
	mov   eax, curBackColor		; Move current background color to EAX
	imul  eax, 16				; Multiply background color by 16 to make room for foreground color
	add   eax, curTextColor		; Add foreground color
	mov   curColor, eax			; Save color scheme in curColor
	call  setTextColor			; Set the color of the text
	ret							; Return to caller

;; If color is not valid, warn user and keep color as it is
_invalidColor:
	; Reset coloring to white on black
	mov   eax, white+(black*16)	; Reset color to default (White on black)
	call  setTextColor
	; Warn user
	push  offset colorError		; Push error message for invalid color number
	call  writeLine				; Write error to console
	mov   eax, curColor			; Get color scheme
	call  setTextColor			; Put color scheme back to what it was
	ret							; Return without changing the color
setForeground ENDP


;;******************************************************************;
;; Call setBackground(colorNum)
;; Parameters:		colorNum --	Color to set the background to
;; Returns:			Nothing
;; Registers Used:	EAX, EDX
;;	Utilizes Irvine
;; 
;; Sets the color of the background to the color associated with
;;	the input number.
;; Colors w/ numbers:
;;		Black (0), White (1), Gray (2), Brown (3), Red (4), 
;;		Yellow (5), Green (6), Blue (7), Cyan (8), Magenta (9), 
;;		Light Gray (10), Light Red (11), Light Green (12), 
;;		Light Blue (13), Light Cyan (14), and Light Magenta (15)
;;******************************************************************;
setBackground PROC near
_setBackground:
	pop   edx					; Pop return address from the stack into EDX [++]
	pop   eax					; Pop color number into EAX [++]
	push  edx					; Restore return address to the stack [--]

	; Make sure color is in the correct range
	cmp   eax, 0
	jl    _invalidColor
	cmp   eax, 15
	jg    _invalidColor

	; Get Irvine''s definition for the color
	push  eax
	call  getColor
	mov   curBackColor, eax		; Save color as foreground color

	; Set color scheme
	mov   eax, curBackColor		; Move current background color to EAX
	imul  eax, 16				; Multiply background color by 16 to make room for foreground color
	add   eax, curTextColor		; Add foreground color
	mov   curColor, eax			; Save color scheme in curColor
	call  setTextColor			; Set the color of the text
	ret							; Return to caller

;; If color is not valid, warn user and keep color as it is
_invalidColor:
	; Reset coloring to white on black
	mov   eax, white+(black*16)	; Reset color to default (White on black)
	call  setTextColor
	; Warn user
	push  offset colorError		; Push error message for invalid color number
	call  writeLine				; Write error to console
	mov   eax, curColor			; Get color scheme
	call  setTextColor			; Put color scheme back to what it was
	ret							; Return without changing the color
setBackground ENDP


;;******************************************************************;
;; Call getColor(colorNum)
;; Parameters:		colorNum	--	Number for color to get
;; Returns:			color (EAX)	--	Irvine color
;; Registers Used:	EAX, EDX
;;	Utilizes Irvine
;; 
;; Gets the Irvine defined color based on the colorNum.
;; Does not follow Irvine''s defined numbers because ROYGBIV makes
;;		more sense then the order Irvine follows
;; Colors w/ numbers:
;;		Black (0), White (1), Gray (2), Brown (3), Red (4), 
;;		Yellow (5), Green (6), Blue (7), Cyan (8), Magenta (9), 
;;		Light Gray (10), Light Red (11), Light Green (12), 
;;		Light Blue (13), Light Cyan (14), and Light Magenta (15)
;;******************************************************************;
getColor PROC near
_getColor:
	pop   edx					; Pop return address from the stack into EDX [++]
	pop   eax					; Pop color number into EAX [++]
	push  edx					; Restore return address to the stack [--]

	; Find the correct color and return with the color in EAX
	cmp   eax, 0
	je    _setBlack
	cmp   eax, 1
	je    _setWhite
	cmp   eax, 2
	je    _setGray
	cmp   eax, 3
	je    _setBrown
	cmp   eax, 4
	je    _setRed
	cmp   eax, 5
	je    _setYellow
	cmp   eax, 6
	je    _setGreen
	cmp   eax, 7
	je    _setBlue
	cmp   eax, 8
	je    _setCyan
	cmp   eax, 9
	je    _setMagenta
	cmp   eax, 10
	je    _setLightGray
	cmp   eax, 11
	je    _setLightRed
	cmp   eax, 12
	je    _setLightGreen
	cmp   eax, 13
	je    _setLightBlue
	cmp   eax, 14
	je    _setLightCyan
	cmp   eax, 15
	je    _setLightMagenta
	jmp   _invalidColor			; If color is not in the range of 0-15, give a warning to the user.

;; Assign the color Black
_setBlack:
	mov   eax, black			; Return with black in EAX
	ret

;; Assign the color White
_setWhite:
	mov   eax, white			; Return with white in EAX
	ret

;; Assign the color Gray
_setGray:
	mov   eax, gray				; Return with gray in EAX
	ret

;; Assign the color Brown
_setBrown:
	mov   eax, brown			; Return with brown in EAX
	ret

;; Assign the color Red
_setRed:
	mov   eax, red				; Return with red in EAX
	ret

;; Assign the color Yellow
_setYellow:
	mov   eax, yellow			; Return with yellow in EAX
	ret

;; Assign the color Green
_setGreen:
	mov   eax, green			; Return with green in EAX
	ret

;; Assign the color Blue
_setBlue:
	mov   eax, blue				; Return with blue in EAX
	ret

;; Assign the color Cyan
_setCyan:
	mov   eax, cyan				; Return with cyan in EAX
	ret

;; Assign the color Magenta
_setMagenta:
	mov   eax, magenta			; Return with magenta in EAX
	ret

;; Assign the color Light Gray
_setLightGray:
	mov   eax, lightGray		; Return with lightGray in EAX
	ret

;; Assign the color Light Red
_setLightRed:
	mov   eax, lightRed			; Return with lightRed in EAX
	ret

;; Assign the color Light Green
_setLightGreen:
	mov   eax, lightGreen		; Return with lightGreen in EAX
	ret

;; Assign the color Light Blue
_setLightBlue:
	mov   eax, lightBlue		; Return with lightBlue in EAX
	ret

;; Assign the color Light Cyan
_setLightCyan:
	mov   eax, lightCyan		; Return with lightCyan in EAX
	ret

;; Assign the color Light Magenta
_setLightMagenta:
	mov   eax, lightMagenta		; Return with lightMagenta in EAX
	ret

;; If color is not valid, warn user and reset the color scheme to white on black.
_invalidColor:
	; Warn user
	push  offset colorError		; Push error message for invalid color number
	call  writeLine				; Write error to console
	mov   eax, white			; Return with a color of white in EAX
	ret
getColor ENDP


;;******************************************************************;
;; Call getCurColor()
;; Parameters:		None
;; Returns:			curColor --	number for current color
;; Registers Used:	EDX
;; 
;; Retrieves the current color and pushes it to the stack
;;******************************************************************;
getCurColor PROC near
_getCurColor:
	pop   edx					; Pop return address from the stack into EDX [++]
	push  curColor				; Push current color to the stack [++]
	push  edx					; Restore return address to the stack [--]
	ret
getCurColor ENDP

;; Irvine Colors
;;  0 - black			= #0C0C0C (Cod Gray)
;;  1 - white			= #F2F2F2 (Concrete)
;;  2 - brown			= #C19C00 (Buddha Gold)
;;  5 - yellow			= #F9F1A5 (Texas)
;;  7 - blue			= #0037DA (Science Blue)
;;  6 - green			= #13A10E (La Palma)
;;  8 - cyan			= #3A96DD (Curious Blue)
;;  4 - red				= #C50F1F (Shiraz)
;;  9 - magenta			= #881798 (Seance)
;;  2 - gray			= #767676 (Boulder)
;; 13 - lightBlue		= #3B77FF (Dodger Blue)
;; 12 - lightGreen		= #16C60C (Malachite)
;; 14 - lightCyan		= #61D6D6 (Viking)
;; 11 - lightRed		= #E74856 (Mandy)
;; 15 - lightMagenta	= #B4009E (Flirt)
;; 10 - lightGray		= #CCCCCC (Silver)

END