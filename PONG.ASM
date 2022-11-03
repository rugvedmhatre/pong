STACK SEGMENT PARA STACK
	DB 64 DUP(' ')
STACK ENDS


DATA SEGMENT PARA 'DATA'

	WINDOW_WIDTH DW 140h				;width of window (320 pixels)
	WINDOW_HEIGHT DW 0C8h				;height of window (200 pixels)
	WINDOW_BOUNDARY DW 6				;window margin from edges

	TIME_AUX DB 0						;variable for checking time
	GAME_ACTIVE_FLAG DB 1				;variable to check whether game is active (1 = Yes; 0 = No)
	CURRENT_SCREEN DB 0					;variable to check current screen (0 = main menu, 1 = game)
	AI_PLAYER DB 0						;variable to check AI player
	
	WINNER_INDEX DB 0					;left = player 1; right = player 2

	GAME_OVER_STRING DB 'GAME OVER','$'	;game over string
	GAME_WIN_STRING DB 'PLAYER 0 WON!','$'
	REPLAY_STRING DB 'Press R to play again.','$'
	EXIT_STRING DB 'Press E to exit to main menu.','$'

	TOP_STRING DB '--------','$'
	PONG_STRING DB '| PONG |','$'			;pong game string
	BOTTOM_STRING DB '--------','$'
	SINGLE_PLAYER_STRING DB 'Press S for single player game','$'
	MULTI_PLAYER_STRING DB 'Press M for multiplayer game','$'
	QUIT_STRING DB 'Press E to exit game','$'

	BALL_INITIAL_X DW 0A0h				;Initial X position of the ball 
	BALL_INITIAL_Y DW 64h				;Initial Y position of the ball
	BALL_X DW 0A0h						;Current X position of the ball
	BALL_Y DW 64h						;Current Y position of the ball
	BALL_SIZE DW 04h					;size of ball = 4 pixels
	BALL_VELOCITY_X DW 05h				;X velocity of the ball
	BALL_VELOCITY_Y DW 02h				;Y velocity of the ball

	PADDLE_LEFT_X DW 0Ah				;Current X position of the left paddle
	PADDLE_LEFT_Y DW 55h				;Current Y position of the left paddle
	PADDLE_LEFT_SCORE DB 0				;Current score of the left paddle
	LEFT_SCORE_STRING DB '0','$'		;left paddle score as string
	
	PADDLE_RIGHT_X DW 130h				;Current X position of the right paddle
	PADDLE_RIGHT_Y DW 55h				;Current Y position of the right paddle
	PADDLE_RIGHT_SCORE DB 0				;Current score of the right paddle
	RIGHT_SCORE_STRING DB '0','$'		;right paddle score as string

	PADDLE_WIDTH DW 05h					;Width of the paddle
	PADDLE_LENGTH DW 1Eh				;Height of the paddle
	LEFT_PADDLE_VELOCITY DW 05h			;Velocity of the paddle
	RIGHT_PADDLE_VELOCITY DW 05h		;Velocity of the paddle
	PADDLE_INITIAL_Y DW 55h				;Initial Y position of paddles

DATA ENDS


CODE SEGMENT PARA 'CODE'

	MAIN PROC FAR
	ASSUME CS:CODE,DS:DATA,SS:STACK		;link the various segments in the procedure	
	PUSH DS								;push DS segment to stack
	SUB AX,AX							;clean the AX register
	PUSH AX								;push AX to the stack
	MOV AX,DATA							;save the contents of DATA on AX register
	MOV DS,AX							;save on the DS the contents of AX
	POP AX								;release the top item from the stack to the AX register
	POP AX								;release the top item from the stack to the AX register

		CALL CLEAR_SCREEN				;call clear screen procedure
		
		CHECK_TIME:
			CMP CURRENT_SCREEN,00h		;check if current screen is main menu
			JE MAIN_MENU_SCREEN			;if current screen is main menu, go to main menu screen

			CMP GAME_ACTIVE_FLAG,00h	;check if game is not active
			JE GAME_OVER_SCREEN			;if game is not active, go to game over screen

			MOV AH,2Ch					;get system time
			INT 21h						;CH=hour, CL=minute, DH=second, DL=1/100second

			CMP DL,TIME_AUX				;compare current time to previous time
			JE CHECK_TIME				;if it is same compare again
			
			MOV TIME_AUX,DL				;update time in TIME_AUX variable

			CALL CLEAR_SCREEN			;clearing previous frame to create new frame for ball

			CALL MOVE_BALL				;call move ball procedure to update position
			CALL DRAW_BALL				;call draw ball procedure
			
			CALL MOVE_PADDLES			;call move paddles procdeure
			CALL DRAW_PADDLES			;call draw paddles procedure

			CALL DRAW_UI				;call draw ui procdeure
			
			JMP CHECK_TIME				;check time again after drawing the ball

		GAME_OVER_SCREEN:
			CALL DRAW_GAME_OVER			;call procdeure to display game over screen
			JMP CHECK_TIME
		
		MAIN_MENU_SCREEN:
			CALL DRAW_MAIN_MENU			;call procdeure to display main menu screen
			JMP CHECK_TIME

		RET
	MAIN ENDP


	MOVE_BALL PROC NEAR

		MOV AX,BALL_VELOCITY_X
		ADD BALL_X,AX					;updating x position of ball

		MOV AX,WINDOW_BOUNDARY
		CMP BALL_X,AX					;if x position of ball < window boundary -> reset the ball position, and give points to right player
		JL RIGHT_SCORED

		MOV AX,WINDOW_WIDTH
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDARY
		CMP BALL_X,AX					;if x position of ball > (window width - window boundary - ball size) -> reset the ball position, and give points to left player
		JG LEFT_SCORED

		MOV AX,BALL_VELOCITY_Y
		ADD BALL_Y,AX					;updating y position of ball

		MOV AX,WINDOW_BOUNDARY
		CMP BALL_Y,AX					;if y position of ball < window boundary -> negate the velocity
		JL NEG_VELOCITY_Y

		MOV AX,WINDOW_HEIGHT
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDARY
		CMP BALL_Y,AX					;if y position of ball > (window height - window boundary - ball size) -> negate the velocity
		JG NEG_VELOCITY_Y
		JMP CHECK_RIGHT_COLLISION		;else check collision with right paddle

		RIGHT_SCORED:
			INC PADDLE_RIGHT_SCORE		;increase paddle right score
			CALL RESET_BALL_POSITION	;reset ball position to center of the screen
			CALL UPDATE_RIGHT_SCORE		;udpate onscreen score
			CMP PADDLE_RIGHT_SCORE,05h	;if paddle right score > 5, game over
			JGE GAME_OVER
			RET

		LEFT_SCORED:
			INC PADDLE_LEFT_SCORE		;increase paddle left score
			CALL RESET_BALL_POSITION	;reset ball position to center of the screen
			CALL UPDATE_LEFT_SCORE		;update onscreen score
			CMP PADDLE_LEFT_SCORE,05h	;if paddle left score > 5, game over
			JGE GAME_OVER
			RET
		
		GAME_OVER:
			CALL RESET_PADDLES			;reset paddle positions
			CMP PADDLE_LEFT_SCORE,05h	;check if left paddle has won
			JNL LEFT_WON
			JMP RIGHT_WON

		LEFT_WON:
			MOV WINNER_INDEX,01h		;left has won
			JMP GAME_OVER_CONTINUED
			
		RIGHT_WON:
			MOV WINNER_INDEX,02h		;right has won
			JMP GAME_OVER_CONTINUED

		GAME_OVER_CONTINUED:
			MOV GAME_ACTIVE_FLAG,00h	;to stop the game	
			MOV PADDLE_LEFT_SCORE,00h	;reset scores to 0
			MOV PADDLE_RIGHT_SCORE,00h	;reset scores to 0
			CALL UPDATE_LEFT_SCORE		;reset the socre on screen
			CALL UPDATE_RIGHT_SCORE		;reset the score on screen
			CALL UPDATE_WINNER_STRING	;update the winner on screen
			RET

		NEG_VELOCITY_Y:
			NEG BALL_VELOCITY_Y			;negate ball position to imitate a bounce
			RET

		CHECK_RIGHT_COLLISION:
			MOV AX,BALL_X				;check for collision on right paddle
			ADD AX,BALL_SIZE				
			CMP AX,PADDLE_RIGHT_X		;compare right paddle X with BALL_X + BALL_SIZE
			JNG CHECK_LEFT_COLLISION	;if BALL_X + BALL_SIZE > PADDLE_RIGHT_X = collision; else check left paddle

			MOV AX,PADDLE_RIGHT_X			
			ADD AX,PADDLE_WIDTH
			CMP BALL_X,AX				;compare BALL_X with right paddle X + width of the paddle
			JNL CHECK_LEFT_COLLISION	;if BALL_X < PADDLE_RIGHT_X + PADDLE_WIDTH = collision; else check left paddle

			MOV AX,BALL_Y
			ADD AX,BALL_SIZE
			CMP AX,PADDLE_RIGHT_Y		;compare right paddle Y with BALL_Y + BALL_SIZE
			JNG CHECK_LEFT_COLLISION	;if BALL_Y + BALL_SIZE > PADDLE_RIGHT_Y = collision; else check left paddle

			MOV AX,PADDLE_RIGHT_Y
			ADD AX,PADDLE_LENGTH
			CMP BALL_Y,AX				;compare BALL_Y with right paddle Y + length of the paddle
			JNL CHECK_LEFT_COLLISION	;if BALL_Y < PADDLE_RIGHT_Y + PADDLE_LENGTH = collision; else check left paddle
			
			JMP NEG_VELOCITY_X			;if above conditions are checked then ball is colliding with right paddle ->  negate the velocity
			
		CHECK_LEFT_COLLISION:
			MOV AX,BALL_X				;check for collision on left paddle
			ADD AX,BALL_SIZE				
			CMP AX,PADDLE_LEFT_X		;compare left paddle X with BALL_X + BALL_SIZE
			JNG NO_COLLISION			;if BALL_X + BALL_SIZE > PADDLE_LEFT_X = collision; else return

			MOV AX,PADDLE_LEFT_X			
			ADD AX,PADDLE_WIDTH
			CMP BALL_X,AX				;compare BALL_X with left paddle X + width of the paddle
			JNL NO_COLLISION			;if BALL_X < PADDLE_LEFT_X + PADDLE_WIDTH = collision; else return

			MOV AX,BALL_Y
			ADD AX,BALL_SIZE
			CMP AX,PADDLE_LEFT_Y		;compare left paddle Y with BALL_Y + BALL_SIZE
			JNG NO_COLLISION			;if BALL_Y + BALL_SIZE > PADDLE_LEFT_Y = collision; else return

			MOV AX,PADDLE_LEFT_Y
			ADD AX,PADDLE_LENGTH
			CMP BALL_Y,AX				;compare BALL_Y with left paddle Y + length of the paddle
			JNL NO_COLLISION			;if BALL_Y < PADDLE_LEFT_Y + PADDLE_LENGTH = collision; else return
			
			JMP NEG_VELOCITY_X			;if above conditions are checked then ball is colliding with left paddle ->  negate the velocity
		
		NEG_VELOCITY_X:
			NEG BALL_VELOCITY_X
			RET

		NO_COLLISION:
			RET

	MOVE_BALL ENDP


	RESET_PADDLES PROC NEAR
		
		MOV AX,PADDLE_INITIAL_Y
		MOV PADDLE_LEFT_Y,AX					;set current left paddle Y position to initial position
		MOV PADDLE_RIGHT_Y,AX					;set current right paddle Y position to initial position

		RET
	RESET_PADDLES ENDP
	

	RESET_BALL_POSITION PROC NEAR
		
		MOV AX,BALL_INITIAL_X
		MOV BALL_X,AX					;set current ball position to initial position
		
		MOV AX,BALL_INITIAL_Y
		MOV BALL_Y,AX					;set current ball position to initial position

		NEG BALL_VELOCITY_X
		NEG BALL_VELOCITY_Y

		RET
	RESET_BALL_POSITION ENDP
		

	DRAW_BALL PROC NEAR
		
		MOV CX,BALL_X					;set to current ball position
		MOV DX,BALL_Y					;set to current ball position
		
		DRAW_BALL_SIZE:
			MOV AH,0Ch					;set the configuration to write a pixel
			MOV AL,0Fh					;chose white color
			MOV BH,00h					;set the page number
			INT 10h						;run the configuration
			
			INC CX						;CX=CX+1
			MOV AX,CX					;AX=CX
			SUB AX,BALL_X				;AX=AX-BALL_SIZE
			CMP AX,BALL_SIZE			;if AX>BALL_SIZE -> Y: We go to next line. OR -> N: We continue on the next column
			JNG DRAW_BALL_SIZE			;jump to label DRAW_BALL_SIZE if comparison not greater

			MOV CX,BALL_X				;set CX to its original value
			INC DX						;DX=DX+1

			MOV AX,DX					;AX=DX
			SUB AX,BALL_Y				;AX=AX-BALL_SIZE
			CMP AX,BALL_SIZE			;if AX>BALL_SIZE -> Y: We go to next column
			JNG DRAW_BALL_SIZE			;jump to label DRAW_BALL_SIZE if comparison not greater

		RET
	DRAW_BALL ENDP


	MOVE_PADDLES PROC NEAR
		
		LEFT_PADDLE:
			MOV AH,01h					;check if a key is pressed
			INT 16h
			JZ RIGHT_PADDLE				;if zero flag is 1 -> then no key is pressed -> now go check the right paddle
			
			MOV AH,00h					;check which key is pressed
			INT 16h

			CMP AL,77h					;check if it is 'w'
			JE MOVE_LEFT_PADDLE_UP		;jump to label MOVE_LEFT_PADDLE_UP
			CMP AL,57h					;check if it is 'W'
			JE MOVE_LEFT_PADDLE_UP		;jump to label MOVE_LEFT_PADDLE_UP

			CMP AL,73h					;check if it is 's'
			JE MOVE_LEFT_PADDLE_DWN		;jump to label MOVE_LEFT_PADDLE_DWN
			CMP AL,53h					;check if it is 'S'
			JE MOVE_LEFT_PADDLE_DWN		;jump to label MOVE_LEFT_PADDLE_DWN
			JMP RIGHT_PADDLE

			MOVE_LEFT_PADDLE_UP:
				MOV AX,LEFT_PADDLE_VELOCITY
				SUB PADDLE_LEFT_Y,AX	;to move up, Y position = Y - velocity
				MOV AX,WINDOW_BOUNDARY
				CMP PADDLE_LEFT_Y,AX	;check if touching the window boundary
				JL STOP_LEFT_AT_TOP		;if Y position < boundary, stop moving up
				JMP RIGHT_PADDLE

				STOP_LEFT_AT_TOP:
					MOV PADDLE_LEFT_Y,AX
					JMP RIGHT_PADDLE

			MOVE_LEFT_PADDLE_DWN:
				MOV AX,LEFT_PADDLE_VELOCITY
				ADD PADDLE_LEFT_Y,AX	;to move down, Y = Y + velocity
				MOV AX,WINDOW_HEIGHT
				SUB AX,WINDOW_BOUNDARY
				SUB AX,PADDLE_LENGTH
				CMP PADDLE_LEFT_Y,AX	;check if touching bottom boundary
				JG STOP_LEFT_AT_BOTTOM	;if Y position > boundary, stop moving down
				JMP RIGHT_PADDLE
				
				STOP_LEFT_AT_BOTTOM:
					MOV PADDLE_LEFT_Y,AX
					JMP RIGHT_PADDLE

		RIGHT_PADDLE:
			CMP AI_PLAYER,01h
			JE AI_CONTROL

			CHECK_KEY_PRESS:
				CMP AL,6Fh				;check if the key is 'o'
				JE MOVE_RIGHT_PADDLE_UP	;jump to label MOVE_RIGHT_PADDLE_UP
				CMP AL,4Fh				;check if it is 'O'
				JE MOVE_RIGHT_PADDLE_UP	;jump to label MOVE_RIGHT_PADDLE_UP

				CMP AL,6Ch				;check if it is 'l'
				JE MOVE_RIGHT_PADDLE_DWN;jump to label MOVE_RIGHT_PADDLE_DWN
				CMP AL,4Ch				;check if it is 'L'
				JE MOVE_RIGHT_PADDLE_DWN;jump to label MOVE_RIGHT_PADDLE_DWN

				JMP EXIT_PROC			;if no key detected, exit

			AI_CONTROL:
				MOV RIGHT_PADDLE_VELOCITY,03h
				MOV AX,BALL_Y
				ADD AX,BALL_SIZE
				MOV BX,PADDLE_RIGHT_Y
				ADD BX,02h
				CMP AX,BX
				JL MOVE_RIGHT_PADDLE_UP

				MOV AX,PADDLE_RIGHT_Y
				ADD AX,PADDLE_LENGTH
				SUB AX,02h
				CMP AX,BALL_Y
				JL MOVE_RIGHT_PADDLE_DWN

				JMP EXIT_PROC

			MOVE_RIGHT_PADDLE_UP:
				MOV AX,RIGHT_PADDLE_VELOCITY
				SUB PADDLE_RIGHT_Y,AX	;to move up, Y = Y - velocity
				MOV AX,WINDOW_BOUNDARY
				CMP PADDLE_RIGHT_Y,AX	;check if touching top boundary
				JL STOP_RIGHT_AT_TOP	;if Y position < boundary, stop moving up
				JMP EXIT_PROC

				STOP_RIGHT_AT_TOP:
					MOV PADDLE_RIGHT_Y,AX
					JMP EXIT_PROC

			MOVE_RIGHT_PADDLE_DWN:
				MOV AX,RIGHT_PADDLE_VELOCITY
				ADD PADDLE_RIGHT_Y,AX	;to move down, Y = Y + velocity
				MOV AX,WINDOW_HEIGHT
				SUB AX,WINDOW_BOUNDARY
				SUB AX,PADDLE_LENGTH
				CMP PADDLE_RIGHT_Y,AX	;check if touching bottom boundary
				JG STOP_RIGHT_AT_BOTTOM	;if Y position > bottom boundary, stop moving down
				JMP EXIT_PROC
				
				STOP_RIGHT_AT_BOTTOM:
					MOV PADDLE_RIGHT_Y,AX
					JMP EXIT_PROC

		EXIT_PROC:						;exit label to return to main procedure
		
		RET
	MOVE_PADDLES ENDP


	DRAW_PADDLES PROC NEAR

		MOV CX,PADDLE_LEFT_X
		MOV DX,PADDLE_LEFT_Y

		DRAW_PADDLE_LEFT:
			MOV AH,0Ch					;set the configuration to write a pixel
			MOV AL,0Fh					;chose white color
			MOV BH,00h					;set the page number
			INT 10h						;run the configuration
			
			INC CX						;CX=CX+1
			MOV AX,CX					;AX=CX
			SUB AX,PADDLE_LEFT_X		;AX=AX-PADDLE_LEFT_X
			CMP AX,PADDLE_WIDTH			;if AX>PADDLE_WIDTH -> Y: We go to next line. OR -> N: We continue on the next column
			JNG DRAW_PADDLE_LEFT		;jump to label DRAW_PADDLE_LEFT if comparison not greater

			MOV CX,PADDLE_LEFT_X		;set CX to its original value
			INC DX						;DX=DX+1

			MOV AX,DX					;AX=DX
			SUB AX,PADDLE_LEFT_Y		;AX=AX-PADDLE_LEFT_Y
			CMP AX,PADDLE_LENGTH		;if AX>PADDLE_LENGTH -> Y: We go to next column
			JNG DRAW_PADDLE_LEFT		;jump to label DRAW_PADDLE_LEFT if comparison not greater

		MOV CX,PADDLE_RIGHT_X
		MOV DX,PADDLE_RIGHT_Y

		DRAW_PADDLE_RIGHT:
			MOV AH,0Ch					;set the configuration to write a pixel
			MOV AL,0Fh					;chose white color
			MOV BH,00h					;set the page number
			INT 10h						;run the configuration
			
			INC CX						;CX=CX+1
			MOV AX,CX					;AX=CX
			SUB AX,PADDLE_RIGHT_X		;AX=AX-PADDLE_RIGHT_X
			CMP AX,PADDLE_WIDTH			;if AX>PADDLE_WIDTH -> Y: We go to next line. OR -> N: We continue on the next column
			JNG DRAW_PADDLE_RIGHT		;jump to label DRAW_PADDLE_RIGHT if comparison not greater

			MOV CX,PADDLE_RIGHT_X		;set CX to its original value
			INC DX						;DX=DX+1

			MOV AX,DX					;AX=DX
			SUB AX,PADDLE_RIGHT_Y		;AX=AX-PADDLE_RIGHT_Y
			CMP AX,PADDLE_LENGTH		;if AX>PADDLE_LENGTH -> Y: We go to next column
			JNG DRAW_PADDLE_RIGHT		;jump to label DRAW_PADDLE_RIGHT if comparison not greater

		RET
	DRAW_PADDLES ENDP


	DRAW_UI PROC NEAR

		MOV AH,02h						;set cursor position
		MOV BH,00h						;set page number
		MOV DH,01h						;set row
		MOV DL,05h						;set column
		INT 10h

		MOV AH,09h
		LEA DX,LEFT_SCORE_STRING		;load the address of the string
		INT 21h

		MOV AH,02h						;set cursor position
		MOV BH,00h						;set page number
		MOV DH,01h						;set row
		MOV DL,22h						;set column
		INT 10h

		MOV AH,09h
		LEA DX,RIGHT_SCORE_STRING		;load the address of the string
		INT 21h

		RET
	DRAW_UI ENDP


	UPDATE_RIGHT_SCORE PROC NEAR
		
		SUB AX,AX
		MOV AL,PADDLE_RIGHT_SCORE

		ADD AL,30h						;to convert number into its ascii character, we add 30h
		MOV [RIGHT_SCORE_STRING],AL		;copy data from AL to the address of the variable
		
		RET
	UPDATE_RIGHT_SCORE ENDP


	UPDATE_LEFT_SCORE PROC NEAR
		
		SUB AX,AX
		MOV AL,PADDLE_LEFT_SCORE

		ADD AL,30h						;to convert number into its ascii character, we add 30h
		MOV [LEFT_SCORE_STRING],AL		;copy data from AL to the address of the variable

		RET
	UPDATE_LEFT_SCORE ENDP


	UPDATE_WINNER_STRING PROC NEAR

		MOV AL,WINNER_INDEX				;get winner index
		ADD AL,30h						;convert to ascii
		MOV [GAME_WIN_STRING+7],AL		;repace the 7th char in string with winner index

		RET
	UPDATE_WINNER_STRING ENDP

	
	DRAW_GAME_OVER PROC NEAR

		CALL CLEAR_SCREEN
		
		MOV AH,02h						;set cursor position
		MOV BH,00h						;set page number
		MOV DH,0Bh						;set row
		MOV DL,0Fh						;set column
		INT 10h

		MOV AH,09h
		LEA DX,GAME_OVER_STRING			;load the address of the string
		INT 21h

		MOV AH,02h						;set cursor position
		MOV BH,00h						;set page number
		MOV DH,0Dh						;set row
		MOV DL,0Dh						;set column
		INT 10h

		MOV AH,09h
		LEA DX,GAME_WIN_STRING			;load the address of the string
		INT 21h

		MOV AH,02h						;set cursor position
		MOV BH,00h						;set page number
		MOV DH,15h						;set row
		MOV DL,09h						;set column
		INT 10h

		MOV AH,09h
		LEA DX,REPLAY_STRING			;load the address of the string
		INT 21h
		
		MOV AH,02h						;set cursor position
		MOV BH,00h						;set page number
		MOV DH,17h						;set row
		MOV DL,06h						;set column
		INT 10h

		MOV AH,09h
		LEA DX,EXIT_STRING				;load the address of the string
		INT 21h

		MOV AH,00h						;wait for key input
		INT 16h
		
		CMP AL,'R'						;if key is R restart game
		JE RESTART_GAME
		CMP AL,'r'						;if key is r restart game
		JE RESTART_GAME
		
		CMP AL,'E'						;if key is E exit to main menu
		JE EXIT_TO_MAIN
		CMP AL,'e'						;if key is e exit to main menu
		JE EXIT_TO_MAIN
		RET

		RESTART_GAME:
			MOV GAME_ACTIVE_FLAG,01h	;set game active flag to restart game
			RET

		EXIT_TO_MAIN:
			MOV GAME_ACTIVE_FLAG,00h	;set game active flag to stop game
			MOV CURRENT_SCREEN,00h		;set current screen to main menu
			RET

	DRAW_GAME_OVER ENDP

	
	DRAW_MAIN_MENU PROC NEAR

		CALL CLEAR_SCREEN
		
		MOV AH,02h						;set cursor position
		MOV BH,00h						;set page number
		MOV DH,09h						;set row
		MOV DL,10h						;set column
		INT 10h

		MOV AH,09h
		LEA DX,TOP_STRING				;load the address of the string
		INT 21h

		MOV AH,02h						;set cursor position
		MOV BH,00h						;set page number
		MOV DH,0Ah						;set row
		MOV DL,10h						;set column
		INT 10h

		MOV AH,09h
		LEA DX,PONG_STRING				;load the address of the string
		INT 21h

		MOV AH,02h						;set cursor position
		MOV BH,00h						;set page number
		MOV DH,0Bh						;set row
		MOV DL,10h						;set column
		INT 10h

		MOV AH,09h
		LEA DX,BOTTOM_STRING			;load the address of the string
		INT 21h

		MOV AH,02h						;set cursor position
		MOV BH,00h						;set page number
		MOV DH,12h						;set row
		MOV DL,05h						;set column
		INT 10h

		MOV AH,09h
		LEA DX,SINGLE_PLAYER_STRING		;load the address of the string
		INT 21h

		MOV AH,02h						;set cursor position
		MOV BH,00h						;set page number
		MOV DH,14h						;set row
		MOV DL,06h						;set column
		INT 10h

		MOV AH,09h
		LEA DX,MULTI_PLAYER_STRING		;load the address of the string
		INT 21h

		MOV AH,02h						;set cursor position
		MOV BH,00h						;set page number
		MOV DH,16h						;set row
		MOV DL,0Ah						;set column
		INT 10h

		MOV AH,09h
		LEA DX,QUIT_STRING				;load the address of the string
		INT 21h

		GET_KEY_PRESS:
			MOV AH,00h					;wait for key input
			INT 16h
			
			CMP AL,'S'					;if key is S single player game
			JE SINGLE_PLAYER_GAME
			CMP AL,'s'					;if key is s single player game
			JE SINGLE_PLAYER_GAME
			
			CMP AL,'M'					;if key is M multiplayer game
			JE MULTI_PLAYER_GAME
			CMP AL,'m'					;if key is m multiplayer game
			JE MULTI_PLAYER_GAME
			
			CMP AL,'E'					;if key is E exit game
			JE EXIT_GAME
			CMP AL,'e'					;if key is e exit game
			JE EXIT_GAME
			JMP GET_KEY_PRESS

		SINGLE_PLAYER_GAME:
			MOV CURRENT_SCREEN,01h		;show game screen
			MOV GAME_ACTIVE_FLAG,01h	;set game active flag to restart game
			MOV AI_PLAYER,01h			;set ai player
			RET

		MULTI_PLAYER_GAME:
			MOV CURRENT_SCREEN,01h		;show game screen
			MOV GAME_ACTIVE_FLAG,01h	;set game active flag to restart game
			MOV AI_PLAYER,00h
			RET

		EXIT_GAME:
			CALL QUIT_GAME
		
		RET
	DRAW_MAIN_MENU ENDP

	
	QUIT_GAME PROC NEAR

		MOV AH,00h                   	;set the configuration to video mode
		MOV AL,02h                   	;choose the video mode
		INT 10h    					 	;execute the configuration 
	
		MOV AH,4Ch                   	;terminate program
		INT 21h

		RET
	QUIT_GAME ENDP


	CLEAR_SCREEN PROC NEAR

		MOV AH,00h						;set the configuration for video mode
		MOV AL,13h						;set video mode
		INT 10h							;run the videomode configuration
		
		MOV AH,0Bh						;set the configuration for background color
		MOV BH,00h						;configuration for background color	
		MOV BL,03h						;set it to black
		INT 10h							;run the configuration

		RET
	CLEAR_SCREEN ENDP


CODE ENDS
END
