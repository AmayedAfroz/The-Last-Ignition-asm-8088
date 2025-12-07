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

CONF_W          equ 280
CONF_H          equ 60
CONF_X          equ (SCREEN_W - CONF_W)/2
CONF_Y          equ (SCREEN_H - CONF_H)/2

END_CAUSE_NONE  equ 0
END_CAUSE_QUIT  equ 1
END_CAUSE_FUEL  equ 2   
END_CAUSE_CRASH equ 3   

start:

	call InputPlayerInfo
    call InitializeGame     
    call InstallKeyboardISR 
	call InstallTimerISR

game_loop:
    call DelayFrame
    
    mov al, [game_paused]
    cmp al, 1
    je .skip_erase

    mov bx, [player_x]
    mov dx, [player_y]
    call EraseCarArea

.skip_erase:
    call HandleInput

    mov al, [game_started]
    cmp al, 0
    je .only_player
    mov al, [game_paused]
    cmp al, 0
    jne .only_player

    call UpdateGameLogic

.only_player:
    mov al, [game_paused]
    cmp al, 1
    je .skip_draw

    mov bx, [player_x]
    mov dx, [player_y]
    call DrawPlayerCar

.skip_draw:
    jmp game_loop
	
	

InputPlayerInfo:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov ax, 0013h
    int 10h

    mov ah, 02h
    mov bh, 0
    mov dh, 10
    mov dl, 5
    int 10h

    mov si, InputPromptStr
.print_p:
    lodsb
    cmp al, 0
    je .print_instr
    mov ah, 0Eh
    mov bl, 15
    int 10h
    jmp .print_p

.print_instr:
    mov ah, 02h
    mov dh, 12
    mov dl, 5
    int 10h
    mov si, InputInstrStr
.pi_loop:
    lodsb
    cmp al, 0
    je .start_input
    mov ah, 0Eh
    mov bl, 7
    int 10h
    jmp .pi_loop

.start_input:
    mov word [PlayerNameIdx], 0
    
    mov ah, 02h
    mov dh, 10
    mov dl, 23
    int 10h

.input_loop:
    mov ah, 00h
    int 16h

    cmp al, 0Dh
    je .input_done

    cmp al, 08h
    je .handle_backspace

    cmp word [PlayerNameIdx], 15
    jae .input_loop

    mov di, PlayerNameBuffer
    add di, [PlayerNameIdx]
    mov [di], al
    
    mov ah, 0Eh
    mov bl, 14
    int 10h
    
    inc word [PlayerNameIdx]
    jmp .input_loop

.handle_backspace:
    cmp word [PlayerNameIdx], 0
    je .input_loop

    mov ah, 0Eh
    mov al, 08h
    int 10h
    mov al, ' '
    int 10h
    mov al, 08h
    int 10h

    dec word [PlayerNameIdx]
    mov di, PlayerNameBuffer
    add di, [PlayerNameIdx]
    mov byte [di], ' '
    jmp .input_loop

.input_done:
    mov di, PlayerNameBuffer
    add di, [PlayerNameIdx]
    mov byte [di], 0

    mov ax, 0013h
    int 10h

    mov ah, 02h
    mov bh, 0
    mov dh, 10
    mov dl, 5
    int 10h

    mov si, InputRollStr
.print_r:
    lodsb
    cmp al, 0
    je .print_roll_instr
    mov ah, 0Eh
    mov bl, 15
    int 10h
    jmp .print_r

.print_roll_instr:
    mov ah, 02h
    mov dh, 12
    mov dl, 5
    int 10h
    mov si, InputInstrStr
.pri_loop:
    lodsb
    cmp al, 0
    je .start_roll_input
    mov ah, 0Eh
    mov bl, 7
    int 10h
    jmp .pri_loop

.start_roll_input:
    mov word [PlayerRollIdx], 0
    
    mov ah, 02h
    mov dh, 10
    mov dl, 23
    int 10h

.roll_loop:
    mov ah, 00h
    int 16h

    cmp al, 0Dh
    je .roll_done

    cmp al, 08h
    je .roll_backspace

    cmp word [PlayerRollIdx], 15
    jae .roll_loop

    mov di, PlayerRollBuffer
    add di, [PlayerRollIdx]
    mov [di], al
    
    mov ah, 0Eh
    mov bl, 14
    int 10h
    
    inc word [PlayerRollIdx]
    jmp .roll_loop

.roll_backspace:
    cmp word [PlayerRollIdx], 0
    je .roll_loop

    mov ah, 0Eh
    mov al, 08h
    int 10h
    mov al, ' '
    int 10h
    mov al, 08h
    int 10h

    dec word [PlayerRollIdx]
    mov di, PlayerRollBuffer
    add di, [PlayerRollIdx]
    mov byte [di], ' '
    jmp .roll_loop

.roll_done:
    mov di, PlayerRollBuffer
    add di, [PlayerRollIdx]
    mov byte [di], 0

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
	
	InitializeGame:
    mov ax,0013h
    int 10h

    mov ax,cs
    mov ds,ax
    mov ax,0A000h
    mov es,ax

    mov byte [obs_active],0
    mov byte [coin_active],0
    mov byte [game_started],0
    mov byte [game_paused],0
    mov byte [confirm_active],0
    mov word [coins_collected],0
    
    mov byte [key_left_held],0
    mov byte [key_right_held],0
    mov byte [input_processed],0

    mov byte [player_lane],1
    mov ax,BASE_LEFT_X + LANE_STEP
    mov [player_x],ax
    mov ax,PLAYER_Y
    mov [player_y],ax

    call DrawStartScreen
    ret

UpdateGameLogic:
    mov al, [game_started]
    cmp al, 0
    je .ugl_ret
    mov al, [game_paused]
    cmp al, 0
    jne .ugl_ret

    call ProcessFuelLogic
    cmp byte [end_cause], END_CAUSE_NONE
    jne .ugl_ret

    call AnimateDashes
    call ProcessSpawning
    
    call ProcessObstacles
    cmp byte [end_cause], END_CAUSE_NONE
    jne .ugl_ret

    call ProcessCoins
    call ProcessFuelItems

.ugl_ret:
    ret

ProcessFuelLogic:
    mov al, [fuel_loss_timer]
    inc al
    mov [fuel_loss_timer], al
    cmp al, 10
    jb .pfl_done
    
    mov byte [fuel_loss_timer], 0
    mov ax, [fuel_level]
    cmp ax, 0
    je .fuel_empty
    dec ax
    mov [fuel_level], ax
    call DrawFuelBar
    cmp ax, 0
    jne .pfl_done

.fuel_empty:
    mov byte [end_cause], END_CAUSE_FUEL
    call HandleEndFromGame
.pfl_done:
    ret

ProcessSpawning:
    mov al, [spawn_timer]
    cmp al, 0
    je .decide_spawn
    dec al
    mov [spawn_timer], al
    ret

.decide_spawn:
    mov byte [spawn_timer], 20

    cmp word [fuel_level], 15   
    jg .normal_rng              
    
    call GetRandom100           
    cmp al, 50
    jb .force_fuel              

.normal_rng:
    call GetRandom100

    cmp al, 10
    jb .spawn_fuel      

    cmp al, 35
    jb .spawn_coin      

    jmp .spawn_obs


.spawn_obs:
    mov al, [obs_active]
    cmp al, 1
    je .done            
    
    call RandomLaneX
    push ax
    call CheckLaneOccupied
    cmp al, 1
    je .occupied_exit
    
    pop ax
    mov [obs_x], ax
    mov word [obs_y], -18   
    mov [obs_lane], cl
    mov byte [obs_active], 1
    mov bx, [obs_x]
    mov dx, [obs_y]
    call DrawObstacleCar
    jmp .done

.spawn_coin:
    mov al, [coin_active]
    cmp al, 1
    je .done
    
    call RandomLaneX
    push ax
    call CheckLaneOccupied
    cmp al, 1
    je .occupied_exit
    
    pop ax
    mov [coin_x], ax
    mov word [coin_y], -5
    mov [coin_lane], cl
    mov byte [coin_active], 1
    mov bx, [coin_x]
    mov dx, [coin_y]
    call DrawCoin
    jmp .done

.spawn_fuel:
.force_fuel:            
    mov al, [fuel_active]
    cmp al, 1
    je .done
    
    call RandomLaneX
    push ax
    call CheckLaneOccupied
    cmp al, 1
    je .occupied_exit
    
    pop ax
    mov [fuel_x], ax
    mov word [fuel_y], -8
    mov [fuel_lane], cl
    mov byte [fuel_active], 1
    mov bx, [fuel_x]
    mov dx, [fuel_y]
    call DrawFuelItem
    jmp .done

.occupied_exit:
    pop ax              
.done:
    ret


ProcessObstacles:
    mov al, [obs_active]
    cmp al, 0
    je .po_done

    mov bx, [obs_x]
    mov dx, [obs_y]
    call EraseCarArea

    mov ax, [obs_y]
    add ax, MOVE_SPEED
    mov [obs_y], ax

    cmp ax, SCREEN_H
    jge .po_remove

    mov bx, [obs_x]
    mov dx, [obs_y]
    call DrawObstacleCar

    mov bx, [obs_x]
    mov dx, [obs_y]
    mov cx, CAR_W
    mov si, CAR_H
    call CheckCollision
    cmp al, 1
    je .crash
    jmp .po_done

.crash:
	call PlayCrashSound         
    call DrawCollisionSpark

    mov byte [end_cause], END_CAUSE_CRASH
    call HandleEndFromGame
    jmp .po_done

.po_remove:
    mov byte [obs_active], 0
.po_done:
    ret

ProcessCoins:
    mov al, [coin_active]
    cmp al, 0
    je .pc_done

    mov bx, [coin_x]
    mov dx, [coin_y]
    call EraseCoin

    mov ax, [coin_y]
    add ax, COIN_SPEED
    mov [coin_y], ax

    cmp ax, SCREEN_H
    jge .pc_remove

    mov bx, [coin_x]
    mov dx, [coin_y]
    call DrawCoin

    mov bx, [coin_x]
    mov dx, [coin_y]
    mov cx, 4
    mov si, 4
    call CheckCollision
    cmp al, 1
    je .collect_coin
    jmp .pc_done

.collect_coin:
    mov bx, [coin_x]
    mov dx, [coin_y]
    call EraseCoin
	
	mov si, sfx_coin            
    call PlaySFX_ISR            

    add word [coins_collected], 10
    mov byte [coin_active], 0
    
    call DrawScoreUI    
    
    jmp .pc_done

.pc_remove:
    mov byte [coin_active], 0
.pc_done:
    ret



ProcessFuelItems:
    mov al, [fuel_active]
    cmp al, 0
    je .pf_done

    mov bx, [fuel_x]
    mov dx, [fuel_y]
    call EraseFuelItem

    mov ax, [fuel_y]
    add ax, COIN_SPEED
    mov [fuel_y], ax

    cmp ax, SCREEN_H
    jge .pf_remove

    mov bx, [fuel_x]
    mov dx, [fuel_y]
    call DrawFuelItem

    mov bx, [fuel_x]
    mov dx, [fuel_y]
    mov cx, 6
    mov si, 8
    call CheckCollision
    cmp al, 1
    je .collect_fuel
    jmp .pf_done

.collect_fuel:
    mov bx, [fuel_x]
    mov dx, [fuel_y]
    call EraseFuelItem
	
	mov si, sfx_fuel            
    call PlaySFX_ISR            

    mov word [fuel_level], 67
    call DrawFuelBar
    mov byte [fuel_active], 0
    jmp .pf_done

.pf_remove:
    mov byte [fuel_active], 0
.pf_done:
    ret






DrawBackground:
    mov bx, 0           
    mov cx, 80          
    call DrawGrassPanel

    mov bx, 240         
    mov cx, 80          
    call DrawGrassPanel

    mov al, 8           
    mov bx, 80          
    xor dx, dx
    mov cx, 160         
    mov si, 200         
    call RectFill

    mov bx, 74
    call DrawProDivider

    mov bx, 240
    call DrawProDivider
    ret

DrawFuelBar1:
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

    mov al, [dash_offset]
    add al, DASH_STEP
    cmp al, DASH_PERIOD
    jb  .keep
    sub al, DASH_PERIOD
.keep:
    mov [dash_offset], al

    mov al, COL_ROAD
    mov bx, ROAD_X + LANE_W
    mov dx, 0
    mov cx, 3
    mov si, SCREEN_H
    call RectFill

    mov bx, ROAD_X + 2*LANE_W
    mov dx, 0
    mov cx, 3
    mov si, SCREEN_H
    call RectFill

    mov bx, ROAD_X + LANE_W
    mov al, COL_DASH
    call DrawDashedLine_Animated

    mov bx, ROAD_X + 2*LANE_W
    mov al, COL_DASH
    call DrawDashedLine_Animated

    mov bx, 74      
    call DrawProDivider

    mov bx, 240     
    call DrawProDivider

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
    mov dx,[obs_y]    
    call EraseCarArea

    mov ax,[obs_y]
    add ax,MOVE_SPEED
    mov [obs_y],ax

    cmp ax,SCREEN_H
    jge .remove_obs       

    mov bx,[obs_x]
    mov dx,[obs_y]
    call DrawObstacleCar
    jmp .done

.remove_obs:
    mov byte [obs_active],0
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
    
    mov word [obs_y], -18   
    
    mov byte [obs_active],1
    
    mov bx,[obs_x]
    mov dx,[obs_y]
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
    call RectFillClipped    
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
    
    cmp dx, SCREEN_H
    jge .skip_erase_coin

    mov al, COL_ROAD
    mov cx, 4
    mov si, 4
    call RectFillClipped

.skip_erase_coin:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret



DrawFuelItem:
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov al, 13
    mov cx, 6
    mov si, 8
    call RectFillClipped
    
    mov al, 15
    push bx
    push dx
    add bx, 1
    sub dx, 2   
    mov cx, 4
    mov si, 2
    call RectFillClipped
    pop dx
    pop bx
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

EraseFuelItem:
    push ax
    push bx
    push cx
    push dx
    push si
    
    cmp dx, SCREEN_H
    jge .skip_erase_fuel

    mov al, COL_ROAD
    mov cx, 6
    mov si, 8
    call RectFillClipped
    
    push bx
    push dx
    add bx, 1
    sub dx, 2
    mov cx, 4
    mov si, 2
    call RectFillClipped
    pop dx
    pop bx

.skip_erase_fuel:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

DrawFuelBar:
    push ax
    push bx
    push cx
    push dx
    push si

    mov al, 0      
    mov bx, 0      
    mov dx, 9      
    mov cx, 71     
    mov si, 10     
    call RectFill

    mov al, 15     
    mov bx, 1      
    mov dx, 10     
    mov cx, 69     
    mov si, 8      
    call RectFill

    mov al, 0
    mov bx, 2      
    mov dx, 11     
    mov cx, 67     
    mov si, 6      
    call RectFill

    mov cx, [fuel_level] 
    cmp cx, 0
    jle .empty
    
    cmp cx, 67
    jbe .check_color
    mov cx, 67

.check_color:
    cmp cx, 40
    ja .col_green
    cmp cx, 20
    ja .col_yellow
    mov al, 4     
    jmp .draw_now
.col_yellow:
    mov al, 14    
    jmp .draw_now
.col_green:
    mov al, 2     

.draw_now:
    mov bx, 2     
    mov dx, 11    
    mov si, 6     
    call RectFill

.empty:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

DrawCollisionSpark:
    push ax
    push bx
    push cx
    push dx
    push si

    mov bx, [player_x]
    mov dx, [player_y]
    
    add bx, 2
    add dx, 5
    
    mov al, 14      
    mov cx, 8
    mov si, 8
    call RectFill
    
    mov al, 4       
    add bx, 2
    add dx, 2
    mov cx, 4
    mov si, 4
    call RectFill
    
    mov al, 14
    
    mov bx, [player_x]
    sub bx, 2
    mov dx, [player_y]
    mov cx, 2
    mov si, 2
    call RectFill
    
    mov bx, [player_x]
    add bx, 12
    call RectFill

    call DelayFrame
    call DelayFrame
    call DelayFrame

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret




CheckCollision:
    push bx
    push cx
    push dx
    push si
    push di 

    mov ax, bx
    add ax, cx      
    cmp ax, [player_x]
    jle .no_hit
    
    mov ax, [player_x]
    add ax, CAR_W   
    cmp bx, ax
    jge .no_hit
    
    mov ax, dx
    add ax, si      
    cmp ax, [player_y]
    jle .no_hit
    
    mov ax, [player_y]
    add ax, CAR_H   
    cmp dx, ax
    jge .no_hit
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    mov al, 1
    ret

.no_hit:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    mov al, 0
    ret	
	


EraseCarArea:
    push ax
    push bx
    push cx
    push dx
    push si

    cmp dx, SCREEN_H
    jge .skip_erase

    mov al, COL_ROAD
    mov cx, CAR_W
    mov si, CAR_H+2   
    
    call RectFillClipped 

.skip_erase:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

RandomLaneX:
    push dx
    mov al, 00h
    out 70h, al
    jmp $+2
    in al, 71h
    and al, 00000011b
    cmp al, 3
    jb .rl_ok
    mov al, 2
.rl_ok:
    mov cl, al         
    
    mov ah, 0
    mov bx, BASE_LEFT_X
    cmp al, 0
    je .rl_fin
    add bx, LANE_STEP
    cmp al, 1
    je .rl_fin
    add bx, LANE_STEP
.rl_fin:
    mov ax, bx         
    pop dx
    ret
	
	
CheckLaneOccupied:
    cmp byte [obs_active], 1
    jne .check_coin
    cmp byte [obs_lane], cl
    je .occupied
.check_coin:
    cmp byte [coin_active], 1
    jne .check_fuel
    cmp byte [coin_lane], cl
    je .occupied
.check_fuel:
    cmp byte [fuel_active], 1
    jne .clear
    cmp byte [fuel_lane], cl
    je .occupied
.clear:
    mov al, 0
    ret
.occupied:
    mov al, 1
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
RectFillClipped:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    cmp bx, SCREEN_W
    jae .rclip_done      

    cmp dx, 0
    jge .check_bottom    
    
    add si, dx           
    cmp si, 0
    jle .rclip_done      
    xor dx, dx           
    jmp .do_draw

.check_bottom:
    mov bp, dx
    add bp, si           
    cmp bp, SCREEN_H
    jbe .do_draw         

    sub bp, SCREEN_H     
    sub si, bp           
    cmp si, 0
    jle .rclip_done

.do_draw:
    call RectFill

.rclip_done:
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
    call RectFillClipped    

    mov al,9
    push bx
    push dx
    add bx,3
    add dx,3
    mov cx,CAR_W-6
    mov si,5
    call RectFillClipped    
    pop dx
    pop bx

    mov al,15
    push bx
    push dx
    add bx,(CAR_W/2)-1
    mov cx,2
    mov si,CAR_H
    call RectFillClipped    
    pop dx
    pop bx

    mov al,0
    push bx
    push dx
    add dx,2
    mov cx,2
    mov si,CAR_H-4
    call RectFillClipped    
    add bx,CAR_W-2
    call RectFillClipped    
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
    
    mov ax, cs
    mov ds, ax

    in al, 60h          

    test al, 80h
    jnz .check_break    

    mov [last_scancode], al  

    cmp al, SC_LEFT
    je .press_left
    cmp al, SC_RIGHT
    je .press_right
    cmp al, SC_UP
    je .press_up
    cmp al, SC_DOWN
    je .press_down
    cmp al, SC_ESC           
    je .press_esc
    jmp .chain_old

.press_left:
    mov byte [key_left_held], 1
    jmp .chain_old
.press_right:
    mov byte [key_right_held], 1
    jmp .chain_old
.press_up:
    mov byte [key_up_held], 1
    jmp .chain_old
.press_down:
    mov byte [key_down_held], 1
    jmp .chain_old
.press_esc:                  
    mov byte [key_esc_held], 1
    jmp .chain_old

.check_break:
    mov ah, al
    and ah, 7Fh         

    cmp ah, SC_LEFT
    je .rel_left
    cmp ah, SC_RIGHT
    je .rel_right
    cmp ah, SC_UP
    je .rel_up
    cmp ah, SC_DOWN
    je .rel_down
    cmp ah, SC_ESC      
    je .rel_esc
    jmp .chain_old

.rel_left:
    mov byte [key_left_held], 0
    mov byte [input_processed], 0
    jmp .chain_old
.rel_right:
    mov byte [key_right_held], 0
    mov byte [input_processed], 0
    jmp .chain_old
.rel_up:
    mov byte [key_up_held], 0
    mov byte [input_processed], 0
    jmp .chain_old
.rel_down:
    mov byte [key_down_held], 0
    mov byte [input_processed], 0
    jmp .chain_old
.rel_esc:               
    mov byte [key_esc_held], 0
    mov byte [esc_processed], 0  
    jmp .chain_old

.chain_old:
    pop ds
    pop ax
    jmp far [old_int9_off]
	
InstallTimerISR:
    push ax
    push ds
    push es
    mov ax, cs
    mov ds, ax
    xor ax, ax
    mov es, ax
    mov ax, [es:1Ch*4]
    mov [old_int1c_off], ax
    mov ax, [es:1Ch*4+2]
    mov [old_int1c_seg], ax
    cli
    mov [es:1Ch*4], word MusicISR
    mov [es:1Ch*4+2], cs
    sti
    mov byte [music_active], 1
    mov word [current_tune], bgm_data
    mov word [note_index], 0
    mov byte [note_timer], 1
    pop es
    pop ds
    pop ax
    ret

UninstallTimerISR:
    push ax
    push ds
    push es
    call SilenceSpeaker
    xor ax, ax
    mov es, ax
    cli
    mov ax, [old_int1c_off]
    mov [es:1Ch*4], ax
    mov ax, [old_int1c_seg]
    mov [es:1Ch*4+2], ax
    sti
    pop es
    pop ds
    pop ax
    ret

SilenceSpeaker:
    push ax
    in al, 61h
    and al, 0FCh
    out 61h, al
    pop ax
    ret

MusicISR:
    push ax
    push bx
    push dx
    push ds
    push si
    mov ax, cs
    mov ds, ax

    cmp byte [music_active], 0
    je .chain_timer

    dec byte [note_timer]
    jnz .chain_timer

    mov si, [current_tune]
    add si, [note_index]
    lodsw
    cmp ax, 0FFFFh
    je .handle_end
    
    mov bx, ax
    lodsb
    mov byte [note_timer], al
    add word [note_index], 3

    cmp bx, 0
    je .silence_now
    
    mov al, 182
    out 43h, al
    mov ax, bx
    out 42h, al
    mov al, ah
    out 42h, al
    in al, 61h
    or al, 3
    out 61h, al
    jmp .chain_timer

.silence_now:
    call SilenceSpeaker
    jmp .chain_timer

.handle_end:
    cmp byte [is_sfx_playing], 1
    je .restore_bgm
    mov word [note_index], 0
    mov byte [note_timer], 1
    jmp .chain_timer

.restore_bgm:
    mov word [current_tune], bgm_data
    mov word [note_index], 0
    mov byte [note_timer], 1
    mov byte [is_sfx_playing], 0
    jmp .chain_timer

.chain_timer:
    pop si
    pop ds
    pop dx
    pop bx
    pop ax
    jmp far [old_int1c_off]

PlayCrashSound:
    push ax
    push bx
    push cx
    push dx
    
    mov byte [music_active], 0 
    call SilenceSpeaker

    in al, 61h
    or al, 3
    out 61h, al
    mov bx, 500         
.slide_loop:
    mov al, 0B6h
    out 43h, al
    mov ax, bx
    out 42h, al
    mov al, ah
    out 42h, al
    mov cx, 0500h       
.delay:
    in al, 61h          
    loop .delay
    add bx, 50          
    xor bx, 10          
    cmp bx, 4000        
    jb .slide_loop
    
    call SilenceSpeaker
    pop dx
    pop cx
    pop bx
    pop ax
    ret

PlayMenuSound:
    push ax
    push bx
    push cx
    push dx
    
    mov byte [music_active], 0
    call SilenceSpeaker

    in al, 61h
    or al, 3
    out 61h, al
    mov bx, 6000        
.thud_loop:
    mov al, 0B6h
    out 43h, al
    mov ax, bx
    out 42h, al
    mov al, ah
    out 42h, al
    mov cx, 0400h       
.delay:
    in al, 61h
    loop .delay
    add bx, 200         
    cmp bx, 20000       
    jb .thud_loop
    
    call SilenceSpeaker
    pop dx
    pop cx
    pop bx
    pop ax
    ret

PlaySFX_ISR:
    push ax
    mov byte [is_sfx_playing], 1
    mov [current_tune], si
    mov word [note_index], 0
    mov byte [note_timer], 1
    mov byte [music_active], 1
    pop ax
    ret	
	
	
	

HandleInput:
    push ax
    push bx
    push cx
    push dx

    mov bl, [game_started]
    cmp bl, 0
    jne .check_confirm_state

    mov al, [last_scancode]
    cmp al, 0
    je .done
    mov byte [last_scancode], 0

    cmp al, SC_ESC
    je .pre_start_esc

    mov bx, [obs_x]
    mov dx, [obs_y]
    call EraseCarArea 

    mov byte [game_started], 1
    mov byte [game_paused], 0
    mov byte [confirm_active], 0
    
    mov byte [obs_active], 0
    mov byte [obs_timer], 0
    mov byte [coin_active], 0
    mov byte [coin_timer], 0
    mov byte [fuel_active], 0
    mov byte [dash_offset], 0
	
    mov word [current_tune], bgm_data 
    mov word [note_index], 0          
    mov byte [note_timer], 1          
    mov byte [music_active], 1        
    
    mov word [coins_collected], 0
    call DrawScoreUI    
    
    mov byte [end_cause], END_CAUSE_NONE
    
    mov word [fuel_level], 67   
    mov byte [fuel_loss_timer], 0

    call RedrawFullFrame
    jmp .done

.pre_start_esc:
    call ConfirmExitProgram
	call DrawStartScreen
    jmp .done

.check_confirm_state:
    mov bl, [confirm_active]
    cmp bl, 0
    je .normal_game_checks

    cmp byte [key_esc_held], 1
    jne .check_yn
    
    cmp byte [esc_processed], 1
    je .check_yn

    mov byte [esc_processed], 1 
    jmp .resume_game

.check_yn:
    mov al, [last_scancode]
    cmp al, 0
    je .done
    mov byte [last_scancode], 0

    cmp al, SC_N
    je .resume_game
    cmp al, SC_Y
    je .quit_run
    jmp .done

.resume_game:
    call HandleResumeGame
    jmp .done

.quit_run:
    mov byte [end_cause], END_CAUSE_QUIT
    call HandleEndFromGame
    jmp .done

.normal_game_checks:
    mov bl, [game_paused]
    cmp bl, 0
    jne .done

    cmp byte [key_esc_held], 1
    jne .check_movement

    cmp byte [esc_processed], 1
    je .check_movement  

    mov byte [esc_processed], 1 
    jmp .enter_confirm

.check_movement:
    cmp byte [input_processed], 1
    je .done

    cmp byte [key_left_held], 1
    je .move_left
    cmp byte [key_right_held], 1
    je .move_right
    cmp byte [key_up_held], 1
    je .move_up
    cmp byte [key_down_held], 1
    je .move_down
    jmp .done

.enter_confirm:

	call PlayMenuSound      
	
    mov byte [game_paused], 1
    mov byte [confirm_active], 1
    call ShowRunConfirmBox
    jmp .done

.move_left:
    mov byte [input_processed], 1
    mov bl, [player_lane]
    cmp bl, 0
    je .done
    dec bl
    mov [player_lane], bl
    call RecomputePlayerX
    jmp .done

.move_right:
    mov byte [input_processed], 1
    mov bl, [player_lane]
    cmp bl, 2
    jae .done
    inc bl
    mov [player_lane], bl
    call RecomputePlayerX
    jmp .done

.move_up:
    mov byte [input_processed], 1
    mov ax, [player_y]
    cmp ax, PLAYER_STEP_Y
    jb .set_top_zero
    sub ax, PLAYER_STEP_Y
    jmp .store_y
.set_top_zero:
    xor ax, ax
.store_y:
    mov [player_y], ax
    jmp .done

.move_down:
    mov byte [input_processed], 1
    mov ax, [player_y]
    mov bx, ax
    add bx, CAR_H
    cmp bx, SCREEN_H
    jae .done
    add ax, PLAYER_STEP_Y
    mov bx, ax
    add bx, CAR_H
    cmp bx, SCREEN_H
    jbe .store_y2
    mov ax, SCREEN_H - CAR_H
.store_y2:
    mov [player_y], ax
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


DrawScoreUI:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov al, 1      
    mov bx, 0      
    mov dx, 22     
    mov cx, 71     
    mov si, 14     
    call RectFill

    mov al, 0      
    mov bx, 1      
    mov dx, 23     
    mov cx, 69     
    mov si, 12     
    call RectFill

    mov ah, 02h
    mov bh, 0
    mov dh, 3      
    mov dl, 0      
    int 10h
    
    mov si, ScoreLabelStr
.print_lbl:
    lodsb
    cmp al, 0
    je .print_val
    mov ah, 0Eh
    mov bl, 14    
    int 10h
    jmp .print_lbl

.print_val:
    mov ax, [coins_collected]
    call PrintNumberAtCursor

    pop di
    pop si
    pop dx
    pop cx
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
    mov word [fuel_level], 67

    call DrawBackground       
	call DrawAllTrees
	call DrawAllBushes   
    call DrawFuelBar          
    call RedrawDashesNoAdvance

    mov byte [player_lane],1
    mov ax,BASE_LEFT_X + LANE_STEP
    mov [player_x],ax
    mov ax,PLAYER_Y
    mov [player_y],ax

    mov bx,[player_x]
    mov dx,[player_y]
    call DrawPlayerCar

    call RandomLaneX
	
    mov [obs_x], ax      
    mov word [obs_y], 80 
	
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
	call DrawAllBushes   
    call DrawFuelBar
    
    call DrawScoreUI    
    
    call RedrawDashesNoAdvance

    mov al,[obs_active]
    cmp al,0
    je  .no_obs
    mov bx,[obs_x]
    mov dx,[obs_y]
    call DrawObstacleCar
.no_obs:

    mov al,[coin_active]
    cmp al,0
    je  .no_coin
    mov bx,[coin_x]
    mov dx,[coin_y]
    call DrawCoin
.no_coin:
    
    mov al,[fuel_active]
    cmp al,0
    je .no_fuel
    mov bx,[fuel_x]
    mov dx,[fuel_y]
    call DrawFuelItem
.no_fuel:

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

    mov al, 1
    mov bx, CONF_X
    mov dx, CONF_Y
    mov cx, CONF_W
    mov si, CONF_H
    call RectFill

    mov al, 15
    mov bx, CONF_X+2
    mov dx, CONF_Y+2
    mov cx, CONF_W-4
    mov si, 2
    call RectFill

    
    mov ah, 02h
    mov bh, 0
    mov dh, (CONF_Y/8)+3
    mov dl, 6           
    int 10h

    mov si, RunConfirmMsg
.scp:
    lodsb
    cmp al, 0
    je  .scp_done
    mov ah, 0Eh
    mov bh, 0
    mov bl, 15
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
	
    mov byte [music_active], 1  
	
    call RedrawFullFrame
    ret


HandleEndFromGame:
    mov byte [game_started], 0
    mov byte [game_paused], 0
	
	mov byte [music_active], 0  
    call SilenceSpeaker         
	
    mov byte [confirm_active], 0
    mov byte [obs_active], 0
    mov byte [coin_active], 0
    mov byte [fuel_active], 0

    call ShowEndSequence    

    mov byte [end_cause], END_CAUSE_NONE
    mov byte [obs_timer], 0
    mov byte [coin_timer], 0
    mov byte [dash_offset], 0
    
    mov word [coins_collected], 0

    call DrawStartScreen
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

    mov al, 0
    call FillScreen

    mov al, 1
    mov bx, CONF_X
    mov dx, CONF_Y
    mov cx, CONF_W
    mov si, CONF_H
    call RectFill

    mov al, 15
    mov bx, CONF_X+2
    mov dx, CONF_Y+2
    mov cx, CONF_W-4
    mov si, 2
    call RectFill

    mov ah, 02h
    mov bh, 0
    mov dh, (CONF_Y/8)+3
    mov dl, 3           
    int 10h

    mov si, ExitProgramMsg
.ce1:
    lodsb
    cmp al, 0
    je  .ce_done
    mov ah, 0Eh
    mov bh, 0
    mov bl, 15
    int 10h
    jmp .ce1
.ce_done:

    mov byte [last_scancode], 0
.wait_choice:
    mov al, [last_scancode]
    cmp al, 0
    je  .wait_choice
    mov byte [last_scancode], 0

    cmp al, SC_Y
    je  .yes
    cmp al, SC_N
    je  .no
    cmp al, SC_ESC
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
	call UninstallTimerISR

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

    mov al, 0
    call FillScreen

    mov al, 4           
    mov bx, CONF_X
    mov dx, CONF_Y
    mov cx, CONF_W      
    mov si, CONF_H
    call RectFill

    mov al, 15
    mov bx, CONF_X+2
    mov dx, CONF_Y+2
    mov cx, CONF_W-4
    mov si, 2
    call RectFill

    mov ah, 02h
    mov bh, 0
    mov dh, (CONF_Y/8)+3
    mov dl, 3           
    int 10h

    mov al, [end_cause]
    cmp al, END_CAUSE_FUEL
    je .msg_fuel
    cmp al, END_CAUSE_CRASH
    je .msg_crash
    
    mov si, EndQuitMsg
    jmp .print_cause

.msg_fuel:
    mov si, EndFuelMsg
    jmp .print_cause

.msg_crash:
    mov si, EndCrashMsg

.print_cause:
    lodsb
    cmp al, 0
    je .cause_done
    mov ah, 0Eh
    mov bh, 0
    mov bl, 15      
    int 10h
    jmp .print_cause
.cause_done:

    mov ah, 02h
    mov dh, (CONF_Y/8)+6
    mov dl, 6           
    int 10h
    
    mov si, EndPressKeyMsg
.pk_loop:
    lodsb
    cmp al, 0
    je .pk_done
    mov ah, 0Eh
    mov bl, 15
    int 10h
    jmp .pk_loop
.pk_done:

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

.redraw_safe:
    mov al, 1
    call FillScreen

    mov ah, 02h
    mov bh, 0
    mov dh, 6
    mov dl, 14
    int 10h
    
    mov si, EndSummaryHeader
    call PrintStringYellow   

    mov ah, 02h
    mov dh, 10
    mov dl, 10
    int 10h
    mov si, EndNameLabel
    call PrintStringWhite

    mov ah, 02h
    mov dh, 10
    mov dl, 18
    int 10h
    mov si, PlayerNameBuffer
    call PrintStringCyan

    mov ah, 02h
    mov dh, 12
    mov dl, 10
    int 10h
    mov si, EndRollLabel
    call PrintStringWhite

    mov ah, 02h
    mov dh, 12
    mov dl, 18
    int 10h
    mov si, PlayerRollBuffer
    call PrintStringCyan

    mov ah, 02h
    mov dh, 14
    mov dl, 10
    int 10h
    mov si, EndCoinsLabel
    call PrintStringWhite

    mov ax, [coins_collected]
    call PrintNumberAtCursor

    mov ah, 02h
    mov dh, 18
    mov dl, 4
    int 10h
    mov si, EndInstrStr
    call PrintStringWhite

    mov byte [last_scancode], 0
.wait_end_choice:
    mov al, [last_scancode]
    cmp al, 0
    je .wait_end_choice
    mov byte [last_scancode], 0

    cmp al, SC_ESC
    je .try_exit
    cmp al, SC_ENTER
    je .back_to_main
    cmp al, SC_SPACE
    je .back_to_main
    jmp .wait_end_choice

.try_exit:
    call ConfirmExitProgram
    jmp .redraw_safe 

.back_to_main:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
	
PrintStringWhite:
    mov bl, 15
    jmp PrintStringGeneric
PrintStringYellow:
    mov bl, 14
    jmp PrintStringGeneric
PrintStringCyan:
    mov bl, 11

PrintStringGeneric:
.ps_loop:
    lodsb
    cmp al, 0
    je .ps_done
    mov ah, 0Eh
    int 10h
    jmp .ps_loop
.ps_done:
    ret




PrintNumberAtCursor:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    cmp ax, 0
    jne .convert_start
    mov al, '0'
    mov ah, 0Eh
    mov bl, 14    
    int 10h
    jmp .pnum_done

.convert_start:
    xor cx, cx
    mov bx, 10

.pnum_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne .pnum_loop

.pnum_print_loop:
    pop dx
    add dl, '0'
    mov al, dl
    mov ah, 0Eh
    mov bl, 14    
    int 10h
    loop .pnum_print_loop

.pnum_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret





DrawProDivider:
    push ax
    push cx
    push dx
    push si
    push di
    push bp

    xor dx, dx          
.div_loop:
    cmp dx, SCREEN_H
    jae .div_done

    mov di, dx
    push dx
    shl di, 8
    shl dx, 6
    add di, dx
    pop dx
    add di, bx

    mov byte [es:di], 19    
    inc di

    mov cx, 6           
    xor si, si          
.pat_loop:
    mov ax, dx          
    add ax, si          
    sub al, [dash_offset] 
    test ax, 8          
    jz .set_yellow
    
    mov al, 0           
    jmp .draw_pix
.set_yellow:
    mov al, 14          

.draw_pix:
    mov [es:di], al
    inc di
    inc si
    loop .pat_loop

    mov byte [es:di], 15    

    inc dx
    jmp .div_loop

.div_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret
	
	
	
DrawDottedGrass:
    xor dx, dx
.y_loop:
    cmp dx, SCREEN_H
    jae .bg_done
    xor bx, bx
.x_loop:
    cmp bx, SCREEN_W
    jae .next_line

    mov al, 10      
    
    test bx, 3
    jnz .plot
    test dx, 3
    jnz .plot
    mov al, 2       

.plot:
    mov di, dx
    push dx
    shl di, 8
    shl dx, 6
    add di, dx
    pop dx
    add di, bx
    mov [es:di], al

    inc bx
    jmp .x_loop

.next_line:
    inc dx
    jmp .y_loop
.bg_done:
    ret

DrawRoughBush:
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov [bx_pos], bx
    mov [by_pos], dx

    mov al, 0
    mov bx, [bx_pos]
    mov dx, [by_pos]
    add bx, 2
    add dx, 8
    mov cx, 16
    mov si, 4
    call RectFill

    mov al, 2       
    mov bx, [bx_pos]
    mov dx, [by_pos]
    add dx, 4
    mov cx, 8
    mov si, 6
    call RectFill   
    
    add bx, 10
    call RectFill   
    
    mov bx, [bx_pos]
    add bx, 4
    mov dx, [by_pos]
    add dx, 1
    mov cx, 10
    mov si, 8
    call RectFill   

    mov al, 4
    mov bx, [bx_pos]
    add bx, 3
    mov dx, [by_pos]
    add dx, 6
    mov cx, 2
    mov si, 1
    call RectFill
    add bx, 10
    add dx, 1
    call RectFill

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

    mov [tx], bx
    mov [ty], dx

    mov al, 6
    mov bx, [tx]
    add bx, 5
    mov dx, [ty]
    add dx, 14
    mov cx, 2
    mov si, 4
    call RectFill

    mov al, 2
    mov bx, [tx]
    add bx, 1
    mov dx, [ty]
    add dx, 10
    mov cx, 10
    mov si, 4
    call RectFill
    
    mov al, 4   
    add bx, 2
    add dx, 1
    mov cx, 1
    mov si, 1
    call RectFill
    mov al, 1   
    add bx, 5
    call RectFill

    mov al, 2
    mov bx, [tx]
    add bx, 3
    mov dx, [ty]
    add dx, 6
    mov cx, 6
    mov si, 4
    call RectFill

    mov al, 2
    mov bx, [tx]
    add bx, 4
    mov dx, [ty]
    add dx, 2
    mov cx, 4
    mov si, 4
    call RectFill

    mov al, 14
    mov bx, [tx]
    add bx, 5
    mov dx, [ty]
    mov cx, 2
    mov si, 2
    call RectFill

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
	
	
	
DrawAllBushes:
    mov si, bushes_left
.bl_loop:
    lodsw
    cmp ax, 0FFFFh
    je .br_start
    mov bx, ax
    lodsw
    mov dx, ax
    call DrawRoughBush
    jmp .bl_loop
.br_start:
    mov si, bushes_right
.br_loop:
    lodsw
    cmp ax, 0FFFFh
    je .done
    mov bx, ax
    lodsw
    mov dx, ax
    call DrawRoughBush
    jmp .br_loop
.done:
    ret
	
DrawGrassPanel:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov al, 10      
    mov dx, 0       
    mov si, 200     
    call RectFill   

    mov bp, bx      
    
    xor dx, dx      
.dot_y_loop:
    cmp dx, 200
    jae .panel_done
    
    mov bx, bp      
    mov si, 0       
    
.dot_x_loop:
    cmp si, cx      
    jae .next_dot_line

    mov di, dx
    push dx
    shl di, 8
    shl dx, 6
    add di, dx      
    pop dx
    add di, bx      
    
    mov byte [es:di], 2  

    add bx, 4
    add si, 4
    jmp .dot_x_loop

.next_dot_line:
    add dx, 4       
    jmp .dot_y_loop

.panel_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


GetRandom100:
    push dx
    push cx
    
    mov ah, 00h
    int 1Ah      
    
    mov ax, dx
    xor dx, dx
    mov cx, 100
    div cx       
    
    mov ax, dx   
    
    pop cx
    pop dx
    ret




obs_x       dw 0
obs_y       dw 0    
obs_active  db 0
obs_timer   db 0
dash_offset db 0

obs_lane    db 0    


coin_x       dw 0
coin_y       dw 0    
coin_active  db 0
coin_timer   db 0
coin_lane    db 0    



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
    dw 10,10,  40,60,  15,110,  30,160, 50,90, 0FFFFh
trees_right:
    dw 260,20, 280,70, 250,120, 290,170, 270,50, 0FFFFh

bushes_left:
    dw 50,40,  20,80,  45,130,  10,180, 0FFFFh
bushes_right:
    dw 290,30, 255,90, 285,140, 250,180, 0FFFFh

bx_pos dw 0
by_pos dw 0
tx dw 0
ty dw 0





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
EndNameLabel       db 'PILOT:',0
EndCoinsLabel      db 'SCORE:',0
EndInstrStr        db 'ENTER: Main Menu    ESC: Exit',0


key_left_held   db 0
key_right_held  db 0
key_up_held     db 0
key_down_held   db 0
input_processed db 0    

key_esc_held    db 0
esc_processed   db 0   



spawn_timer     db 0    
spawn_interval  db 25   

fuel_x      dw 0
fuel_y      dw 0
fuel_lane   db 0
fuel_active db 0

fuel_level      dw 60   
fuel_loss_timer db 0    

ScoreLabelStr db "Score:", 0
ScoreLabelOnly db "SCORE", 0   

PlayerNameBuffer    times 20 db ' '  
                    db 0             
PlayerNameIdx       dw 0             

InputPromptStr      db 'Enter Pilot Name: ', 0
InputInstrStr       db '(Max 15 chars, ENTER to confirm)', 0


EndFuelMsg         db 'Game Over: You ran out of Fuel!', 0
EndCrashMsg        db 'Game Over: You crashed!', 0





old_int1c_off   dw 0
old_int1c_seg   dw 0

music_active    db 0
note_timer      db 0
note_index      dw 0
current_tune    dw bgm_data
is_sfx_playing  db 0

bgm_data:
    dw 5423
    db 2
    dw 0
    db 1
    
    dw 5423
    db 2
    dw 0
    db 1
    
    dw 4560
    db 2
    dw 0
    db 1
    
    dw 4063
    db 4
    dw 0
    db 2
    
    dw 5423
    db 2
    dw 0
    db 1
    
    dw 4063
    db 2
    dw 0
    db 1
    
    dw 3619
    db 4
    dw 0
    db 2
    
    dw 5423
    db 2
    dw 0
    db 1
    
    dw 5423
    db 2
    dw 0
    db 1
    
    dw 4560
    db 2
    dw 0
    db 1
    
    dw 4063
    db 4
    dw 0
    db 2
    
    dw 3619
    db 2
    dw 4063
    db 2
    dw 4560
    db 2
    dw 4831
    db 2
    
    dw 0FFFFh    

sfx_coin:
    dw 2000     
    db 1        
    dw 0        
    db 1
    dw 2500     
    db 2
    dw 0FFFFh

sfx_fuel:
    dw 1000
    db 1
    dw 1500
    db 1
    dw 2000
    db 2
    dw 0FFFFh
	
PlayerRollBuffer    times 20 db ' '
                    db 0
PlayerRollIdx       dw 0
InputRollStr        db 'Enter Roll Number: ', 0
EndRollLabel       db 'ROLL NO:',0
	