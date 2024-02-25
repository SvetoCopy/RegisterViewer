.286
.model tiny
.code
org 100h

RegStrLen			equ 9d

FnMaxHeight			equ 24D
FnMaxWidth			equ 80d

FnHeight 			equ 10d
FnWidth				equ 50d
FnLineSize			equ 160d
FnLeftCornerX		equ 30d
FnLeftCornerY		equ 0d

FnStarSym			equ 2ah
FnStandartSet1_code equ 31h
FnStandartSet2_code equ 32h
FnStandartSet3_code equ 33h

FnSetSize			equ 9d

FnCMDArgsAddr		equ 80h

LOCALS @@
Start:
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

is_pressed		db 0

HEX_alph		db '0123456789ABCDEF'

AX_str			db 'AX: 0000$'
BX_str			db 'BX: 0000$'
CX_str			db 'CX: 0000$'
DX_str			db 'DX: 0000$'
SI_str			db 'SI: 0000$'
DI_str			db 'DI: 0000$'
BP_str			db 'BP: 0000$'
SP_str			db 'SP: 0000$'
DS_str			db 'DS: 0000$'
ES_str			db 'ES: 0000$'

ChangeIntVector macro num

				mov ax, 35&num&h			; change 08 int vector
				int 21h

				mov Old&num&ofs, bx
				mov bx, es
				mov Old&num&seg, bx
				push 0
				pop es
				mov bx, 4 * &num&h

				cli

				mov es:[bx], offset New&num
				push cs
				pop ax

				mov es:[bx + 2], ax

				sti

				endm

New09	proc

		push ds bp di si cx dx ax bx es

		in al, 60h
		cmp al, 52h
		jne @@go_out		; if (button != insert) go_out

		push cs
		pop ds

		lea bx, is_pressed	; is_pressed = true
		push ds
		pop es
		mov byte ptr es:[bx], 1h

@@go_out:
		pop es bx ax dx cx si di bp ds
		db 0EAh

Old09ofs	dw 0
Old09seg	dw 0

		iret

endp

New08	proc

		push ds bp di si cx dx ax bx es

		push cs
		pop ds

		cmp is_pressed, 1h
		jne @@go_out

		push 0b800h
		pop es

		lea bx, StandartSet1
		push bx

		lea bx, Header_name
		push bx

		mov bx, (80 * 5 + 40) * 2
		mov ch, 12d
		mov dx, 12d
		mov ah, 4eh

		Call WriteFrame

		pop es bx ax dx cx si di bp ds
		push ds bp di si cx dx ax bx es

		push es ds sp bp di si dx cx bx ax	; calling WriteReg

		push cs
		pop ds

		push 0b800h
		pop es
		mov ah, 24h

		call WriteReg

@@go_out:
		pop es bx ax dx cx si di bp ds
		db 0EAh

Old08ofs	dw 0
Old08seg	dw 0

		iret

endp

;-------------------------------------------------------------------------------
; Write str value to var from reg
; Entry:
;	 AX - reg_value
; 	 CX - str address
; Assumes:
;	 ES = 0b800h
; Destr:
;
;-------------------------------------------------------------------------------
WriteRegToVar	proc
			push bx dx si di es

			mov bx, ax		; bx = ABCDh

			shr bh, 4			; Write(0A)

			lea dx, HEX_alph
			mov bl, bh
			mov bh, 0
			add dx, bx

			push ds
			pop es
			mov si, dx
			mov di, cx
			movsb

			inc cx

			mov bx, ax		; bx = ABCDh

			shl bh, 4			; Write(0B)
			shr bh, 4

			lea dx, HEX_alph
			mov bl, bh
			mov bh, 0
			add dx, bx

			mov si, dx
			mov di, cx
			movsb

			inc cx

			mov bx, ax		; bx = ABCDh

			shr bl, 4			; Write(0C)

			lea dx, HEX_alph
			mov bh, 0
			add dx, bx

			mov si, dx
			mov di, cx
			movsb

			inc cx

			mov bx, ax		; bx = ABCDh

			shl bl, 4			; Write(0D)
			shr bl, 4

			lea dx, HEX_alph
			mov bh, 0
			add dx, bx
			mov si, dx
			mov di, cx
			movsb

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
; Assumes:
;	 ES = 0b800h
; Destr: bx, cx
;
;-------------------------------------------------------------------------------
WriteReg	proc
			push bp
			mov bp, sp

			mov bx, (80 * 6 + 42) * 2
			add bp, 4
			mov dx, 0
			lea cx, AX_str

@@while_cond:
			cmp dx, 10d
			jl @@while_body

			pop bp
			ret 20

@@while_body:
			mov ax, [bp]
			add cx, 4

			call WriteRegToVar
			sub cx, 7
			mov ah, 4eh

			call WriteStrVarToFrame

			add bx, FnLineSize
			add cx, 1
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
;
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

include strtonum.asm
EOP:

end 	Start
