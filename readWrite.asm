; Main Console program
; Wayne Cook
; 20 September 2024
; Show how to do input and output
; Revised: WWC 14 March 2024 Added new module
; Revised: WWC 15 March 2024 Added this comment to force a new commit.
; Revised: WWC 13 September 2024 Minor updates for Fall 2024 semester.
; Revised: JB   7 October, 2024 - Added module for a new line
; Revised: JB  17 October, 2024 - Updated headers and added getInt and intStr
; Revised: JB  20 October, 2024 - Added a version of writeNumber that ends with no space
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
;		EBP - Callee Saved register - base pointer.386P

.model flat

;; Library calls used for input from and output to the console
extern  _GetStdHandle@4:near
extern  _WriteConsoleA@20:near
extern  _ReadConsoleA@20:near
extern  _ExitProcess@4: near


.data

msg				byte	"Hello, World", 10, 0			; ends with line feed (10) and NULL
prompt			byte	"Please type your name: ", 0	; ends with string terminator (NULL or 0)
results			byte	10,"You typed: ", 0
newLine			byte	10,0	; Starts a new line
space			byte	" ",0	; Creates a space
inputPrompt		dword	?		; Prompt for user input
outputHandle	dword	?		; Output handle writing to consol. uninitslized
inputHandle		dword	?		; Input handle reading from consolee. uninitslized
written			dword	?
retTemp			DD		?		; Temporarily store return address
INPUT_FLAG		equ		-10
OUTPUT_FLAG		equ		-11

;; Reading and writing requires buffers. I fill them with 00h.
readBuffer		byte	1024  DUP(00h)
writeBuffer		byte	1024  DUP(00h)
numberBuffer	byte	1024  DUP(00h)
numCharsToRead	dword	1024
numCharsRead	dword	?		; Unset or uninitialized


.code


;;******************************************************************;
;; Call initialize_console()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	EAX
;; 
;; Initialize Input and Output handles so you only have to do that once.
;; This is your first assembly routine
;;******************************************************************;
initialize_console PROC near
_initialize_console:

	 ; handle = GetStdHandle(-11)
	push  OUTPUT_FLAG
	call  _GetStdHandle@4
	mov   outputHandle, eax
	 ; handle = GetStdHandle(-10)
	push  INPUT_FLAG
	call  _GetStdHandle@4
	mov   inputHandle, eax
	ret
initialize_console ENDP


;;******************************************************************;
;; Call readline()
;; Parameters:		None
;; Returns:			EAX		--	console input
;; Registers Used:	EAX
;; 
;; Now the read/write handles are set, read a line
;;******************************************************************;
readline PROC near
_readline: 
	 ; ReadConsole(handle, &buffer, numCharToRead, numCharsRead, null)
	push  0
	push  offset numCharsRead
	push  numCharsToRead
	push  offset readBuffer
	push  inputHandle
	call  _ReadConsoleA@20
	mov   eax, offset readBuffer
	ret							; Returns with console input in EAX
readline ENDP


;;******************************************************************;
;; Call charCount(string)
;; Parameters:		string	--	String to check length of
;; Returns:			EAX		--	Character Count
;; Registers Used:	EAX, EBX (s), ECX (s), EDX (s)
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
	mov   eax,0					; load counter to 0
	mov   ecx,0					; Clear ECX register
_countLoop:
	mov   cl,[ebx]				; Look at the character in the string
	cmp   ecx,0					; check for end of string.
	je    _endCount
	inc   eax					; Up the count by one
	inc   ebx					; go to next letter
	jmp   _countLoop
_endCount:
	pop   edx
	pop   ecx					; Restore EBX and ECX
	pop   ebx
	ret							;Return with EAX containing character count
charCount ENDP


;;******************************************************************;
;; Call writeline(location)
;; Parameters:		location --	buffer location of the string to be
;;								printed
;; Returns:			Nothing
;; Registers Used:	EAX, EBX, EDX
;; 
;; For all routines, the last item to be pushed on the stack is the
;; return address, save it to a register then save any other 
;; expected parameters in registers, then restore the return address
;; to the stack.
;;******************************************************************;
writeline PROC near
_writeline:
	pop   edx					; pop return address from the stack into EDX
	pop   ebx					; Pop the buffer location of string to be printed into EBX
	;pop   eax					; Pop the buffer size string to be printed into EAX.
	push  edx					; Restore return address to the stack

	push  ebx
	push  ebx
	call  charCount
	pop   ebx

	 ; WriteConsole(handle, &msg[0], numCharsToWrite, &written, 0)
	push  0
	push  offset written
	push  eax					; return size to the stack for the call to _WriteConsoleA@20 (20 is how many bits are in the call stack)
	push  ebx					; return the offset of the line to be written
	push  outputHandle
	call  _WriteConsoleA@20
	ret
writeline ENDP



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
	call  writeline
	pop   eax					; Restore EAX
	ret
writeln ENDP


;;******************************************************************;
;; Call writeSp()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	None
;; 
;; Writes a space to the console
;;******************************************************************;
writeSp PROC near
_writeSp:
	push  offset space
	call  writeline
	ret
writeSp ENDP


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
	add   dx,'0'				; Turn the remainer into an ASCII number
	push  dx					; Now push the remainder onto the stack
	inc   esi					; increment number count
	jmp   genNumLoop			; One more time.
endNumLoop:
	cmp   esi,0
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
	;push  offset numberBuffer
	;call  charCount
	;push  eax
	push  offset numberBuffer
	call  writeline
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
;; Call genNumber()
;; Parameters:		None
;; Returns:			Nothing
;; Registers Used:	None
;; 
;; writeNumber - print the ASCII value of a number.
;; To help callers, I will save all registers, except eax, which will be location
;;  in number ASCII string to be written. This routine will show the official
;;  way to handle the stack and base pointers. It is less effecient, but it
;;  preserves all registers.
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
	add   dx,'0'				; Turn the remainer into an ASCII number
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
	mov   dx, 0					; cannot load a literal into an addressed location
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
	call  writeline

	call  readline
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
	mul   edx
	add   eax, ebx
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

END