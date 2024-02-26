.286
.model tiny
.code
org 100h

RegStrLen			equ 9d

NumLockScanCode		equ 45h
InsertScanCode		equ 52h

FnMaxHeight			equ 24D
FnMaxWidth			equ 80d

FnHeight 			equ 15d
FnWidth				equ 12d
FnLineSize			equ 160d
FnLeftCornerX		equ 42d
FnLeftCornerY		equ 6d

FnStarSym			equ 2ah
FnStandartSet1_code equ 31h
FnStandartSet2_code equ 32h
FnStandartSet3_code equ 33h

FnSetSize			equ 9d

FnCMDArgsAddr		equ 80h
FnColor				equ 30h

LOCALS @@
Start:
		jmp main

		include marcos.asm
		include strtonum.asm

main:
		mov ax, 1234h
		lea cx, RegArray
		add cx, 4
		call WriteRegToVar


		mov ax, 3509h		; change 09 int vector
		int 21h

		mov Old09ofs, bx
		mov bx, es
		mov Old09seg, bx
		push 0
		pop es
		mov bx, 4 * 09h

		cli

		mov es:[bx], offset New09
		push cs
		pop ax

		mov es:[bx + 2], ax

		sti

		mov ax, 3508h			; change 08 int vector
		int 21h

		mov Old08ofs, bx
		mov bx, es
		mov Old08seg, bx
		push 0
		pop es
		mov bx, 4 * 08h

		cli

		mov es:[bx], offset New08
		push cs
		pop ax

		mov es:[bx + 2], ax

		sti

		mov ax, 3100h			; TSR
		mov dx, offset EOP

		shr dx, 4
		inc dx

		int 21h

EndSym			db '$'
StandartSet1	db '/-\| |\-/'
Header_name		db 'Hello!$'

cs_str      db 'CS: 0000$'

is_pressed		db 0

HEX_alph		db '0123456789ABCDEF'

RegArray		db 'AX: 0000$'
				db 'BX: 0000$'
				db 'CX: 0000$'
				db 'DX: 0000$'
				db 'SI: 0000$'
				db 'DI: 0000$'
				db 'BP: 0000$'
				db 'SP: 0000$'
				db 'DS: 0000$'
				db 'ES: 0000$'
				db 'SS: 0000$'
				db 'IP: 0000$'
				db 'CS: 0000$'


New09	proc

		push ds bp di si cx dx ax bx es

		push cs
		pop ds

		GetButtFromKbrd

		mov ch, InsertScanCode
		mov bh, 80h
		or ch, bh

		cmp al, ch
		je @@viewer_on				; if (button == insert) @@viewer_on

		mov ch, NumLockScanCode
		mov bh, 80h
		or ch, bh

		cmp al, ch
		je @@viewer_off				; if (button == NumLock) @@viewer_off

		jmp @@go_out

@@viewer_off:
		lea bx, is_pressed			; is_pressed = false
		push ds
		pop es
		mov byte ptr es:[bx], 0h
		jmp @@go_out

@@viewer_on:
		lea bx, is_pressed			; is_pressed = true
		push ds
		pop es
		mov byte ptr es:[bx], 1h

@@go_out:
		pop es bx ax dx cx si di bp ds

		JmpFar

Old09ofs	dw 0
Old09seg	dw 0

		iret
endp

New08	proc
		push ss es ds sp bp di si dx cx bx ax	; calling WriteReg

		push cs
		pop ds

		cmp is_pressed, 1h			; if (is_pressed == true) go_out
		jne @@go_out

		EStoVideoMem

		lea bx, StandartSet1		; push stack[1] arg
		push bx

		lea bx, Header_name			; push stack[0] arg
		push bx

		mov bx, FnLeftCornerX * 2 + FnLeftCornerY * FnLineSize
		mov ch, FnHeight
		mov dx, FnWidth
		mov ah, FnColor

		Call WriteFrame

		EStoVideoMem
		mov ah, FnColor

		call WriteReg

@@go_out:
		pop ax bx cx dx si di bp sp ds es ss

		JmpFar

Old08ofs	dw 0
Old08seg	dw 0

		iret

endp

;-------------------------------------------------------------------------------
; Split byte-reg, like this AB ->0A0B
; Entry:
;	 BH - byte-reg
; Return:
; 	 BX - splitted reg
; Assumes:
;	 ES = 0b800h
; Destr: DX
;
;-------------------------------------------------------------------------------
SplitByteReg	proc

				mov bl, bh	; 0A
				shr bh, 4

				shl bl, 4	; 0B
				shr bl, 4

				ret
				endp

;-------------------------------------------------------------------------------
; Write str value to var from reg
; Entry:
;	 AX - reg_value
; 	 CX - str address
; Assumes:
;	 ES = 0b800h
; Destr: CX
;
;-------------------------------------------------------------------------------
WriteRegToVar	proc

				push bx dx si di es

				push ds
				pop es

				mov bx, ax			; Write ah
				call SplitByteReg
				ReplaceByte

				inc cx

				mov bx, ax			; Write al
				mov bh, bl
				call SplitByteReg
				ReplaceByte

				pop es di si dx bx
				ret
				endp

;-------------------------------------------------------------------------------
; Write registers to frame
; Entry:
;	 STACK[0] - AX
;	 STACK[1] - BX
;	 STACK[2] - CX
;	 STACK[3] - DX
;	 STACK[4] - SI
;	 STACK[5] - DI
;	 STACK[6] - BP
;	 STACK[7] - SP
;	 STACK[8] - DS
;	 STACK[9] - ES
;	 STACK[10] - SS
;	 STACK[11] - IP
;	 STACK[12] - CS
; Assumes:
;	 ES = 0b800h
; Destr: bx, cx
;
;-------------------------------------------------------------------------------
WriteReg	proc

			push bp
			mov bp, sp

			mov bx, (FnLeftCornerX + 2) * 2 + (FnLeftCornerY + 1) * FnLineSize
			add bp, 4
			mov dx, 0
			lea cx, RegArray

@@while_cond:
			cmp dx, 13d
			jl @@while_body

			pop bp
			ret

@@while_body:
			mov ax, [bp]			;  v   		 -->  	   v
			add cx, 4				; 'AX: ABCD' -->  'AX: ABCD'

			call WriteRegToVar		;     	  v	 -->   v
			sub cx, 7				; 'AX: ABCD' -->  'AX: ABCD'
			mov ah, FnColor

			call WriteStrVarToFrame

			add bx, FnLineSize
									;     	  v	 		   -->   		   v
			add cx, 1				; 'AX: ABCD''BX: ABCD' -->  'AX: ABCD''BX: ABCD'
			add bp, 2
			inc dx

			jmp @@while_cond

			endp

;-------------------------------------------------------------------------------
; Write str to frame
; Entry:
;	 AH - bkgd_color
;	 CX - str address ( ended with $ )
;	 BX - start pos
; Assumes:
;	 ES = 0b800h
; Destr: cx
;-------------------------------------------------------------------------------
WriteStrVarToFrame	proc

			push si ax bx

@@while_cond:
			mov si, cx
			lodsb
			cmp al, EndSym
			jne @@while_body

			pop bx ax si

			ret
@@while_body:
			mov es:[bx], ax

			inc cx
			add bx, 2
			jmp @@while_cond
			endp

;-------------------------------------------------------------------------------
; Write frame to VMemory
; Entry:
;	 CH - height
;	 DX - width
; 	 BX - left position
;	 AH - color
;	 STACK[0] - str_address
;	 STACK[1] - set_adress
; Assumes:
;	 ES = 0b800h
; Destr: AX, CX, BX, DX
;-------------------------------------------------------------------------------
WriteFrame	proc

		push bp			; saving bp
		mov bp, sp

		push cx			; saving height
		push dx			; saving width
		push bx			; saving left pos

		mov cl, 1h		; print_first_line

		push dx			; saving dx
		push bx			; saving bx

		push [bp + 6]
		call WriteFrameLine

		pop bx			; getting old bx
		pop dx			; getting old dx

		add bx, FnLineSize	; bx = bx + Line_size
	    Sub ch, 1

@@while_cond:
		cmp ch, 1		; while ( height > 1 )
		jle @@end_while

		mov cl, 2h		; print_middle_line

		push dx			; saving dx
		push bx			; saving bx
		push [bp + 6]
		call WriteFrameLine
		pop bx			; getting old bx
		pop dx			; getting old dx

		sub ch, 1
		add bx, FnLineSize	; bx = bx + Line_size

		jmp @@while_cond

@@end_while:
		mov cl, 3h		; print_last_line
		push [bp + 6]
		Call WriteFrameLine
		pop bx			; getting old left pos
		pop dx			; getting old width
		pop cx
		pop bp			; getting old bp

		ret 4			; exit from func and clear stack
		endp

;-------------------------------------------------------------------------------
; Write a line of frame to VMemory
; Entry:
;	 AH - color
;	 CL - line_type:
;		  	1h - first line
;			2h - middle line
;			3h - last line
; 	 DX - width
;	 BX - left position
;	 STACK[0] - CurrentSet
; Assumes:
;	 ES = 0b800h
; Destr: AL, CL, BX, DX, SI
;
;-------------------------------------------------------------------------------

WriteFrameLine	proc

check_1:
		push bp			; saving bp
		mov bp, sp
		cmp cl, 1h
		jne check_2

		mov si, [bp + 4]			; passing argument right_border
		add si, 2
		mov al, [si]
		push ax

		mov si, [bp + 4]			; passing argument left_border
		mov al, [si]
		push ax

		mov si, [bp + 4]			; passing argument middle_sym
		add si, 1
		mov cl, [si]

		call WriteSymLine

		pop bp			; getting old bp

		ret 2

check_2:
		cmp cl, 2h
		jne check_3

		mov si, [bp + 4]			; passing argument right_border
		add si, 5
		mov al, [si]
		push ax

		mov si, [bp + 4]			; passing argument left_border
		add si, 3
		mov al, [si]
		push ax

		mov si, [bp + 4]			; passing argument middle_sym
		add si, 4
		mov cl, [si]

		call WriteSymLine

		pop bp			; getting old bp

		ret 2

check_3:

		mov si, [bp + 4]			; passing argument right_border
		add si, 8
		mov al, [si]
		push ax

		mov si, [bp + 4]			; passing argument left_border
		add si, 6
		mov al, [si]
		push ax

		mov si, [bp + 4]			; passing argument middle_sym
		add si, 7
		mov cl, [si]

		call WriteSymLine

		pop bp			; getting old bp

		ret 2			; exit from func and clear stack
		endp
;-------------------------------------------------------------------------------
; Writes a sequence of identical characters in a line with borders.
; Example: [|==============|]
;
; Entry: AH - background color
;	 CL 	  - middle symbol
;	 BX 	  - left position
;	 DX 	  - width
;	 STACK[0] - left_border   (left_border higher then
;	 STACK[1] - right_border   right_border in stack)
; Assumes:
;	 ES = 0b800h
; Destr: BX, DX, AL
;-------------------------------------------------------------------------------

WriteSymLine 	proc

		push bp			; saving bp
		mov bp, sp

		push dx			; saving dx [*]

		mov dx, [bp+4]		; getting left_border
		mov al, dl

		Call WriteSym

		pop dx			; getting old dx from [*]

		add bx, 2
		sub dx, 2 		; subbed left and right border

		push dx			; Memset(bx, ax, dx)
		mov al, cl
		push ax
		push bx
		Call MemSet

		add bx, dx		; left_pos += 2 * width
		add bx, dx

		mov dx, [bp+6]		; getting right_border
		mov al, dl

		call WriteSym

		pop bp			; getting old bp

		ret 4			; exit from func and clear stack
		endp

;-------------------------------------------------------------------------------
; Write str to VMemory
; Entry:
;	 SI - source address
;	 AH - color
;  	 BX - offset to VMemory
; Assumes:
;	 ES = 0b800h
; Destr: none
;
;------------------------------------------------------------------------------

WriteString	proc

while_6_cond:
		mov ch, [si]
		cmp ch, 24h
		jne while_6

		ret
while_6:
		mov al, ch
		Call WriteSym
		add bx, 2
		add si, 1
		jmp while_6_cond

		endp

;-------------------------------------------------------------------------------
; Write  a symbol to VMemory
; Entry: AH color,
;	 AL symbol
;  	 BX offset to VMemory
; Assumes:
;	 ES = 0b800h
; Destr: none
;
;------------------------------------------------------------------------------

WriteSym 	proc

		mov es:[bx], ax
		ret

		endp

;-------------------------------------------------------------------------------
; The function calculates the length of a box_text that ends with $
; Way of passing arguments: PASCAL
;
; Entry: STACK[0] - str
; Ret:	 CX		  - length
; Destr: si, al
;
;-------------------------------------------------------------------------------
StrLenBoxtext	proc

			push bp			; saving bp
			push ax			; saving ax

			mov bp, sp

			mov si, [bp + 6]  ; getting first arg


			xor cx, cx

@@while_cond:
			mov al, [si]
			cmp al, EndSym
			jne @@while_body

			pop ax			; getting old ax
			pop bp			; getting old bp

			ret 2			; exit from func and clear stack

@@while_body:

			add cx, 1
			add si, 1
			jmp @@while_cond

			endp

EOP:

end 	Start
