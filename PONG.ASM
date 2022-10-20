STACK SEGMENT PARA STACK
	DB 64 DUP(' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'
	
	BALL_X DW 0Ah					;X Position of the Ball
	BALL_Y DW 0Ah					;Y Position of the Ball

DATA ENDS

CODE SEGMENT PARA 'CODE'
    
	MAIN PROC FAR
	ASSUME CS:CODE,DS:DATA,SS:STACK	;link the various segments in the procedure
	PUSH DS							;push DS segment to stack
	SUB AX,AX						;clean the AX register
	PUSH AX							;push AX to the stack
	MOV AX,DATA						;save the contents of DATA on AX register
	MOV DS,AX						;save on the DS the contents of AX
	POP AX							;release the top item from the stack to the AX register
	POP AX							;release the top item from the stack to the AX register

		MOV AH,00h					;set the configuration for video mode
		MOV AL,13h					;set video mode
		INT 10h						;run the videomode configuration
		
		MOV AH,0Bh					;set the configuration for background color
		MOV BH,00h					;configuration for background color
		MOV BL,03h					;set it to black
		INT 10h						;run the configuration
		
		MOV AH,0Ch					;set the configuration to write a pixel
		MOV AL,0Fh					;chose white color
		MOV BH,00h					;set the page number
		MOV CX,BALL_X				;set the X position
		MOV DX,BALL_Y				;set the Y position
		INT 10h						;run the configuration

		RET
	MAIN ENDP

CODE ENDS
END
