STACK SEGMENT PARA STACK
	DB 64 DUP(' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'
	
	BALL_X DW 0Ah					;X Position of the Ball
	BALL_Y DW 0Ah					;Y Position of the Ball
	BALL_SIZE DW 04h 				;4 pixel size Ball

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
		
		CALL DRAW_BALL				;call draw ball procedure

		RET
	MAIN ENDP

	DRAW_BALL PROC NEAR
		
		MOV CX,BALL_X  				;set the column (X)
		MOV DX,BALL_Y  				;set the line (Y)
		
		DRAW_BALL_SIZE:
			MOV AH,0Ch     			;set the configuration to write a pixel
			MOV AL,0Fh     			;chose white color
			MOV BH,00h     			;set the page number
			INT 10h        			;run the configuration
			
			INC CX					;CX=CX+1
			MOV AX,CX				;AX=CX
			SUB AX,BALL_X			;AX=AX-BALL_SIZE
			CMP AX,BALL_SIZE		;IF AX>BALL_SIZE -> Y: We go to next line. OR -> N: We continue on the next column
			JNG DRAW_BALL_SIZE		;Jump to label DRAW_BALL_SIZE if comparison not greater

			MOV CX,BALL_X			;set CX to its original value
			INC DX					;DX=DX+1

			MOV AX,DX				;AX=DX
			SUB AX,BALL_Y			;AX=AX-BALL_SIZE
			CMP AX,BALL_SIZE		;IF AX>BALL_SIZE -> Y: We go to next column
			JNG DRAW_BALL_SIZE		;Jump to label DRAW_BALL_SIZE if comparison not greater

		RET
	DRAW_BALL ENDP

CODE ENDS
END
