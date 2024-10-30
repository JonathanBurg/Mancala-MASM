; Main Console Program
; Jonathan Burgener
; DD Month 2024
; Description
; 
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

extern	writeline:	 near
extern	readline:	 near
extern	charCount:	 near
extern	writeNumber: near
extern	writeNum:	 near


.data

num1			DD		?		; first number for each iteration
num2			DD		?		; second number for each iteration
itr				DD		?		; iterator to make sure only 45 terms are printed
msg				byte	"Hello, World", 10, 0							; ends with line feed (10) and NULL
prompt			byte	"Fibonacci Series (First 45 terms): ", 10, 0	; ends with string terminator (NULL or 0)
endln			byte	"    ", 10, 0
termBuffer		byte	", ",0
results			byte	?		; buffer to print vars
numCharsToRead	dword	1024
bufferAddr		dword	?


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
	 ; Do Something

exit:
	ret							; Return to the main program.
start ENDP

END