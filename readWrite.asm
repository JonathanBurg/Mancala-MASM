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
;; Revised: JB  22 November, 2024 - Annoyed of linker not linking properly with Irvine. 
;;						abandoning Irvine. Reverting to previous version of readWrite.asm,
;;						and re-adding procedure to clear the console. Adding Documentation.
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
;;		initializeConsole()
;;		readLine()
;;		charCount(string)
;;		writeLine(location)
;;		writeln()
;;		writeSp()
;;		writeNum(number)
;;		writeNumber(number)
;;		genNumber()
;;		readInt(prompt)

.model flat

;; Library calls used for input from and output to the console
extern	_GetStdHandle@4:			 near
extern	_WriteConsoleA@20:			 near
extern	_ReadConsoleA@20:			 near
extern	_ExitProcess@4:				 near
extern	_GetConsoleMode@8:			 near
extern	_SetConsoleMode@8:			 near
extern	_SetConsoleCursorPosition@8: near


.data

msg				byte	"Hello, World", 10, 0			; ends with line feed (10) and NULL
prompt			byte	"Please type your name: ", 0	; ends with string terminator (NULL or 0)
results			byte	10,"You typed: ", 0
newLine			byte	10,0	; Starts a new line
space			byte	" ",0	; Creates a space
continueMsg		byte	10, "Press enter to continue: ", 0
inputPrompt		dword	?		; Prompt for user input
outputHandle	dword	?		; Output handle writing to consol. uninitslized
inputHandle		dword	?		; Input handle reading from consolee. uninitslized
written			dword	?
retTemp			DD		?		; Temporarily store return address
INPUT_FLAG		equ		-10
OUTPUT_FLAG		equ		-11

;; Reading and writing requires buffers. I fill them with 00h.
readBuffer		byte	1024  DUP(00h)	; Buffer to input strings from console
writeBuffer		byte	1024  DUP(00h)	; Buffer to hold string to write to console
numberBuffer	byte	1024  DUP(00h)	; Buffer to hold the string resulting from converting an integer to a string
numCharsToRead	dword	1024			; Number of characters to read from the console
numCharsRead	dword	?				; Unset or uninitialized. Number of chars read
NULL			equ		0				; Null value for invokation of MASM processes

; Needed for clearing the console.
clear_console byte 1bh, '[', '2', 'J'
clear_scroll_back byte 1bh, '[', '3', 'J'

.code


;;******************************************************************;
;; Call initialize_console()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	EAX (s)
;; 
;; Initialize Input and Output handles so you only have to do that 
;;		once.
;; This is your first assembly routine
;; 
;; 
;; This process sets up the console by storing the handles to the 
;;		Input and the Output in inputHandle and outputHandle 
;;		respectively. The process gets the output handle from pushing 
;;		the OUTPUT_FLAG (-11) to _GetStdHandle@4 which returns the 
;;		output handle in EAX. Likewize, the input handle is retrieved 
;;		by pushing the INPUT_FLAG (-10) to _GetStdHandle@4 which 
;;		returns the input handle in EAX. Since inputHandle and 
;;		outputHandle are stored in the memory, they can be retrieved 
;;		by other processes to get input from inputHandle or write 
;;		strings to outputHandle. This process had no parameters to 
;;		remove from the stack. This process only needs to be called 
;;		once (preferably when the program starts) to set up the 
;;		handles.
;; 
;; 
;; call initialize_console
;; 
;; Procedure removes all parameters from the stack.
;;******************************************************************;
initialize_console PROC near
_initialize_console:
	push  eax					; Save EAX [--]
	; handle = GetStdHandle(-11)
	push  OUTPUT_FLAG			; [--]
	call  _GetStdHandle@4		; [--] [+*2]
	mov   outputHandle, eax
	; handle = GetStdHandle(-10)
	push  INPUT_FLAG			; [--]
	call  _GetStdHandle@4		; [--] [+*2]
	mov   inputHandle, eax
	pop   eax					; Restore EAX [++]
	ret							; [++]
initialize_console ENDP			; [ESP+=4], Parameters removed from stack [++]


;;******************************************************************;
;; Call readLine()
;; Parameters:		None
;; Returns:			EAX - ptr to buffer
;; Registers Used:	EAX
;; 
;; Now the read/write handles are set, read a line
;; 
;; 
;; This process has no parameters. Instead it uses the
;;		_ReadConsoleA@20 library to get text input from the user via 
;;		the console referenced in the inputHandle. The library has 5 
;;		parameters. The first parameter pushed is the null character, 
;;		or the string terminator. The second parameter is the address 
;;		of a buffer to hold the number of chars read. The third 
;;		parameter is the max amount of chars to read from the handle. 
;;		The fourth parameter is the address of the buffer to store 
;;		the read input in. The fifth parameter holds the handle the 
;;		input is being read from. ReadConsoleA@20 stores the inputted 
;;		string in readBuffer. The address to the string is stored in 
;;		EAX which can then be used by the caller.
;; 
;; 
;; call  readLine()
;; 
;; Procedure removes all parameters from the stack.
;;******************************************************************;
readLine PROC near
_readLine:
	  ; ReadConsole(handle, &buffer, numCharToRead, numCharsRead, null)
	push  NULL					; Null [--]
	push  offset numCharsRead	; Number of characters read (1024) [--]
	push  numCharsToRead		; Number of characters to read (1024) [--]
	push  offset readBuffer		; Buffer to hold input in [--]
	push  inputHandle			; Handle for input [--]
	call  _ReadConsoleA@20		; Get input [--] [+*6]
	mov   eax, offset readBuffer	; Move address of readBuffer to EAX
	ret							; Return input in EAX [++]
readLine ENDP					; [ESP+=4], Parameters removed from stack [++]


;;******************************************************************;
;; Call charCount(addr)
;; Parameters:		addr - address of buffer = &addr[0]
;; Returns:			EAX - character count
;; Registers Used:	EAX, EBX (s), ECX (s), EDX (s)
;; 
;; All strings need to end with a NULL (0). So I do not have to 
;;		manually count the number of characters in the line, I wrote 
;;		this routine.
;; 
;; 
;; This process counts the number of character in a string. It pops 
;;		the address of buffer containing the string to be counted 
;;		into EBX. EAX is used as the counter, and ECX is used to pull 
;;		individual characters from the buffer to count them and check 
;;		for the string terminator. The process goes through a loop to 
;;		pull each character from EBX into the last 8 bits of ECX, 
;;		checks if the character is the string terminator (0), 
;;		increments EAX and increments EBX to the next character. If 
;;		the pulled character is the string terminator, the loop is 
;;		terminated and the process returns to the caller with the 
;;		character count in EAX. All parameters are removed from the 
;;		stack, so no adjustments to ESP are needed.
;; 
;; 
;; push  addr
;; call  charCount
;; 
;; Procedure removes all parameters from the stack.
;;******************************************************************;
charCount PROC near
_charCount:
	pop   [retTemp]				; Save return address [++]
	pop   eax					; Save offset/address of string [++]
	push  [retTemp]				; Put return address back on the stack [--]
	push  ebx					; Save EBX [--]
	push  ecx					; Save ECX [--]
	push  edx					; Save EDX [--]
	mov   ebx, eax				; Move offset/address of string to ebx
	mov   eax, 0				; load counter to 0
	mov   ecx, 0				; Clear ECX register
_countLoop:
	mov   cl, [ebx]				; Look at the character in the string
	cmp   ecx, NULL				; check for end of string.
	je    _endCount
	inc   eax					; Up the count by one
	inc   ebx					; go to next letter
	jmp   _countLoop
_endCount:
	pop   edx					; [++]
	pop   ecx					; Restore EBX and ECX [++]
	pop   ebx					; [++]
	ret							; Return with EAX containing character count [++]
charCount ENDP					; [ESP+=8], Parameter removed from stack [+*2]


;;******************************************************************;
;; Call writeLine(location)
;; Parameters:		location --	buffer location of the string to be
;;								printed
;; Returns:			Nothing
;; Registers Used:	EAX, EBX, EDX
;; 
;; For all routines, the last item to be pushed on the stack is the 
;;		return address, save it to a register then save any other 
;;		expected parameters in registers, then restore the return
;;		address to the stack.
;; 
;; 
;; This routine has one parameters. The first parameter, addr, is 
;;		stored in EBX. The second parameter, chars, is stored in EAX. 
;;		addr is the address of the string to write to the console, 
;;		chars is the number of characters in the string. 
;;		_WriteConsoleA@20 is used to write to the console and it 
;;		takes 5 parameters. The first parameter pushed is the 
;;		character being used as null, or the string terminator. The 
;;		second parameter is a buffer to hold the characters written. 
;;		The third parameter is the number of chars to write, or chars. 
;;		The fourth parameter is the address of the buffer holding the 
;;		string to be written. The fifth parameter is the handle to 
;;		write to. All parameters are removed from the stack so no 
;;		adjustments to ESP are needed.
;; 
;; 
;; push  chars
;; push  addr
;; call  writeLine
;; 
;; Procedure removes all parameters from the stack.
;;******************************************************************;
writeLine PROC near
_writeLine:
	pop   edx					; pop return address from the stack into EDX
	pop   ebx					; Pop the buffer location of string to be printed into EBX
	push  edx					; Restore return address to the stack

	push  ebx
	push  ebx
	call  charCount
	pop   ebx

	 ; WriteConsole(handle, &msg[0], numCharsToWrite, &written, 0)
	push  NULL
	push  offset written
	push  eax					; return size to the stack for the call to _WriteConsoleA@20 (20 is how many bits are in the call stack)
	push  ebx					; return the offset of the line to be written
	push  outputHandle
	call  _WriteConsoleA@20
	ret
writeLine ENDP


;;******************************************************************;
;; Call writeln()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	EAX (s)
;; 
;; Writes a line break to the console
;;******************************************************************;
writeln PROC near
_writeln:
	push  eax					; Save EAX
	 ; Create new line
	;push  offset newLine		; Push string with line feed (10) and NULL
	;call  charCount
	;push  eax
	push  offset newLine
	call  writeLine
	pop   eax					; Restore EAX
	ret
writeln ENDP


;;******************************************************************;
;; Call writesp()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	None
;; 
;; Writes a space to the console
;;******************************************************************;
writesp PROC near
_writesp:
	push  offset space
	call  writeLine
	ret
writesp ENDP


;;******************************************************************;
;; Call writeNum(number)
;; Parameters:		number	--	Value to write to console
;; Returns:			Nothing
;; Registers Used:	EAX, EBX (s), ECX (s), EDX, ESI (s)
;; 
;; For all routines, the last item to be pushed on the stack is the
;; return address, save it to a register then save any other
;; expected parameters in registers, then restore the return address
;; to the stack.
;;******************************************************************;
writeNum PROC near
_writeNum:
	pop   edx					; pop return address from the stack into EDX
	pop   eax					; Pop the number to be written.
	push  edx					; Restore return address to the stack

	 ; Save working registers
	push  ebx
	push  ecx
	push  esi

	mov   ecx, 10				; Set the divisor to ten
	mov   esi, 0				; Count number of numbers written
	mov   ebx, offset numberBuffer	; Save the start of the write buffer
 ; The dividend is place in eax, then divide by ecx, the result goes into eax, with the remiander in edx
genNumLoop:
	cmp   eax, 0				; Stop when the number is 0
	jle   endNumLoop
	mov   edx, 0				; Clear the register for the remainder
	div   ecx					; Do the divide
	add   dx, '0'				; Turn the remainer into an ASCII number
	push  dx					; Now push the remainder onto the stack
	inc   esi					; increment number count
	jmp   genNumLoop			; One more time.
endNumLoop:
	cmp   esi, 0
	jle   numExit
	pop   dx
	mov   [ebx], dx				; Add the number to the output sring
	dec   esi					; Get ready for the next number
	inc   ebx					; Go to the next character
	jmp   endNumLoop			; Do it one more time
	
numExit:
	mov   dx, 0					; cannot load a literal into an addressed location
	mov   [ebx], dx				; Add a space to the end of the number
	mov   [ebx+1], esi			; Add the number to the output sring
	push  offset numberBuffer
	call  writeLine
	 ; Restore working registers
	pop   esi
	pop   ecx
	pop   ebx
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
	pop   edx
	pop   eax
	push  edx

	push  eax
	call  writeNum
	call  writeSp
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
genNumber PROC near
_genNumber:
	; Subroutine Prologue
	push  ebp					; Save the old base pointer value.
	mov   ebp, esp				; Set the new base pointer value to access parameters
	sub   esp, 4				; Make room for one 4-byte local variable, if needed
	push  edi					; Save the values of registers that the function
	push  esi					; will modify. This function uses EDI and ESI.
	; The eax, ebx, ecx, edx registers do not need to be saved,
	;	  but they are for the sake of the calling routine.
	push  eax					; EAX needed as a dividend
	;push ebx					; Only save if not used as a return value
	push  ecx					; Ditto
	push  edx					; Ditto
	; Subroutine Body
	mov   eax, [ebp+8]			; Move value of parameter 1 into EAX
	mov   ebx, [ebp+12]			; Save the start of the write buffer
	mov   ecx, 10				; Set the divisor to ten
	;mov   esi, 0				; Count number of numbers written
;; The dividend is place in eax, then divide by ecx, the result goes into eax, with the remiander in edx
	cmp   eax, 0				; Stop when the nubmer is 0
	jle   numExit
	mov   edx, 0				; Clear the register for the remainder
	div   ecx					; Do the divide
	add   dx, '0'				; Turn the remainer into an ASCII number
	;push  dx					; Now push the remainder onto the stack
	;inc   esi					; increment number count
;; Do another recursive call;
	push  ebx					; Pass on the start of the number buffer.
	push  eax					; And the number
	call  genNumber				; Do the recursion
	pop   eax					; Remove the two parameters
	pop   eax					; Leave ebx alone
;; Load the number, one digit at a time.
	mov   bx, dx				; Add the number to the output sring
	inc   ebx					; go to the next ASCII location
	mov   dx, NULL				; cannot load a literal into an addressed location
	mov   bx, dx				; Add a space to the end of the number
	
numExit:
	; If eax is used as a return value, make sure it is loaded by now.
	; And restore all saved registers
	; Subroutine Epilogue
	pop   edx
	pop   ecx
	;pop   ebx
	pop   eax
	pop   esi					; Recover register values
	pop   edi
	mov   esp, ebp				; Deallocate local variables
	pop   ebp					; Restore the caller''s base pointer value
	ret
genNumber ENDP


;;******************************************************************;
;; Call readInt(prompt)
;; Parameters:		prompt	--	Prompt for the desired input
;; Returns:			input 	--	User inputted value
;; Registers Used:	EAX, EBX (s), ECX (s), EDX
;; 
;; Routine to get user input and convert it to an integer
;; Algorithm written by Wayne Cook
;; Adapted by Jonathan Burgener to fit program
;;******************************************************************;
readInt PROC near
_readInt:
	pop   edx					; Pop return address from the stack into EDX
	pop   inputPrompt			; Pop the number to be written.
	push  edx					; Restore return address to the stack
	 ; Store working registers
	push  ebx
	push  ecx
	xor   eax, eax
	xor   ebx, ebx
	xor   ecx, ecx
	xor   edx, edx

	 ; Type a prompt for the user
	push  inputPrompt
	call  writeLine

	call  readLine
	mov   ecx, eax

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
	 ; Restore working registers
	pop   ecx
	pop   ebx

	pop   edx					; Pop return address from the stack into EDX
	push  eax					; Push input value to stack
	push  edx					; Restore return address to the stack
	 ; Returns with the input value in the stack
	ret
readInt ENDP


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

	call  readLine				; Wait for input to continue
	;sub   esp, 4
	ret							; Return to caller
pauseProgram ENDP


;;******************************************************************;
;; Call clearConsole@0()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	EAX, EBP (s), ESP
;; 
;; clears console and scroll back too
;; returns console mode back to normal
;; https://learn.microsoft.com/en-us/windows/console/clearing-the-screen
;; can get much more advanced here: 
;;					https://en.wikipedia.org/wiki/ANSI_escape_code
;;******************************************************************;
clearConsole@0 proc near
    push ebp ; save base
    mov ebp, esp ; get stack pointer

    sub esp, 4
    push esp
    push outputHandle
    ; https://learn.microsoft.com/en-us/windows/console/getconsolemode
    ; BOOL WINAPI GetConsoleMode(
    ; _In_  HANDLE  hConsoleHandle,
    ; _Out_ LPDWORD lpMode
    ; );
    call _GetConsoleMode@8

    cmp eax, 0
    je  _error

    mov eax, [ebp - 4] ; get current console mode
    or eax, 04h ; ENABLE_VIRTUAL_TERMINAL_PROCESSING ; https://learn.microsoft.com/en-us/windows/console/setconsolemode

    ; https://learn.microsoft.com/en-us/windows/console/setconsolemode
    ; BOOL WINAPI SetConsoleMode(
    ; _In_ HANDLE hConsoleHandle,
    ; _In_ DWORD  dwMode
    ; );
    push eax
    push outputHandle
    call _SetConsoleMode@8

    cmp eax, 0
    je _error
   
    ; print "\x1b[2J", clear viewable screen
    ; print "\x1b[3J", clear scroll back
    ; "\x1b" is an escape char = 1bh
    ;push 4
    push offset clear_console
    call writeLine

    ;push 4
    push offset clear_scroll_back
    call writeLine

	push 0						; Coordinates 0,0 to upper left corner.
	push  outputHandle			; [--]
	call _SetConsoleCursorPosition@8


    ; restore the mode on the way out to be nice to other command-Line applications
    ; pop eax   ; no need to pop and push
    ; push eax
    push outputHandle
    call _SetConsoleMode@8

    jmp _exit

_error:

_exit:
    mov esp, ebp ; because of the error handling, make sure no vars are forgotten
    pop ebp
    ret ;4
clearConsole@0 endp

END