org 100h

SCREEN_W        equ 320
SCREEN_H        equ 200
ROAD_X          equ 80
ROAD_W          equ 160
LANE_W          equ 53
LANE_STEP       equ 53
CAR_W           equ 12
CAR_H           equ 18
BASE_LEFT_X     equ 100
PLAYER_Y        equ 170
COL_GRASS_LIGHT equ 10
COL_GRASS_DARK  equ 2
COL_ROAD        equ 8
COL_EDGE        equ 15
COL_DASH        equ 15
COL_PLAYER      equ 4
COL_OBS         equ 1
COL_TREE_TOP    equ 2
COL_TREE_SHADE  equ 10
COL_TREE_TRUNK  equ 6

start:
    mov ax,0013h
    int 10h
    mov ax,0A000h
    mov es,ax
    call DrawBackground
    call DrawAllTrees
    mov bx,BASE_LEFT_X + LANE_STEP
    mov dx,PLAYER_Y
    call DrawPlayerCar
    call RandomLaneX
    mov [obs_x],ax
    mov bx,[obs_x]
    mov byte [obs_y],40
    mov dl,[obs_y]
    call DrawObstacleCar
.waitKey:
    mov ah,0
    int 16h
    mov ax,0003h
    int 10h
    mov ah,4Ch
    int 21h

DrawBackground:
    mov al,COL_GRASS_LIGHT
    call FillScreen
    mov bx,0
    mov cx,SCREEN_W
    mov dx,0
    mov si,SCREEN_H
    call GrassPattern
    mov bx,ROAD_X
    xor dx,dx
    mov cx,ROAD_W
    mov si,SCREEN_H
    mov al,COL_ROAD
    call RectFill
    mov bx,ROAD_X
    xor dx,dx
    mov cx,3
    mov si,SCREEN_H
    mov al,COL_EDGE
    call RectFill
    mov bx,ROAD_X + ROAD_W - 3
    xor dx,dx
    mov cx,3
    mov si,SCREEN_H
    mov al,COL_EDGE
    call RectFill
    mov bx,ROAD_X + LANE_W
    mov al,COL_DASH
    call DrawDashedLine
    mov bx,ROAD_X + 2*LANE_W
    mov al,COL_DASH
    call DrawDashedLine
    ret

GrassPattern:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    mov di,dx
.yloop:
    mov bx,0
.xloop:
    mov al,COL_GRASS_DARK
    test bx,1
    jz .skip
    test di,1
    jz .skip
    mov al,COL_GRASS_LIGHT
.skip:
    mov cx,1
    mov si,1
    call RectFill
    inc bx
    cmp bx,cx
    jb .xloop
    inc di
    cmp di,si
    jb .yloop
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

DrawTree:
    push ax
    push bx
    push cx
    push dx
    push si
    mov al,COL_TREE_TOP
    mov cx,6
    mov si,4
    call RectFill
    mov al,COL_TREE_SHADE
    push bx
    push dx
    add bx,1
    add dx,1
    mov cx,4
    mov si,2
    call RectFill
    pop dx
    pop bx
    mov al,COL_TREE_TRUNK
    push bx
    push dx
    add bx,2
    add dx,4
    mov cx,2
    mov si,2
    call RectFill
    pop dx
    pop bx
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

DrawAllTrees:
    mov si,trees_left
.leftLoop:
    lodsw
    cmp ax,0FFFFh
    je .rightSide
    mov bx,ax
    lodsw
    mov dx,ax
    call DrawTree
    jmp .leftLoop
.rightSide:
    mov si,trees_right
.rightLoop:
    lodsw
    cmp ax,0FFFFh
    je .done
    mov bx,ax
    lodsw
    mov dx,ax
    call DrawTree
    jmp .rightLoop
.done:
    ret

DrawPlayerCar:
    push ax
    push bx
    push cx
    push dx
    push si
    mov al,COL_PLAYER
    mov cx,CAR_W
    mov si,CAR_H
    call RectFill
    mov al,11
    push bx
    push dx
    add bx,2
    add dx,3
    mov cx,CAR_W-4
    mov si,4
    call RectFill
    pop dx
    pop bx
    mov al,12
    push bx
    push dx
    add dx,CAR_H-3
    mov cx,CAR_W
    mov si,3
    call RectFill
    pop dx
    pop bx
    mov al,0
    push bx
    push dx
    add dx,2
    mov cx,2
    mov si,CAR_H-4
    call RectFill
    add bx,CAR_W-2
    call RectFill
    pop dx
    pop bx
    mov al,14
    push bx
    push dx
    add bx,4
    mov cx,CAR_W-8
    mov si,2
    call RectFill
    pop dx
    pop bx
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

DrawObstacleCar:
    push ax
    push bx
    push cx
    push dx
    push si
    mov al,COL_OBS
    mov cx,CAR_W
    mov si,CAR_H
    call RectFill
    mov al,9
    push bx
    push dx
    add bx,3
    add dx,3
    mov cx,CAR_W-6
    mov si,5
    call RectFill
    pop dx
    pop bx
    mov al,15
    push bx
    push dx
    add bx,(CAR_W/2)-1
    mov cx,2
    mov si,CAR_H
    call RectFill
    pop dx
    pop bx
    mov al,0
    push bx
    push dx
    add dx,2
    mov cx,2
    mov si,CAR_H-4
    call RectFill
    add bx,CAR_W-2
    call RectFill
    pop dx
    pop bx
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

RandomLaneX:
    mov al,00h
    out 70h,al
    jmp $+2
    in al,71h
    and al,00000011b
    cmp al,3
    jb  short .ok
    mov al,2
.ok:
    mov ah,0
    mov bx,BASE_LEFT_X
    cmp al,0
    je  short .fin
    add bx,LANE_STEP
    cmp al,1
    je  short .fin
    add bx,LANE_STEP
.fin:
    mov ax,bx
    ret

DrawDashedLine:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx,4
.dl_loop:
    mov cx,3
    mov si,8
    call RectFill
    add dx,16
    cmp dx,SCREEN_H
    jb  .dl_loop
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

FillScreen:
    push di
    push cx
    xor di,di
    mov cx,SCREEN_W*SCREEN_H
    rep stosb
    pop cx
    pop di
    ret

RectFill:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    mov di,dx
    shl di,8
    mov bp,dx
    shl bp,6
    add di,bp
    add di,bx
    mov bp,si
    mov bx,cx
.rf_row:
    mov cx,bx
    rep stosb
    mov dx,SCREEN_W
    sub dx,bx
    add di,dx
    dec bp
    jnz .rf_row
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

trees_left:
    dw 20,10, 30,40, 15,70, 25,100, 40,130, 15,160, 60,180, 0FFFFh
trees_right:
    dw 250,20, 270,50, 300,80, 280,110, 260,140, 290,160, 310,185, 0FFFFh

obs_x dw 0
obs_y db 0
