EStoVideoMem	macro

		push 0b800h
		pop es

		endm

GetButtFromKbrd	macro

		in al, 60h

		endm

JmpFar		macro

		db 0EAh

		endm


ReplaceByte	macro

		lea dx, HEX_alph
		add dl, bh

		mov si, dx
		mov di, cx
		movsb

		inc cx

		lea dx, HEX_alph
		add dl, bl

		mov si, dx
		mov di, cx
		movsb

		endm

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
