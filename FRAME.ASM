.model tiny
.186

COLOR = 04eh
SYM = 0b1h
X = 2
Y = 10

.code
org 100h
locals @@


;------------------------------------------------
; EXIT to DOS
;------------------------------------------------
; Entry:	None
; Exit: 	(not defined)
; Expects:	(none)
; Destroys:	...
;------------------------------------------------
EXIT		macro
			nop
			mov ax, 4c00h
			int 21h
			nop
			endm

start:
            mov bx, 0b800h
			mov es, bx

            mov al, 20h                 ; clearing screen
            xor ah, ah
            call ClrScr

            call GetArgs

            call DrawFrame

            EXIT

;------------------------------------------------
; Gets arguments from command line
;------------------------------------------------
; Entry:	none
; Exit:     AH = color of the frame
;           AL = style of the frame
;           CX = width of the frame
;           DX = height of the frame
;           DI = coordinates of the top left corner
;           SI = start of the message or the user's style
; Expects:	none
; Destroys: BX
;------------------------------------------------
GetArgs     proc

            mov si, 82h					          ; cmd on 82h

            call TwoDigitD                        ; x coord in ax
            push ax
            inc si
            call TwoDigitD                        ; y coord in ax
            inc si

            pop bx
            mov cx, 80                            ; calculating final coord
            mul cx
            add ax, bx
            mov di, ax

            push dx
            call TwoDigitH                        ; color of the frame
            mov ah, al
            xor al, al
            push ax
            inc si

            call TwoDigitD                        ; style of the frame
            inc si
            pop dx
            add ax, dx
            pop dx

            push ax
            xor cx, cx
            xor ax, ax
            call StrLen
            mov cl, al                            ; lenght of the message is width of the frame
            mov dl, ah                            ; height of the message is height of the frame
            add dl, 3
            add cx, 2
            pop ax

            ret
            endp

;------------------------------------------------
; Two-digit number from cmd in DEX
;------------------------------------------------
; Entry:	SI = ptr of the number
; Exit:		AL = two-digit number
;           SI = SI + 2
; Expects:	none
; Destroys: AH DX
;------------------------------------------------

TwoDigitD   proc

            lodsb               ; bytes in AX
            mov ah, al
            lodsb

            cmp al, 41h
            jae @@AL

            sub al, 30h         ; changing al into number
            jmp @@ALDONE

@@AL:       sub al, 41h
            add al, 0Ah


@@ALDONE:   cmp ah, 41h         ; changing ah into number
            jae @@AH

            sub ah, 30h
            jmp @@AHDONE

@@AH:       sub ah, 41h
            add ah, 0Ah

@@AHDONE:
            push ax
            mov dx, 10d
            xor al, al
            mul dx
            pop dx
            add al, ah
            add al, dl
            xor dx, dx
            xor ah, ah
            endp
            ret

;------------------------------------------------
; Two-digit number from cmd in HEX
;------------------------------------------------
; Entry:	SI = ptr of the number
; Exit:		AL = two-digit number
;           SI = SI + 2
; Expects:	none
; Destroys: AH DX
;------------------------------------------------

TwoDigitH   proc

            lodsb               ; bytes in AX
            mov ah, al
            lodsb

            cmp al, 41h
            jae @@AL

            sub al, 30h         ; changing al into number
            jmp @@ALDONE

@@AL:       sub al, 41h
            add al, 0Ah


@@ALDONE:   cmp ah, 41h         ; changing ah into number
            jae @@AH

            sub ah, 30h
            jmp @@AHDONE

@@AH:       sub ah, 41h
            add ah, 0Ah

@@AHDONE:
            shl ah, 4
            add al, ah
            endp
            ret

;------------------------------------------------
; Draws frame with text
;------------------------------------------------
; Entry:	AH = color
;           AL = frame style
;			CX = width of the frame
;			DX = height of the frame
;           SI = user's style and message
;           DI = coordinates of the top left corner
; Exit:		none
; Expects:	ES = 0b800h
; Destroys: AL, SI, DI
;------------------------------------------------

DrawFrame   proc

            push ax                     ; save style and color
            push cx                     ; save width
            push dx                     ; save height
            push di                     ; save starting coordinates
            push si                     ; save style or message ptr
            push di                     ; save coords
            push dx                     ; save height

            cmp al, 0h
            je @@StlDone
            mov si, offset style1       ; setting style
            push ax
            xor ah, ah
            sub al, 1
            push bx
            mov bx, 9
            mul bx
            pop bx
            add si, ax
            pop ax
            jmp @@StlDone

@@StlDone:
            lodsb                       ; top left corner in al
            mov dh, [si]                ; top sym in dh
            inc si
            mov dl, [si]                ; top right corner in dl
            inc si

            call DrawLine

            pop dx                      ; return dx
            sub dx, 2
            pop di
            add di, 160d

@@Height:   cmp dx, 0h                  ; check for end
            je @@Done

            push di                     ; saves coords, width
            push dx

            push si
            lodsb                       ; top left corner in al
            mov dh, [si]                ; top sym in dh
            inc si
            mov dl, [si]                ; top right corner in dl
            inc si
            pop si

            call DrawLine

            pop dx                      ; coords to the next line
            pop di
            add di, 160d

            dec dx                      ; reduce height remaining
            jmp @@Height

@@Done:
            add si, 3
            lodsb                       ; bottom left corner in al
            mov dh, [si]                ; bottom sym in dh
            inc si
            mov dl, [si]                ; bottom right corner in dl
            inc si
            call DrawLine

            pop si                      ; start of message
            pop di                      ; starting coords
            pop dx                      ; height in dx
            pop cx                      ; width in cx

            add di, 162d                ; start of the text

            pop ax
            cmp al, 0h
            jne @@PrtMsg
            add si, 10d

@@PrtMsg:
            call PrtMsg

            ret
            endp


;------------------------------------------------
; Draws line
;------------------------------------------------
; Entry:	AH = color
;           AL = left symbol
;			CX = width of the frame
;           DH = mid symbol
;           DL = right symbol
;           DI = coordinates of the start of line
; Exit:		none
; Expects:	ES = 0b800h
; Destroys: AL, DH, DL, DI
;------------------------------------------------

DrawLine    proc

            push cx                 ; save cx
            stosw                   ; draw right symbol
            mov al, dh

            sub cx, 2

@@Width:    cmp cx, 0h              ; draws middle symbols
            je @@Done

            stosw
            dec cx

            jmp @@Width

@@Done:
            mov al, dl              ; draws left symbol
            stosw

            pop cx

            endp
            ret

ClrScr		proc

			xor bx, bx
			mov cx, 80d * 25d

@@Next:		mov es:[bx], ax
			add bx, 2
			loop @@Next

			ret
			endp

;------------------------------------------------
; Prints text from cmd
;------------------------------------------------
; Entry:	AH = color
;           SI = start message ptr
;           DI = coordinates of the start of line
; Exit:		none
; Expects:	ES = 0b800h
; Destroys: AL, DH, DL
;------------------------------------------------

PrtMsg      proc

            push di
@@Next:		cmp byte ptr [si], 0dh				; check for the end of the string
		    je @@Done

		    lodsb

            cmp al, '#'
            jne @@NoEnter
            pop di
            add di, 160d
            push di
            jmp @@Next

@@NoEnter:  stosw

		    jmp @@Next

@@Done:     pop di
            ret
            endp

;------------------------------------------------
; Counting strings lenght
;------------------------------------------------
; Entry:    SI = start message ptr
; Exit:		AL = len of the string
;           AH = height of the frame
; Expects:	AX = 0
; Destroys: CL
;------------------------------------------------

StrLen      proc

            push si

@@Next:     cmp byte ptr [si], 0dh           ; check for the end of the string
            je @@Done

            cmp byte ptr [si], '#'
            jne @@NoEnter
            inc ah                           ; one more line in text
            cmp cl, al
            jbe @@NoChange
            mov al, cl
@@NoChange:
            inc si
            xor cl, cl
            jmp @@Next
@@NoEnter:
            inc cl
            inc si                           ; next char

            jmp @@Next

@@Done:     cmp cl, al
            jbe @@Lastwrd
            mov al, cl
@@LastWrd:

            pop si
            ret
            endp

.data

style1      db 0dah, 0c4h, 0bfh, 0b3h, ' ', 0b3h, 0c0h, 0c4h, 0d9h

style2      db 03h, 03h, 03h, 03h, ' ', 03h, 03h, 03h, 03h

end start
