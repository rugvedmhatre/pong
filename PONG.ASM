STACK SEGMENT PARA STACK
    DB 64 DUP(' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'

DATA ENDS

CODE SEGMENT PARA 'CODE'
    
	MAIN PROC FAR
		
		MOV DL,'A'
		MOV AH,6h
		INT 21h

		RET
	MAIN ENDP

CODE ENDS
END