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

; structure declaration
list struct
	 row   			dd 0
	 place			dd 0
	 price			dq 0 
list ends

.data
	template		db "Row: %d, place: %d, price: %s;", 0ah, 0
	enterN			db "Enter n: ", 0
	enterArrElem	db "Enter array element (r, pl, pr):", 0ah, 0
	try				db "Invalid input. Try again.", 0ah, 0
	byPlace			db 0ah, "Sorted by place:", 0ah, 0
	byPrice			db 0ah, "Sorted by price:", 0ah, 0
	n				dd 0
	array			list 100 dup ( <> )

.data?
	inputHandle     dd ?
	outputHandle	dd ?
	numberOfChars	dd ?
	buffer			db 3000 dup (?)
	tmp				db 100 dup (?)

.code                                                                                               
;---------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------

; void readList(list* array, int size)
readList:
	push	EBP
	mov		EBP, ESP
	           
	startLoopRead:
		cmp		dword ptr [ EBP + 12 ], 0
		je 		endLoopRead
		
        ;-------------------------------------------------------------------------------------------
        
        jmp		startRead
                                                                                                   
        retry:
        
        push	NULL
        push	offset numberOfChars
        push	26
        push	offset try
        push	outputHandle
        call	WriteConsole
        
        ;-------------------------------------------------------------------------------------------
        
        startRead:
		
		push	offset enterArrElem  
		call	lstrlen
		
		push	NULL
		push	offset numberOfChars
		push	EAX
		push	offset enterArrElem
		push	outputHandle
		call	WriteConsole
		
		;-------------------------------------------------------------------------------------------
		
		mov		EBX, dword ptr [ EBP + 8 ]          ; EBX = offset array
		
		;-------------------------------------------------------------------------------------------
													; read list[i].row
		push	NULL
		push	offset numberOfChars
		push	15
		push	offset buffer
		push	inputHandle
		call	ReadConsole
		
		cmp		buffer[0], '-'
		jne		lblrow
		mov		buffer[0], 2d
		lblrow:
		
		mov		EDX, offset buffer
		mov		EAX, numberOfChars
		mov		byte ptr [ EDX + EAX - 2], 0
		
		push	offset buffer
		call	atodw
		mov		dword ptr [ EBX ], EAX
		
		;-------------------------------------------------------------------------------------------
	   												; data verification	                                                                                            
		cmp		dword ptr [ EBX ], 0
		jle		retry
		
		;-------------------------------------------------------------------------------------------
													; read list[i].place
		push	NULL
		push	offset numberOfChars
		push	15
		push	offset buffer
		push	inputHandle
		call	ReadConsole
		
		cmp		buffer[0], '-'
		jne		lblplace
		mov		buffer[0], 2d
		lblplace:
		
		mov		EDX, offset buffer
		mov		EAX, numberOfChars
		mov		byte ptr [ EDX + EAX - 2], 0
		
		push	offset buffer
		call	atodw
		mov		dword ptr [ EBX  + 4 ], EAX
		
		;-------------------------------------------------------------------------------------------
													; data verification                                                                                            
		cmp		dword ptr [ EBX + 4 ], 0
		jle		retry
	
		;-------------------------------------------------------------------------------------------
													; read list[i].price
		push	NULL
		push	offset numberOfChars
		push	15
		push	offset buffer
		push	inputHandle
		call	ReadConsole
		
		mov		EDX, offset buffer
		mov		EAX, numberOfChars
		mov		byte ptr [ EDX + EAX - 2 ], 0
		
		add		EBX, 8
		
		push	EBX
		push	offset buffer
		call	StrToFloat 
		
		;-------------------------------------------------------------------------------------------
		                                            ; data verification
		mov		EBX, dword ptr [ EBP + 8 ]  		; EBX = offset array
		                                                                                            
		finit										; clear ST
		fldz                                        ; ST(0) = 0
		fld		qword ptr [ EBX + 8 ]               ; ST(0) -> ST(1), ST(0) = list[i].price
		fcom	ST(1)                               ; compare ST(0) and ST(1)
		fstsw	AX                                  ; save FPU flags in AX
		sahf                                        ; set CPU flags from AX
		jbe		retry
		
		;-------------------------------------------------------------------------------------------
		
		add		dword ptr [ EBP + 8 ], 16 			; to next element
		dec 	dword ptr [ EBP + 12 ]                                  
		
		;-------------------------------------------------------------------------------------------
		
		jmp		startLoopRead
	endLoopRead:
	
	pop		EBP
ret 8

;---------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------

; int listCompareByPlace(list* first, list* second)
listCompareByPlace:
	push	EBP
	mov		EBP, ESP     
               
	mov		EAX, dword ptr [ EBP + 8 ]				; EAX = offset first
	mov		EBX, dword ptr [ EBP + 12 ]             ; EBX = offset second
	
	mov		EDX, dword ptr [ EAX ]                  ; EDX = first.row 
	cmp		EDX, dword ptr [ EBX ]                  ; compare EDX and second.row
	jg		gcbpl
	jl		lcbpl
	
	mov		EDX, dword ptr [ EAX + 4 ]				; EDX = first.place
	cmp		EDX, dword ptr [ EBX + 4 ]              ; compare EDX and second.place
	jg 		gcbpl
	jl		lcbpl
													; if ( first == second )
	mov		EAX, 0                                  ; return 0
	jmp		returnCBPL
	
	gcbpl:											; if ( first > second )
	mov		EAX, 1                                  ; return 1
	jmp		returnCBPL
	
	lcbpl:                            				; if ( first < second )
	mov		EAX, -1                                 ; return -1
	
	returnCBPL:
	
    pop		EBP
ret 8

;---------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------
                                                                                                    
; int listCompareByPrice(list* first, list* second)
listCompareByPrice:
	push	EBP
	mov		EBP, ESP
	           
	mov		EAX, dword ptr [ EBP + 8 ]				; EAX = offset first	
	mov		EBX, dword ptr [ EBP + 12 ]             ; EBX = offset second
	
	finit                           				; clear ST
    fld		qword ptr [ EAX + 8 ]                   ; ST(0) = first.price
    fcom	qword ptr [ EBX + 8 ]                   ; compare ST(0) and second.price
	fstsw	AX                                      ; save FPU flags in AX
	sahf                                            ; set CPU flags from AX
	ja		acbpr
	jb		bcbpr
	                              					; if ( first == second )
	mov		EAX, 0                                  ; return 0
	jmp		returnCBPR
	
	acbpr:    										; if ( first > second )
	mov		EAX, 1                                  ; return 1
	jmp		returnCBPR
	
	bcbpr: 											; if ( first < second )												
	mov		EAX, -1                                 ; return -1
	
	returnCBPR:
		
	pop		EBP
ret 8

;---------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------
                                                                                              
; void swap(list* first, list* second)
swap:
	push	EBP
	mov		EBP, ESP
	           
	mov		EBX, dword ptr [ EBP + 8 ]				; EBX = offset first
	mov		EDX, dword ptr [ EBP + 12 ]             ; EDX = offset second
	
	mov		EAX, dword ptr [ EBX ]                	; EAX = first.row
	mov		ECX, dword ptr [ EDX ]                  ; ECX = second.row
	mov		dword ptr [ EDX ], EAX                  ; second.row = EAX
	mov		dword ptr [ EBX ], ECX                  ; first.row = ECX
	
	mov		EAX, dword ptr [ EBX + 4 ]         		; EAX = first.place
	mov		ECX, dword ptr [ EDX + 4 ]              ; ECX = second.place
	mov		dword ptr [ EDX + 4 ], EAX              ; first.place = EAX
	mov		dword ptr [ EBX + 4 ], ECX              ; second.place = ECX        
	
	finit                       					; clear ST
	fld		qword ptr [ EBX + 8 ]                   ; ST(0) = first.price
	fld		qword ptr [ EDX + 8 ]                   ; ST(0) -> ST(1), ST(0) = second.price
	fstp	qword ptr [ EBX + 8 ]                   ; first.price = ST(0), ST(1) -> ST(0)
	fstp	qword ptr [ EDX + 8 ]                   ; second.price = ST(0)
	
	pop		EBP
ret 8

;---------------------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------------------- 
                                                                                                    
; void	bubbleSort(list* array, int size, *)
bubbleSort:
	push	EBP
	mov		EBP, ESP
	              
	sub		ESP, 4									; reserve memory for local variable
	           
    mov		ECX, 1
    
    startLoopSort1:
       	cmp		ECX, dword ptr [ EBP + 12 ]			; for ( ECX = 1; ECX < size; ECX++ )
        je		endLoopSort1
       	
       	mov		EAX, dword ptr [ EBP + 12 ]			; EAX = size
       	sub		EAX, ECX                            ; EAX = EAX - ECX
       	mov		dword ptr [ EBP - 4 ], EAX 			; localVarible = EAX		
       	
       	push	ECX									; save ECX value in stack
    	mov		ECX, 0
    		 		             
    	startLoopSort2:
    		cmp		ECX, dword ptr [ EBP - 4 ]		; for ( ECX = 0; ECX < ( size - prev ECX ); ECX++ )
    		je 		endLoopSort2
    		           
    		push	ECX								; save ECX value in stack
    		
    		mov		EBX, dword ptr [ EBP + 8 ]		; EBX = offset array
    		
    		mov		EAX, 16							; EAX = 16
    		mul		ECX                             ; EAX = 16 * ECX ( element offset )
    		
    		add		EBX, EAX						; EBX = EBX + EAX ( array[ ECX ] )
    		push	EBX						
    		add		EBX, 16							; EBX = EBX + EAX + 16 ( array[ ECX + 1 ] )
    		push	EBX
    		call	dword ptr [ EBP + 16 ]			; call compare function
    		
    		pop		ECX								; restore ECX value
    	
    		cmp		EAX, 0							; compare return value and 0
    		jge		continueSort
    												; if ( array[ ECX ] > array[ ECX + 1 ] ) 
    		push	ECX								; save ECX value in stack
    		
    		mov		EBX, dword ptr [ EBP + 8 ]		; EBX = offset array
    		
    		mov		EAX, 16							; EAX = 16                     
    		mul		ECX								; EAX = 16 * ECX ( element offset )
    		
       		add		EBX, EAX						; EBX = EBX + EAX ( array[ ECX ] )						
    		push	EBX
    		add		EBX, 16							; EBX = EBX + EAX + 16 ( array[ ECX + 1 ] )
    		push	EBX
    		call	swap							; swap(array[ ECX + 1 ], array[ ECX ]) 
    		
    		pop		ECX								; restore ECX value
    		
    		continueSort:
    		
    		inc		ECX
    		
    		jmp		startLoopSort2
    	endLoopSort2:
        
        pop		ECX									; restore ECX value from stack
        inc		ECX
        
    	jmp		startLoopSort1
    endLoopSort1:
    
    add		ESP, 4									; clear memory
	
	pop		EBP
ret	12

;---------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------

; void listToStr(char* buffer, list* array, int size)
listToStr:
	push	EBP
	mov		EBP, ESP           

	startLoopConvert:		
		cmp		dword ptr [ EBP + 16 ], 0
		je		endLoopConvert 
		                        
	 	mov		EAX, dword ptr [ EBP + 12 ]			; EAX = offset array
	 
		push	offset tmp
		push	dword ptr [ EAX + 12 ]
		push	dword ptr [ EAX + 8 ]
		call	FloatToStr      					; convert array[i].price to string
		
	 	mov		EAX, dword ptr [ EBP + 12 ]			; EAX = offset array	 
		
	   	push	offset tmp
	   	push	dword ptr [ EAX + 4 ]
		push	dword ptr [ EAX ]
		push	offset template
		push	dword ptr [ EBP + 8 ]
		call	wsprintf 							; form output string
			
		add		ESP, 20
		
		add		[ EBP + 8 ], EAX
		add		dword ptr [ EBP + 12 ], 16 			; to next element
		dec		dword ptr [ EBP + 16 ]
		
		jmp		startLoopConvert 
	endLoopConvert:
	
	pop		EBP	
ret 16

;---------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------

main:
;--------------------------------------------------------------------------------------------------- 
                                                                                                    
	push	STD_INPUT_HANDLE
	call	GetStdHandle
	mov		inputHandle, EAX
	
	push	STD_OUTPUT_HANDLE
	call	GetStdHandle
	mov		outputHandle,EAX

;--------------------------------------------------------------------------------------------------- 
       												; read n
    tryN:   												
       												                                                                                              
	push	NULL
	push	offset numberOfChars
	push	9
	push	offset enterN
	push 	outputHandle
	call	WriteConsole
	
	push	NULL
	push	offset numberOfChars
	push	15
	push	offset buffer
	push	inputHandle
	call	ReadConsole
	
	cmp		buffer[0], '-'
	jne		lbln
	mov		buffer[0], 2d
	lbln:
	
	mov		EDX, offset buffer
	mov		EAX, numberOfChars
	mov		byte ptr [ EDX + EAX - 2 ], 0
	
	push	offset buffer
	call	atodw
	mov		n, EAX 
	
	cmp		n, 0
	jle		tryN

;--------------------------------------------------------------------------------------------------- 
                                                                                                   
	push	n
	push	offset array
	call	readList 								; readList(array, n)                                                                               
	
;---------------------------------------------------------------------------------------------------
             										; write label
	push	NULL
	push	offset numberOfChars
	push	18
	push	offset byPlace
	push	outputHandle
	call	WriteConsole

;---------------------------------------------------------------------------------------------------
                                                                                                  
	push	listCompareByPlace
	push	n
	push	offset array
	call	bubbleSort						   		; bubbleSort(array, n, listCompareByPlace)

;---------------------------------------------------------------------------------------------------
                                                                                                    
	push	n
	push	offset array
	push	offset buffer
	call	listToStr    							; convert array to string
	
	push	offset buffer
	call	lstrlen
	
	push	NULL
	push	offset numberOfChars
	push	EAX
	push	offset buffer
	push	outputHandle
	call	WriteConsole  
     		
;---------------------------------------------------------------------------------------------------
  													; write label
	push	NULL
	push	offset numberOfChars
	push	18
	push	offset byPrice
	push	outputHandle
	call	WriteConsole

;---------------------------------------------------------------------------------------------------
                                                                                                   
	push	listCompareByPrice
	push	n
	push	offset array
	call	bubbleSort 								; bubbleSort(array, n, listCompareByPrice)

;---------------------------------------------------------------------------------------------------
                                                                                                    
	push	n
	push	offset array
	push	offset buffer
	call	listToStr   							; convert array to string
	
	push	offset buffer
	call	lstrlen
	
	push	NULL
	push	offset numberOfChars
	push	EAX
	push	offset buffer
	push	outputHandle
	call	WriteConsole
	
;---------------------------------------------------------------------------------------------------
	
	push	NULL
	push	offset numberOfChars
	push	1
	push	offset buffer
	push	inputHandle
	call	ReadConsole
	
	push	0
	call	ExitProcess
		
;---------------------------------------------------------------------------------------------------
end main 