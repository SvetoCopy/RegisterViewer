.286
.model tiny
.code
org 100h

LOCALS @@
Start:
                mov ax, cs
                lea cx, cs_str
                add cx, 4
                call WriteRegToVar

                push cs
                pop ds

                mov ah, 09h
                lea dx, cs_str
                int 21h

@@start_loop:
                in al, 60h
                cmp al, 1h
                je @@go_out

                mov ax, 1111h
                mov bx, 2222h
                mov cx, 3333h
                mov dx, 4444h
                mov si, 5555h
                mov di, 6666h

                jmp @@start_loop

@@go_out:
                int 20h

HEX_alph	db '0123456789ABCDEF'

ReplaceByte	macro

                lea dx, HEX_alph
                mov bh, 0
                add dx, bx

                mov si, dx
                mov di, cx
                movsb

                endm

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

                mov bx, ax			; bx = ABCDh
                shr bh, 4			; Write(0A)
                mov bl, bh
                ReplaceByte

                inc cx

                mov bx, ax			; bx = ABCDh
                shl bh, 4			; Write(0B)
                shr bh, 4
                mov bl, bh
                ReplaceByte

                inc cx

                mov bx, ax			; bx = ABCDh
                shr bl, 4			; Write(0C)
                ReplaceByte

                inc cx

                mov bx, ax			; bx = ABCDh
                shl bl, 4			; Write(0D)
                shr bl, 4
                ReplaceByte

                pop es di si dx bx
                ret
                endp

cs_str          db 'CS: 0000$'
end             Start
