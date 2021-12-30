.486
.model flat, stdcall

option casemap : none

include windows.inc
include kernel32.inc
include masm32.inc
include user32.inc

includelib kernel32.lib
includelib masm32.lib
includelib user32.lib

.data                   
	enterA			db "Enter a: ", 0
	enterB			db "Enter b: ", 0 
	res				db "(%s + %s) / %s - 4 * %s = %s", 0
	four			dq 4.0

.data?  
	inputHandle		dd ?
	outputHandle 	dd ?
	numberOfChars	dd ?
	buffer			db 100 dup (?)
    strA			db 100 dup (?)
    strB			db 100 dup (?)
    answer			db 100 dup (?)
    a				dq ?
	b				dq ?
	result			dq ?  
	
.code

main:
;---------------------------------------------------------------------------------------------------

	push 	STD_INPUT_HANDLE
	call 	GetStdHandle
	mov  	inputHandle, EAX
	
	push 	STD_OUTPUT_HANDLE
	call 	GetStdHandle
	mov  	outputHandle, EAX
	
;---------------------------------------------------------------------------------------------------
	                                                ; read a
	push 	NULL
	push 	offset numberOfChars
	push 	9
	push 	offset enterA
	push 	outputHandle
	call 	WriteConsole
	
	push 	NULL
	push 	offset numberOfChars
	push 	15
	push 	offset strA
	push 	inputHandle
	call 	ReadConsole

	mov  	EDX, offset strA
	mov  	EAX, numberOfChars
	mov 	byte ptr [ EDX + EAX - 2], 0
	
	push 	offset a
	push 	offset strA
	call 	StrToFloat    
	
;---------------------------------------------------------------------------------------------------
	                                                ; read b
	push 	NULL
	push 	offset numberOfChars
	push 	9
	push 	offset enterB
	push 	outputHandle
	call 	WriteConsole
	
	push 	NULL
	push 	offset numberOfChars
	push 	15
	push 	offset strB
	push 	inputHandle
	call 	ReadConsole

	mov  	EDX, offset strB
	mov  	EAX, numberOfChars
	mov 	byte ptr [ EDX + EAX - 2], 0
	
	push 	offset b
	push 	offset strB
	call 	StrToFloat  
	
;--------------------------------------------------------------------------------------------------- 
	         
   	finit											; clear ST
 	fld   	a             							; ST(0) = a
 	fadd  	b             							; ST(0) = a + b
 	fdiv  	a             							; ST(0) = (a + b) / a
 	fld   	a             							; ST(0) -> ST(1), ST(0) = a
 	fmul  	four          							; ST(0) = 4 * a
 	fsubr 	ST(0), ST(1)   							; ST(0) = ST(1) - ST(0)
  	fstp  	result        							; result = ST(0)
  	
;---------------------------------------------------------------------------------------------------
	                                     			; output of result
	push 	offset buffer
	push 	dword ptr result + 4
	push 	dword ptr result
	call 	FloatToStr
	        
	push 	offset buffer
	push 	offset strA
	push 	offset strA
	push 	offset strB
	push 	offset strA
	push 	offset res
	push 	offset answer
	call 	wsprintf
	
	push 	offset answer
	call 	lstrlen
	
	push 	NULL
	push 	offset numberOfChars
	push 	EAX
	push 	offset answer
	push 	outputHandle
	call 	WriteConsole
	
;---------------------------------------------------------------------------------------------------
	
	push 	NULL
	push 	offset numberOfChars
	push 	1
	push 	offset buffer
	push 	inputHandle
	call 	ReadConsole
	
	push 	0
	call 	ExitProcess
;---------------------------------------------------------------------------------------------------
end main