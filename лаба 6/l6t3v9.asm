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
	maskAnd         dw 1111001111111111b
	maskOr			dw 0000110000000000b
	template 	   	db "| %10.10s | %10.10s |", 0ah, 0
	enterX1			db "Enter x1: ", 0
	enterX2			db "Enter x2: ", 0
	enterDX			db "Enter dx:  ", 0
	enterA			db "Enter a:  ", 0
	enterB			db "Enter b:  ", 0
	arguments		dq 100 dup (0)
	values			dq 100 dup (0)

.data?
	inputHandle	    dd ?
	outputHandle	dd ?
	numberOfChars	dd ?
	buffer			db 1000 dup (?)
	result			db 1000 dup (?)
	argument		db 1000 dup (?)
	value			db 1000 dup (?)
	flags			dw ?
	x1				dq ?
	x2 				dq ?
	x				dq ?
	a				dq ?
	b				dq ?
	sizeArr			dd ?


.code

;---------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------

; void initArguments(float* arguments, int size, float x1, float x2, float dx)
initArguments:
	push	EBP
	mov		EBP, ESP
	
	sub		ESP, 4									; reserve memory in stack for local variable

	mov  	EBX, dword ptr [ EBP + 8 ]				; EBX = offset arguments
	
	finit                                       	; clear ST
	mov		EAX, dword ptr [ EBP + 16 ]				; EAX = offset x1
	fld  	qword ptr [ EAX ]                       ; ST(0) = x1
	fstp 	qword ptr [ EBX ]                   	; arguments[0] = x1
 
	cmp		dword ptr [ EBP + 12 ], 1				; compare size and 1
	je		endLoopInitArg
													; if ( size != 1 )
	mov		EAX, dword ptr [ EBP + 20 ]				; EAX = offset x2
   	fld  	qword ptr [ EAX ]   					; ST(0) = x2
   	mov		EAX, dword ptr [ EBP + 12 ]             ; EAX = size                    
	fstp 	qword ptr [ EBX + EAX * 8 - 8 ]     	; arguments[size - 1 ] = x2
	
	dec		dword ptr [ EBP + 12 ]
	mov		ECX, 0
	
	startLoopInitArg:
	   	cmp   	ECX, dword ptr [ EBP + 12 ]
		je    	endLoopInitArg
		 
		mov		dword ptr [ EBP - 4 ], ECX			; save ECX value for using in FPU 
		                    
		finit                                   	; clear ST                                                   
		mov		EAX, dword ptr [ EBP + 24 ]         ; EAX = offset dx
		fld   	qword ptr [ EAX ]                   ; ST(0) = dx
		fimul 	dword ptr [ EBP - 4 ]               ; ST(0) = ST(0) * ECX
		mov		EAX, dword ptr [ EBP + 16 ]         ; EAX = offset x1
		fadd  	qword ptr [ EAX ]                   ; ST(0) = ST(0) + x1
		fstp  	qword ptr [ EBX ]     				; arguments[i] = ST(0)
		
		add		EBX, 8								; to next element
		inc		ECX
	
		jmp   	startLoopInitArg
	endLoopInitArg:
	
	add		ESP, 4									; clear memory
	
	pop 	EBP                               
ret 20

;---------------------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------------------- 

; void initValues(float* arguments, float* values, int size, float a, float b)
initValues:
	push	EBP
	mov		EBP, ESP								
	
	startLoopInitVal:
		cmp		dword ptr [ EBP + 16 ], 0                     
		je   	endLoopInitVal
		
		mov		EBX, dword ptr [ EBP + 8 ]			; EBX = offset arguments[i]
		mov		EDX, dword ptr [ EBP + 12 ]         ; EDX = offset values[i]
	                         
	 	finit                                   	; clear ST
	 	fldz                                        ; ST(0) = 0
	 	fld  	qword ptr [ EBX ]     		   		; ST(0) -> ST(1), ST(0) = arguments[i]
	 	fcom	ST(1)                       		; compare ST(0) and ST(1)
	 	fstsw	AX                              	; save FPU flags in AX
	 	sahf                                    	; set CPU flags from AX
	 	ja		lbl                             
	 	                                        	; if ( argumets[i] <= 0 )
		fmul 	ST(0), ST(0)                    	; ST(0) = ST(0) * ST(0)
		mov		EAX, dword ptr [ EBP + 20 ]         ; EAX = offset a
		fadd	qword ptr [ EAX ]                  	; ST(0) = ST(0) + a
		fldln2                                  	; ST(0) -> ST(1), ST(0) = ln(2)
		fxch	ST(1)                           	; ST(0) <-> ST(1)
		fyl2x                                   	; ST(0) = ST(1) * log2( ST(0) )
	 	jmp		continue                       	
	 	
	 	lbl:                                    	; if ( argumets[i] > 0 )
        fmul	ST(0), ST(0)                    	; ST(0) = ST(0) * ST(0)
        fld		qword ptr [ EBX ]     				; ST(0) -> ST(1), ST(0) = arguments[i]
        mov		EAX, dword ptr [ EBP + 24 ]        	; EAX = offset b
        fmul	qword ptr [ EAX ]                   ; ST(0) = ST(0) * b
        fsubr	ST(0), ST(1)                    	; ST(0) = ST(1) - ST(0)
        mov		EAX, dword ptr [ EBP + 20 ]         ; EAX = offset a
        fld		qword ptr [ EAX ]                   ; ST(0) -> ST(1), ST(0) = a
        fldln2                                  	; ST(1) -> ST(2), ST(0) -> ST(1), ST(0) = ln(2)
        fxch	ST(1)                           	; ST(0) <-> ST(1)
        fyl2x                                   	; ST(0) = ST(1) * log2( ST(0) )
	    fmul	ST(0), ST(0)                    	; ST(0) = ST(0) * ST(0)
	    faddp	ST(1), ST(0)	                	; ST(1) = ST(0) + ST(1), ST(1) -> ST(0)	                         
	    
	    continue:
	 	fstp  	qword ptr [ EDX ]	    			; values[i] = ST(0)
	                                  
	                 
	    add		dword ptr [ EBP + 8 ], 8			; to next element
	    add		dword ptr [ EBP + 12 ], 8           ; to next element  
	 	dec 	dword ptr [ EBP + 16 ]
	
		jmp  	startLoopInitVal
	endLoopInitVal:        
	
	pop		EBP								   	
ret 20

;---------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------

; void arraysToStr(char* buffer, float* arguments, float* values, int size)
arraysToStr:
	push  	EBP
	mov		EBP, ESP                          	

	mov  	EBX, dword ptr [ EBP + 8 ]				; EBX = offset buffer	
	
	startLoopPrint:
		cmp  	dword ptr [ EBP + 20 ], 0
		je   	endLoopPrint
		                
		mov  	EDX, dword ptr [ EBP + 12 ]			; EDX = offset arguments[i]
		                                    	
	 	push 	offset argument
	 	push 	dword ptr [ EDX + 4 ]	
	 	push 	dword ptr [ EDX ]
	 	call 	FloatToStr
	 	
	 	mov  	EDX, dword ptr [ EBP + 16 ]			; EDX = ofsfet values[i]
	 	                        			   		
	   	push 	offset value
	 	push 	dword ptr [ EDX + 4 ]
	  	push 	dword ptr [ EDX ]
	  	call 	FloatToStr
	 											
	   	push 	offset value
	 	push 	offset argument
	 	push 	offset template
	 	push 	EBX
		call 	wsprintf							; form string
		
		add		ESP, 16 
	 	
	 	add  	EBX, EAX   
	 	add		dword ptr [ EBP + 12 ], 8			; to next element
	 	add		dword ptr [ EBP + 16 ], 8           ; to next element
	 	dec  	dword ptr [ EBP + 20 ]
		
		jmp  	startLoopPrint
	endLoopPrint:
	
	pop		EBP	
ret 16

;---------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------

main:
;---------------------------------------------------------------------------------------------------

	push 	STD_INPUT_HANDLE
    call 	GetStdHandle
    mov  	inputHandle, EAX
    
    push 	STD_OUTPUT_HANDLE
    call 	GetStdHandle
    mov  	outputHandle, EAX
    
;---------------------------------------------------------------------------------------------------
    							                	; read x1
    push 	NULL
    push 	offset numberOfChars
    push 	10
    push 	offset enterX1
    push 	outputHandle
    call 	WriteConsole
    
    push 	NULL
    push 	offset numberOfChars
    push 	15
    push 	offset buffer
    push 	inputHandle
    call 	ReadConsole
    
    mov  	EDX, offset buffer
    mov  	EAX, numberOfChars
    mov  	byte ptr [ EDX + EAX - 2 ], 0
                      
    push 	offset x1
    push 	offset buffer
    call 	StrToFloat
    
;---------------------------------------------------------------------------------------------------
													; read x2
    push 	NULL
    push 	offset numberOfChars
    push 	10
    push 	offset enterX2
    push 	outputHandle
    call 	WriteConsole
    
    push 	NULL
    push 	offset numberOfChars
    push 	15
    push 	offset buffer
    push 	inputHandle
    call 	ReadConsole
    
    mov  	EDX, offset buffer
    mov  	EAX, numberOfChars
    mov  	byte ptr [ EDX + EAX - 2 ], 0
                      
    push 	offset x2
    push 	offset buffer
    call 	StrToFloat
    
;---------------------------------------------------------------------------------------------------
                                                	; read dx
    push 	NULL
    push 	offset numberOfChars
    push 	10
    push 	offset enterDX
    push 	outputHandle
    call 	WriteConsole
    
    push 	NULL
    push 	offset numberOfChars
    push 	15
    push 	offset buffer
    push 	inputHandle
    call 	ReadConsole
    
    mov  	EDX, offset buffer
    mov  	EAX, numberOfChars
    mov  	byte ptr [ EDX + EAX - 2 ], 0
                      
    push 	offset x
    push 	offset buffer
    call 	StrToFloat
    
;---------------------------------------------------------------------------------------------------
                                                	; read a
    push 	NULL
    push 	offset numberOfChars
    push 	10
    push 	offset enterA
    push 	outputHandle
    call 	WriteConsole
    
    push 	NULL
    push 	offset numberOfChars
    push 	15
    push 	offset buffer
    push 	inputHandle
    call 	ReadConsole
    
    mov  	EDX, offset buffer
    mov  	EAX, numberOfChars
    mov  	byte ptr [ EDX + EAX - 2 ], 0
                      
    push 	offset a
    push 	offset buffer
    call 	StrToFloat
    
;---------------------------------------------------------------------------------------------------
                                                	; read b
    push 	NULL
    push 	offset numberOfChars
    push 	10
    push 	offset enterB
    push 	outputHandle
    call 	WriteConsole
    
    push 	NULL
    push 	offset numberOfChars
    push 	15
    push 	offset buffer
    push 	inputHandle
    call 	ReadConsole
    
    mov  	EDX, offset buffer
    mov  	EAX, numberOfChars
    mov  	byte ptr [ EDX + EAX - 2 ], 0
                      
    push 	offset b
    push 	offset buffer
    call 	StrToFloat
    
;---------------------------------------------------------------------------------------------------
 	finit                                       	; clear ST
 	fld		x1                                  	; ST(0) = x1
 	fcomp	x2                                  	; compare x1 and x2
 	fstsw	AX                                  	; save FPU flags in AX
  	sahf                                        	; set CPU flags from AX
 	je		ex1x2                               	; jump if x1 == x2

	finit                                       	; clear ST
	fld   	x2								   		; ST(0) = x2
	fsub  	x1										; ST(0) = x2 - x1
	fabs									   		; ST(0) = | x2 - x1 |
	fdiv  	x			   					   		; ST(0) = | x2 - x1 | / x
	fabs			                            	; ST(0) = | ST(0) |
	fnstcw	flags                               	; save FPU flags
	mov		AX, flags                           
	and		AX, maskAnd								; form a new bitmap
	or		AX, maskOr
	mov		flags, AX
	fldcw	flags                              		; set FPU flags
   	frndint             					   		; round( ST(0) )
	fld1           		   					   		; ST(0) -> ST(1), ST(0) = 1
	fadd 	ST(0), ST(1)   					   		; ST(0) = ST(1) + ST(0)
	fld1           		   					   		; ST(0) -> ST(1), ST(0) = 1
	fadd 	ST(0), ST(1)   							; ST(0) = ST(1) + ST(0)
	fistp	sizeArr       					   		; sizeArr = ST(0)
	jmp 	cp
	
	ex1x2:
	mov		sizeArr, 1
	cp:

;--------------------------------------------------------------------------------------------------- 
    
	finit                                       	; clear ST
	fld  	x1             							; ST(0) = x1
	fcom 	x2             					   		; compare x1 and x2  
	fstsw	AX                                  	; save FPU flags in AX
	sahf                                        	; set CPU flags from AX
	jb  	bvx1                                	; jump if x1 < x2
	fld  	x2										; ST(0) -> ST(1), ST(0) = x2
	fstp 	x1             							; x1 = ST(0), ST(1) -> ST(0)
	fstp 	x2								   		; x2 = ST(0)
	bvx1:                                                                
	
;---------------------------------------------------------------------------------------------------

  	finit                                       	; clear ST
  	fldz                                        	; ST(0) = 0
  	fcom	x                                   	; compare 0 and dx
  	fstsw	AX                                  	; save FPU flags in AX
  	sahf                                        	; set CPU flags from AX
  	jb		bzx                                		; jump if 0 > dx
  	finit                                       	; clear ST
  	fld		x1                                  	; ST(0) = x1
  	fld		x2                                  	; ST(0) -> ST(1), ST(0) = x2
  	fstp	x1                                  	; x1 = ST(0), ST(1) -> ST(0) 
	fstp	x2                                  	; x2 = ST(0)
  	bzx:
	
;---------------------------------------------------------------------------------------------------
                     
	push	offset x
	push	offset x2
    push	offset x1         
    push	sizeArr
	push	offset arguments
	call 	initArguments                       	; initialize array of arguments
	
;---------------------------------------------------------------------------------------------------
                        
	mov		EBX, offset arguments
	mov		EDX, offset values

	mov		EAX, sizeArr
	cmp 	EAX, 1
	je		nec
	
	finit                                    		; clear ST
	fld		qword ptr [ EDX + EAX * 8 - 8]      	; ST(0) = arguments[ sizeArr - 1 ]
	fcom	qword ptr [ EDX + EAX * 8 - 16 ]    	; compare ST(0) and arguments[ sizeArr - 2 ]
	fstsw	AX                                  	; save FPU flags in AX
	sahf                                        	; set CPU flags from AX
	jne		nec                                 
	dec		sizeArr
	nec:
	
;--------------------------------------------------------------------------------------------------- 
                    
    push	offset b
    push	offset a                     
 	push	sizeArr                   
   	push	offset values
	push	offset arguments
	call 	initValues                          	; initialize array of values
	
;--------------------------------------------------------------------------------------------------- 
                         
    push	sizeArr   
	push	offset values
    push	offset arguments
	push	offset result
   	call 	arraysToStr      	                	; convert arrays to string
	                                            	; output of result
   	push 	offset result
   	call 	lstrlen
	     	
   	push 	NULL
   	push 	offset numberOfChars
 	push 	EAX
   	push 	offset result
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