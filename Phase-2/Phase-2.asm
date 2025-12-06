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

COL_GRASS_DARK  equ 2
COL_GRASS_LIGHT equ 10
COL_ROAD        equ 8
COL_EDGE        equ 15
COL_DASH        equ 15
COL_PLAYER      equ 4
COL_OBS         equ 1
COL_TREE_TOP    equ 2
COL_TREE_SHADE  equ 10
COL_TREE_TRUNK  equ 6

COL_COIN        equ 14

OBST_INTERVAL   equ 20
FRAME_DELAY_TCK equ 1
MOVE_SPEED      equ 3

DASH_STEP       equ 2
DASH_PERIOD     equ 16

COIN_INTERVAL   equ 10
COIN_SPEED      equ 2

start:
    mov ax,0013h
    int 10h

    mov ax,0A000h
    mov es,ax

    call DrawBackground
    call DrawAllTrees
    call DrawFuelBar

    mov bx,BASE_LEFT_X + LANE_STEP
    mov dx,PLAYER_Y
    call DrawPlayerCar

    mov byte [obs_active],0
    mov byte [obs_timer],0
    mov byte [dash_offset],0
    mov byte [coin_active],0
    mov byte [coin_timer],0

main_loop:
    call DelayFrame
    call UpdateObstacle
    call UpdateCoin
    call AnimateDashes

    mov bx,BASE_LEFT_X + LANE_STEP
    mov dx,PLAYER_Y
    call DrawPlayerCar
    jmp main_loop

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
    ret

DrawFuelBar:
    push ax
    push bx
    push cx
    push dx
    push si

    mov al,15
    mov bx,10
    mov dx,10
    mov cx,60
    mov si,8
    call RectFill

    mov al,13
    add bx,1
    add dx,1
    mov cx,58
    mov si,6
    call RectFill

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
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

AnimateDashes:
    push ax
    push bx
    push cx
    push dx
    push si

    mov al,[dash_offset]
    add al,DASH_STEP
    cmp al,DASH_PERIOD
    jb  .keep
    sub al,DASH_PERIOD
.keep:
    mov [dash_offset],al

    mov al,COL_ROAD
    mov bx,ROAD_X + LANE_W
    mov dx,0
    mov cx,3
    mov si,SCREEN_H
    call RectFill

    mov bx,ROAD_X + 2*LANE_W
    mov dx,0
    mov cx,3
    mov si,SCREEN_H
    call RectFill

    mov bx,ROAD_X + LANE_W
    mov al,COL_DASH
    call DrawDashedLine_Animated

    mov bx,ROAD_X + 2*LANE_W
    mov al,COL_DASH
    call DrawDashedLine_Animated

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

UpdateObstacle:
    mov al,[obs_active]
    cmp al,0
    je  .maybe_spawn

    mov bx,[obs_x]
    mov dl,[obs_y]
    mov dh,0
    call EraseCarArea

    mov al,[obs_y]
    add al,MOVE_SPEED
    mov [obs_y],al

    mov ah,0
    mov bx,ax
    add bx,CAR_H
    cmp bx,SCREEN_H
    jb  .draw_new

    mov bx,[obs_x]
    mov dl,[obs_y]
    mov dh,0
    call EraseCarArea
    mov byte [obs_active],0
    jmp .done

.draw_new:
    mov bx,[obs_x]
    mov dl,[obs_y]
    mov dh,0
    call DrawObstacleCar
    jmp .done

.maybe_spawn:
    mov al,[obs_timer]
    inc al
    mov [obs_timer],al
    cmp al,OBST_INTERVAL
    jb  .done
    mov byte [obs_timer],0

    call RandomLaneX
    mov [obs_x],ax
    mov byte [obs_y],10
    mov byte [obs_active],1

    mov bx,[obs_x]
    mov dl,[obs_y]
    mov dh,0
    call DrawObstacleCar
.done:
    ret

UpdateCoin:
    mov al,[coin_active]
    cmp al,0
    je  .maybe_spawn

    mov bx,[coin_x]
    mov dl,[coin_y]
    mov dh,0
    call EraseCoin

    mov al,[coin_y]
    add al,COIN_SPEED
    mov [coin_y],al
    cmp al,SCREEN_H
    jb  .draw_new

    mov byte [coin_active],0
    jmp .done

.draw_new:
    mov bx,[coin_x]
    mov dl,[coin_y]
    mov dh,0
    call DrawCoin
    jmp .done

.maybe_spawn:
    mov al,[coin_timer]
    inc al
    mov [coin_timer],al
    cmp al,COIN_INTERVAL
    jb  .done
    mov byte [coin_timer],0

    call RandomLaneX
    mov [coin_x],ax
    mov byte [coin_y],5
    mov byte [coin_active],1

    mov bx,[coin_x]
    mov dl,[coin_y]
    mov dh,0
    call DrawCoin
.done:
    ret

DrawCoin:
    push ax
    push bx
    push cx
    push dx
    push si
    mov al,COL_COIN
    mov cx,4
    mov si,4
    call RectFill
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

EraseCoin:
    push ax
    push bx
    push cx
    push dx
    push si
    mov al,COL_ROAD
    mov cx,4
    mov si,4
    call RectFill
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

EraseCarArea:
    push ax
    push bx
    push cx
    push dx
    push si
    cmp dl,SCREEN_H
    jae .skip
    mov al,COL_ROAD
    mov cx,CAR_W
    mov si,CAR_H+2
    call RectFill
.skip:
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
    and al,11b
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

DelayFrame:
    push ax
    push bx
    push es
    mov ax,40h
    mov es,ax
    mov bx,[es:6Ch]
.wait:
    mov ax,[es:6Ch]
    sub ax,bx
    cmp ax,FRAME_DELAY_TCK
    jb  .wait
    pop es
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

DrawDashedLine:
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx,4
.dl_loop:
    cmp dx,SCREEN_H
    jae .done
    mov cx,3
    mov si,8
    cmp dx,SCREEN_H-8
    jbe .draw_ok
    mov si,SCREEN_H
    sub si,dx
.draw_ok:
    call RectFill
    add dx,16
    jmp .dl_loop
.done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

DrawDashedLine_Animated:
    push ax
    push bx
    push cx
    push dx
    push si

    xor dx,dx
    mov dl,[dash_offset]

.dl_a_loop:
    cmp dx,SCREEN_H
    jae .done_a

    mov cx,3
    mov si,8
    cmp dx,SCREEN_H-8
    jbe .draw_ok_a
    mov si,SCREEN_H
    sub si,dx
.draw_ok_a:
    call RectFill
    add dx,16
    jmp .dl_a_loop

.done_a:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
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

    mov al,12
    push bx
    push dx
    add dx,CAR_H-3
    mov cx,CAR_W
    mov si,3
    call RectFill
    pop dx
    pop bx

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

obs_x       dw 0
obs_y       db 0
obs_active  db 0
obs_timer   db 0
dash_offset db 0

coin_x       dw 0
coin_y       db 0
coin_active  db 0
coin_timer   db 0

trees_left:
    dw 20,10, 30,40, 15,70, 25,100, 40,130, 15,160, 60,180, 0FFFFh
trees_right:
    dw 250,20, 270,50, 300,80, 280,110, 260,140, 290,160, 310,185, 0FFFFh
