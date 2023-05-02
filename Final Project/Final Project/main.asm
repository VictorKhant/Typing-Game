; Author:
; Program Name:
; Program Description:
; Date

INCLUDE Irvine32.inc
.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dwExitCode: DWORD

.data
	str1 BYTE 50 DUP(?)
	ROW = 50
	COL = 7
	twoD BYTE ROW * COL DUP(?)
	twoDWhere WORD ROW DUP(?)
	maxCol BYTE ?
	maxRow BYTE ?
	count DWORD 0
	printedStr DWORD 1
	typing DWORD -1
	msec DWORD ?
	speed DWORD 100
	inputArr BYTE COL DUP(?)
	pos DWORD 0
	error BYTE 0
	doneStr DWORD 0
	finish DWORD 0
	gameOver BYTE "GAME OVER!",0
	endGame BYTE "Type Anything To END...",0
	mistakeMsg BYTE "Mistakes:",0
	mistakes DWORD 0
	againMsg BYTE "Press 'y' to go again, press anykeys to exit:",0
	modeMsg BYTE "Easy(E), Medium(M), Hard(H), Insane(I)", 0
	modePrompt BYTE "Select a mode:",0
	invalidMsg BYTE "INVALID CHOICE!", 0
	isWin DWORD 0
	winMsg BYTE "YOU WON:)",0
.code
BetterRandomRange PROC 
	sub eax, ebx		;set eax to positive number
	call RandomRange
	add eax, ebx		;add back with original lower bound
	ret
BetterRandomRange ENDP

										;esi should hold the offset of twod
RandomString PROC uses ecx ebx eax esi		;return random string and stored in twoD
	mov eax, COL -1			;limit string size
	mov ebx, 2
	call BetterRandomRange
	mov ecx, eax
	inc ecx
	L5:
		mov eax, 26
		call RandomRange	;generate within 26 alphabets
		add eax, 'a'		;move eax to first Alpha
		mov [esi],al		;change the string
		inc esi				;increase to next index
		loop L5
		inc count
	ret
RandomString ENDP

RandomColumn PROC			;generate random column no.
	movzx eax, maxCol		
	sub eax, COL			;fix the margin cases
	call RandomRange
	ret
RandomColumn ENDP

SetMaxXY PROC
	call GetMaxXY			;al=row dl=col
	mov maxRow, al			;save max Y
	mov maxCol, dl			;save max X
	ret
SetMaxXY ENDP
GenerateStrings PROC uses ecx ebx
	mov ecx, 25					;loop counter
	mov ebx, OFFSET twoDWhere
	mov esi, OFFSET twoD
	call Randomize
	L1:
		call RandomString		;create random string in twod
		call RandomColumn		;store random col in al
		mov dl,al				;mov random col num to dl
		mov dh,0				;initialize location to first row
		mov [ebx], dx			;store the location of strings
		add ebx, TYPE twoDWhere	;move next index of location
		add esi, COL			;move next index of twoD
		loop L1
	ret
GenerateStrings ENDP

NextRow PROC						;dx has the row and col num; ax has the index
		inc dh						;move string by 1 row
		mov [twoDWhere + ax], dx	;save new location
	ret
NextRow ENDP
FallingStrings PROC uses eax

	INVOKE SetMaxXY				;set Max row and col
	call GenerateStrings		;generate 25 strings
	mov ecx, 0				    ;loop counter

	call Getmseconds

	add eax, speed
	mov msec, eax
L1:	
	mov ecx, printedStr			;loop counter
	mov eax, 0					;index of twoDWHere
	mov edx, OFFSET twoD		;pointer pointing to twoD
	cmp doneStr, 25
	jz OVER1
	L2:
		push eax
		mov esi, edx
		mov al, [edx]
		mov dl, al
		pop eax
		.IF dl!=0
			mov dx, [twoDWhere + ax]	;get the location of specific string
			cmp dh, maxRow				;If the string reach the button, leave the function
			jz OVER2
			call GotoXY					;go to current location

			push edx
			mov edx, esi

			call WriteString
			
			pop edx
			call NextRow				;store the new location
		.ENDIF
			mov edx, esi				;restore pointer to twoD
			add edx, COL				;next index
			add ax, TYPE twoDWhere		;next index for location

		loop L2
		
L3:
	call DetectInput
	call Getmseconds
	.IF eax >= msec
		call clrscr
			inc printedStr					;increment the number of printed string
			add eax, speed					;delay
			mov msec, eax
	.ELSE
		jmp L3
	.ENDIF
	jmp L1
OVER1:
	mov isWin, 1
OVER2:
	ret
FallingStrings ENDP

SearchTwoD PROC uses esi edi ebx edx ecx	;al has the first char of user input for the string
									;return typing = -1 if not found
	mov esi, 0						;current pos
	mov edi, OFFSET twoD			
	mov ecx, printedStr				;loop counter
	L1:
		mov bl, BYTE PTR [edi]		;get first char
		.IF al==bl					;if the char are the same
			mov typing, esi			;store index
			jmp DONE
		.ENDIF
			inc esi					;next index
			add edi,COL				;next index of strings
			loop L1
	mov typing, -1					;-1 if not found
	DONE:
	ret
SearchTwoD ENDP
ClearInput PROC uses esi
	mov esi, 0						;index counter
	mov ecx, COL					;loop counter
	L1:	
		mov [inputArr + esi],0		;set every index to zero
		inc esi
		loop L1
	ret
ClearInput ENDP
DetectInput PROC uses ebx eax edx ecx esi
	mov esi, OFFSET inputArr
	mov edi, OFFSET twoD
LOOKFORKEY:
	mov eax, 25
	call Delay
	call Readkey					;read key pressed
	jz DONE							;if not pressed, exit

	.IF typing == -1				;if not found the string yet,
		INVOKE SearchTwoD				;search in the two D
	.ENDIF

	.IF typing != -1				;if found alr
		push eax
		mov eax, typing				;find index of twoD array	
		mov edx, COL
		mul edx
		add edi, eax				;move edi to current idex
		pop eax
		mov edx, pos
		
		.IF al== [edi+edx]			;compare al with respective char
			mov error, 0			;if chars are the same, then no error
			add esi,pos					;if not end, store the char to inputArr
			mov [esi],al
			inc pos
			inc edx	
			.IF BYTE PTR [edi+edx] ==0	;check if this index is end of the string
				mov BYTE PTR [edi], 0	;clear the string
				inc doneStr				;increment the completed string
				mov finish, 1
				jmp DONE
			.ENDIF	
		.ELSE
			mov al, [edi+edx]			;if not correct, error
			mov error, al
			inc mistakes
		.ENDIF
	.ENDIF
DONE:
	.IF typing != -1
		mov eax, typing
		mov ebx, TYPE twoDWhere
		mul ebx
		mov dx, [twoDWhere + eax]		;get the position
		dec dh							;decrement one row
		call Gotoxy
		mov edx, OFFSET inputArr	
		mov eax, green + (black*16)
		call SetTextColor				;printed typed chars
		call WriteString
		.IF error != 0
			mov eax, red + (black*16)
			call SetTextColor
			mov al, error
			call WriteChar				;if there is errors, print with red color
		.ENDIF
		mov eax, white + (black*16)		;change back to default
		call SetTextColor
		.IF finish == 1
			mov typing, -1			;set to not found
			call ClearInput			;clear input string
			mov pos,0				;set input array pos to 0
			mov finish, 0
		.ENDIF
	.ENDIF
	ret
DetectInput ENDP
CleanUp PROC
	mov ecx, ROW*COL				;delete all the strings in twoD and reset the flags
	mov esi, OFFSET twoD
L1:
	mov BYTE PTR[esi], 0
	inc esi
	loop L1
	call ClearInput
	mov count, 0
	mov printedStr, 1
	mov typing, -1
	mov pos, 0
	mov error, 0
	mov doneStr, 0
	mov finish, 0
	mov isWin, 0
	ret
CleanUp ENDP
Game PROC 
L1:
	call Startup					;startup screen
	call FallingStrings				;typing process and display
	mov dh, 13
	mov dl,51
	call Gotoxy
	.IF isWin == 1
		mov edx, OFFSET winMsg			;win message
	.ELSE
		mov edx, OFFSET gameOver		;gameOver generator
	.ENDIF
	call WriteString
	mov dh, 14
	mov dl, 51
	call Gotoxy
	mov eax, red + (black*16)
	call SetTextColor
	mov edx, OFFSET mistakeMsg
	call WriteString
	mov eax, mistakes
	call WriteDec
	mov eax, white + (black*16)
	call SetTextColor

	mov dh, 15
	mov dl, 34
	call Gotoxy
	mov edx, OFFSET againMsg
	call WriteString
	mov eax, 1000
	call delay
	call ReadChar
	call Clrscr
	call Cleanup
	cmp al, 'y'
		jz L1
	ret
Game ENDP

Startup PROC
L1:
	mov dh, 14
	mov dl, 40
	call Gotoxy
	mov edx, OFFSET modeMsg				;output mode message
	call WriteString
	mov dh, 15
	mov dl, 51
	call Gotoxy
	mov edx, OFFSET modePrompt			;output mode prompt
	call WriteString
	call ReadChar
	.IF al == 'E' || al == 'e'
		mov speed, 1500
	.ELSEIF al == 'M' || al == 'm'
		mov speed, 1200
	.ELSEIF al == 'H' || al == 'h'
		mov speed, 900
	.ELSEIF al == 'I' || al == 'i'
		mov speed, 700
	.ELSE
		call Clrscr
		mov edx, OFFSET invalidMsg		;if Invalid show again:
		call WriteString
		jmp L1
	.ENDIF
	call Clrscr
	ret
Startup ENDP
main PROC
	call Game
	INVOKE ExitProcess, 0
main ENDP
END main
