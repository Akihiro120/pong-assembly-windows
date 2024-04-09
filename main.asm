extern exit
extern printf

; raylib
extern InitWindow
extern CloseWindow
extern WindowShouldClose
extern BeginDrawing
extern EndDrawing
extern ClearBackground
extern DrawFPS
extern SetTargetFPS
extern DrawRectangleV
extern GetFrameTime
extern DrawCircleV
extern Vector2Length
extern Clamp
extern IsKeyPressed
extern IsKeyDown
extern DrawLineEx
extern DrawCircleLinesV
extern DrawRing

section .text

; function - box vs circle collision
; rcx: rectangle <- passed via address
; rdx: circle-position <- passed via address
; r8: circle-radius <- passed via address
check_collision_box_circle:
	
	; setup stack frame
	push rbp
	mov rbp, rsp

	; allocate stack 64 bytes
	sub rsp, 64

	;------------------------------------------
	; center.x, rsp
	movd xmm1, dword [r8]
	movd xmm0, dword [rdx]
	addss xmm0, xmm1
	movd [rsp], dword xmm0						; move the value of xmm0 into [rsp]			- center.x
	; center.y, rsp + 4
	movd xmm1, dword [r8]
	movd xmm0, dword [rdx + 4]
	addss xmm0, xmm1
	movd [rsp + 4], dword xmm0					; move the value of xmm0 into [rsp + 4]		- center.y

	;------------------------------------------
	; calculate aabb info
	;------------------------------------------
	mov rdi, 2
	cvtsi2ss xmm1, rdi							; convert the int 2, to a single scalar 2.0
	; aabb_half_extents.x
	movd xmm0, dword [rcx + 8]
	divss xmm0, xmm1
	movd [rsp + 8], dword xmm0					; move the value of xmm0 into [rsp + 8]		- aabb_half_extents.x
	; aabb_half_extents.y
	movd xmm0, dword [rcx + 12]
	divss xmm0, xmm1
	movd [rsp + 12], dword xmm0					; move the value of xmm0 into [rsp + 12]	- aabb_half_extents.y

	;------------------------------------------
	; aabb_center.x
	movd xmm0, dword [rcx]
	movd xmm1, dword [rsp + 8]
	addss xmm0, xmm1
	movd [rsp + 16], xmm0						; move the value of xmm0 into [rsp + 16]    - aabb_center.x
	; aab_center.y
	movd xmm0, dword [rcx + 4]
	movd xmm1, dword [rsp + 12]
	addss xmm0, xmm1
	movd [rsp + 20], xmm0						; move the value of xmm0 into [rsp + 20]	- aabb_center.y

	;------------------------------------------
	; difference.x
	movd xmm0, dword [rsp]
	movd xmm1, dword [rsp + 16]
	subss xmm0, xmm1
	movd [rsp + 24], xmm0						; move the value of xmm0 into [rsp + 24]	- difference.x
	; difference.y
	movd xmm0, dword [rsp + 4]
	movd xmm1, dword [rsp + 20]
	subss xmm0, xmm1
	movd [rsp + 28], xmm0						; move the value of xmm0 into [rsp + 28]	- difference.y

	;------------------------------------------
	; clamped.x
	movd xmm0, dword [rsp + 24]
	movd xmm1, dword [rsp + 8]
	movd xmm3, dword [negative_one]				; move negative one into xmm3
	mulss xmm1, xmm3							; negate the xmm1 register
	movd xmm2, dword [rsp + 8]
	call Clamp
	movd [rsp + 32], xmm0						; move the value of xmm0 into [rsp + 32]	- clamped.x
	; clamped.y
	movd xmm0, dword [rsp + 28]
	movd xmm1, dword [rsp + 12]
	movd xmm3, dword [negative_one]
	mulss xmm1, xmm3
	movd xmm2, dword [rsp + 12]
	call Clamp
	movd [rsp + 36], xmm0						; move the value of xmm0 into [rsp + 36]	- clamped.y

	;-----------------------------------------
	; closest.x
	movd xmm0, dword [rsp + 16]
	movd xmm1, dword [rsp + 32]
	addss xmm0, xmm1
	movd [rsp + 40], xmm0						; move the value of xmm0 into [rsp + 40]	- closest.x
	; closest.y
	movd xmm0, dword [rsp + 20]
	movd xmm1, dword [rsp + 36]
	addss xmm0, xmm1
	movd [rsp + 44], xmm0						; move the value of xmm0 into [rsp + 44]	- closest.y

	;-----------------------------------------
	; difference.x (new)
	movd xmm0, dword [rsp + 40]
	movd xmm1, dword [rsp]
	subss xmm0, xmm1
	movd [rsp + 24], xmm0						; move the value of xmm0 into [rsp + 24] <- location of difference.x
	; difference.y (new)
	movd xmm0, dword [rsp + 44]
	movd xmm1, dword [rsp + 4]
	subss xmm0, xmm1
	movd [rsp + 28], xmm0						; move the value of xmm0 into [rsp + 28] <- location of difference.y

	;----------------------------------------
	mov rcx, qword [rsp + 24]					; move the value of difference [x, y] <- quadword, into the rcx register
	call Vector2Length							; the output of the function is in xmm0
	movd xmm1, dword [r8]						; move the value in r8 (circle_radius) into the xmm1 register
	ucomiss xmm0, xmm1
	jbe .check_collision_box_circle_true
	jmp .check_collision_box_circle_false
	
.check_collision_box_circle_true:
	mov rax, 1									; in the case that there is collision, RAX will return 1
	jmp .check_collision_box_circle_end

.check_collision_box_circle_false:
	mov rax, 0									; in the case that there is no collision, RAX will return 0
	jmp .check_collision_box_circle_end

.check_collision_box_circle_end:
	add rsp, 64									; deallocate the stack of 64 bytes
		
	; reset stack frame
	mov rsp, rbp
	pop rbp

	ret
	
section .data
	; formats
	float_format: db "%i", 0x0A, 0						; format for floats

	; window related
	WINDOW_WIDTH: dd 800
	WINDOW_HEIGHT: dd 600
	WINDOW_TITLE: db "Pong in Assembly :)", 0

	clear_color: db 0, 0, 0, 255

	negative_one: dd -1.0

	; ball
	ball_position:										; ball position
		dd 400.0
		dd 300.0

	ball_displacement:									; ball displacement over time
		dd 0.0
		dd 0.0

	ball_radius: dd 8.0

	ball_velocity:										; balls velocity
		dd 250.0
		dd 100.0

	; color
	ball_color: db 255, 255, 255, 255					; ball color (WHITE)
	grey_color: db 100, 100, 100, 255

	; paddle
	paddle_1_rectangle:									; paddle 1 rectangle
		dd 100.0
		dd 236.0
		dd 32.0
		dd 128.0

	paddle_2_rectangle:									; paddle 2 rectangle
		dd 668.0
		dd 236.0
		dd 32.0
		dd 128.0
	
	paddle_move_speed:
		dd -200.0
		dd 200.0

	; timing related
	delta_time: dd 0.0									; deltatime
	physics_delta_time: dd 0.0							; physics delta time, use for deltatime calculation in simulations
	sub_steps: dd 16									; number of physics ticks per frame
	physics_loop_index: dd 16							; index for the loop in the physics loop

	; score
	score_left: dd 0
	score_right: dd 0 
	start: dd 1

	; keys
	W_KEY: equ 87
	S_KEY: equ 83

	UP_KEY: equ 265
	DOWN_KEY: equ 264

	; line
	line_start_pos:
		dd 400.0
		dd 0.0
	
	line_end_pos:
		dd 400.0
		dd 600.0

	line_thickness: 
		dd 1.0

	; circle
	center_circle_pos:
		dd 400
		dd 300
	
	center_circle_radius:
		

section .text
global main

main:
	; stack frame
	push rbp											; create a stack alignment of 16 bytes
	mov rbp, rsp

	; initialize window
	mov rcx, [WINDOW_WIDTH]								; set the window width
	mov rdx, [WINDOW_HEIGHT]							; set the window height
	mov r8, WINDOW_TITLE								; set the window title
	call InitWindow										; call the InitWindow function

	;mov rcx, 144										; set the framerate cap to 144
	;call SetTargetFPS

.render_loop:
	; window should close
	call WindowShouldClose								; call the WindowShouldClose function, either 0, or 1 will be returned in rax
	test rax, rax										; test rax against itself
	jne .exit_program									; exit the program if the window should close

	; drawing
	call BeginDrawing									; start drawing, called via BeginDrawing

	; clear background
	mov rcx, [clear_color]								; clear the canvas
	call ClearBackground								; call the ClearBackground function, takes in the color to clear the screen with

	; delta time
	call GetFrameTime									; get the current delta time, output is in xmm0
	movss dword [delta_time], xmm0						; store the delta time output in a double word variable
	
	; game related
	mov rdi, [start]									; see if the game has started
	test rdi, rdi										
	jnz .startgame_if									; if the game has started allow for updates
	jmp .startgame_if_end								; else remain in idle

	.startgame_if:										; update loop						
		mov rcx, [sub_steps]							; stores the value of the substeps variable in rcx
		mov [physics_loop_index], rcx					; when the loop resets we set the physics_loop_index to the substeps

		movd xmm0, dword [delta_time]					; move the value in teh delta time variable into xmm0
		cvtsi2ss xmm1, dword [sub_steps]				; we convert substeps to a single scalar variable
		divss xmm0, xmm1								; perform division on the delta time, and the substeps
		movd [physics_delta_time], xmm0					; the output will give our physics_delta_time
		.update_physics:
			call .update_ball							; update the ball's physics 
				
			; update loop
			dec dword [physics_loop_index]				; update the loop index, via decrementing the index
			mov edi, dword [physics_loop_index]			; check if the index has reached zero
			mov rsi, 0
			cmp	rdi, rsi
			jg .update_physics							; continue updating physics
			jmp .update_physics_end						; move on to the next updates
		
		.update_physics_end:							; update the paddles
			call .update_paddle_1						;
			call .update_paddle_2						;
		
			jmp .startgame_if_end						

	.startgame_if_end:

	call .render_ball									; rendering of the sprites
	call .render_paddle_1
	call .render_paddle_2

	; draw line
	mov rcx, qword [line_start_pos]
	mov rdx, qword [line_end_pos]
	movd xmm2, dword [line_thickness]
	mov r9d, dword [grey_color]
	call DrawLineEx

	; draw fps
	mov rcx, 10
	mov rdx, 10
	call DrawFPS										; draws an fps counter on the top left

	call EndDrawing

	; loop the render loop
	jmp .render_loop									; loop the render loop

.exit_program:											; upon the closing of the window
	; close window	
	call CloseWindow									; destroy and close the current window instance

	; end program
	mov rcx, 0
	call exit

	; end stack frame
	mov rsp, rbp										; deallocate the stack frame
	pop rbp

.update_ball:
	; new stack frame
	push rbp											; reallocate a new stack frame
	mov rbp, rsp	

	; move the ball
	movd xmm2, dword [physics_delta_time]				; use the physics delta time	
	;x
	movd xmm0, dword [ball_position]
	movd xmm1, dword [ball_velocity]
	mulss xmm1, xmm2
	addss xmm0, xmm1
	movd dword [ball_position], xmm0					; move the ball position based on the formula, position + (velocity * delta_time)
	
	;y
	movd xmm0, dword [ball_position + 4]
	movd xmm1, dword [ball_velocity + 4]
	mulss xmm1, xmm2
	addss xmm0, xmm1
	movd dword [ball_position + 4], xmm0

	; check if collide with bounds of the screen
	; ------------------------------------------------------------
	; x
	movd xmm0, dword [ball_position]
	movd xmm2, dword [ball_velocity]
	movd xmm3, dword [physics_delta_time]
	mulss xmm2, xmm3
	addss xmm0, xmm2
	movd xmm1, dword [ball_radius]
	addss xmm0, xmm1
	cvtsi2ss xmm1, dword [WINDOW_WIDTH]
	ucomiss xmm0, xmm1										; determine if the ball has reached the window(bottom/right) border
	jae .invert_x_vel										; invert the x-velocity

	movd xmm0, dword [ball_position]
	movd xmm2, dword [ball_velocity]
	movd xmm3, dword [physics_delta_time]
	mulss xmm2, xmm3
	addss xmm0, xmm2
	movd xmm1, dword [ball_radius]
	subss xmm0, xmm1
	mov rdi, 0
	cvtsi2ss xmm1, rdi
	ucomiss xmm0, xmm1
	jbe .invert_x_vel										; invert the x-velocity

	; ------------------------------------------------------------ ; determine if the ball ever reachs the top/left bounds of the border
	; y
	movd xmm0, dword [ball_position + 4]
	movd xmm2, dword [ball_velocity + 4]
	movd xmm3, dword [physics_delta_time]
	mulss xmm2, xmm3
	addss xmm0, xmm2
	movd xmm1, dword [ball_radius]
	subss xmm0, xmm1
	mov rdi, 0
	cvtsi2ss xmm1, rdi
	ucomiss xmm0, xmm1
	jbe .invert_y_vel

	movd xmm0, dword [ball_position + 4]
	movd xmm2, dword [ball_velocity + 4]
	movd xmm3, dword [physics_delta_time]
	mulss xmm2, xmm3
	addss xmm0, xmm2
	movd xmm1, dword [ball_radius]
	addss xmm0, xmm1
	cvtsi2ss xmm1, dword [WINDOW_HEIGHT]
	ucomiss xmm0, xmm1
	jae .invert_y_vel
	
	; ------------------------------------------------------------ do collision checks on the ball and paddle based on the circle vs box collision formula
	; paddle
	
	mov rdx, ball_displacement
	
	; ----------------------------------------------- vertical
	movd xmm0, dword [ball_position]
	movd [rdx], dword xmm0

	movd xmm0, dword [ball_position + 4]
	movd xmm1, dword [ball_velocity + 4]
	movd xmm2, dword [physics_delta_time]
	mulss xmm1, xmm2
	addss xmm0, xmm1
	movd [rdx + 4], dword xmm0										; move the ball ahead via velocity

	; paddle 1 collision
	mov rcx, paddle_1_rectangle
	mov r8, ball_radius
	call check_collision_box_circle
	test rax, rax
	jnz .invert_y_vel

	; paddle 2 collision
	mov rcx, paddle_2_rectangle
	mov r8, ball_radius
	call check_collision_box_circle
	test rax, rax
	jnz .invert_y_vel

	; ----------------------------------------------- horizontal
	movd xmm0, dword [ball_position]
	movd xmm1, dword [ball_velocity]
	movd xmm2, dword [physics_delta_time]
	mulss xmm1, xmm2
	addss xmm0, xmm1
	movd [rdx], dword xmm0

	movd xmm0, dword [ball_position + 4]
	movd [rdx + 4], dword xmm0

	; paddle 1 collision
	mov rcx, paddle_1_rectangle
	mov r8, ball_radius
	call check_collision_box_circle
	test rax, rax
	jnz .invert_x_vel

	; paddle 2 collision
	mov rcx, paddle_2_rectangle
	mov r8, ball_radius
	call check_collision_box_circle
	test rax, rax
	jnz .invert_x_vel

	jmp .update_ball_end

	; x
	.invert_x_vel:														; inverse the x-velocity, by multiplying the x coord by -1
		movd xmm0, dword [ball_velocity]
		movd xmm1, dword [negative_one]
		mulss xmm0, xmm1
		movd dword [ball_velocity], xmm0

		jmp .update_ball_end

	; y
	.invert_y_vel:														; inverse the y-velocity, by multiplying the y corrd by -1
		movd xmm0, dword [ball_velocity + 4]
		movd xmm1, dword [negative_one]
		mulss xmm0, xmm1
		movd dword [ball_velocity + 4], xmm0

		jmp .update_ball_end

.update_ball_end:
	
	; end stack frame
	mov rsp, rbp
	pop rbp

	ret

.render_ball:															; render the ball
	push rbp
	mov rbp, rsp

	; draw ball
	mov rcx, qword [ball_position]
	movd xmm1, dword [ball_radius]
	mov r8d, dword [ball_color]
	call DrawCircleV

	mov rsp, rbp
	pop rbp

	ret

.update_paddle_1:
	mov ecx, W_KEY
	call IsKeyDown
	test al, al

	jnz	.update_paddle_1_move_paddle_up
	jmp .update_paddle_1_move_paddle_end_up

	.update_paddle_1_move_paddle_up:

		movd xmm0, dword [paddle_1_rectangle + 4]
		movd xmm1, dword [paddle_move_speed]
		movd xmm2, dword [delta_time]
		mulss xmm1, xmm2
		addss xmm0, xmm1
		movd [paddle_1_rectangle + 4], dword xmm0

		jmp .update_paddle_1_move_paddle_end_up

	.update_paddle_1_move_paddle_end_up:

		mov ecx, S_KEY
		call IsKeyDown
		test al, al

		jnz	.update_paddle_1_move_paddle_down
		jmp .update_paddle_1_move_paddle_end_down

		.update_paddle_1_move_paddle_down:

			movd xmm0, dword [paddle_1_rectangle + 4]
			movd xmm1, dword [paddle_move_speed + 4]
			movd xmm2, dword [delta_time]
			mulss xmm1, xmm2
			addss xmm0, xmm1
			movd [paddle_1_rectangle + 4], dword xmm0

			jmp .update_paddle_1_move_paddle_end_down

		.update_paddle_1_move_paddle_end_down:

			ret

.update_paddle_2:
	mov ecx, UP_KEY
	call IsKeyDown
	test al, al

	jnz	.update_paddle_2_move_paddle_up
	jmp .update_paddle_2_move_paddle_end_up

	.update_paddle_2_move_paddle_up:

		movd xmm0, dword [paddle_2_rectangle + 4]
		movd xmm1, dword [paddle_move_speed]
		movd xmm2, dword [delta_time]
		mulss xmm1, xmm2
		addss xmm0, xmm1
		movd [paddle_2_rectangle + 4], dword xmm0

		jmp .update_paddle_2_move_paddle_end_up

	.update_paddle_2_move_paddle_end_up:

		mov ecx, DOWN_KEY
		call IsKeyDown
		test al, al

		jnz	.update_paddle_2_move_paddle_down
		jmp .update_paddle_2_move_paddle_end_down

		.update_paddle_2_move_paddle_down:

			movd xmm0, dword [paddle_2_rectangle + 4]
			movd xmm1, dword [paddle_move_speed + 4]
			movd xmm2, dword [delta_time]
			mulss xmm1, xmm2
			addss xmm0, xmm1
			movd [paddle_2_rectangle + 4], dword xmm0

			jmp .update_paddle_2_move_paddle_end_down

		.update_paddle_2_move_paddle_end_down:

			ret

.render_paddle_1:														; render paddle 1
	push rbp
	mov rbp, rsp

	mov rcx, qword [paddle_1_rectangle]
	mov rdx, qword [paddle_1_rectangle + 8]
	mov r8d, dword [ball_color]
	call DrawRectangleV

	mov rsp, rbp
	pop rbp

	ret

.render_paddle_2:														; render paddle 2
	push rbp
	mov rbp, rsp

	mov rcx, qword [paddle_2_rectangle]
	mov rdx, qword [paddle_2_rectangle + 8]
	mov r8d, dword [ball_color]
	call DrawRectangleV

	mov rsp, rbp
	pop rbp

	ret
