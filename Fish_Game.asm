[org 0x0100]

jmp start

;<><><><><><><><><><><><><><><( variables )><><><><><><><><><><><><><><>

pre_isr_kb:    dd 0   ; to store old isr for keyboard
pre_isr_timer: dd 0   ; to store old isr for timer

enter_k: db 0         ; flag for enter key
esc:     db 0         ; flag for exit
sft:     db 0         ; flag for shifting control of fish
y:       db 0         ; flag for yes
n:       db 0         ; flag for no

time_tick:   db 0     ; to calculate time
ran_num_1:   dw 3040  ; our random number 1
ran_num_2:   dw 3180  ; our random number 2

fish_cor:   dw 3320   ; initial cordinate of fish
fish_orint: dw 1      ; orientation of fish

fish_cor1:   dw 3564  ; initial cordinate of fish
fish_orint1: dw 0     ; orientation of fish

sco_msg: db ' SCORE: '; string
score:   dw 0         ; player's score

coin1_pos:  dw 3608   ; cordinate of red coin
coin1_life: db 5      ; life-span of red coin
coin2_pos:  dw 3754   ; cordinate of green coin
coin2_life: db 10     ; life-span of green coin

msg_conf: db ' Are You Sure?  [Y]es / [N]o '
screen_buffer: times 4000 db 0 ; scondary area to save our video memory

; PCB layout:
; ax,bx,cx,dx,si,di,bp,sp,ip,cs,ds,ss,es,flags,next,dummy
; 0, 2, 4, 6, 8,10, 12,14,16,18,20,22,24, 26 , 28 , 30
pcb: times 2*16 dw 0    ; space for 2 PCBs
stack: times 2*256 dw 0 ; space for 2 512 byte stacks
nextpcb: dw 1           ; index of next free pcb
current: dw 0           ; index of current pcb

;######################[Music Notes]######################

C4: dw 262
Csh4: dw 278
D4: dw 293
Dsh4: dw 311
E4: dw 230
F4: dw 349
Fsh4: dw 370
G4: dw 393
Gsh4: dw 415
A4: dw 440
Ash4: dw 466
B4: dw 494

C5: dw 523
Csh5: dw 554
D5: dw 587
Dsh5: dw 622
E5: dw 660
F5: dw 698
Fsh5: dw 740
G5: dw 784
Gsh5: dw 831
A5: dw 880
Ash5: dw 932
B5: dw 988

C6: dw 1046
Csh6: dw 1108
D6: dw 1174
Dsh6: dw 1245
E6: dw 1318
F6: dw 1397
Fsh6: dw 1480
G6: dw 1568
Gsh6: dw 1662
A6: dw 1760
Ash6: dw 1864
B6: dw 1975

C7: dw  2093
Csh7: dw 2217
D7: dw 2349
Dsh7: dw 2489
E7: dw 2637
F7: dw 2794
Fsh7: dw 2960
G7: dw 3136
Gsh7: dw 3322
A7: dw 3520
Ash7: dw 3730
B7: dw 3951

;#########################################################

;<><><><><><><><><><><><><><><><><></><><><><><><><><><><><><><><><><><>

;|||//////////////////////////////////////////////////////////////////////|||
;----------------> Function to Fill color between two bounds <---------------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||

    Fill_color:      ; fills passed color inside the 
    push bp          ; boundaries passed by parameters
    mov bp, sp
    push si
    push di
    push ax
    push cx

    mov si, [bp + 4] ; boundries between which we will fill color
    mov di, [bp + 6] ;
    add di, 2
    sub si, di
    mov cx, si
    shr cx, 1        ; divide cx by 2
    mov ax, [bp + 8] ;

    cld
    rep stosw
    
    pop cx
    pop ax
    pop di
    pop si
    Pop bp
    
    ret 6
;'''''''''''''''''''''''''''''''''''''''''

clr_sc:             ; clear's the whole screen
    pusha

    push 0xb800
    pop es
    mov ax, 0x0F20
    mov di, 0
    mov cx, 2000

    cld
    rep stosw

    popa
    ret
;'''''''''''''''''''''''''''''''''''''''''
;|||//////////////////////////////////////////////////////////////////////|||
;----------------------> Cloud and Sky Print Function <----------------------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||

cloud:         ;// prints cloud at the passed cordinate in the sky
    push bp
    mov bp, sp
    push di
    push es
    push ax
    push cx

    mov di, [bp + 4] ;store cordinate (parameter) of cloud
    mov ax, 0xB800
    mov es, ax
    mov ax, 0x0fdb ;0x1f box ascii
    mov cx, 3

    mov word [es:di], ax ;upper part of cloud
    add di,158

    cloud_loop:
    mov word [es:di], ax
    add di, 2
    dec cx
    jnz cloud_loop

    pop cx
    pop ax
    pop es
    pop di
    pop bp
    ret 2
;'''''''''''''''''''''''''''''''''''''''''

Stars:  ;prints starts on the first div on random places
    push ax
    push es
    
    mov ax, 0xB800
    mov es, ax
    mov ax, 0x0FF9

    mov [es:186 + 160], ax      ; offset of 160 cuz needed space for score bar
    mov [es:64 + 160], ax
    mov [es:316 + 160], ax

    mov ah, 0x07  ;;for slightly dim stars
    mov [es:254 + 160], ax
    mov [es:542 + 160], ax
    mov [es:326+ 160], ax

    mov ax, 0x0F2E
    mov [es:302+ 160], ax
    mov [es:408+ 160], ax
    mov [es:46+ 160], ax

    mov al, 0x2A
    mov [es:106 + 160], ax
    mov [es:358 + 160], ax
    mov [es:12 + 160], ax

    pop es
    pop ax

    ret
;'''''''''''''''''''''''''''''''''''''''''

color_sky_day:   ;//print sky and call's cloud function and give then cordinate
    push es
    push ax
    push cx
    push di

    mov ax, 0xB800
    mov es, ax
    mov di, 160
    mov ax, 0x0bdb      ; 0x1220 ;change color of sky
    mov cx, 640
    
    cld
    rep stosw

    push 330
    call cloud

    push 410
    call cloud

    pop di
    pop cx
    pop ax
    pop es
    ret
;'''''''''''''''''''''''''''''''''''''''''

color_sky_night:   ;//print sky and call's start function
    push es
    push ax
    push cx
    push di

    mov ax, 0xB800
    mov es, ax
    mov di, 160
    mov ax, 0x0b20 ;night sky color(black)
    mov cx, 640
    
    cld
    rep stosw

    call Stars

    pop di
    pop cx
    pop ax
    pop es
    ret
;'''''''''''''''''''''''''''''''''''''''''

;|||//////////////////////////////////////////////////////////////////////|||
;---------------> Mountain and it's related print functions <----------------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||

Print_mountains:  ;// prints all mountain and passes them cordinates
    push ax

    mov ax, 660;cordinate to print mountain
    push ax
    call Pr_mount

    mov ax, 848
    push ax
    call Pr_mount   

    mov ax, 718
    push ax
    call Pr_mount
    
    mov ax, 284
    push ax
    call Pr_mount
    
    pop ax
    ret
;'''''''''''''''''''''''''''''''''''''''''

Pr_mount:  ;// print mountain at the required cordinate and call color mountain function and also prints the green belt
    push bp
    mov bp, sp

    push es
    push ax
    push cx
    push di
    push si
    
    mov ax, 0xB800
    mov es, ax ;
    mov di, [bp + 4] ; di ->mountain's left side boundary      
    mov ax, di
    add ax, 2      
    mov si, ax ; si ->mountain's right side boundary

    mov ax, 0x6620 ;0x0adb 
    
    mov word [ES:si], ax
    mov word [ES:di], ax

    p_m:
       add di, 156 
       add si, 164 
       mov word [ES:di], ax
       mov word [ES:si], ax

       push 0x662F ;passing color to fill between
       push di
       push si
       call Fill_color 
       cmp di, 1280
       jb p_m

    mov di, 1440
    mov ax, 0x02db ; 
    mov cx, 80

    cld ; clear directionFlag -> di+2
    rep stosw
   
    pop si
    pop di
    pop cx
    pop ax
    pop es
    pop bp

    ret 2
;'''''''''''''''''''''''''''''''''''''''''

;|||//////////////////////////////////////////////////////////////////////|||
;------------------> Sea and Ship related print functions <------------------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||

Sea:            ; function to print the middle (ship area) sea
    push es
    push ax
    push cx
    push di
    
    mov ax, 0xB800
    mov es, ax
    mov di, 1600
    mov ax, 0x09db ;sea color 09 db ascii for box char
    mov cx, 800

    cld
    rep stosw

    pop di
    pop cx
    pop ax
    pop es
    ret
;'''''''''''''''''''''''''''''''''''''''''

Ship:               ; call's print function for ship and 
    Push ax         ; give cordinate and size of that ships

    mov ax, 19      ; size of ship
    push ax
    mov ax, 2128    ; position of ship
    push ax
    call Print_Ship

    pop ax
    ret 
;'''''''''''''''''''''''''''''''''''''''''    

Print_Ship:             ; will print ship at the given
    push bp             ; cordinate and size of ship
    mov bp, sp

    push es
    push ax
    push cx
    push di
    push si
    push bx
    push dx
    
    mov ax, 0xB800
    mov es, ax
    mov ax, 0x0fec
    mov di, [bp + 4]    ; starting cordinate
    mov cx, [bp + 6]    ; size of ship

    mov si ,di
    mov word [es:si], ax 

    mov bx, 3           ; height of every ship with size > 26

    cmp cx, 26 
    ja skip_ship1
    mov bx, 2           ; height of ship with size less than 26

    cmp cx, 10     
    ja skip_ship2
    mov bx, 1           ; height of ship with size less than 10

    skip_ship2:
    skip_ship1:
   
    upper_part:
      add si, 2
      mov word [es:si], ax 
      dec cx
    jnz upper_part

    mov ax, 0x08de      ; left side border of ship
    mov dx, 0x08dd      ; right side border of ship
    
    side_parts:
      add di, 162
      add si, 158
      mov word [es:di], ax
      mov word [es:si], dx 

      push 0x08db
      push di
      push si
      call Fill_color   ; function will fill color between the boundaries

      dec bx
    jnz side_parts

    pop dx
    pop bx
    pop si
    pop di
    pop cx
    pop ax
    pop es
    pop bp

    ret 4
;//'''''''''''''''''''''''''''''''''''''''''

;|||//////////////////////////////////////////////////////////////////////|||
;----------------> Deep Sea and its objects print functions <----------------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||

deep_sea:               ; colors the deep sea and call's the print
    push es             ; function of sea weed, fish...    
    push ax             ; and also passes parameters to them
    push cx
    push di
    
    mov ax, 0xB800
    mov es, ax
    mov di, 3040
    mov ax, 0x1020 
    mov cx, 480

    cld
    rep stosw

    push 3904           ; last row is from 3840 to 3998
    push 4              ; length of weed
    call sea_weeds

    push 3910   
    push 3       
    call sea_weeds
    
    push 3898   
    push 3       
    call sea_weeds
    ;--------

    push 3870           ; last row is from 3840 to 3998
    push 3      
    call sea_weeds

    push 3864   
    push 2       
    call sea_weeds
    
    push 3858   
    push 3       
    call sea_weeds
    ;--------

    push 3988           ; last row is from 3840 to 3998
    push 3      
    call sea_weeds

    push 3980   
    push 5       
    call sea_weeds
    
    push 3974   
    push 4       
    call sea_weeds
    ;--------

    push word [fish_orint] ; 0 for fish facing right and 1 for fish facing left
    push word [fish_cor]   ; passing fish cordinate
    call fish
    ;--------

    push word [fish_orint1] ; 0 for fish facing right and 1 for fish facing left
    push word [fish_cor1]   ; passing fish cordinate
    call fish
    ;--------

    push 3930
    call Treasure
    ;--------

    call print_coins

    pop di
    pop cx
    pop ax
    pop es
    ret
;'''''''''''''''''''''''''''''''''''''''''

sea_weeds:              ; prints the sea weeds of the given 
    push bp             ; size and at the given location
    mov bp, sp

    push ax
    push bx
    push es
    push cx
    push di

    mov ax, 0xb800
    mov es, ax
    mov ax, 0x12dd
    mov bx, 0x12de
    mov di, [bp + 6]    ; cordinate of weed
    mov cx, [bp + 4]    ; size of weed 

    weed_l:
        mov [es:di], ax
        sub di,160
        dec cx
        cmp cx, 0
        je break

        mov [es:di], bx
        sub di, 160
        dec cx
        cmp cx, 0
        jne weed_l 

    break:

    pop di
    pop cx
    pop es
    pop bx
    pop ax
    pop bp

    ret 4
;'''''''''''''''''''''''''''''''''''''''''

Treasure:               ; prints the treasure box 
    push bp             ; at the position passed
    mov bp, sp

    push ax
    push es
    push di
    push si

    mov ax, 0xb800
    mov es, ax
    mov si, [bp + 4];
    mov di, si

    mov word [es:di], 0x6edd
    sub di, 160
    mov word [es:di], 0x6edd
    sub di, 160
    mov di, si
    add di,12
    mov word [es:di], 0x6ede
    push 0x6620
    push si
    push di
    call Fill_color
    sub di, 160
    mov word [es:di], 0x6ede
    sub di, 2
    mov word [es:di], 0x605f
    sub di, 2
    mov word [es:di], 0x605F
    sub di, 2
    mov word [es:di], 0x6edc
    sub di, 2
    mov word [es:di], 0x605F
    sub di, 2
    mov word [es:di], 0x605F
    
    pop si
    pop di
    pop es
    pop ax
    pop bp

    ret 2
;;'''''''''''''''''''''''''''''''''''''''''

fish:                   ; prints the fish at the passed 
    push bp             ; position and in the given orientation
    mov bp, sp
    
    push cx
    push ax
    push es
    push di
    push dx

    mov ax, 0xb800
    mov es, ax
    mov di, [bp + 4];
    mov cx, [bp + 6];

    cmp cx, 1           ; for left facing fish
    jne skip_fish1

    add di, 2
    mov word [es:di], 0x187B
    sub di, 2

    skip_fish1:
    mov word [es:di], 0x18fe

    sub di, 2
    mov word [es:di], 0x18db

    sub di, 2
    mov word [es:di], 0x18db

    sub di, 2
    mov word [es:di], 0x18fe

    cmp cx, 0           ; for right facing fish
    jne skip_fish2
    sub di, 2
    mov word [es:di], 0x187d

    skip_fish2:

    pop dx
    pop di
    pop es
    pop ax
    pop cx
    pop bp

    ret 4
;//'''''''''''''''''''''''''''''''''''''''''

;|||//////////////////////////////////////////////////////////////////////|||
;---------------> Functions to move the screen left or right <---------------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||

move_upper:             ; moves the whole sky section
    push ax             ; by one block to left
    
    mov ax, 1
    left_upper_loop:
        push ax
        call move_left
        inc ax
        cmp ax, 9
    jne left_upper_loop
    
    pop ax

    ret
;'''''''''''''''''''''''''''''''''''''''''

move_middle:            ; moves the whole middle section 
    push ax             ; by one block to right
    
    mov ax, 10
    right_middle_loop:
        push ax
        call move_right
        inc ax
        cmp ax, 19
    jne right_middle_loop
    
    pop ax
    ret
;'''''''''''''''''''''''''''''''''''''''''

move_left:              ; moves the a row passed
    push bp             ;  one block to the left
    mov bp, sp

    push es
    push ax
    push ds
    push cx
    push di
    push si
    
    mov ax, 0xb800
    mov es, ax
    mov ds, ax
    mov ax, 80 
    mul byte [bp + 4]   ; line no. [we did (80)*line no.] 
    SHL ax, 1           ; multiply by 2 (to get location according to <word>)
    mov di, ax
    add ax, 2
    mov si, ax
    mov cx, 80          ; no. of element in each row

    push word [es:di]   ; storing the first element so that it do not get destroyed
    cld
    rep movsw
    sub di, 2           ; making it point to the last location of the given row
    pop word [es:di]    ; putting the last element

    pop si
    pop di
    pop cx
    pop ds
    pop ax
    pop es
    pop bp

    ret 2
;'''''''''''''''''''''''''''''''''''''''''

move_right:             ; moves the a row passed
    push bp             ; one block to the right
    mov bp, sp

    push es
    push ax
    push ds
    push cx
    push di
    push si
    
    mov ax, 0xb800
    mov es, ax
    mov ds, ax
    mov ax, 80 
    mul byte [bp + 4]  ; line no. [we did (80)*line no.] 
    SHL ax, 1          ; multiply by 2 (to get location according to <word>)
    add ax, 158
    mov di, ax
    sub ax, 2
    mov si, ax
    mov cx, 80        ; no. of element in each row

    push word [es:di] ; storing the first element so that it do not get destroyed
    std
    rep movsw
    add di, 2         ; making it point to the last location of the given row
    pop word [es:di]  ; putting the last element

    pop si
    pop di
    pop cx
    pop ds
    pop ax
    pop es
    pop bp

    ret 2
;'''''''''''''''''''''''''''''''''''''''''

Delay:              ; fuction to produce a small delay
    push cx
    mov cx, 0xFFFF

    del:
    loop del

    pop cx
    ret
;'''''''''''''''''''''''''''''''''''''''''

;|||//////////////////////////////////////////////////////////////////////|||
;-------------------> Functions to produce sound effects <-------------------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||

SFX:                ; function to produce a sound
    pusha

    mov cx, 2

    loop1:         
    mov al, 0b6h
    out 43h, al
                    
    mov ax, 1fb4h   ; load the counter 2 value for d3 
    out 42h, al     ; 0x42 is speaker port
    mov al, ah
    out 42h, al

    in al, 61h      ; turn the speaker on
    mov ah,al
    or al, 3h
    out 61h, al
    call Delay
    mov al, ah
    out 61h, al

    call Delay

            
    mov ax, 152fh   ; load the counter 2 value for a3
    out 42h, al
    mov al, ah
    out 42h, al


    in al, 61h      ; turn the speaker on
    mov ah,al
    or al, 3h
    out 61h, al
    call Delay
    mov al, ah
    out 61h, al
	
            
    mov ax, 0A97h   ; load the counter 2 value for a4
    out 42h, al
    mov al, ah
    out 42h, al
	
    in al, 61h       ; turn the speaker on
    mov ah,al
    or al, 3h
    out 61h, al
    call Delay
    mov al, ah
    out 61h, al

    call Delay
 
    loop loop1

    popa
    ret
;'''''''''''''''''''''''''''''''''''''''''

tone:             ; function to produce sound 
    pusha         ; of frequecy on ax
    
    out 42h, al
    mov al, ah
    out 42h, al

    in al, 61h    ; turn the speaker on
    mov ah,al
    or al, 3h
    out 61h, al
    call Delay
    call Delay
    mov al, ah
    out 61h, al

    popa
    ret
;'''''''''''''''''''''''''''''''''''''''''

round_1:
    mov ax, [C4]
    call tone

    call Delay
    call Delay

    mov ax, [E4]
    call tone   

    call Delay
    call Delay

    mov ax, [G4]
    call tone

    call Delay
    call Delay

    mov ax, [A4]
    call tone

    call Delay
    call Delay

    mov ax, [G4]
    call tone

    call Delay
    call Delay

    mov ax, [E4]
    call tone

    call Delay
    call Delay

    mov ax, [C4]
    call tone

    ret
;;

round1:
    mov ax, [C4]
    call tone

    call Delay
    call Delay

    mov ax, [Csh5]
    call tone

    call Delay
    call Delay


    mov ax, [E4]
    call tone   

    call Delay
    call Delay

    mov ax, [F4]
    call tone

    call Delay
    call Delay


    mov ax, [G4]
    call tone

    call Delay
    call Delay

    mov ax, [Gsh4]
    call tone

    call Delay
    call Delay


    mov ax, [A4]
    call tone

    call Delay
    call Delay

    mov ax, [B4]
    call tone

    call Delay
    call Delay

    mov ax, [Gsh4]
    call tone

    call Delay
    call Delay

    mov ax, [G4]
    call tone

    call Delay
    call Delay


    mov ax, [F4]
    call tone

    call Delay
    call Delay

    mov ax, [E4]
    call tone

    call Delay
    call Delay

    mov ax, [Csh4]
    call tone

    call Delay
    call Delay


    mov ax, [C4]
    call tone


ret
;;
 round_3:

    mov ax, [Csh6]
    call tone

    call Delay
    call Delay

    mov ax, [E6]
    call tone  

    call Delay
    call Delay

    mov ax, [G6]
    call tone

    call Delay
    call Delay

    mov ax, [A6]
    call tone

    call Delay
    call Delay

    mov ax, [G6]
    call tone

    call Delay
    call Delay

    mov ax, [E6]
    call tone

    call Delay
    call Delay

    mov ax, [C6]
    call tone

    ret;;

    round3:

    mov ax, [C6]
    call tone

    call Delay
    call Delay

    mov ax, [Csh6]
    call tone

    call Delay
    call Delay

    mov ax, [E6]
    call tone   

    call Delay
    call Delay

    mov ax, [F6]
    call tone

    call Delay
    call Delay


    mov ax, [G6]
    call tone

    call Delay
    call Delay

    mov ax, [Gsh6]
    call tone

    call Delay
    call Delay


    mov ax, [A6]
    call tone

    call Delay
    call Delay

    mov ax, [B6]
    call tone

    call Delay
    call Delay

    mov ax, [Gsh6]
    call tone

    call Delay
    call Delay

    mov ax, [G6]
    call tone

    call Delay
    call Delay
 
    mov ax, [F6]
    call tone

    call Delay
    call Delay

    mov ax, [E6]
    call tone

    call Delay
    call Delay

    mov ax, [Csh6]
    call tone

    call Delay
    call Delay

    mov ax, [C6]
    call tone


ret

round_2:

    mov ax, [Csh5]
    call tone

    call Delay
    call Delay

    mov ax, [Fsh5]
    call tone  

    call Delay
    call Delay

    mov ax, [G5]
    call tone

    call Delay
    call Delay

    mov ax, [Ash5]
    call tone

    call Delay
    call Delay

    mov ax, [G5]
    call tone

    call Delay
    call Delay

    mov ax, [E5]
    call tone

    call Delay
    call Delay

    mov ax, [C5]
    call tone

    ret
;;

round2

    mov ax, [C5]
    call tone

    call Delay
    call Delay

    mov ax, [Csh5]
    call tone

    call Delay
    call Delay

    mov ax, [E7]
    call tone   

    call Delay
    call Delay

    mov ax, [F5]
    call tone

    call Delay
    call Delay

    mov ax, [G5]
    call tone

    call Delay
    call Delay

    mov ax, [Gsh5]
    call tone

    call Delay
    call Delay

    mov ax, [A5]
    call tone

    call Delay
    call Delay

    mov ax, [B5]
    call tone

    call Delay
    call Delay

    mov ax, [Gsh5]
    call tone

    call Delay
    call Delay

    mov ax, [G5]
    call tone

    call Delay
    call Delay

    mov ax, [F5]
    call tone

    call Delay
    call Delay

    mov ax, [E5]
    call tone

    call Delay
    call Delay

    mov ax, [Csh5]
    call tone

    call Delay
    call Delay

    mov ax, [C5]
    call tone

ret

round_4:

    mov ax, [C7]
    call tone

    call Delay
    call Delay

    mov ax, [E7]
    call tone   

    call Delay
    call Delay

    mov ax, [G7]
    call tone

    call Delay
    call Delay

    mov ax, [A7]
    call tone

    call Delay
    call Delay

    mov ax, [G7]
    call tone

    call Delay
    call Delay

    mov ax, [E7]
    call tone

    call Delay
    call Delay


    mov ax, [C7]
    call tone

    ret;
    
round4:

    mov ax, [C7]
    call tone

    call Delay
    call Delay

    mov ax, [Csh7]
    call tone

    call Delay
    call Delay


    mov ax, [E7]
    call tone   

    call Delay
    call Delay

    mov ax, [F7]
    call tone

    call Delay
    call Delay

    mov ax, [G7]
    call tone

    call Delay
    call Delay

    mov ax, [Gsh7]
    call tone

    call Delay
    call Delay

    mov ax, [A7]
    call tone

    call Delay
    call Delay

    mov ax, [B7]
    call tone

    call Delay
    call Delay

    mov ax, [Gsh7]
    call tone

    call Delay
    call Delay

    mov ax, [G7]
    call tone

    call Delay
    call Delay


    mov cx, 0x0000
    mov dx, 0xffff
    mov ax, [F7]
    call tone

    call Delay
    call Delay

    mov cx, 0x0000
    mov dx, 0xffff
    mov ax, [E7]
    call tone

    call Delay
    call Delay

    mov cx, 0x0000
    mov dx, 0xffff
    mov ax, [Csh7]
    call tone

    call Delay
    call Delay


    mov cx, 0x0000
    mov dx, 0xffff
    mov ax, [C7]
    call tone

    ret
;;

BG_SFX:

w:
    cmp byte[esc], 1
    je w
             
    call round_1

    call Delay
    call Delay

    cmp byte[esc], 1
    je w

    call round_2

    call Delay
    call Delay

    cmp byte[esc], 1
    je w

    call round_3

    call Delay
    call Delay

    cmp byte[esc], 1
    je w
    
    call round_4

    jmp w

    ret
;'''''''''''''''''''''''''''''''''''''''''

BG:

    loop2:
    cmp byte[esc], 1
    je loop2
    
    call round1

    call Delay
    call Delay

    cmp byte[esc], 1
    je loop2

    call round2

    call Delay
    call Delay

   cmp byte[esc], 1
    je loop2

    call round3

    call Delay
    call Delay

    cmp byte[esc], 1
    je loop2

    call round4
    
    jmp loop2

    ret
;'''''''''''''''''''''''''''''''''''''''''

SFX_Coin:         ; function to produce coin collect sound
    pusha
   
    mov al, 0b6h
    out 43h, al
 
    mov ax, 1A97h ; load the counter 2 value for d3
    out 42h, al   ; 0x42 is speaker port
    mov al, ah
    out 42h, al

    in al, 61h    ; turn the speaker on
    mov ah,al
    or al, 3h
    out 61h, al
    call Delay
    call Delay
    call Delay
    mov al, ah
    out 61h, al

	popa
    ret
;'''''''''''''''''''''''''''''''''''''''''

;|||//////////////////////////////////////////////////////////////////////|||
;----------------> Keyboards ISR and it's related functions <----------------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||

Control_kb:       ; function to identify which key has 
    pusha         ; been pressed and to pass ip to 
                  ; operation required by that key
    push cs
    pop ds

    in al, 0x60   ; reading from keyBoard port

    cmp al, 0x4B  ; checking if left key is pressed
    jne next0
    call kb_left
    jmp Origional

next0: 
    cmp al, 0x48  ; checking if up key is pressed
    jne next1
    call kb_up
    jmp Origional

next1:
    cmp al, 0x50  ; checking if down key is pressed
    jne next2
    call kb_down
    jmp Origional

next2:
    cmp al, 0x4D   ; checking if right key is pressed
    jne next3
    call kb_right
    jmp Origional

next3:
    cmp al, 0x01   ; checking if escape key is pressed
    jne next4
    call kb_esc
    jmp exit

next4:
    cmp al, 0x2A   ; checking if shift_L key is pressed
    jne next5
    call kb_shftL
    jmp exit

next5:
    cmp al, 0x15   ; checking if y key is pressed
    jne next6
    call kb_y
    jmp exit

next6:
    cmp al, 0x31   ; checking if n key is pressed
    jne next7
    call kb_n
    jmp exit

next7:
    cmp al, 0x1C   ; checking if enter key is pressed
    jne Origional
    call kb_enter
    jmp exit

Origional:
    popa
    jmp far [cs:pre_isr_kb]

exit:
    mov al, 0x20
	out 0x20, al    ; sending E.O.I. message to PIC port
    popa
    iret
;'''''''''''''''''''''''''''''''''''''''''

kb_y:
    pusha

    cmp byte[esc], 1    ; only works if confirm promt is open
    jne leave_y

    mov byte[y], 1

 leave_y:
    popa
    ret
;'''''''''''''''''''''''''''''''''''''''''

kb_n:
    pusha

    cmp byte[esc], 1    ; only works if confirm promt is open
    jne leave_n

    mov byte[n], 1

 leave_n:
    popa
    ret
;'''''''''''''''''''''''''''''''''''''''''

kb_left:                ; moves our fish one block left (with required checks)
    push ax
    push bx

    cmp byte[esc], 1    ; if escaped key is pressed then leaving the function immediately
    jne enter_left
        pop bx          ; poping to avoid stack corruption
        pop ax
        ret

 enter_left:
    cmp byte[enter_k], 0
    jne valid_left
        pop bx          ; poping to avoid stack corruption
        pop ax
        ret


 valid_left:
    cmp byte[sft], 1    ; checking which fist to move
    jne next_sft_l

    mov ax, [fish_cor1];
    jmp first_cmp_l

next_sft_l:
    mov ax, [fish_cor];

first_cmp_l:      
    sub ax, 2
    mov bx, ax
    sub bx, 6

    cmp bx, 3038        ; checks to make fist reappear on the 
    jne next0_left      ; same row when try to exits the row
    add ax, 152
    jmp inbound_left

next0_left:
    cmp bx, 3198
    jne next1_left
    add ax, 152
    jmp inbound_left

next1_left:
    cmp bx, 3358
    jne next2_left
    add ax, 152
    jmp inbound_left

next2_left:
    cmp bx, 3518
    jne next3_left
    add ax, 152
    jmp inbound_left

next3_left:
    cmp bx, 3678
    jne next4_left
    add ax, 152
    jmp inbound_left

next4_left:
    cmp bx, 3838
    jne inbound_left
    add ax, 152

inbound_left:
    cmp byte[sft], 1
    jne next_sft_last

    mov [fish_cor1], ax
    push 1
    pop word[fish_orint1]
    jmp sft_leave_left

next_sft_last:
    mov [fish_cor], ax
    push 1
    pop word[fish_orint]

sft_leave_left:
    call coin_collect       ; checks if the fish collected the coin after movement
    call deep_sea
    
    pop bx
    pop ax
    ret
;//'''''''''''''''''''''''''''''''''''''''''

kb_up:                  ; moves our fish one block up (with required checks)
    push ax

    cmp byte[esc], 1    ; if escaped key is pressed then leaving the function immediately
    jne enter_up
        pop ax          ; poping to avoid stack corruption
        ret

 enter_up:
    cmp byte[enter_k], 0
    jne valid_up
        pop ax          ; poping to avoid stack corruption
        ret

valid_up:
    cmp byte[sft], 1    ; checking which fist to move
    jne next_sft_up

    mov ax, [fish_cor1];
    jmp first_cmp_up

next_sft_up:
    mov ax, [fish_cor];

first_cmp_up: 
    sub ax, 160

    cmp ax, 3038        ; check to make fish remain in it's sea boundary
    jg inbound_up       ; and call sfx if try to escape the boundary
    call SFX
    add ax, 160

inbound_up:
    cmp byte[sft], 1
    jne next_sft_last_up

    mov [fish_cor1], ax
    push 1
    pop word[fish_orint1]
    jmp sft_leave_up

next_sft_last_up:
    mov [fish_cor], ax
    push 1
    pop word[fish_orint]
    
sft_leave_up:
    call coin_collect      ; checks if the fish collected the coin after movement
    call deep_sea

    pop ax
    ret
;//'''''''''''''''''''''''''''''''''''''''''

kb_down:                    ; moves our fish one block down (with required checks)
    push ax

    cmp byte[esc], 1        ; if escaped key is pressed then leaving the function immediately
    jne enter_down
        pop ax              ; poping to avoid stack corruption
        ret

 enter_down:
    cmp byte[enter_k], 0
    jne valid_down
        pop ax              ; poping to avoid stack corruption
        ret
    
 valid_down:
    cmp byte[sft], 1        ; checking which fist to move
    jne next_sft_down
    
    mov ax, [fish_cor1];
    jmp first_cmp_down

next_sft_down:
    mov ax, [fish_cor];

first_cmp_down:
    add ax, 160

    cmp ax, 4000            ; check to make fish remain in it's sea boundary
    jle inbound_down        ;  and call sfx if try to escape the boundary
    sub ax, 160
    call SFX

inbound_down:
    cmp byte[sft], 1
    jne next_sft_last_down

    mov [fish_cor1], ax
    push 0
    pop word[fish_orint1]
    jmp sft_leave_down

next_sft_last_down:
    mov [fish_cor], ax
    push 0
    pop word[fish_orint]
    
sft_leave_down:
    call coin_collect       ; checks if the fish collected the coin after movement
    call deep_sea

    pop ax
    ret
;//'''''''''''''''''''''''''''''''''''''''''

kb_right:               ; moves our fish one block right (with required checks)
    push ax

    cmp byte[esc], 1    ; if escaped key is pressed then leaving the function immediately
    jne enter_right
        pop ax          ; poping to avoid stack corruption
        ret

 enter_right:
    cmp byte[enter_k], 0
    jne valid_right
        pop ax          ; poping to avoid stack corruption
        ret

 valid_right:
    cmp byte[sft], 1    ; checking which fist to move
    jne next_sft_right
    mov ax, [fish_cor1];
    jmp first_cmp_right

next_sft_right:
    mov ax, [fish_cor];

first_cmp_right:
    add ax, 2

    cmp ax, 4000        ; checks to make fist reappear on the 
    jne next0_right     ; same row when try to exits the row
    sub ax, 152
    jmp inbound_right

next0_right:
    cmp ax, 3840
    jne next1_right
    sub ax, 152
    jmp inbound_right

next1_right:
    cmp ax, 3680
    jne next2_right
    sub ax, 152
    jmp inbound_right

next2_right:
    cmp ax, 3520
    jne next3_right
    sub ax, 152
    jmp inbound_right

next3_right:
    cmp ax, 3360
    jne next4_right
    sub ax, 152
    jmp inbound_right

next4_right:
    cmp ax, 3200
    jne inbound_right
    sub ax, 152

inbound_right:
    cmp byte[sft], 1
    jne next_sft_last_right

    mov [fish_cor1], ax
    push 0
    pop word[fish_orint1]
    jmp sft_leave_right

next_sft_last_right:
    mov [fish_cor], ax
    push 0
    pop word[fish_orint]
    
sft_leave_right:
    call coin_collect       ; checks if the fish collected the coin after movement
    call deep_sea

    pop ax
    ret
;//'''''''''''''''''''''''''''''''''''''''''

kb_enter:    ; set the enter flag to 1

    mov byte[enter_k], 1
    ret
;'''''''''''''''''''''''''''''''''''''''''

kb_esc:     ; set the exit flag to 1
    mov byte[esc], 1
    ret
;'''''''''''''''''''''''''''''''''''''''''

kb_shftL:   ; shifts the control to second or first fist

    cmp byte[sft], 1
    jne skip_sft

    mov byte[sft], 0
    ret

 skip_sft:
    mov byte[sft], 1
    ret
;'''''''''''''''''''''''''''''''''''''''''


;|||//////////////////////////////////////////////////////////////////////|||
;--------------> Function to Initialize PCB for multitasking <---------------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||


initpcb:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push si

    mov bx, [bp + 4]            ; read next available pcb index
    cmp bx, 2                   ; are all PCBs used
    jge exit_pcb                ; yes, exit

    mov cl, 5
    shl bx, cl                  ; multiply by 32 for pcb start
    mov ax, [bp+8]              ; read segment parameter
    mov [pcb+bx+18], ax         ; save in pcb space for cs
    mov ax, [bp+6]              ; read offset parameter
    mov [pcb+bx+16], ax         ; save in pcb space for ip
    mov [pcb+bx+22], ds         ; set stack to our segment
    mov si, [bp + 4]            ; read this pcb index

    mov cl, 9
    shl si, cl                  ; multiply by 512
    add si, 256*2 + stack       ; end of stack for this thread
    sub si, 2

    mov [pcb+bx+14], si         ; save si in pcb space for sp
    mov word[pcb+bx+26], 0x0200 ; initialize thread flags
    mov ax, [pcb+28]            ; read next of 0th thread in ax
    mov [pcb+bx+28], ax         ; set as next of new thread
    mov ax, [bp + 4]            ; read new thread index
    mov [pcb+28], ax            ; set as next of 0th thread
    inc word [bp + 4]           ; this pcb is now used

 exit_pcb: 
    pop si
    pop cx
    pop bx
    pop ax
    pop bp
    ret 6
;'''''''''''''''''''''''''''''''''''''''''


;|||//////////////////////////////////////////////////////////////////////|||
;--------------------> Timer and it's related functions <--------------------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||


Check_sec:
    pusha

    cmp byte[time_tick], 18         ; will decrease coins life after every second
    jne exit_check

    dec byte[coin1_life]
    dec byte[coin2_life]
    mov byte[time_tick], 0

    cmp byte[coin1_life], 0
    jne next_coin_life

    push word[ran_num_1]
    pop word[coin1_pos]
    call deep_sea
    mov byte[coin1_life], 5

 next_coin_life:
    cmp byte[coin2_life], 0
    jne exit_check

    push word[ran_num_2]
    pop word[coin2_pos]
    call deep_sea
    mov byte[coin2_life], 10

 exit_check:
    popa
    ret
;'''''''''''''''''''''''''''''''''''''''''

timer:

    push cs
    pop ds    

    cmp byte[cs:enter_k], 0
    jne esc_check

    push ax
    mov al, 0x20                           ; E.O.T. signal to P.I.C.
	out 0x20, al
    pop ax

    iret

 esc_check:
    cmp byte[cs:esc], 1                    ; if escaped key is pressed
    jne continue_timer                     ; exit the timer
    jmp change_thread
    
 continue_timer:

    inc byte[cs:time_tick]
    add word[cs:ran_num_1], 2
    add word[cs:ran_num_2], 2

    cmp word[cs:ran_num_1], 3760
    jne next_ran
    mov word[cs:ran_num_1], 3040

 next_ran:
    cmp word[cs:ran_num_2], 3680;3520
    jne skip_ran
    mov word[cs:ran_num_2], 3040

 skip_ran:
    call Check_sec

 change_thread:
    push ds
    push bx

    push cs
    pop ds                  ; initialize ds to data segment
    
    mov bx, [current]       ; read index of current in bx
    shl bx, 5               ; multiply by 32 for pcb start

    mov [pcb+bx+0], ax      ; save ax in current pcb
    mov [pcb+bx+4], cx      ; save cx in current pcb
    mov [pcb+bx+6], dx      ; save dx in current pcb
    mov [pcb+bx+8], si      ; save si in current pcb
    mov [pcb+bx+10], di     ; save di in current pcb
    mov [pcb+bx+12], bp     ; save bp in current pcb 
    mov [pcb+bx+24], es     ; save es in current pcb
    pop ax                  ; read original bx from stack
    mov [pcb+bx+2], ax      ; save bx in current pcb
    pop ax                  ; read original ds from stack
    mov [pcb+bx+20], ax     ; save ds in current pcb
                        
                            ; stored by interept call
    pop ax                  ; read original ip from stack
    mov [pcb+bx+16], ax     ; save ip in current pcb
    pop ax                  ; read original cs from stack
    mov [pcb+bx+18], ax     ; save cs in current pcb
    pop ax                  ; read original flags from stack
    mov [pcb+bx+26], ax     ; save flags in current pcb

    mov [pcb+bx+22], ss     ; save ss in current pcb
    mov [pcb+bx+14], sp     ; save sp in current pcb
    mov bx, [pcb+bx+28]     ; read next pcb of this pcb

    mov [current], bx       ; update current to new pcb
    mov cl, 5
    shl bx, cl              ; multiply by 32 for pcb start
    mov cx, [pcb+bx+4]      ; read cx of new process
    mov dx, [pcb+bx+6]      ; read dx of new process
    mov si, [pcb+bx+8]      ; read si of new process
    mov di, [pcb+bx+10]     ; read di of new process
    mov bp, [pcb+bx+12]     ; read bp of new process
    mov es, [pcb+bx+24]     ; read es of new process
    mov ss, [pcb+bx+22]     ; read ss of new process
    mov sp, [pcb+bx+14]     ; read sp of new process
    push word[pcb+bx+26]    ; push flags of new process
    push word[pcb+bx+18]    ; push cs of new process
    push word[pcb+bx+16]    ; push ip of new process
    push word[pcb+bx+20]    ; push ds of new process

    mov al, 0x20            ; E.O.T. signal to P.I.C.
	out 0x20, al

    mov ax, [pcb+bx+0]      ; read ax of new process
    mov bx, [pcb+bx+2]      ; read bx of new process
    pop ds                  ; read ds of new process

    iret
;'''''''''''''''''''''''''''''''''''''''''

;|||//////////////////////////////////////////////////////////////////////|||
;---------------> Numbers, Coins & String printing functions <---------------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||

print_score:            ; Prints the number passed 
    push bp             ; to it as parameter
    mov bp, sp

    push es
    push ax
    push bx
    push cx
    push dx
    push di

    mov ax, 0xb800
    mov es, ax          ; point es to video base
    mov ax, [bp+4]      ; load number in ax
    mov bx, 10          ; use base 10 for division
    mov cx, 0           ; initialize count of digits

    nextdigit: 
        mov dx, 0       ; zero upper half of dividend
        div bx          ; divide by 10
        add dl, 0x30    ; convert digit into ascii value
        push dx         ; save ascii value on stack
        inc cx          ; increment count of values
        cmp ax, 0       ; is the quotient zero
    jnz nextdigit       ; if no divide it again

    mov di, 16    

    nextpos: 
        pop dx          ; remove a digit from the stack
        mov dh, 0x17    ; use normal attribute
        mov [es:di], dx ; print char on screen
        add di, 2       ; move to next screen location
    loop nextpos        ; repeat for all digits on stack

    pop di
    pop dx
    pop cx
    pop bx
    pop ax 
    pop es
    pop bp

    ret 2
;'''''''''''''''''''''''''''''''''''''''''

print_coins:                ; prints coins on there 
    pusha                   ; respective positions

    push 0xB800
    pop es

    mov di, [coin1_pos];
    mov word[es:di], 0x146F ; 6F ascii for small o (red coin)

    mov di, [coin2_pos];
    mov word[es:di], 0x126F

    popa
    ret
;'''''''''''''''''''''''''''''''''''''''''

print_String:              ; take cordinate, size and string
        push di            ; as parameters to print it
        mov di, sp

        push ax
        push bx
        push es
        push bp
        push dx

        mov ah, 0x13       ; bios print string service

        mov al, [di + 12]  ; to update our cursor
        mov bh, 0          ; to print on page 0
        mov bl, [di + 10]  ;attribute for string
        mov dx, [di + 8]   ; corndinate to print on

        push ds            ; es = ds
        pop es         

        mov bp, [di + 4]   ; putting string's ip in bp
        mov cx, [di + 6]   ; putting size in cx
        int 0x10

        pop dx
        pop bp
        pop es
        pop bx
        pop ax
        pop di
        ret 10
;'''''''''''''''''''''''''''''''''''''''''

;|||//////////////////////////////////////////////////////////////////////|||
;---------------------> Function for Exit Confirmation <---------------------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||

print_confirm:                  ; all the functionality of our confirm window
    pusha

    call save_sc                ; saving our screen in a buffer before changing it
    call clr_sc                 ; calling function to clear our screen
    mov ah, 0x1F                ; our bg and fg color for the prompt

    mov al, 0xC9                
    mov word [es:1340], ax
    mov al, 0xBB
    mov word [es:1380], ax      ; printing our prompt box from line: (1286 - 1336)

    mov al,0xCD
    push ax
    push 1340
    push 1380
    call Fill_color

    mov al,0xBA
    mov word [es:1500], ax
    mov word [es:1540], ax

    mov al, 0x20
    push ax
    push 1500
    push 1540
    call Fill_color

    mov al,0xBA
    mov word [es:1660], ax
    mov word [es:1700], ax

    mov al, 0x20
    push ax
    push 1660
    push 1700
    call Fill_color

    mov al,0xBA
    mov word [es:1820], ax
    mov word [es:1860], ax

    mov al, 0x20
    push ax
    push 1820
    push 1860
    call Fill_color

    mov al, 0xC8
    mov word [es:1980], ax
    mov al, 0xBC
    mov word [es:2020], ax

    mov al, 0xCD
    push ax                         
    push 1980
    push 2020
    call Fill_color                 

    push 0
    push 0x001F
    push 2337                   ; printing our prompt strings inside the box
    push 15
    push msg_conf
    call print_String           ; using function to print

    mov bx, msg_conf
    add bx, 16

    push 0
    push 0x001F
    push 2498
    push 14
    push bx
    call print_String

    wait_in:                    ; waiting for user's input in a loop
        cmp byte[n], 1          ; if user input y then setting the escape flag 
        jne next_opt            ; else if user input n then clearing escape flag
        mov byte[esc], 0        ; and retoring the game screen
        mov byte[n], 0
        call rstore_sc
     jmp go_away_ex

      next_opt:
        cmp byte[y], 1
        jne wait_in
        mov byte[esc], 1
    call clr_sc

 go_away_ex:
    popa
    ret
;'''''''''''''''''''''''''''''''''''''''''

;|||//////////////////////////////////////////////////////////////////////|||
;--------------------> Save and Restore Screen Function <--------------------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||

save_sc:	        ; function to save the current
    push ax         ; content of screen in a 4000B
    push ds         ; buffer
    push es
    push si
    push di
    push cx

	mov ax, 0xb800  
	mov ds, ax      ; ds = 0xb800

	push cs
	pop es

	mov cx, 4000    ; number of screen locations

	mov si, 0
	mov di, screen_buffer

	cld             ; [es:di] = [ds:si]
	rep movsb       ; save screen

    pop cx
    pop di
    pop si
    pop es
    pop ds
    pop ax
	ret
;'''''''''''''''''''''''''''''''''''''''''

rstore_sc:          ; Function to copy the content of
    push ax         ; a 4000B buffer to our screen
    push ds
    push es
    push si
    push di
    push cx


	mov ax, 0xb800
	mov es, ax      ; ds = 0xb800

	push cs
	pop ds

	mov cx, 4000    ; number of screen locations

	mov si, screen_buffer
	mov di, 0

	cld             ; [es:di] = [ds:si]
	rep movsb       ; save screen

    pop cx
    pop di
    pop si
    pop es
    pop ds
    pop ax
	ret	
;'''''''''''''''''''''''''''''''''''''''''

;|||//////////////////////////////////////////////////////////////////////|||
;-----------> Function to print the score bar and initial score <------------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||

Score_bar:
    pusha

    push 0xB800         ; es = 0xb800
    pop es
    mov ax, 0x1120
    mov di, 0
    mov cx, 80

    cld                 ; auto incriment (di+=2)
    rep stosw

    push 0
    push 0x001F         ; passing parameters
    push 0              ; to the print string 
    push 8              ; function
    push sco_msg    
    call print_String   ; printing score string

    mov bx, str_title   ; puting the starting
    add bx, 2           ; of str_title in bx

    push 0
    push 0x001F
    push 0034
    push 13
    push bx    
    call print_String   ; printing Game Name

    push word [score] 
    call print_score    ; printing initial score 

    popa
    ret
;'''''''''''''''''''''''''''''''''''''''''

;|||//////////////////////////////////////////////////////////////////////|||
;-----> Function to check if coin is collected and updating the score <------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||

coin_collect:               ; updates score and cordinate of coin if 
    pusha                   ; it is collrcted by either fish

    mov ax, [fish_cor]      ; storing cordinate of fish 1 in ax to check if it collected coin

    cmp [coin1_pos], ax     ; updating score if it collected coin
    jne next_c0
    add word [score], 50
    jmp update_coin1

 next_c0:
    cmp [coin2_pos], ax
    jne next_c1
    add word [score], 10
    jmp update_coin2

 next_c1:
    sub  ax, 6              ; check if collected while fish1 face is on the left side
    cmp [coin1_pos], ax
    jne next_c2
    add word [score], 50
    jmp update_coin1

 next_c2:
    cmp [coin2_pos], ax     ; updating score if it collected coin
    jne next_fish
    add word [score], 10
    jmp update_coin2

 next_fish:
    mov ax, [fish_cor1]     ; storing cordinate of fish 2 in ax to check if it collected coin

    cmp [coin1_pos], ax     ; updating score if it collected coin
    jne next_c3
    add word [score], 50
    jmp update_coin1

 next_c3:
    cmp [coin2_pos], ax
    jne next_c4
    add word [score], 10
    jmp update_coin2

 next_c4:
    sub  ax, 6              ; check if collected while fish2 face is on the left side
    cmp [coin1_pos], ax
    jne next_c5
    add word [score], 50
    jmp  update_coin1

 next_c5:
    cmp [coin2_pos], ax     ; updating score if it collected coin
    jne leave_coin
    add word [score], 10
    jmp update_coin2

 update_coin1:
    push word[ran_num_2]
    pop word[coin1_pos]

    mov word[coin1_life], 5 ; resetting the life of coin
    call SFX_Coin
    push word [score]       ; printing updated score
    call print_score
    jmp leave_coin

 update_coin2:
    push word[ran_num_1]
    pop word[coin2_pos]

    mov word[coin2_life], 10 ; resetting the life of coin
    call SFX_Coin
    push word [score]       ; printing updated score
    call print_score

 leave_coin:
    popa
    ret

;|||//////////////////////////////////////////////////////////////////////|||
;---------------------> Complete Frame print function <---------------------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||

Print_Frame:                ; call all objects print 
    pusha                   ; function to complete the frame

    call color_sky_day
    call Print_mountains
    call Sea
    call Ship
    call deep_sea
    call Score_bar

    popa
    ret
;'''''''''''''''''''''''''''''''''''''''''

;|||//////////////////////////////////////////////////////////////////////|||
;---------------> Function to Hook and unHook the interepts <----------------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||

Hook_ints:                       ; Saves and hooks our new keyboard
    push ax                      ; and timer interepts
    push es 

    AND ax, 0
    mov es, ax                    ; es pointing to start of IVT

    push cs
    push BG_SFX
    push 1
    call initpcb

    mov ax, [es:9*4]              ; Saving our old kb interept cs and ip
    mov [pre_isr_kb], ax
    mov ax, [es:9*4 + 2];
    mov [pre_isr_kb + 2], ax
    
    cli
    mov word[es:9*4], Control_kb  ; Hooking kb interept
    mov word[es:9*4+2], cs
    sti

    mov ax, [es:8*4]              ; Saving our old kb interept cs and ip
    mov [pre_isr_timer], ax
    mov ax, [es:8*4 + 2];
    mov [pre_isr_timer + 2], ax

    cli
    mov word[es:8*4], timer       ; hooking our timer
    mov word[es:8*4 + 2], cs
    sti

    pop es
    pop ax
    ret
;'''''''''''''''''''''''''''''''''''''''''

UnHook_ints:                  ; Unhook our timer and keyboard interepts 
    push ax                   ; and restores the origional ones
    push es

    call clr_sc

    AND ax, 0
    mov es, ax                ; es pointing to start of IVT

    cli                       ; disabling interepts while unhooking our kb interept an restoring old one 
    mov ax, [pre_isr_kb];
    mov [es:9*4], ax
    mov ax, [pre_isr_kb+2];
    mov [es:9*4+2], ax
    sti

    cli
    mov ax, [pre_isr_timer]    ; unhooking timer interept
    mov [es:8*4], ax
    mov ax, [pre_isr_timer + 2];
    mov [es:8*4 + 2], ax
    sti

    pop es
    pop ax
    ret
;'''''''''''''''''''''''''''''''''''''''''

;|||//////////////////////////////////////////////////////////////////////|||
;--------------> Function to Run our game and it's functions <---------------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||

Animate:                   ; Runs our game screen
    pusha

    again:
    mov cx, 0x00f0         ; will stop after 3 complete loops of animation
    Animation:
        call Delay
        call Delay
        call Delay

        cli                 ; disabling interept to avoid a display bug
        call move_upper
        sti

        cli
        call move_middle
        sti

        cmp byte[esc], 1    ; check for exit
        je brk_animation

    loop Animation

    call color_sky_night
    call Print_mountains

      mov cx, 0x00f0        ; will stop after 3 complete loops of animation
    Animation1:
        call Delay
        call Delay
        call Delay

        cli                 ; disabling interept to avoid a display bug
        call move_upper
        sti

        cli
        call move_middle
        sti

        cmp byte[esc], 1    ; check for exit
        je brk_animation

    loop Animation1

        call color_sky_day
        call Print_mountains
        jmp again

    brk_animation:
        call print_confirm
        cmp byte[esc], 0
        je Animation

    popa
    ret
;'''''''''''''''''''''''''''''''''''''''''

reso:
    pusha

    mov ax, 0x001E ;08, 14, 17,->132x25 // 1A->132x28 // 1E->132x60,75
    int 0x10
    mov bx, 0

    popa
    ret
;'''''''''''''''''''''''''''''''''''''''''


;|||//////////////////////////////////////////////////////////////////////|||
;---------------> Function to Slide Buffer screen on Screen <----------------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||


Slide_screen:           ; function to print the screen
        pusha           ; from screen buffer with a sliding animation

        mov ax, 0xb800
        mov es, ax
        mov di, 0
        mov si, screen_buffer
        mov dx, 0
        cld
        lop:
           mov cx, 80
           rep movsw
           call Delay
           call Delay
           inc dx
           cmp dx, 25
           jne lop
        popa
        ret
;'''''''''''''''''''''''''''''''''''''''''


;OOOOOOOOOOOOOOOOOO{all intro print functions and variables}OOOOOOOOOOOOOOOOOO

str_title: db '<(Sea Simulator)>'                           ; string size: 17 
str_greet: db 'Welcome, '                                   ; string size: 9 
str0:   db '-===<(Controls)>===-'                           ; string size: 20
str1:   db '=> Press ESC key to exit the game.'             ; string size: 34
str2:   db '=> Press Arrow keys to move Fish.'              ; string size: 33
str3:   db '=> Press LShift key to change active Fish.'     ; string size: 43
str4:   db '-===<(About Coins)>===-'                        ; string size: 23
str5:   db '=> Collect Green coin to earn 10 and Red coin to earn 50 points.'       ; string size: 65 
str6:   db '=> Green coin Respawns after 5 and Red coin Respawns after 10 seconds.' ; string size: 71
str7:   db 'Developed By: 21L-1770 And 21L-5373'            ; string size: 35
str8:   db 'Press Enter To Continue Or Press Escape To Exit'; string size: 47

msg_name:	db ' Enter your name: '                         ; name prompt string
name_size:  dw 18                                           ; name string size
buf_name:	db 50 						                    ; Byte # 0: Max length of buffer
            db 0 						                    ; Byte # 1: number of characters on return(actual size after writing)
times 50    db 0                                            ; Space for user input

;OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

;|||//////////////////////////////////////////////////////////////////////|||
;------------------> Function to print the intro page box <------------------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||

Intro_box:      ; function to print full intro box
    pusha       ; with string inside

    call clr_sc
    call Introbox
    call Print_Ins
    
    popa
    ret
;'''''''''''''''''''''''''''''''''''''''''

Introbox:         ; Prints tha background of intro-box
    push ax
    push di
    push es

    mov ax , 0xB800
    mov es , ax
    mov di , 640
    mov cx, 1280
    mov ax, 0x1120

    cld
    rep stosw

    call Print_Border
    
    pop es
    pop di
    pop ax
    ret
;'''''''''''''''''''''''''''''''''''''''''

Print_Border:       ; function to print the borders
    push es         ; on the boundries of the intro box
    push ax
    push cx
    push di

    mov ax, 0xb800
    mov es, ax
    mov di, 640     ; put top left corner here
    mov ah, 0x1f
    mov al, 0xcd;
    mov cx, 79      ; top boundary distance
    cld 
    rep stosw

    mov cx, 16      ; distance between top-right to bottom-right
    mov al, 0xBA    ; ||

 right:
    mov word[es:di], ax
    add di, 160
    sub cx, 1
    jnz right

    mov cx, 79      ; bottom boundary distance
    mov al, 0xcd
    std
    rep stosw

    mov cx, 16      ; distance between top-left to bottom-left
    mov al, 0xBA    ;||

    left:
    mov word[es:di], ax
    sub di, 160
    sub cx, 1
    jnz left

    mov di, 640     ; printing corner blocks
    mov al, 0xC9;
    mov word[es:di],ax

    mov di, 798
    mov al, 0xbb
    mov word[es:di],ax

    mov di, 3358
    mov al, 0xbc
    mov word[es:di],ax

    mov di, 3200
    mov al, 0xc8
    mov word[es:di],ax

    mov ax, 0x1F7C
    mov cx, 11
    mov di, 1358

 mid:
    mov word[es:di], ax
    add di, 160
    dec cx
    jnz mid

    pop di
    pop cx
    pop ax
    pop es
    ret
;'''''''''''''''''''''''''''''''''''''''''


Intro:          ; function to call intro_box
    pusha       ; and enable continue or exit

    call Print_Frame
    call save_sc
    call clr_sc

    call Intro_box

    wait_intro:
        cmp byte[esc], 1
        je exit_intro

        cmp byte[enter_k], 1
        jne wait_intro
    
    call Slide_screen

 exit_intro:
    popa
    ret
;'''''''''''''''''''''''''''''''''''''''''

;|||//////////////////////////////////////////////////////////////////////|||
;------------------> Function to print intro page strings <------------------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||

Print_Ins:         ; function to print customize string 
    pusha          ; on the string

    mov bx, str_title
    push 0
    push 0x001B
    push 703        ; +256 to get the next line
    push 2
    push bx
    call print_String
    
    add bx, 2
    push 0
    push 0x001F
    push 705
    push 13
    push bx
    call print_String

    add bx, 13
    push 0
    push 0x001B
    push 718
    push 2
    push bx
    call print_String
;//////////////////////

    mov bx, str_greet
    push 0
    push 0x001F
    push 1215
    push 9
    push bx
    call print_String

    mov ax, 0
    mov al, [buf_name + 1];
    mov bx, buf_name
    add bx, 2

    push 0
    push 0x001F
    push 1224
    push ax
    push bx
    call print_String

;//////////////////////
    push 0
    mov bx, str1
    push 0x001F
    push 2210       ; +256 to get the next value
    push 9
    push bx
    call print_String

    add bx, 9
    push 0
    push 0x001A
    push 2219       ; +256 to get the next value
    push 4
    push bx
    call print_String

    add bx, 4
    push 0
    push 0x001F
    push 2223
    push 21
    push bx
    call print_String
;//////////////////////

    mov bx, str0
    push 0 
    push 0x001F
    push 1706
    push 20
    push bx
    call print_String

    mov bx, str4
    push 0 
    push 0x001F
    push 1744
    push 23
    push bx
    call print_String
;//////////////////////

    mov bx, str2 
    push 0 
    push 0x001F
    push 2722
    push 20
    push bx
    call print_String
    
    add bx, 9
    push 0
    push 0x001A
    push 2731
    push 6
    push bx
    call print_String

    add bx, 6
    push 0
    push 0x001F
    push 2737
    push 18
    push bx
    call print_String
;///////////////////
    
    mov bx, str3
    push 0
    push 0x001F
    push 3234
    push 9
    push bx
    call print_String

    add bx, 9
    push 0
    push 0x001A
    push 3243
    push 7
    push bx
    call print_String

    add bx, 7
    push 0
    push 0x001F
    push 3250
    push 20
    push bx
    call print_String

    add bx, 20
    push 0
    push 0x001F
    push 3492
    push 6
    push bx
    call print_String
;///////////////////

    mov bx, str5
    push 0
    push 0x001F
    push 2249
    push 11
    push bx
    call print_String

    add bx, 11
    push 0
    push 0x0012
    push 2260
    push 6
    push bx
    call print_String

    add bx, 6
    push 0
    push 0x001F
    push 2266
    push 13
    push bx
    call print_String

    add bx, 13
    push 0
    push 0x0012
    push 2279
    push 3
    push bx
    call print_String

    add bx, 3
    push 0
    push 0x001F
    push 2282
    push 4
    push bx
    call print_String

    add bx, 4
    push 0
    push 0x0014
    push 2508
    push 4
    push bx
    call print_String

    add bx, 4
    push 0
    push 0x001F
    push 2512
    push 13
    push bx
    call print_String

    add bx, 13
    push 0
    push 0x0014
    push 2525
    push 3
    push bx
    call print_String

    add bx, 3
    push 0
    push 0x001F
    push 2528
    push 7
    push bx
    call print_String
;//////////////////

    mov bx, str6
    push 0
    push 0x001F
    push 3017
    push 3
    push bx
    call print_String

    add bx, 3
    push 0
    push 0x0012
    push 3020
    push 6 
    push bx
    call print_String

    add bx, 6
    push 0
    push 0x001F
    push 3026
    push 20
    push bx
    call print_String

    add bx, 20
    push 0
    push 0x0012
    push 3046
    push 2
    push bx
    call print_String

    add bx, 2
    push 0
    push 0x001F
    push 3048
    push 4
    push bx
    call print_String

    add bx, 4
    push 0
    push 0x0014
    push 3276
    push 4
    push bx
    call print_String

    add bx, 4
    push 0
    push 0x001F
    push 3280
    push 20
    push bx
    call print_String

    add bx, 20
    push 0
    push 0x0014
    push 3300
    push 3
    push bx
    call print_String

    add bx, 3
    push 0
    push 0x001F
    push 3303
    push 8
    push bx
    call print_String
;//////////////////////

    push 0
    push 0x001F
    push 4906
    push 35
    push str7
    call print_String
;//////////////////////

    push 0
    push 0x0087
    push 5648
    push 47
    push str8
    call print_String

    popa
    ret
;'''''''''''''''''''''''''''''''''''''''''

;|||//////////////////////////////////////////////////////////////////////|||
;-----------> Function to ask user's name and store it in buffer <-----------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||

ask_name:
    pusha
    
    call clr_sc

    push 1
    push 0x000F
    push 0000                     ; h-bits = x-cor, l-bits = y-cor 
    push word[name_size]
    push msg_name
    call print_String

    mov dx, buf_name 		      ; input buffer (ds:dx pointing to input buffer)
	mov ah, 0x0A 			      ; DOS' service A – buffered input
	int 0x21 			          ; dos services call

    popa
    ret
;'''''''''''''''''''''''''''''''''''''''''

;|||//////////////////////////////////////////////////////////////////////|||
;------------------------------> Main Function <-----------------------------
;|||\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\|||

start:
    
    call reso
    call ask_name
    call Hook_ints
    call Intro

    cmp byte[esc], 1
    je leave_game
    
    call Animate
 leave_game:
    call UnHook_ints

mov ax, 0x4c00
int 0x21
;'''''''''''''''''''''''''''''''''''''''''