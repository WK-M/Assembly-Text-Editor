; Kendall Molas
; CSc 211
MODEL SMALL

.code
assume cs:cseg, ds:cseg
cseg segment 
org 100h

START:
    ;LOAD GRAPHICS
    mov ax, 0b800h
    mov es, ax

    xor dx,dx ; Needed for some reason

    ; CLEAR SCREEN
    mov ah, 0
    mov al, 03
    int 10h

    call TOP
    jmp GET_CHOICE

    TOP PROC
        ; Fill Color in for Menu
        mov di, 1
        COLOR_SCHEME:
            mov BYTE PTR es:[di], 4Fh
            add di, 2
            cmp di, 4000
            jle COLOR_SCHEME

        ; ---------------------------------------
        ; Instantiate Messages
        call CENTER
        mov ah, 09
        mov dx, offset msg0
        int 21h

        mov dh, 1
        call CENTER
        mov ah, 09
        mov dx, offset msg1
        int 21h

        mov dh, 2
        call CENTER
        mov ah, 09
        mov dx, offset msg2
        int 21h

        mov dh, 3
        call CENTER
        mov ah, 09
        mov dx, offset msg3
        int 21h

        mov dh, 4
        mov ah, 09
        mov dx, offset newline
        int 21h
            
        mov dh, 5
        call CENTER
        mov ah, 09
        mov dx, offset control_msg0
        int 21h

        mov dh, 6
        call CENTER
        mov ah, 09
        mov dx, offset control_msg1
        int 21h

        mov dh, 7
        call CENTER
        mov ah, 09
        mov dx, offset control_msg2
        int 21h

        mov dh, 8
        call CENTER
        mov ah, 09
        mov dx, offset control_msg3
        int 21h

        mov dh, 9
        call CENTER
        mov ah, 09
        mov dx, offset control_msg4
        int 21h

        mov dh, 10
        call CENTER
        mov ah, 09
        mov dx, offset control_msg5
        int 21h

        mov dh, 11
        call CENTER
        mov ah, 09
        mov dx, offset control_msg6
        int 21h

        mov dh, 12
        mov ah, 09
        mov dx, offset newline
        int 21h

        mov dh, 13
        call CENTER
        mov ah, 09
        mov dx, offset control_msg7
        int 21h

        mov dh, 14
        call CENTER
        mov ah, 09
        mov dx, offset control_msg8
        int 21h

        ret
    TOP ENDP

    CENTER PROC
        mov dl, 25
        add dh, 1
        mov ah, 2
        mov bh, 0 
        int 10h
        ret
    CENTER ENDP

    ; End Instantiate of Messages
    ; ---------------------------------------

    ; ---------------------------------------
    ; MENU OPTIONS

    GET_CHOICE:
        ; Grow SI Foward
        cld
        mov ah, 02h
        mov dh, 1
        mov dl, 55
        int 10h

        mov ah, 0h
        int 16h
        
        cmp ah, 02h
        je CREATE

        cmp ah, 03h
        je OPEN_AND_MODIFY

        cmp ah, 42h
        je PROGRAM_EXIT

    TRY_AGAIN:
        mov dh, 17
        call CENTER
        mov ah, 09
        mov dx, offset repeat_msg0
        int 21h
        jmp GET_CHOICE

    PROGRAM_EXIT:
        ; CLEAR SCREEN
        mov ah, 0
        mov al, 03
        int 10h

        mov ah, 4ch
        int 21h
    ; ---------------------------------------

    ; ---------------------------------------
    ; File Related
    CREATE:
        call FILE_DEFAULT
        mov dx, offset inname
        mov ah, 3ch
        sub cx,cx
        int 21h
        mov outh, ax

        mov ah, 0
        mov al, 03
        int 10h
        jmp SET_CURSOR_POS

    OPEN_AND_MODIFY:
        ; CLEAR SCREEN
        mov ah, 0
        mov al, 03
        int 10h

        mov ah, 09
        mov dx, offset newline
        int 21h

        mov ah, 09
        mov dx, offset newline
        int 21h

        ; Open the current file in read mode
		mov ah, 3dh
		mov al, 0
        mov dx, offset inname
        int 21h
        jc JUMP_TO_ERROR_FROM_MENU
        mov inh, ax

        ; Start File Read
        mov ah, 3fh
        mov bx, inh
        mov cx, BUFF_SIZE ; Read n size bytes
        mov dx, offset buffer ; store address of buffer to dx
        int 21h

        add dx, ax; <-- 
        mov bx, dx
        mov byte ptr [bx], '$' ; Add string termination to end of bx register

        mov dx, offset buffer
        mov ah, 9
        int 21h
        jmp SET_CURSOR_POS

    JUMP_TO_ERROR_FROM_MENU:
        jmp ERROR

    SET_BORDERS PROC
        mov BYTE PTR es:[6], 'M'
        mov BYTE PTR es:[7], 04h
        mov BYTE PTR es:[8], 'O'
        mov BYTE PTR es:[9], 04h
        mov BYTE PTR es:[10], 'D'
        mov BYTE PTR es:[11], 04h
        mov BYTE PTR es:[12], 'E'
        mov BYTE PTR es:[13], 04h
        mov BYTE PTR es:[14], ':'
        mov BYTE PTR es:[15], 04h

        ; Second Row
        mov di, 160
        top_border:
            mov BYTE PTR ES:[DI], 205
            mov BYTE PTR ES:[DI+1], 02h
            add di, 2
            cmp di, 320
            jne top_border
        
        ; 23rd Row
        mov di, 3680
        bottom_border:
            mov BYTE PTR ES:[DI], 205
            mov BYTE PTR ES:[DI+1], 01h
            add di, 2
            cmp di, 3840
            jne bottom_border

        ret
    SET_BORDERS ENDP

    ; SET ORIGINAL CURSOR POSITION
    SET_CURSOR_POS:
        call SET_BORDERS
        mov ah, 01h
        mov cx, 0007h ; block cursor
        int 10h

        mov ah, 02h
        mov dl, 0
        mov dh, 2
        int 10h
        mov si, offset buffer     ; Store address of buffer into SI
        jmp VIEW_MODE
        
    ; ------------------------------------------
    ; -------- DRAW MODE--------
    ; Enable Drawing of Boxes

    RIGHT_DRAW:
        cmp dl, 79
        jge DRAW_MODE
        cmp dh, 23
        jge DRAW_MODE

        call DRAW_BOX
        mov ah,02h ; Output to screen

        add dl, 1
        int 10h
        mov [si], al ; Output to buffer
        inc si
        jmp DRAW_MODE

    DELETE_CHAR_DRAW:
        cmp dl, 0  ; If deleting at top row
        je DRAW_MODE

        ; Move cursor back one
        mov ah, 02h
        sub dl, 1
        int 10h

        ; and delete 
        mov ah, 0ah
        mov al, 20h
        mov cx, 1
        int 10h

        ; Decrement SI and place whitespace on selected area
        dec si
        mov al, 20h
        mov [si], al

        jmp DRAW_MODE

    DRAW_MODE:
        mov BYTE PTR es:[18], 'D'
        mov BYTE PTR es:[19], 05h

        mov ah, 0
        int 16h

        cmp ah, 0eh
        je DELETE_CHAR_DRAW

        cmp al, 'l'
        je RIGHT_DRAW

        cmp al, 'h'
        je LEFT_DRAW

        cmp al, 'j'
        je DOWN_DRAW

        cmp al, 'k'
        je UP_DRAW

        cmp al, 'i'
        je JUMP_TO_EDIT_FROM_DRAW

        cmp ah, 42h
        je JUMP_TO_OPEN_FROM_DRAW

        cmp ah, 01h
        je VIEW_MODE

        jne DRAW_MODE

    DRAW_BOX PROC
        mov ah, 0ah
        mov al, 254 ;  
        mov cx, 1
        int 10h
        ret
    DRAW_BOX ENDP

    LEFT_DRAW:
        cmp dl, 0 ; Boundary Check
        jle DRAW_MODE

        call DRAW_BOX
        mov ah,02h
        sub dl, 1
        int 10h
        mov [si], al ; Output to buffer
        dec si
        jmp DRAW_MODE

    DOWN_DRAW:
        cmp dh, 22
        jge DRAW_MODE

        call DRAW_BOX
        mov ah,02h
        add dh, 1
        int 10h

        mov [si], al
        add si, 80
        jmp DRAW_MODE

    UP_DRAW:
        cmp dh, 2
        jle DRAW_MODE

        call DRAW_BOX
        mov ah,02h
        sub dh, 1
        int 10h
        
        mov [si], al
        sub si, 80
        jmp DRAW_MODE
    ; ------------- END DRAW MODE --------------
    ; ------------------------------------------

    JUMP_TO_DRAW_FROM_VIEW:
        jmp DRAW_MODE

    ; Jump helper to allow jump from draw mode to save
    JUMP_TO_OPEN_FROM_DRAW:
        jmp OPEN_TO_WRITE

    JUMP_TO_EDIT_FROM_DRAW:
        jmp EDIT_MODE

    ; ------------------------------------------
    ; -------- VIEW MODE--------
    DELETE_CHAR_AT_POS:
        mov ah, 0ah
        mov al, 20h
        mov cx, 1
        int 10h

        mov al, 20h
        mov [si], al
        ;dec si
        jmp VIEW_MODE

    VIEW_MODE:
        mov BYTE PTR es:[18], 'V'
        mov BYTE PTR es:[19], 02h

        ; Read keyboard input
		mov ah, 0
		int 16h

        cmp al, 'l'
        je RIGHT_KEY

        cmp al, 'h'
        je LEFT_KEY

        cmp al, 'j'
        je DOWN_KEY

        cmp al, 'k'
        je UP_KEY

        cmp al, 'i'
        je JUMP_TO_EDIT_MODE_FROM_DRAW

        cmp al, 'd'
        je JUMP_TO_DRAW_FROM_VIEW ; Use jump helper to get to view mode

        cmp al, 'x'
        je DELETE_CHAR_AT_POS

        ; If F8 has been pressed, go to open and write buffer into file
        cmp ah, 42h
        je JUMP_TO_OPEN_FROM_EDIT ; Use jump helper to get to view mode

        jne VIEW_MODE

    DOWN_KEY:
        cmp dh, 22
        jge VIEW_MODE

        mov ah, 02h
        add dh, 1
        int 10h

        ; new location, move down a row
        add si, 80
        jmp VIEW_MODE

    UP_KEY:
        cmp dh, 2
        jle VIEW_MODE

        mov ah, 02h
        sub dh, 1
        int 10h

        ;new location, move up a row
        sub si, 80
        jmp VIEW_MODE

    RIGHT_KEY:
        cmp dl, 79
        jge VIEW_MODE

        cmp dh, 23
        jge VIEW_MODE

        mov ah, 02h
        add dl, 1
        int 10h
        inc si
        jmp VIEW_MODE

    LEFT_KEY:
        ; ---------------------------------------------
        ; Parameters to prevent exiting box area
        cmp dl, 0
        jle VIEW_MODE

        cmp dh, 0
        jle VIEW_MODE
        ; ---------------------------------------------

        dec si
        mov ah, 02h
        sub dl, 1
        int 10h
        jmp VIEW_MODE

    DELETE_CHAR: 
        cmp dl, 0  ; If deleting at top row
        je EDIT_MODE

        ; Move cursor back one
        mov ah, 02h
        sub dl, 1
        int 10h

        ; and delete 
        mov ah, 0ah
        mov al, 20h
        mov cx, 1
        int 10h

        ; Decrement SI and place whitespace on selected area
        dec si
        mov al, 20h
        mov [si], al

        jmp EDIT_MODE
    ; -------- END VIEW MODE--------
    ; ------------------------------------------
    JUMP_TO_EDIT_MODE_FROM_DRAW:
        jmp EDIT_MODE

    JUMP_TO_VIEW_MODE_FROM_EDIT:
        jmp VIEW_MODE

    JUMP_TO_OPEN_FROM_EDIT:
        jmp OPEN_TO_WRITE

    ADJUST_CURSOR_POS:
        mov ah, 02h
        sub dl, 1
        int 10h
        jmp EDIT_MODE
    
    ; ------------------------------------------
    ; -------- EDIT MODE--------
    EDIT_MODE:
        mov BYTE PTR es:[18], 'E'
        mov BYTE PTR es:[19], 08h

        ; USE FOR CHECKING IF BOX EXISTS AT CURRENT CURSOR POSITION
        mov ah, 08h
        int 10h
        cmp al, 254
        je ADJUST_CURSOR_POS

        ; Wait for Keypress
        mov ah, 0
        int 16h

        ; If Escape has been pressed, return to view mode
        cmp ah, 01h
        je JUMP_TO_VIEW_MODE_FROM_EDIT

        ; If backspace pressed, erase character
        cmp ah, 0eh
        je DELETE_CHAR

        cmp ah, 1ch
        je ENTER_KEY

        ; If F8 has been pressed, go to open and write buffer into file
        cmp ah, 42h
        je OPEN_TO_WRITE

        ; Else: Take user input and store in SI
        mov [si], al
        inc si

        ; And output to screen
        mov ah, 0ah
        mov cx, 1
        int 10h

        ; Move Cursor to the right (column) after input
        mov ah, 02h
        add dl, 1
        int 10h

        jne EDIT_MODE

    ENTER_KEY:
        cmp dh, 22 ; check boundary
        jge EDIT_MODE

        mov ah, 02h
        add dh,1
        int 10h

        add si, 80
        jmp EDIT_MODE
    ; -------- END EDIT MODE--------
    ; ------------------------------------------

    ; ------------------------------
    ; CLOSING AND SAVING FILES
    ; Open file for writing
    OPEN_TO_WRITE:
		mov ah, 3dh
		mov al, 2
        ; Open filename that was either created or modified
        mov dx, offset inname 
        int 21h
        jc ERROR
        mov inh, ax
        
    SAVE_FILE:
        mov ah, 40h
        mov bx, outh ; get file handle
        mov cx, BUFF_SIZE
        mov dx, offset buffer
        int 21h

    CLOSE_FILE:
        mov ah, 3eh
        mov bx, outh
        int 21h
        jmp DONE

    ERROR:
        mov ah, 09
        mov dx, offset error_msg0
        int 21h

        mov ah, 4ch
        int 21h
    ; ---------------------------------------
    ; File Parameters

    FILE_DEFAULT PROC
        mov ah, 0
        mov al, 03
        int 10h

        inname db 'try2.txt', 0
        outname db 'try2.txt', 0
        BUFF_SIZE = 1760
        buffer db BUFF_SIZE dup(?)
        inh dw ? ; input file handle
        outh dw ?
        ret
    FILE_DEFAULT ENDP
    ; End File Parameters
    ; ---------------------------------------
    DONE:
        ; CLEAR SCREEN
        mov ah, 0
        mov al, 03
        int 10h

        ; CREATE NEW LINE AND TERMINATE PROGRAM
        mov dl, 10
        mov ah, 02h
        int 21h

        mov ah, 09
        mov dx, offset saved_file
        int 21h

        mov ah, 4ch
        int 21h

    ; ---------------------------------------
    ; Messages
    success_msg db 'success has occurred', 10, 13, '$'
    msg0 db 'Type number to choose option:', 10, 13, '$'
    msg1 db '(1) Create new file', 10, 13, '$'
    msg2 db '(2) Open Existing File and View', 10, 13, '$'
    msg3 db '(F8) Exit this Menu', 10, 13, '$'
    newline db ' ', 10, 13, '$'
    saved_file db 'File saved. Now closing', 10, 13, '$'
    control_msg0 db 'Text(VIM) CONTROLS:', 10,13,'$'
    control_msg1 db 'Insert Mode: i', 10,13,'$'
    control_msg2 db 'Draw Mode: d', 10,13,'$'
    control_msg3 db 'View Mode: Escape', 10,13,'$'
    control_msg4 db 'ERASE: Backspace', 10,13,'$'
    control_msg5 db 'Delete at Cursor: x', 10,13,'$'
    control_msg6 db 'Exit and Save: F8', 10,13,'$'
    control_msg7 db 'Note that to open file', '$'
    control_msg8 db 'Must execute COM again', '$'

    repeat_msg0 db 'Please choose valid choice.', 10, 13, '$'
    error_msg0 db 'Please create a file before opening.', 10, 13, '$'
cseg ends
end START
