INCLUDE Irvine32.inc

.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dwExitCode:DWORD

MAX_COLS = 30
MAX_ROWS = 30

.data

	; grid that stores the game of life
	; 0 represents DEAD
	; 1 represents ALIVE
	; NOTE: actual game is stored only between index (1-MAX_ROWS-2) and (1-MAX_COLS-2) inclusive. 
	grid BYTE MAX_ROWS*MAX_COLS DUP ('0')

	; copy of the grid that stores the game of life 
	tempGrid BYTE MAX_ROWS*MAX_COLS DUP ('0')

	; A space to match the spacing of characters drawn vertically/horizontally and represents dead organism
	space BYTE ' '

	; i --> row of the character to be read
	i DWORD ?
	
	; j --> column of the character to be read
	j DWORD ?

	; val --> value to be set at a location i,j in grid[i][j]
	val BYTE ?

	; flag indicates if main grid is to be drawn(=1) or tempGrid(=0)
	drawMain DWORD 1

	; flag indicates if the temp grid is to be copied to main grid or other way. 1 means main = temp(copy temp to main), and 0 means temp = main
	copyToMain DWORD 0


	; Phase 3 flag
	; Determines if the wrapping is to be done row-wise(1) or column-wise(0)
	rowWise DWORD 1 

	; stores the number of alive in the mini 3x3 grid
	numAlive DWORD 0

.code
main PROC

	call getUserInput 

	;call setTheseAlive

	call drawGrid

	call countNeighbors

	push eax
	mov eax, white + (black*16)
	call SetTextColor
	pop eax
		

	INVOKE ExitProcess, 0
	
main ENDP

; FUNCTIONS

; ----------------------
; Name: drawSpace
; Desc: Draws the dead organism character(or ' ') on the screen
; Input: None
; Returns: None. Simply outputs to screen
; ----------------------
drawSpace PROC
	pusha

	mov al, space
	call WriteChar
	popa

	ret
drawSpace ENDP

; ----------------------
; Name: read_ij
; Desc: Reads the character stored in array[i][j]
; Input: i --> row of the character to be read
;		 j --> column of the character to be read
;		 readFromMain --> ; flag indicates if the grid[i][j] is to be read from grid or tempGrid. 1 means read from grid, 0 means read from tempGrid
; Returns: In al, the character stored in array[i][j]
; ----------------------
read_ij PROC uses edx,
	varReadFromMain: DWORD, varI: DWORD, varJ: DWORD

	mov edx, varI
	imul edx, MAX_COLS
	add edx, varJ
	
	cmp varReadFromMain, 1
	je fromMain

	mov al, tempGrid[edx]
	jmp DONE

	fromMain:
		mov al, grid[edx]

	DONE:

	ret
read_ij ENDP

; set_ij
;  - getIndex
;  - goes to getIndex and writes a value there

; ----------------------
; Name: set_ij
; Desc: Set the character stored in array[i][j] = val
; Input: i --> row of the character to be set
;		 j --> column of the character to be set
;		 val --> character that is to be saved in array[i][j]
;		 setInMain --> ; flag indicates if the grid[i][j] is to be set to val in grid or tempGrid. 1 means grid[i][j]=val and 0 means tempGrid[i][j]=val
; Returns: None. Mutates the character stored in array[i][j] to val
; ----------------------
set_ij PROC,
	varSetInMain: DWORD, varI: DWORD, varJ: DWORD, varVal: BYTE

	pushad

	mov edx, varI
	imul edx, MAX_COLS
	add edx, varJ
	mov al, varVal

	cmp varSetInMain, 1
	je inMain

	mov tempGrid[edx], al
	jmp DONE

	inMain:
		mov grid[edx], al

	DONE:

	popad
	ret
set_ij ENDP

; ----------------------
; Name: setTheseAlive
; Desc: sets desired cells in main grid alive to start the simulation of game of life
; Input: None.
; Returns: Updated grid with desired cells set alive(val='1')
; ----------------------
setTheseAlive PROC
	pushad
	
		INVOKE set_ij, 1, 4, 4, '1'
		INVOKE set_ij, 1, 5, 5, '1'
		INVOKE set_ij, 1, 6, 5, '1'
		INVOKE set_ij, 1, 6, 4, '1'
		INVOKE set_ij, 1, 6, 3, '1'

	popad
	ret
setTheseAlive ENDP

getUserInput PROC
	pushad
		
		; exclude gutters
		mov dl, 1
		mov dh, 1
		call Gotoxy

		; exclude gutters

		; ecx represents row(i), edx represents col(j)
		mov ecx, 1
		mov edx, 1

		start:
			call drawGrid			
			call ReadChar
			
			.IF al == 'w'
				dec ecx			

			.ELSEIF al == 'a'
				dec edx
			.ELSEIF al == 's'
				inc ecx
			.ELSEIF al == 'd'
				inc edx
			.ELSEIF al == ' '
				INVOKE read_ij, 1, ecx, edx
				.IF al == '1'
					INVOKE set_ij, 1, ecx, edx, '0'
				.ELSEIF al == '0'
					INVOKE set_ij, 1, ecx, edx, '1'
				.ENDIF

			.ELSEIF al == 'q'
				jmp DONE

			.ENDIF
			jmp start

		DONE:

	popad
	ret
getUserInput ENDP

; ----------------------
; Name: copyGrid
; Desc: Copies the elements from tempGrid to grid or grid to tempGrid based on flag copyToMain
; Input: copyToMain - either 1 or 0
; Returns: Updated grid or temGrid based on flag copyToMain
; ----------------------
copyGrid PROC
	pushad
		mov esi, OFFSET grid
		mov edi, OFFSET tempGrid
		mov ecx, MAX_ROWS*MAX_COLS
		
		cmp copytoMain, 1
		je toMain

		toTemp:
			mov al, [esi]
			mov [edi], al

			add esi, TYPE grid[0]
			add edi, TYPE grid[0]

			loop toTemp

		jmp DONE

		toMain:
			mov al, [edi]
			mov [esi], al

			add esi, TYPE grid[0]
			add edi, TYPE grid[0]

			loop toMain

		DONE:

	popad
	ret
copyGrid ENDP

; ----------------------
; Name: drawGrid
; Desc: Draws the grid of game of life on the screen
; Input: None
; Returns: None. Simply outputs to screen
; ----------------------
drawGrid PROC
	pushad

	mov eax, 1
	call Delay

	push edx
	mov edx, 0
	call gotoxy
	pop edx

	;call Clrscr


	; Number of rows to be printed
	mov ecx, (MAX_ROWS-2)
	
	; esi stores the index of the row of the character being printed, max = MAX_ROWS-1
	mov esi, 1

	OUTER:
		
		push ecx

		; Number of columns to be considered excluding gutter
		mov ecx, (MAX_COLS-2)

		; edi stores the index of the column of the character being printed, max = MAX_COLS-1
		mov edi, 1

		;call goToCenter

		;mov i, esi

		INNER:

			INVOKE read_ij, 1, esi, edi

			cmp al, '1'
			jne INVISIBLE

			; al has the character needed to be printed
			push eax
			mov eax, white + (white*16)
			call SetTextColor
			pop eax
			call drawSpace
			call drawSpace

			jmp DONE

			INVISIBLE:
			push eax
			mov eax, black + (black*16)
			call SetTextColor
			pop eax
			call drawSpace
			;call WriteChar
			call drawSpace

			DONE:

			inc edi
			loop INNER

			call Crlf

		pop ecx
		inc esi

		loop OUTER

	popad

	ret
drawGrid ENDP


; ----------------------
; Name: countNeighbors
; Desc: Counts the neighbors of all cells and stores the results of whether each cell is alive or not in tempGrid. 
;		logic --> tempGrid = next generation, followed by grid = temp grid
; Input: None
; Returns: updated grid
; ----------------------
countNeighbors PROC
	pushad

	; run until the user closes the window to end the game
	start:

		call top_gutter
		call bottom_gutter
		call left_gutter
		call right_gutter
		
		call copy_corners


		; PERFORM SIMULATION
		; Number of rows to be considered excluding gutter
		mov ecx, (MAX_ROWS-2)
	
		; esi stores the index of the row of the character being printed, max = MAX_ROWS-1
		mov esi, 1

		OUTER:
		
			push ecx

			; Number of columns to be considered excluding gutter
			mov ecx, (MAX_COLS-2)

			; edi stores the index of the column of the character being printed, max = MAX_COLS-1
			mov edi, 1

			mov i, esi

			INNER:
				mov j, edi

				; get num alive around the current cell as a 3x3 grid
				call countNumAlive

				cmp numAlive, 1
				jbe DIE

				cmp numAlive, 4
				jae DIE

				cmp numAlive, 3
				je RESURRECT

				cmp numAlive, 2
				je CHECK_SELF_ALIVE
				
				DIE:
					INVOKE set_ij, 0, i, j, '0'
					jmp DONE

				CHECK_SELF_ALIVE:
					INVOKE read_ij, 1, i, j
					cmp al, '1'
					je RESURRECT

					jmp DONE

				RESURRECT:
					INVOKE set_ij, 0, i, j, '1'

				DONE:

				inc edi
				loop INNER

				;call Crlf

			pop ecx
			inc esi

			dec ecx
			jnz OUTER

			mov copyToMain, 1
			call copyGrid

			call drawGrid

		jmp start
	popad
	ret
countNeighbors ENDP

top_gutter PROC
	pushad
	
	mov esi, 1
	mov ecx, MAX_COLS-2

	L1:

		INVOKE read_ij, 1, MAX_ROWS-2, esi

		INVOKE set_ij, 1, 0, esi, al

		inc esi
		loop L1

	popad
	ret
top_gutter ENDP

bottom_gutter PROC
	pushad

	mov esi, 1
	mov ecx, MAX_COLS-2

	L1:
		INVOKE read_ij, 1, 1, esi

		INVOKE set_ij, 1, MAX_ROWS-1, esi, al

		inc esi
		loop L1

	popad
	ret
bottom_gutter ENDP

left_gutter PROC
	pushad

	mov esi, 1
	mov ecx, MAX_ROWS-3

	L1:

		INVOKE read_ij, 1, esi, MAX_COLS-2
		INVOKE set_ij, 1, esi, 0, al

		inc esi
		loop L1

	popad
	ret
left_gutter ENDP

right_gutter PROC
	pushad

	mov esi, 1
	mov ecx, MAX_ROWS-3

	L1:

		INVOKE read_ij, 1, esi, 1
		INVOKE set_ij, 1, esi, MAX_COLS-1, al

		inc esi
		loop L1

	popad
	ret
right_gutter ENDP

copy_corners PROC
	pushad

	;;;;;;;;;;;

	; good bottom-right to gutter top-left
	INVOKE read_ij, 1, MAX_ROWS-2, MAX_COLS-2
	INVOKE set_ij, 1, 0, 0, al

	;;;;;;;;;;;;;
	
	; good bottom-left to gutter top-right
	INVOKE read_ij, 1, MAX_ROWS-2, 0
	INVOKE set_ij, 1, 0, MAX_COLS-1, al

	;;;;;;;;;;;;

	; good top-right to gutter bottom-left
	INVOKE read_ij, 1, 1, MAX_COLS-2
	INVOKE set_ij, 1, MAX_ROWS-1, 0, al

	; good top-left to gutter bottom-right
	INVOKE read_ij, 1, 1, 1
	INVOKE set_ij, 1, MAX_ROWS-1, MAX_COLS-1, al

	;;;;;;;;;;;;;

	popad
	ret
copy_corners ENDP


; ----------------------
; Name: countNumAlive
; Desc: Counts the neighbors of all cells and stores the results of whether each cell is alive or not in tempGrid. 
; Input: i: row of the cell around which the 3x3 grid is considered to count num alive
;		 j: column of the cell around which the 3x3 grid is considered to count num alive
; Returns: numAlive: num alive in the 3x3 cell surrounding grid[i][j]
; ----------------------
countNumAlive PROC
	pushad

	;mov readFromMain, 1

	mov numAlive, 0

	push i
	push j

	dec i
	dec j

	INVOKE read_ij, 1, i, j

	.IF al == '1'
		inc numAlive
	.ENDIF

	inc j
	INVOKE read_ij, 1, i, j

	.IF al == '1'
		inc numAlive
	.ENDIF

	inc j
	INVOKE read_ij, 1, i, j

	.IF al == '1'
		inc numAlive
	.ENDIF

	;;;;;;;;;;

	sub j, 2
	inc i
	INVOKE read_ij, 1, i, j

	.IF al == '1'
		inc numAlive
	.ENDIF

	add j, 2
	INVOKE read_ij, 1, i, j

	.IF al == '1'
		inc numAlive
	.ENDIF

	;;;;;;;;;;;

	sub j, 2
	inc i
	INVOKE read_ij, 1, i, j

	.IF al == '1'
		inc numAlive
	.ENDIF

	inc j
	INVOKE read_ij, 1, i, j

	.IF al == '1'
		inc numAlive
	.ENDIF

	inc j
	INVOKE read_ij, 1, i, j

	.IF al == '1'
		inc numAlive
	.ENDIF

	pop j
	pop i

	popad
	ret
countNumAlive ENDP

END main