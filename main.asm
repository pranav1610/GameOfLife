INCLUDE Irvine32.inc

.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dwExitCode:DWORD

MAX_COLS = 16
MAX_ROWS = 16

.data

	; grid that stores the game of life
	; 0 represents DEAD
	; 1 represents ALIVE
	; NOTE: actual game is stored only between index (1-MAX_ROWS-2) and (1-MAX_COLS-2) inclusive. 
	grid BYTE MAX_ROWS*MAX_COLS DUP ('0')

	; copy of the grid that stores the game of life 
	tempGrid BYTE MAX_ROWS*MAX_COLS DUP ('0')

	; character representing the organism
	organism BYTE 'O'

	; A space to match the spacing of characters drawn vertically/horizontally and represents dead organism
	space BYTE ' '

	; Location where broad starts
	gridX BYTE ?
	gridY BYTE ? 

	; i --> row of the character to be read
	i DWORD ?
	
	; j --> column of the character to be read
	j DWORD ?

	; temporary row of the character to be read
	tempI DWORD ?
	
	; temporary column of the character to be read
	tempJ DWORD ?

	; val --> value to be set at a location i,j in grid[i][j]
	val BYTE ?

	; Temporarily stores the index of a character
	tempIndex DWORD ?

	; Stores the character in above index
	tempChar BYTE ?

	; flag indicates if main grid is to be drawn(=1) or tempGrid(=0)
	drawMain DWORD 1

	; flag indicates if the temp grid is to be copied to main grid or other way. 1 means main = temp(copy temp to main), and 0 means temp = main
	copyToMain DWORD 0

	; flag indicates if the grid[i][j] is to be read from grid or tempGrid. 1 means read from grid, 0 means read from tempGrid
	readFromMain DWORD 1

	; flag indicates if the grid[i][j] is to be set to val in grid or tempGrid. 1 means grid[i][j]=val and 0 means tempGrid[i][j]=val
	setInMain DWORD 1

	; Phase 3 flag
	; Determines if the wrapping is to be done row-wise(1) or column-wise(0)
	rowWise DWORD 1 

	; stores the number of alive in the mini 3x3 grid
	numAlive DWORD 0



	testStr BYTE "here", 0

	

.code
main PROC

	; get the optimal start position of grid drawing
	call GetMaxXY

	mov gridX,al

	; mov up to a length that equals half the grid to center the grid
	sub dl, MAX_ROWS*2
	mov gridY, dl

	;call initGrid

	call setTheseAlive

	call drawGrid

	push eax
	mov eax, yellow + (black*16)
	call SetTextColor
	pop eax

	call countNeighbors

	push eax
	mov eax, white + (black*16)
	call SetTextColor
	pop eax
		

	INVOKE ExitProcess, 0
	
main ENDP

; FUNCTIONS

; ----------------------
; Name: drawOrganism
; Desc: Draws the organism character(or 'O') on the screen
; Input: None
; Returns: None. Simply outputs to screen
; ----------------------
drawOrganism PROC
	pusha
	mov al, organism
	call WriteChar

	popa
	ret
drawOrganism ENDP

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
read_ij PROC uses edx
	mov edx, i
	imul edx, MAX_COLS
	add edx, j
	
	cmp readFromMain, 1
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
set_ij PROC
	pushad

	mov edx, i
	imul edx, MAX_COLS
	add edx, j
	mov al, val

	cmp setInMain, 1
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
; Name: initGrid
; Desc: Initalize the grid as follows:
;			1. Set the border as a 'gutter' or character 0
;			2. Set all remaining cells between 1 & MAX_ROWS-2 and 1 and MAX_COLS-2 to 0 indicating they are dead
;			3. Set alive only desired characters to play. Alive is defined by setting that cell = 1
; Input: None
; Returns: None. Mutates the character stored in grid
; ----------------------
initGrid PROC
	pushad
		
	; Number of rows to be set
	mov ecx, (MAX_ROWS-1)
	
	; esi stores the index of the row of the character being printed, max = MAX_ROWS-1
	mov esi, 0

	; Value to be set to entire grid to begin with
	mov val, '0'

	OUTER:
		
		push ecx
		mov ecx, (MAX_COLS-1)

		; edi stores the index of the column of the character being printed, max = MAX_COLS-1
		mov edi, 0

		mov i, esi

		INNER:
			mov j, edi
			mov setInMain, 1

			; parameters i, j, setInMain, and val are set, call grid[i][j] = val now.
			call set_ij

			mov setInMain, 0
			call set_ij

			inc edi
			loop INNER

		pop ecx
		inc esi

		loop OUTER

	; reset flag
	mov setInMain, 0

	popad
	ret
initGRID ENDP

; ----------------------
; Name: setTheseAlive
; Desc: sets desired cells in main grid alive to start the simulation of game of life
; Input: None.
; Returns: Updated grid with desired cells set alive(val='1')
; ----------------------
setTheseAlive PROC
	pushad
		mov setInMain, 1
		mov val, '1'

		mov i, 4
		mov j, 3
		call set_ij

		mov i, 4
		mov j, 4
		call set_ij

		mov i, 4
		mov j, 5
		call set_ij
		
		mov val, '0'
		mov setInMain, 0
	popad
	ret
setTheseAlive ENDP


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

	mov eax, 1000
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

		mov i, esi

		INNER:
			mov j, edi

			mov readFromMain, 1

			; i and j set, print character to screen
			call read_ij

			cmp al, '1'
			jne INVISIBLE

			call WriteChar

			; al has the character needed to be printed
			;push eax
			;mov eax, white + (white*16)
			;call SetTextColor
			;pop eax
			call drawSpace
			;call drawSpace

			jmp DONE

			INVISIBLE:
			;push eax
			;mov eax, black + (black*16)
			;call SetTextColor
			;pop eax
			;call drawSpace
			call WriteChar
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

goToCenter PROC
	pusha

	mov dl, gridX
	mov dh, gridY

	call Gotoxy

	; next row to be printed below current location, so (x,y + 1) if curr = (x,y)
	inc dh
	mov gridY, dh

	popa
	ret
goToCenter ENDP


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
		
		; PERFORM WRAPPING
		; row-wise wrapping
		mov rowWise, 1

		; row MAX_ROWS-2 to top gutter(row 0)
		mov tempI, MAX_ROWS-2
		mov tempJ, 0
		call wrap_elements

		; row MAX_ROWS-1 to row 1
		mov tempI, MAX_ROWS-1
		mov tempJ, 1
		call wrap_elements

		; column-wise wrapping
		mov rowWise, 0
		
		; col MAX_COLS-2 to left gutter(column 0)
		mov tempI, MAX_COLS-2
		mov tempJ, 0
		call wrap_elements

		; row MAX_COLS-1 to row 1
		mov tempI, MAX_COLS-1
		mov tempJ, 1
		call wrap_elements


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

				cmp numAlive, 2
				jbe DIE

				cmp numAlive, 5
				jae DIE

				cmp numAlive, 3
				je RESURRECT
			

				DIE:
					mov val, '0'
					mov setInMain, 0
					call set_ij
					jmp DONE

				RESURRECT:
					mov val, '1'
					mov setInMain, 0
					call set_ij

				DONE:

				inc edi
				loop INNER

				call Crlf

			pop ecx
			inc esi

			loop OUTER

			mov copyToMain, 1
			call copyGrid
			call drawGrid

		jmp start
	popad
	ret
countNeighbors ENDP

; ----------------------
; Name: wrap_elements
; Desc: Copies elements from row/col tempI to row/col tempJ respectively
; Input: tempI: row/col that needs to be copied to row/col tempJ
;		 tempJ: row/col where row/col tempI is copied
; Returns: Updated grid such that the gutter copies what's in good row/col
; ----------------------
wrap_elements PROC
	pushad
	
	push i
	push j

	mov ecx, MAX_ROWS

	; indexed addressing for changing row/col based on rowWise flag
	mov esi, 0
	
	cmp rowWise, 1
	je ROW
	
	; COLUMN-WISE
	
		L2:
			mov i, esi
			mov ebx, tempI
			mov j, ebx
			call read_ij

			mov val, al

			mov ebx, tempJ
			mov j, ebx
			mov setInMain, 1
			call set_ij

			inc esi
			loop L2

	jmp DONE


	; ROW-WISE
	ROW:
		
		
		L1:
			mov j, esi
			mov ebx, tempI
			mov i, ebx
			call read_ij

			mov val, al

			mov ebx, tempJ
			mov i, ebx
			mov setInMain, 1
			call set_ij

			inc esi
			loop L1

	DONE:

	pop j
	pop i

	popad
	ret 8
wrap_elements ENDP	


; ----------------------
; Name: countNumAlive
; Desc: Counts the neighbors of all cells and stores the results of whether each cell is alive or not in tempGrid. 
; Input: i: row of the cell around which the 3x3 grid is considered to count num alive
;		 j: column of the cell around which the 3x3 grid is considered to count num alive
; Returns: numAlive: num alive in the 3x3 cell surrounding grid[i][j]
; ----------------------
countNumAlive PROC
	pushad

	mov readFromMain, 1

	mov numAlive, 0

	push i
	push j

	dec i
	dec j
	call read_ij

	.IF al == '1'
		inc numAlive
	.ENDIF

	inc j
	call read_ij
	.IF al == '1'
		inc numAlive
	.ENDIF

	inc j
	call read_ij
	.IF al == '1'
		inc numAlive
	.ENDIF

	;;;;;;;;;;

	sub j, 2
	inc i

	call read_ij
	.IF al == '1'
		inc numAlive
	.ENDIF

	inc j
	call read_ij
	.IF al == '1'
		inc numAlive
	.ENDIF

	inc j
	call read_ij
	.IF al == '1'
		inc numAlive
	.ENDIF

	;;;;;;;;;;;

	sub j, 2
	inc i

	call read_ij
	.IF al == '1'
		inc numAlive
	.ENDIF

	inc j
	call read_ij
	.IF al == '1'
		inc numAlive
	.ENDIF

	inc j
	call read_ij
	.IF al == '1'
		inc numAlive
	.ENDIF

	pop j
	pop i

	popad
	ret
countNumAlive ENDP

END main