org 100h

start:
    mov ax,0013h
    int 10h

    push cs
    pop ds

    mov si, screen_palette_new
    call LoadPalette

    call DrawMainImage

    call LoadingBarAnim

    call DrawMainImage

    mov si, PressMsg
    mov bl, 15
    mov dh, 23
    mov dl, 8
    call PrintStringRC

    mov ah, 00h
    int 16h

    int 20h

LoadPalette:
    push ax
    push cx
    push dx

    mov dx,03C8h
    xor al,al
    out dx,al

    inc dx
    mov cx,256*3

.lp:
    lodsb
    out dx,al
    loop .lp

    pop dx
    pop cx
    pop ax
    ret

DrawMainImage:
    push ax
    push cx
    push si
    push di

    mov ax,0A000h
    mov es,ax
    xor di,di
    mov si,screen_image_new
    mov cx,320*200
    cld
    rep movsb

    pop di
    pop si
    pop cx
    pop ax
    ret

LoadingBarAnim:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov al,20h
    mov bx,20
    mov dx,180
    mov cx,244
    mov si,12
    call DrawRect

    mov al,0
    mov bx,20
    mov dx,180
    mov cx,244
    mov si,12
    call DrawRect

    mov bx,21
    mov dx,182
    mov si,8
    mov cx,0
    mov bp,60

.lbLoop:
    add cx,4
    cmp cx,256
    jbe .ok
    mov cx,256
.ok:
    mov al,0Fh
    call DrawRect

    call Delay50ms

    dec bp
    jnz .lbLoop

    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

DrawRect:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov ax,0A000h
    mov es,ax

    mov di,dx
    mov ax,di
    shl ax,6
    shl di,8
    add di,ax
    add di,bx

.rowLoop:
    mov dx,cx
    rep stosb
    add di,320
    sub di,dx
    dec si
    jnz .rowLoop

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

Delay50ms:
    push cx
    push dx

    mov cx,3
.oLoop:
    mov dx,0FFFFh
.iLoop:
    dec dx
    jnz .iLoop
    loop .oLoop

    pop dx
    pop cx
    ret

PrintStringRC:
    push ax
    push bx
    push cx
    push dx
    push si

    mov ah,02h
    mov bh,0
    int 10h

.next:
    lodsb
    test al,al
    jz .done
    mov ah,0Eh
    mov bh,0
    int 10h
    jmp .next

.done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

PressMsg db "Press Any Key to Continue",0

screen_palette_new:
    incbin "screen_palette_new.bin"
screen_image_new:
    incbin "screen_image_new.bin"