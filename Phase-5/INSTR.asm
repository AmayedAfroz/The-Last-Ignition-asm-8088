org 100h

start:
    mov ax,0013h
    int 10h

    push cs
    pop ds

    mov si, instructions2_palette
    call LoadPalette

    mov ax,0A000h
    mov es,ax
    xor di,di
    mov si,instructions2_image
    mov cx,320*200
    cld
    rep movsb

    mov ah,00h
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

instructions2_palette:
    incbin "instructions2_palette.bin"
instructions2_image:
    incbin "instructions2_image.bin"