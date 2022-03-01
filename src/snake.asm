[bits 16]
org 0x7c00

%define TOTAL_PIXELS 320*200
%define PITCH 320
%define WIDTH 320
%define HEIGHT 200
%define SNAKE_PART_SIZE 10
%define APPLE_SIZE 10
%define SNAKE_LIST_ADDR 0x7e00

; some VGA color values
%define LIGHT_RED 0x27
%define WHITE 0x0f
%define LIME 0x2e

%define W_SCANCODE 0x11
%define A_SCANCODE 0x1e
%define S_SCANCODE 0x1f
%define D_SCANCODE 0x20

main:
    xor ax, ax
    mov ds, ax
    mov ss, ax
    cld

    mov sp, 0x7bff
    mov bp, sp

    ; sets the video mode (320x200, 255 colors)
    xor ah, ah
    mov al, 0x13
    int 0x10

    mov ax, 0xa000
    mov es, ax

    call draw_bg
    call update_apple
    mov dword [SNAKE_LIST_ADDR], 0x0000

.main_loop:
    ; clear the screen
    call draw_bg 

    ; draw the stuff
    call draw_snake
    call draw_apple

    ; handle keypresses
    call handle_keyboard
    
    ; check for collisions
    call check_collision

    ; update the snake's position
    call update_snake

    call sleep
    jmp .main_loop

    ; we should never get here
    cli
    hlt

draw_bg:
    xor di, di
    mov cx, TOTAL_PIXELS
    mov al, WHITE
    rep stosb 
    ret

; di: x coordinate
; bx: y coordinate
; di: return value
calculate_pos:
    mov ax, PITCH
    mul bx
    add di, ax
    ret

; cx: square size
; di: square position
; al: square color
draw_square:
    mov dx, di
    mov bx, cx
.loop:
    push cx
    mov cx, bx
    rep stosb
    add dx, PITCH
    mov di, dx

    pop cx
    loop .loop
    ret

draw_snake:
    mov si, SNAKE_LIST_ADDR
    xor cx, cx 
.loop:
    cmp cl, byte [snake_length] 
    je .end
    lodsd

    ; ax now has the x pos, and the upper 16 bits of eax the y pos
    mov di, ax
    shr eax, 16
    mov bx, ax
    call calculate_pos

    push cx
    mov ax, LIME
    mov cx, SNAKE_PART_SIZE
    call draw_square
    pop cx
    
    inc cl
    jmp .loop
.end:
    ret

draw_apple:
    mov di, word [apple_x]
    mov bx, word [apple_y]
    call calculate_pos
    mov cx, APPLE_SIZE
    mov ax, LIGHT_RED
    call draw_square
    ret

; lolz
update_apple:
    rdtsc
    mov byte [apple_x], al
    movzx dx, ah
    cmp ah, 180 ; the max y value we can have is 200
    jle .continue
    mov dx, 180
.continue:
    mov word [apple_y], dx
    ret

update_snake:
    mov eax, dword [SNAKE_LIST_ADDR] ; save previous position of the head

    ; update the position of the head
    mov dx, word [vel_x]
    add word [SNAKE_LIST_ADDR], dx
    mov dx, word [vel_y]
    add word [SNAKE_LIST_ADDR + 2], dx

    mov bx, SNAKE_LIST_ADDR + 4 
    mov cx, 1 

; move each part of the snake to the previous position of the part ahead of it
.loop:
    cmp cl, byte [snake_length] 
    je .end

    mov edi, dword [bx]
    mov dword [bx], eax
    mov eax, edi
    
    add bx, 4
    inc cl
    jmp .loop
.end:
    ret

check_collision:
    ; check to see if we collided with the apple
    mov ax, word [SNAKE_LIST_ADDR] ; x pos
    mov bx, word [SNAKE_LIST_ADDR + 2] ; y pos

    mov dx, word [apple_x]
    add dx, APPLE_SIZE
    cmp ax, dx
    jg .next
    add ax, SNAKE_PART_SIZE
    cmp ax, word [apple_x]
    jl .next

    mov dx, word [apple_y]
    add dx, APPLE_SIZE
    cmp bx, dx
    jg .next
    add bx, SNAKE_PART_SIZE
    cmp bx, word [apple_y]
    jl .next

    ; collided with the apple
    inc word [snake_length] ; increment the length of the snake
    call update_apple

    jmp .end

.next:
    ; check to see if we collided with the borders
    mov ax, word [SNAKE_LIST_ADDR] ; x pos
    mov bx, word [SNAKE_LIST_ADDR + 2] ; y pos

    cmp ax, 0
    jge .collide_right
    jmp .reset
.collide_right:
    add ax, SNAKE_PART_SIZE
    cmp ax, WIDTH
    jle .collide_top
    jmp .reset
.collide_top:
    cmp bx, 0
    jge .collide_bottom
    jmp .reset
.collide_bottom:
    add bx, SNAKE_PART_SIZE
    cmp bx, HEIGHT
    jle .end

.reset:
    mov byte [snake_length], 1
    mov dword [SNAKE_LIST_ADDR], 0x0000 ; put the snake at x: 0, y: 0
    mov word [vel_x], 10
    mov word [vel_y], 0
    call update_apple

.end:
    ret

; sleep by polling PIT's counter
sleep:
    xor ax, ax
    out 0x43, ax
.loop:
    in al, 0x40
    shl ax, 8
    in al, 0x40
    test ax, ax
    jne .loop
    ret

handle_keyboard:
    ; see if a key was pressed
    mov ah, 0x1
    int 0x16
    jz .end

    xor ah, ah
    int 0x16

    ; see if the key pressed matches WASD
    cmp ah, W_SCANCODE
    jne .test_a 
    mov word [vel_y], -10
    mov word [vel_x], 0
    jmp .end
.test_a:
    cmp ah, A_SCANCODE
    jne .test_s
    mov word [vel_x], -10
    mov word [vel_y], 0
    jmp .end
.test_s:
    cmp ah, S_SCANCODE
    jne .test_d
    mov word [vel_y], 10
    mov word [vel_x], 0
    jmp .end
.test_d:
    cmp ah, D_SCANCODE
    jne .end
    mov word [vel_x], 10
    mov word [vel_y], 0
.end:
    ret

; global variables

vel_x dw 10
vel_y dw 0

snake_length db 1

apple_x dw 0
apple_y dw 0

times 510-($-$$) db 0
dw 0xaa55