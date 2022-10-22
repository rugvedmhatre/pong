STACK SEGMENT PARA STACK
	DB 64 DUP(' ')
STACK ENDS


DATA SEGMENT PARA 'DATA'

	WINDOW_WIDTH DW 140h	;width of window (320 pixels)
	WINDOW_HEIGHT DW 0C8h	;height of window (200 pixels)
	WINDOW_BOUNDARY DW 6	;window margin from edges

	TIME_AUX DB 0			;variable for checking time

	BALL_INITIAL_X DW 0A0h	;Initial X position of the Ball 
	BALL_INITIAL_Y DW 64h	;Initial Y position of the Ball
	BALL_X DW 0A0h			;X Position of the Ball
	BALL_Y DW 64h			;Y Position of the Ball
	BALL_SIZE DW 04h		;4 pixel size Ball
	BALL_VELOCITY_X DW 05h	;X Velocity of the ball
	BALL_VELOCITY_Y DW 02h	;Y Velocity of the ball

	PADDLE_LEFT_X DW 0Ah	;Initial X position of the Left Paddle
	PADDLE_LEFT_Y DW 0Ah	;Initial Y position of the Left Paddle
	PADDLE_RIGHT_X DW 130h	;Initial X position of the Right Paddle
	PADDLE_RIGHT_Y DW 0Ah	;Initial Y position of the Right Paddle
	PADDLE_WIDTH DW 05h		;Width of the paddle
	PADDLE_LENGTH DW 1Fh	;Height of the paddle

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

		CALL CLEAR_SCREEN			;call clear screen procedure
		
		CHECK_TIME:
			MOV AH,2Ch				;get system time
			INT 21h					;CH=hour, CL=minute, DH=second, DL=1/100second

			CMP DL,TIME_AUX			;compare current time to previous time
			JE CHECK_TIME			;if it is same compare again
			
			MOV TIME_AUX,DL			;update time in TIME_AUX variable

			CALL CLEAR_SCREEN		;clearing previous frame to create new frame for ball

			CALL MOVE_BALL			;call move ball procedure to update position
			CALL DRAW_BALL			;call draw ball procedure

			CALL DRAW_PADDLES		;call draw paddles procedure
			
			JMP CHECK_TIME			;check time again after drawing the ball

		RET
	MAIN ENDP


	MOVE_BALL PROC NEAR

		MOV AX,BALL_VELOCITY_X
		ADD BALL_X,AX				;updating x position of ball

		MOV AX,WINDOW_BOUNDARY
		CMP BALL_X,AX				;if x position of ball < window boundary -> reset the ball position
		JL RESET_BALL

		MOV AX,WINDOW_WIDTH
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDARY
		CMP BALL_X,AX				;if x position of ball > (window width - window boundary - ball size) -> reset the ball position
		JG RESET_BALL

		MOV AX,BALL_VELOCITY_Y
		ADD BALL_Y,AX				;updating y position of ball

		MOV AX,WINDOW_BOUNDARY
		CMP BALL_Y,AX				;if y position of ball < window boundary -> negate the velocity
		JL NEG_VELOCITY_Y

		MOV AX,WINDOW_HEIGHT
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDARY
		CMP BALL_Y,AX				;if y position of ball > (window height - window boundary - ball size) -> negate the velocity
		JG NEG_VELOCITY_Y

		RET

		RESET_BALL:
			CALL RESET_BALL_POSITION
			RET
		
		NEG_VELOCITY_Y:
			NEG BALL_VELOCITY_Y
			RET

	MOVE_BALL ENDP


	RESET_BALL_POSITION PROC NEAR
		
		MOV AX,BALL_INITIAL_X
		MOV BALL_X,AX
		
		MOV AX,BALL_INITIAL_Y
		MOV BALL_Y,AX

		RET
	RESET_BALL_POSITION ENDP
		

	DRAW_BALL PROC NEAR
		
		MOV CX,BALL_X				;set the column (X)
		MOV DX,BALL_Y				;set the line (Y)
		
		DRAW_BALL_SIZE:
			MOV AH,0Ch				;set the configuration to write a pixel
			MOV AL,0Fh				;chose white color
			MOV BH,00h				;set the page number
			INT 10h					;run the configuration
			
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


	DRAW_PADDLES PROC NEAR

		MOV CX,PADDLE_LEFT_X
		MOV DX,PADDLE_LEFT_Y

		DRAW_PADDLE_LEFT:
			MOV AH,0Ch				;set the configuration to write a pixel
			MOV AL,0Fh				;chose white color
			MOV BH,00h				;set the page number
			INT 10h					;run the configuration
			
			INC CX					;CX=CX+1
			MOV AX,CX				;AX=CX
			SUB AX,PADDLE_LEFT_X	;AX=AX-PADDLE_LEFT_X
			CMP AX,PADDLE_WIDTH		;IF AX>PADDLE_WIDTH -> Y: We go to next line. OR -> N: We continue on the next column
			JNG DRAW_PADDLE_LEFT	;Jump to label DRAW_PADDLE_LEFT if comparison not greater

			MOV CX,PADDLE_LEFT_X	;set CX to its original value
			INC DX					;DX=DX+1

			MOV AX,DX				;AX=DX
			SUB AX,PADDLE_LEFT_Y	;AX=AX-PADDLE_LEFT_Y
			CMP AX,PADDLE_LENGTH	;IF AX>PADDLE_LENGTH -> Y: We go to next column
			JNG DRAW_PADDLE_LEFT	;Jump to label DRAW_PADDLE_LEFT if comparison not greater

		MOV CX,PADDLE_RIGHT_X
		MOV DX,PADDLE_RIGHT_Y

		DRAW_PADDLE_RIGHT:
			MOV AH,0Ch				;set the configuration to write a pixel
			MOV AL,0Fh				;chose white color
			MOV BH,00h				;set the page number
			INT 10h					;run the configuration
			
			INC CX					;CX=CX+1
			MOV AX,CX				;AX=CX
			SUB AX,PADDLE_RIGHT_X	;AX=AX-PADDLE_RIGHT_X
			CMP AX,PADDLE_WIDTH		;IF AX>PADDLE_WIDTH -> Y: We go to next line. OR -> N: We continue on the next column
			JNG DRAW_PADDLE_RIGHT	;Jump to label DRAW_PADDLE_RIGHT if comparison not greater

			MOV CX,PADDLE_RIGHT_X	;set CX to its original value
			INC DX					;DX=DX+1

			MOV AX,DX				;AX=DX
			SUB AX,PADDLE_RIGHT_Y	;AX=AX-PADDLE_RIGHT_Y
			CMP AX,PADDLE_LENGTH	;IF AX>PADDLE_LENGTH -> Y: We go to next column
			JNG DRAW_PADDLE_RIGHT	;Jump to label DRAW_PADDLE_RIGHT if comparison not greater

		RET
	DRAW_PADDLES ENDP


	CLEAR_SCREEN PROC NEAR

		MOV AH,00h					;set the configuration for video mode
		MOV AL,13h					;set video mode
		INT 10h						;run the videomode configuration
		
		MOV AH,0Bh					;set the configuration for background color
		MOV BH,00h					;configuration for background color	
		MOV BL,03h					;set it to black
		INT 10h						;run the configuration

		RET
	CLEAR_SCREEN ENDP


CODE ENDS
END
