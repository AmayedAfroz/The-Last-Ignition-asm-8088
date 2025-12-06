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

PLAYER_STEP_Y   equ 5

SC_ESC          equ 1
SC_UP           equ 48h
SC_LEFT         equ 4Bh
SC_RIGHT        equ 4Dh
SC_DOWN         equ 50h
SC_Y            equ 15h
SC_N            equ 31h
SC_ENTER        equ 1Ch
SC_SPACE        equ 39h

CONF_W          equ 180
CONF_H          equ 50
CONF_X          equ (SCREEN_W - CONF_W)/2
CONF_Y          equ (SCREEN_H - CONF_H)/2

END_CAUSE_NONE  equ 0
END_CAUSE_QUIT  equ 1
END_CAUSE_FUEL  equ 2
END_CAUSE_CRASH equ 3

start:
    mov ax,0013h
    int 10h

    mov ax,cs
    mov ds,ax
    mov ax,0A000h
    mov es,ax

    call InstallKeyboardISR

    mov byte [obs_active],0
    mov byte [obs_timer],0
    mov byte [dash_offset],0
    mov byte [coin_active],0
    mov byte [coin_timer],0

    mov byte [game_started],0
    mov byte [game_paused],0
    mov byte [confirm_active],0
    mov byte [last_scancode],0
    mov byte [end_cause],END_CAUSE_NONE
    mov word [coins_collected],0

    mov byte [player_lane],1
    mov ax,BASE_LEFT_X + LANE_STEP
    mov [player_x],ax
    mov ax,PLAYER_Y
    mov [player_y],ax

    call ShowIntroScreen
    call ShowInstructionScreen

    call DrawStartScreen

    jmp main_loop

main_loop:
    call DelayFrame

    mov bx,[player_x]
    mov dx,[player_y]
    call EraseCarArea

    call HandleInput

    mov al,[game_started]
    cmp al,0
    je .only_player

    mov al,[game_paused]
    cmp al,0
    jne .only_player

    call UpdateObstacle
    call UpdateCoin
    call AnimateDashes

.only_player:
    mov bx,[player_x]
    mov dx,[player_y]
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
    in  al,71h
    and al,00000011b
    cmp al,3
    jb  .ok
    mov al,2
.ok:
    mov ah,0
    mov bx,BASE_LEFT_X
    cmp al,0
    je  .fin
    add bx,LANE_STEP
    cmp al,1
    je  .fin
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

InstallKeyboardISR:
    push ax
    push dx
    push ds
    push es

    mov ax,cs
    mov ds,ax

    xor ax,ax
    mov es,ax

    mov ax,[es:9*4]
    mov [old_int9_off],ax
    mov ax,[es:9*4+2]
    mov [old_int9_seg],ax

    cli
    mov ax,cs
    mov [es:9*4],word KbISR
    mov [es:9*4+2],ax
    sti

    pop es
    pop ds
    pop dx
    pop ax
    ret

UninstallKeyboardISR:
    push ax
    push ds
    push es

    xor ax,ax
    mov es,ax

    cli
    mov ax,[old_int9_off]
    mov [es:9*4],ax
    mov ax,[old_int9_seg]
    mov [es:9*4+2],ax
    sti

    pop es
    pop ds
    pop ax
    ret

KbISR:
    push ax
    push ds

    mov ax,cs
    mov ds,ax

    in  al,60h

    test al,80h
    jnz .done

    cmp al,0E0h
    je  .done

    mov [last_scancode],al

.done:
    mov al,20h
    out 20h,al

    pop ds
    pop ax
    iret

HandleInput:
    push ax
    push bx
    push cx
    push dx

    mov al,[last_scancode]
    cmp al,0
    je  .done
    mov byte [last_scancode],0

    mov bl,[game_started]
    cmp bl,0
    jne .check_confirm_and_playing

    cmp al,SC_ESC
    je  .pre_start_esc

    mov byte [game_started],1
    mov byte [game_paused],0
    mov byte [confirm_active],0
    mov byte [obs_active],0
    mov byte [obs_timer],0
    mov byte [coin_active],0
    mov byte [coin_timer],0
    mov byte [dash_offset],0
    mov word [coins_collected],0
    mov byte [end_cause],END_CAUSE_NONE

    call RedrawFullFrame
    jmp .done

.pre_start_esc:
    call ConfirmExitProgram
    jmp .done

.check_confirm_and_playing:
    mov bl,[confirm_active]
    cmp bl,0
    je  .normal_game

    cmp al,SC_ESC
    je  .resume_game
    cmp al,SC_N
    je  .resume_game
    cmp al,SC_Y
    je  .quit_run
    jmp .done

.resume_game:
    call HandleResumeGame
    jmp .done

.quit_run:
    mov byte [end_cause],END_CAUSE_QUIT
    call HandleEndFromGame
    jmp .done

.normal_game:
    cmp al,SC_ESC
    je  .enter_confirm

    mov bl,[game_paused]
    cmp bl,0
    jne .done

    cmp al,SC_LEFT
    je  .move_left
    cmp al,SC_RIGHT
    je  .move_right
    cmp al,SC_UP
    je  .move_up
    cmp al,SC_DOWN
    je  .move_down

    jmp .done

.enter_confirm:
    mov byte [game_paused],1
    mov byte [confirm_active],1
    call ShowRunConfirmBox
    jmp .done

.move_left:
    mov bl,[player_lane]
    cmp bl,0
    je  .done
    dec bl
    mov [player_lane],bl
    call RecomputePlayerX
    jmp .done

.move_right:
    mov bl,[player_lane]
    cmp bl,2
    jae .done
    inc bl
    mov [player_lane],bl
    call RecomputePlayerX
    jmp .done

.move_up:
    mov ax,[player_y]
    cmp ax,PLAYER_STEP_Y
    jb  .set_top_zero
    sub ax,PLAYER_STEP_Y
    jmp .store_y
.set_top_zero:
    xor ax,ax
.store_y:
    mov [player_y],ax
    jmp .done

.move_down:
    mov ax,[player_y]
    mov bx,ax
    add bx,CAR_H
    cmp bx,SCREEN_H
    jae .done

    add ax,PLAYER_STEP_Y
    mov bx,ax
    add bx,CAR_H
    cmp bx,SCREEN_H
    jbe .store_y2
    mov ax,SCREEN_H - CAR_H
.store_y2:
    mov [player_y],ax
    jmp .done

.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

RecomputePlayerX:
    push ax
    push bx
    mov al,[player_lane]
    xor ah,ah
    mov bx,LANE_STEP
    mul bl
    mov bx,BASE_LEFT_X
    add bx,ax
    mov [player_x],bx
    pop bx
    pop ax
    ret

DrawStartScreen:
    push ax
    push bx
    push cx
    push dx
    push si

    mov byte [dash_offset],0

    call DrawBackground
    call DrawAllTrees
    call DrawFuelBar
    call RedrawDashesNoAdvance

    mov ax,BASE_LEFT_X + LANE_STEP
    mov [player_x],ax
    mov ax,PLAYER_Y
    mov [player_y],ax
    mov byte [player_lane],1

    mov bx,[player_x]
    mov dx,[player_y]
    call DrawPlayerCar

    call RandomLaneX
    mov bx,ax
    mov dx,80
    call DrawObstacleCar

    mov ah,02h
    mov bh,0
    mov dh,24
    mov dl,5
    int 10h

    mov si,MainMsg
.m_print:
    lodsb
    cmp al,0
    je  .done_print
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    jmp .m_print
.done_print:

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

RedrawDashesNoAdvance:
    push ax
    push bx
    push cx
    push dx
    push si

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

RedrawFullFrame:
    push ax
    push bx
    push cx
    push dx
    push si

    call DrawBackground
    call DrawAllTrees
    call DrawFuelBar
    call RedrawDashesNoAdvance

    mov al,[obs_active]
    cmp al,0
    je  .no_obs
    mov bx,[obs_x]
    mov dl,[obs_y]
    mov dh,0
    call DrawObstacleCar
.no_obs:

    mov al,[coin_active]
    cmp al,0
    je  .no_coin
    mov bx,[coin_x]
    mov dl,[coin_y]
    mov dh,0
    call DrawCoin
.no_coin:

    mov bx,[player_x]
    mov dx,[player_y]
    call DrawPlayerCar

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

ShowRunConfirmBox:
    push ax
    push bx
    push cx
    push dx
    push si

    mov al,1
    mov bx,CONF_X
    mov dx,CONF_Y
    mov cx,CONF_W
    mov si,CONF_H
    call RectFill

    mov al,15
    mov bx,CONF_X+2
    mov dx,CONF_Y+2
    mov cx,CONF_W-4
    mov si,2
    call RectFill

    mov ah,02h
    mov bh,0
    mov dh,(CONF_Y/8)+3
    mov dl,10
    int 10h

    mov si,RunConfirmMsg
.scp:
    lodsb
    cmp al,0
    je  .scp_done
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    jmp .scp
.scp_done:

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

HandleResumeGame:
    mov byte [game_paused],0
    mov byte [confirm_active],0
    call RedrawFullFrame
    ret

HandleEndFromGame:
    mov byte [game_started],0
    mov byte [game_paused],0
    mov byte [confirm_active],0
    mov byte [obs_active],0
    mov byte [coin_active],0

    call ShowEndSequence

    mov byte [end_cause],END_CAUSE_NONE
    mov byte [obs_timer],0
    mov byte [coin_timer],0
    mov byte [dash_offset],0
    mov word [coins_collected],0

    call DrawStartScreen
    ret

ShowIntroScreen:
    push ax
    push bx
    push cx
    push dx
    push si

    mov al,1
    call FillScreen

    mov ah,02h
    mov bh,0
    mov dh,5
    mov dl,8
    int 10h

    mov si,GameTitleStr
.si1:
    lodsb
    cmp al,0
    je  .skip1
    mov ah,0Eh
    mov bh,0
    mov bl,14
    int 10h
    jmp .si1
.skip1:

    mov ah,02h
    mov bh,0
    mov dh,8
    mov dl,10
    int 10h

    mov si,DevNameStr
.si2:
    lodsb
    cmp al,0
    je  .skip2
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    jmp .si2
.skip2:

    mov ah,02h
    mov bh,0
    mov dh,10
    mov dl,10
    int 10h

    mov si,RollStr
.si3:
    lodsb
    cmp al,0
    je  .skip3
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    jmp .si3
.skip3:

    mov ah,02h
    mov bh,0
    mov dh,18
    mov dl,10
    int 10h

    mov si,LoadingStr
.ld1:
    lodsb
    cmp al,0
    je  .ld_done
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    jmp .ld1
.ld_done:

    mov cx,30
    xor bx,bx

.load_loop:
    mov ax,bx
    shl ax,1
    add ax,30
    mov dx,150
    mov si,4

    push cx
    mov cx,6
    mov al,12
    mov bx,ax
    call RectFill
    pop cx

    call DelayFrame

    inc bx
    loop .load_loop

    mov ah,02h
    mov bh,0
    mov dh,20
    mov dl,5
    int 10h

    mov si,IntroContinueStr
.ic1:
    lodsb
    cmp al,0
    je  .ic_done
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    jmp .ic1
.ic_done:

    call WaitKeyOrEsc_ExitProgramAllowed

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

ShowInstructionScreen:
    push ax
    push bx
    push cx
    push dx
    push si

    mov al,2
    call FillScreen

    mov ah,02h
    mov bh,0
    mov dh,3
    mov dl,20
    int 10h
    mov si,InstrHeaderStr
.ih1:
    lodsb
    cmp al,0
    je  .ih_done
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    jmp .ih1
.ih_done:

    mov ah,02h
    mov dh,6
    mov dl,3
    int 10h
.ins1:
    lodsb
    cmp al,0
    je  .i1_done
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    jmp .ins1
.i1_done:

    mov ah,02h
    mov dh,8
    mov dl,3
    int 10h
.ins2:
    lodsb
    cmp al,0
    je  .i2_done
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    jmp .ins2
.i2_done:

    mov ah,02h
    mov dh,10
    mov dl,3
    int 10h
.ins3:
    lodsb
    cmp al,0
    je  .i3_done
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    jmp .ins3
.i3_done:

    mov ah,02h
    mov dh,12
    mov dl,3
    int 10h
.ins4:
    lodsb
    cmp al,0
    je  .i4_done
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    jmp .ins4
.i4_done:

    mov ah,02h
    mov dh,14
    mov dl,3
    int 10h
.ins5:
    lodsb
    cmp al,0
    je  .i5_done
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    jmp .ins5
.i5_done:

    mov ah,02h
    mov dh,18
    mov dl,5
    int 10h
    mov si,InstrContinueStr
.icnt:
    lodsb
    cmp al,0
    je  .icnt_done
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    jmp .icnt
.icnt_done:

    call WaitKeyOrEsc_ExitProgramAllowed

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

WaitKeyOrEsc_ExitProgramAllowed:
    push ax

    mov byte [last_scancode],0

.wait_loop:
    mov al,[last_scancode]
    cmp al,0
    je  .wait_loop

    mov byte [last_scancode],0

    cmp al,SC_ESC
    je  .got_esc

    pop ax
    ret

.got_esc:
    call ConfirmExitProgram
    jmp .wait_loop

ConfirmExitProgram:
    push ax
    push bx
    push cx
    push dx
    push si

    mov al,0
    call FillScreen

    mov al,1
    mov bx,CONF_X
    mov dx,CONF_Y
    mov cx,CONF_W
    mov si,CONF_H
    call RectFill

    mov al,15
    mov bx,CONF_X+2
    mov dx,CONF_Y+2
    mov cx,CONF_W-4
    mov si,2
    call RectFill

    mov ah,02h
    mov bh,0
    mov dh,(CONF_Y/8)+3
    mov dl,9
    int 10h

    mov si,ExitProgramMsg
.ce1:
    lodsb
    cmp al,0
    je  .ce_done
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    jmp .ce1
.ce_done:

    mov byte [last_scancode],0

.wait_choice:
    mov al,[last_scancode]
    cmp al,0
    je  .wait_choice
    mov byte [last_scancode],0

    cmp al,SC_Y
    je  .yes
    cmp al,SC_N
    je  .no
    cmp al,SC_ESC
    je  .no

    jmp .wait_choice

.yes:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    call ExitToDOS

.no:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

ExitToDOS:
    call UninstallKeyboardISR

    mov ax,0003h
    int 10h

    mov ax,4C00h
    int 21h

ShowEndSequence:
    push ax

    call ShowEndCauseBox
    call ShowEndSummaryScreen

    pop ax
    ret

ShowEndCauseBox:
    push ax
    push bx
    push cx
    push dx
    push si

    mov al,0
    call FillScreen

    mov al,4
    mov bx,CONF_X
    mov dx,CONF_Y
    mov cx,CONF_W
    mov si,CONF_H
    call RectFill

    mov al,15
    mov bx,CONF_X+2
    mov dx,CONF_Y+2
    mov cx,CONF_W-4
    mov si,2
    call RectFill

    mov ah,02h
    mov bh,0
    mov dh,(CONF_Y/8)+3
    mov dl,8
    int 10h

    mov si,EndQuitMsg
.se1:
    lodsb
    cmp al,0
    je  .se_done
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    jmp .se1
.se_done:

    mov ah,02h
    mov dh,(CONF_Y/8)+6
    mov dl,10
    int 10h
    mov si,EndPressKeyMsg
.se2:
    lodsb
    cmp al,0
    je  .se2_done
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    jmp .se2
.se2_done:

    call WaitKeyOrEsc_ExitProgramAllowed

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

ShowEndSummaryScreen:
    push ax
    push bx
    push cx
    push dx
    push si

    mov al,1
    call FillScreen

    mov ah,02h
    mov bh,0
    mov dh,4
    mov dl,8
    int 10h
    mov si,EndSummaryHeader
.es1:
    lodsb
    cmp al,0
    je  .es1_done
    mov ah,0Eh
    mov bh,0
    mov bl,14
    int 10h
    jmp .es1
.es1_done:

    mov ah,02h
    mov dh,7
    mov dl,5
    int 10h
    mov si,EndNameLabel
.esn1:
    lodsb
    cmp al,0
    je  .esn1_done
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    jmp .esn1
.esn1_done:

    mov ah,02h
    mov dh,7
    mov dl,20
    int 10h
    mov si,DevNameStr
.esn2:
    lodsb
    cmp al,0
    je  .esn2_done
    mov ah,0Eh
    mov bh,0
    mov bl,11
    int 10h
    jmp .esn2
.esn2_done:

    mov ah,02h
    mov dh,9
    mov dl,5
    int 10h
    mov si,EndRollLabel
.esr1:
    lodsb
    cmp al,0
    je  .esr1_done
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    jmp .esr1
.esr1_done:

    mov ah,02h
    mov dh,9
    mov dl,20
    int 10h
    mov si,RollStr
.esr2:
    lodsb
    cmp al,0
    je  .esr2_done
    mov ah,0Eh
    mov bh,0
    mov bl,11
    int 10h
    jmp .esr2
.esr2_done:

    mov ah,02h
    mov dh,11
    mov dl,5
    int 10h
    mov si,EndCoinsLabel
.esc1:
    lodsb
    cmp al,0
    je  .esc1_done
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    jmp .esc1
.esc1_done:

    mov ax,[coins_collected]
    call PrintNumberAtCursor

    mov ah,02h
    mov dh,15
    mov dl,3
    int 10h
.ei1:
    lodsb
    cmp al,0
    je  .ei_done
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    jmp .ei1
.ei_done:

    mov byte [last_scancode],0

.wait_end_choice:
    mov al,[last_scancode]
    cmp al,0
    je  .wait_end_choice
    mov byte [last_scancode],0

    cmp al,SC_ESC
    je  .try_exit

    cmp al,SC_ENTER
    je  .back_to_main
    cmp al,SC_SPACE
    je  .back_to_main

    jmp .wait_end_choice

.try_exit:
    call ConfirmExitProgram
    jmp .wait_end_choice

.back_to_main:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

PrintNumberAtCursor:
    push ax
    push bx
    push cx
    push dx

    mov bx,10
    xor cx,cx
    cmp ax,0
    jne .pn_loop
    mov dl,'0'
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    jmp .pn_done

.pn_loop:
    xor dx,dx
    div bx
    add dl,'0'
    push dx
    inc cx
    cmp ax,0
    jne .pn_loop

.pn_print:
    pop dx
    mov ah,0Eh
    mov bh,0
    mov bl,15
    int 10h
    loop .pn_print

.pn_done:
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

player_x       dw 0
player_y       dw 0
player_lane    db 0
game_started   db 0
game_paused    db 0
confirm_active db 0
last_scancode  db 0

end_cause       db 0
coins_collected dw 0

old_int9_off dw 0
old_int9_seg dw 0

trees_left:
    dw 20,10, 30,40, 15,70, 25,100, 40,130, 15,160, 60,180, 0FFFFh
trees_right:
    dw 250,20, 270,50, 300,80, 280,110, 260,140, 290,160, 310,185, 0FFFFh

GameTitleStr       db 'THE LAST IGNITION',0
DevNameStr         db 'Developer: Amayed Afroz',0
RollStr            db 'Roll No: 24L-6113',0
LoadingStr         db 'Loading...',0
IntroContinueStr   db 'Press any key to continue',0

InstrHeaderStr     db 'INSTRUCTIONS',0
Instr1Str          db '- Arrow keys: move car (L/R/U/D)',0
Instr2Str          db '- Collect coins to increase score',0
Instr3Str          db '- Fuel bar shows remaining fuel',0
Instr4Str          db '- ESC: pause game and open exit box',0
Instr5Str          db '- Y/N only work in confirmation boxes',0
InstrContinueStr   db 'Press any key to go to main screen',0

MainMsg            db 'Press any key to start the game.',0

RunConfirmMsg      db 'Do you want to exit? (Y/N)',0
ExitProgramMsg     db 'Exit game and return to DOS? (Y/N)',0

EndQuitMsg         db 'Game Over: You quit the game.',0
EndPressKeyMsg     db 'Press any key to continue...',0

EndSummaryHeader   db 'RUN SUMMARY',0
EndNameLabel       db 'Player Name:',0
EndRollLabel       db 'Roll No:',0
EndCoinsLabel      db 'Coins Collected:',0
EndInstrStr        db 'ENTER/SPACE: main menu   ESC: exit.',0