TITLE Brick Breaker Game (Brick_Breaker.asm)
; A Brick Breaker game with Windows GUI
; Internal logic aligned with x86 Assembly Course concepts (Loops, Stack, Mul/Div, Bitwise)

.386                                         ; use 386 instruction set
.model flat, stdcall                         ; flat memory model, stdcall convention
option casemap:none                          ; case sensitive identifiers

; ============================================
; Constants (Win32 API requirements)
; ============================================
NULL                EQU 0                    
WS_OVERLAPPED       EQU 00000000h            
WS_CAPTION          EQU 00C00000h            
WS_SYSMENU          EQU 00080000h            
WS_MINIMIZEBOX      EQU 00020000h            
WS_VISIBLE          EQU 10000000h            
CS_HREDRAW          EQU 0002h                
CS_VREDRAW          EQU 0001h                
IDI_APPLICATION     EQU 32512                
IDC_ARROW           EQU 32512                
SW_SHOW             EQU 5                    
CW_USEDEFAULT       EQU 80000000h            
WM_CREATE           EQU 0001h                
WM_DESTROY          EQU 0002h                
WM_PAINT            EQU 000Fh            
WM_KEYDOWN          EQU 0100h            
WM_TIMER            EQU 0113h            
TRUE                EQU 1                
FALSE               EQU 0                
TRANSPARENT_BK      EQU 1                
SRCCOPY             EQU 00CC0020h        

VK_LEFT             EQU 25h              
VK_RIGHT            EQU 27h              
VK_SPACE            EQU 20h              
VK_ESCAPE           EQU 1Bh              
VK_RETURN           EQU 0Dh              
VK_I                EQU 49h              
VK_Q                EQU 51h              
VK_R                EQU 52h              
WINDOW_WIDTH        EQU 640                  
WINDOW_HEIGHT       EQU 500                  

BORDER_LEFT         EQU 30                   
BORDER_TOP          EQU 50                   
BORDER_RIGHT        EQU 610                  
BORDER_BOTTOM       EQU 450                  
BORDER_THICKNESS    EQU 4                    

BRICK_ROWS          EQU 3               
BRICK_COLS          EQU 8               
TOTAL_BRICKS        EQU 24              
BRICK_WIDTH         EQU 62              
BRICK_HEIGHT        EQU 20              
BRICK_GAP           EQU 6               
BRICK_START_X       EQU 42              
BRICK_START_Y       EQU 70              

PADDLE_WIDTH        EQU 80              
PADDLE_HEIGHT       EQU 12              
PADDLE_Y            EQU 425             
PADDLE_SPEED        EQU 15              

BALL_SIZE           EQU 8               
BALL_SPEED          EQU 3               
POWERUP_SIZE        EQU 16              

TIMER_ID            EQU 1               
TIMER_INTERVAL      EQU 8               

; ============================================
; Structures
; ============================================
POINT STRUCT
    x   DWORD ?
    y   DWORD ?
POINT ENDS

RECT STRUCT
    left    DWORD ?
    top     DWORD ?
    right   DWORD ?
    bottom  DWORD ?
RECT ENDS

MSG STRUCT
    hwnd    DWORD ?
    message DWORD ?
    wParam  DWORD ?
    lParam  DWORD ?
    time    DWORD ?
    pt      POINT <>
MSG ENDS

WNDCLASSEX STRUCT
    cbSize          DWORD ?
    style           DWORD ?
    lpfnWndProc     DWORD ?
    cbClsExtra      DWORD ?
    cbWndExtra      DWORD ?
    hInstance       DWORD ?
    hIcon           DWORD ?
    hCursor         DWORD ?
    hbrBackground   DWORD ?
    lpszMenuName    DWORD ?
    lpszClassName   DWORD ?
    hIconSm         DWORD ?
WNDCLASSEX ENDS

PAINTSTRUCT STRUCT
    hdc         DWORD ?
    fErase      DWORD ?
    rcPaint     RECT <>
    fRestore    DWORD ?
    fIncUpdate  DWORD ?
    rgbReserved BYTE 32 DUP(?)
PAINTSTRUCT ENDS

; ============================================
; Function Prototypes
; ============================================
GetModuleHandleA PROTO :DWORD
ExitProcess PROTO :DWORD
Beep PROTO :DWORD,:DWORD
GetTickCount PROTO                           
RegisterClassExA PROTO :DWORD
CreateWindowExA PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ShowWindow PROTO :DWORD,:DWORD
UpdateWindow PROTO :DWORD
GetMessageA PROTO :DWORD,:DWORD,:DWORD,:DWORD
TranslateMessage PROTO :DWORD
DispatchMessageA PROTO :DWORD
DefWindowProcA PROTO :DWORD,:DWORD,:DWORD,:DWORD
PostQuitMessage PROTO :DWORD
BeginPaint PROTO :DWORD,:DWORD
EndPaint PROTO :DWORD,:DWORD
LoadIconA PROTO :DWORD,:DWORD
LoadCursorA PROTO :DWORD,:DWORD
GetClientRect PROTO :DWORD,:DWORD
FillRect PROTO :DWORD,:DWORD,:DWORD      
SetTimer PROTO :DWORD,:DWORD,:DWORD,:DWORD 
KillTimer PROTO :DWORD,:DWORD             
InvalidateRect PROTO :DWORD,:DWORD,:DWORD 
wsprintfA PROTO C :DWORD,:DWORD,:VARARG   
CreateSolidBrush PROTO :DWORD
DeleteObject PROTO :DWORD
SetBkMode PROTO :DWORD,:DWORD
SetTextColor PROTO :DWORD,:DWORD
TextOutA PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
SelectObject PROTO :DWORD,:DWORD
GetStockObject PROTO :DWORD
CreateCompatibleDC PROTO :DWORD
CreateCompatibleBitmap PROTO :DWORD,:DWORD,:DWORD
BitBlt PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
DeleteDC PROTO :DWORD

; ============================================
; Data
; ============================================
.data
className       BYTE "BrickBreakerWnd", 0  
windowTitle     BYTE "Brick Breaker", 0    
titleText       BYTE "BRICK BREAKER", 0    
hInstance       DWORD 0                     
hwndMain        DWORD 0                     

bricks          BYTE 1,1,1,1,1,1,1,1        
                BYTE 1,1,1,1,1,1,1,1        
                BYTE 1,1,1,1,1,1,1,1        

rowColors       DWORD 00FF0000h             ; blue
                DWORD 0000CC00h             ; green
                DWORD 000000FFh             ; red

paddleX         DWORD 280                   

ballX           DWORD 316                   
ballY           DWORD 413                   
ballDX          SDWORD 3                    
ballDY          SDWORD -3                   
ballActive      DWORD 0                     

ball2X          DWORD 0                     
ball2Y          DWORD 0                     
ball2DX         SDWORD 0                    
ball2DY         SDWORD 0                    
ball2Active     DWORD 0                     

powerX          DWORD 0                     
powerY          DWORD 0                     
powerActive     DWORD 0                     
powerSpeed      DWORD 4                     

score           DWORD 0                     
lives           DWORD 3                     
bricksLeft      DWORD 24                    
gameState       DWORD 3                     
timerTicks      DWORD 0                     
timeSeconds     DWORD 0                     
solidBaseTimer  DWORD 0                     
currentRound    DWORD 1                     

scoreLabel      BYTE "Score: ", 0           
livesLabel      BYTE "Lives: ", 0           
timeLabel       BYTE "Time: ", 0            
roundLabel      BYTE "Round: ", 0           

scoreBuf        BYTE 32 DUP(0)              
livesBuf        BYTE 32 DUP(0)              
timeBuf         BYTE 32 DUP(0)              
roundBuf        BYTE 32 DUP(0)              
fmtStr          BYTE "%d", 0                

winMsg          BYTE "YOU WIN!", 0          
loseMsg         BYTE "GAME OVER", 0         
restartMsg      BYTE "Press SPACE to restart", 0 
startMsg        BYTE "Press SPACE to launch ball", 0 
hint1Msg        BYTE "Left/Right Arrows to move", 0  
hint2Msg        BYTE "Red bricks give 5s solid base!", 0 
hint3Msg        BYTE "Survive 5s for random Multiball drops!", 0  
titleWelcomeMsg BYTE "WELCOME TO BRICK BREAKER", 0
titlePlayMsg    BYTE "PRESS ENTER TO PLAY GAME", 0
titleInstrMsg   BYTE "PRESS I FOR INSTRUCTION BOX", 0
titleExitMsg    BYTE "PRESS ESC TO QUIT GAME", 0
instrTitleMsg   BYTE "INSTRUCTIONS", 0
endScoresMsg    BYTE "YOUR TOTAL SCORE: ", 0
endLivesMsg     BYTE "LIVES REMAINING: ", 0
endRestartMsg   BYTE "PRESS R TO RESTART YOUR GAME", 0
endQuitMsg      BYTE "PRESS Q TO QUIT GAME", 0

; ============================================
; Code Segment
; ============================================
.code

; ---------------------------------------------------------
; [Lab 6: Stacks and Procedures] 
; Procedure to reset all bricks back to active state (1)
; Uses PUSHAD/POPAD to preserve register states
; ---------------------------------------------------------
ResetBricks PROC
    PUSHAD                      ; Push all general purpose registers to stack

    mov ecx, TOTAL_BRICKS       ; [Lab 4: Loops] Set loop counter
    mov esi, OFFSET bricks      ; [Lab 4: Arrays] Register indirect addressing base

L_ResetLoop:
    mov BYTE PTR [esi], 1       ; [Lab 3: Memory Access] Write 1 to memory
    inc esi                     ; Point to next element in array
    LOOP L_ResetLoop            ; Decrement ECX and jump if not zero

    POPAD                       ; Pop all registers from stack
    RET                         ; Return from procedure
ResetBricks ENDP

; ---------------------------------------------------------
; Main Window Procedure
; ---------------------------------------------------------
WndProc PROC hWin:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    LOCAL ps:PAINTSTRUCT                    
    LOCAL hdc:DWORD                         
    LOCAL screenDC:DWORD                    
    LOCAL hBitmap:DWORD                     
    LOCAL hOldBitmap:DWORD                  
    LOCAL rc:RECT                           
    LOCAL hBrush:DWORD                      
    LOCAL brickRow:DWORD                    
    LOCAL brickCol:DWORD                    
    LOCAL brickX:DWORD                      
    LOCAL brickY:DWORD                      

    mov eax, uMsg

    .IF eax == WM_PAINT
        invoke BeginPaint, hWin, ADDR ps
        mov screenDC, eax

        invoke CreateCompatibleDC, screenDC
        mov hdc, eax                               
        invoke GetClientRect, hWin, ADDR rc
        invoke CreateCompatibleBitmap, screenDC, rc.right, rc.bottom
        mov hBitmap, eax
        invoke SelectObject, hdc, hBitmap
        mov hOldBitmap, eax

        invoke GetStockObject, 4                   
        invoke FillRect, hdc, ADDR rc, eax

        ; [Lab 7: Conditional Structure]
        cmp gameState, 3                     
        je drawTitleScreen
        cmp gameState, 4                     
        je drawInstructionScreen
        cmp gameState, 1                     
        je drawEndScreen
        cmp gameState, 2                     
        je drawEndScreen

        invoke GetClientRect, hWin, ADDR rc
        invoke CreateSolidBrush, 00400000h
        mov hBrush, eax
        invoke FillRect, hdc, ADDR rc, hBrush
        invoke DeleteObject, hBrush

        invoke CreateSolidBrush, 00808080h
        mov hBrush, eax
        invoke SelectObject, hdc, hBrush
        mov rc.left, BORDER_LEFT
        mov rc.top, BORDER_TOP
        mov rc.right, BORDER_RIGHT
        mov rc.bottom, BORDER_TOP + BORDER_THICKNESS
        invoke FillRect, hdc, ADDR rc, hBrush
        mov rc.left, BORDER_LEFT
        mov rc.top, BORDER_TOP
        mov rc.right, BORDER_LEFT + BORDER_THICKNESS
        mov rc.bottom, BORDER_BOTTOM
        invoke FillRect, hdc, ADDR rc, hBrush
        mov rc.left, BORDER_RIGHT - BORDER_THICKNESS
        mov rc.top, BORDER_TOP
        mov rc.right, BORDER_RIGHT
        mov rc.bottom, BORDER_BOTTOM
        invoke FillRect, hdc, ADDR rc, hBrush
        invoke DeleteObject, hBrush         

        cmp solidBaseTimer, 0                
        jle skipBottomBorder                 
        
        invoke CreateSolidBrush, 000000FFh   
        mov hBrush, eax                      
        mov rc.left, BORDER_LEFT             
        mov rc.top, BORDER_BOTTOM            
        mov rc.right, BORDER_RIGHT           
        mov eax, BORDER_BOTTOM               
        add eax, BORDER_THICKNESS            
        mov rc.bottom, eax                   
        invoke FillRect, hdc, ADDR rc, hBrush 
        invoke DeleteObject, hBrush          
    skipBottomBorder:

        mov brickRow, 0                      
    drawRowLoop:
        cmp brickRow, BRICK_ROWS             
        jge doneDrawBricks                   

        mov eax, brickRow                    
        shl eax, 2                           ; [Lab 8: Bitwise Shift] Multiply by 4
        mov eax, [rowColors + eax]           
        invoke CreateSolidBrush, eax         
        mov hBrush, eax                      

        mov eax, brickRow                    
        mov ecx, BRICK_HEIGHT + BRICK_GAP    
        imul eax, ecx                        
        add eax, BRICK_START_Y               
        mov brickY, eax                      

        mov brickCol, 0                      
    drawColLoop:
        cmp brickCol, BRICK_COLS             
        jge doneRow                          

        mov eax, brickRow                    
        imul eax, BRICK_COLS                 
        add eax, brickCol                    
        movzx eax, BYTE PTR [bricks + eax]   
        cmp eax, 0                           
        je skipBrick                         

        mov eax, brickCol                    
        mov ecx, BRICK_WIDTH + BRICK_GAP     
        imul eax, ecx                        
        add eax, BRICK_START_X               
        mov brickX, eax                      

        mov eax, brickX                      
        mov rc.left, eax
        mov eax, brickY                      
        mov rc.top, eax
        mov eax, brickX                      
        add eax, BRICK_WIDTH
        mov rc.right, eax
        mov eax, brickY                      
        add eax, BRICK_HEIGHT
        mov rc.bottom, eax

        invoke FillRect, hdc, ADDR rc, hBrush 

    skipBrick:
        inc brickCol                         
        jmp drawColLoop                      
    doneRow:
        invoke DeleteObject, hBrush          
        inc brickRow                         
        jmp drawRowLoop                      
    doneDrawBricks:

        invoke CreateSolidBrush, 00FFFF00h   
        mov hBrush, eax                      
        mov eax, paddleX                     
        mov rc.left, eax                     
        mov rc.top, PADDLE_Y                 
        add eax, PADDLE_WIDTH                
        mov rc.right, eax                    
        mov eax, PADDLE_Y                    
        add eax, PADDLE_HEIGHT               
        mov rc.bottom, eax                   
        invoke FillRect, hdc, ADDR rc, hBrush 
        invoke DeleteObject, hBrush          

        invoke CreateSolidBrush, 00FFFFFFh   
        mov hBrush, eax                      
        mov eax, ballX                       
        mov rc.left, eax                     
        mov eax, ballY                       
        mov rc.top, eax                      
        mov eax, ballX                       
        add eax, BALL_SIZE                   
        mov rc.right, eax                    
        mov eax, ballY                       
        add eax, BALL_SIZE                   
        mov rc.bottom, eax                   
        invoke FillRect, hdc, ADDR rc, hBrush 
        invoke DeleteObject, hBrush          

        cmp ball2Active, 1
        jne skipDrawBall2
        invoke CreateSolidBrush, 0000FFFFh   
        mov hBrush, eax
        mov eax, ball2X
        mov rc.left, eax
        mov eax, ball2Y
        mov rc.top, eax
        mov eax, ball2X
        add eax, BALL_SIZE
        mov rc.right, eax
        mov eax, ball2Y
        add eax, BALL_SIZE
        mov rc.bottom, eax
        invoke FillRect, hdc, ADDR rc, hBrush
        invoke DeleteObject, hBrush
    skipDrawBall2:

        cmp powerActive, 1
        jne skipDrawPower
        invoke CreateSolidBrush, 00FF00FFh   
        mov hBrush, eax
        mov eax, powerX
        mov rc.left, eax
        mov eax, powerY
        mov rc.top, eax
        mov eax, powerX
        add eax, POWERUP_SIZE                
        mov rc.right, eax
        mov eax, powerY
        add eax, POWERUP_SIZE                   
        mov rc.bottom, eax
        invoke FillRect, hdc, ADDR rc, hBrush
        invoke DeleteObject, hBrush
    skipDrawPower:

        invoke SetBkMode, hdc, TRANSPARENT_BK 
        
        invoke SetTextColor, hdc, 00FFFFFFh   
        invoke TextOutA, hdc, 30, 15, ADDR scoreLabel, 7 
        invoke wsprintfA, ADDR scoreBuf, ADDR fmtStr, score 
        invoke TextOutA, hdc, 80, 15, ADDR scoreBuf, eax 

        invoke TextOutA, hdc, 140, 15, ADDR roundLabel, 7 
        invoke wsprintfA, ADDR roundBuf, ADDR fmtStr, currentRound 
        invoke TextOutA, hdc, 196, 15, ADDR roundBuf, eax 

        invoke SetTextColor, hdc, 0000FFFFh   
        invoke TextOutA, hdc, 260, 15, ADDR titleText, 13 

        invoke SetTextColor, hdc, 00FFFFFFh   
        invoke TextOutA, hdc, 450, 15, ADDR timeLabel, 6 
        invoke wsprintfA, ADDR timeBuf, ADDR fmtStr, timeSeconds 
        invoke TextOutA, hdc, 496, 15, ADDR timeBuf, eax 

        invoke TextOutA, hdc, 540, 15, ADDR livesLabel, 7 
        invoke wsprintfA, ADDR livesBuf, ADDR fmtStr, lives 
        invoke TextOutA, hdc, 596, 15, ADDR livesBuf, eax 

        cmp ballActive, 0                    
        jne skipStartMsg                     
        invoke SetTextColor, hdc, 00AAAAAAh  
        invoke TextOutA, hdc, 225, 300, ADDR startMsg, 26 
    skipStartMsg:
        jmp donePaint                        

    drawTitleScreen:
        invoke SetBkMode, hdc, TRANSPARENT_BK
        invoke SetTextColor, hdc, 0000FFFFh  
        invoke TextOutA, hdc, 220, 150, ADDR titleWelcomeMsg, 24
        invoke SetTextColor, hdc, 00FFFFFFh  
        invoke TextOutA, hdc, 220, 220, ADDR titlePlayMsg, 24
        invoke TextOutA, hdc, 220, 270, ADDR titleInstrMsg, 27
        invoke TextOutA, hdc, 220, 320, ADDR titleExitMsg, 22
        jmp donePaint

    drawInstructionScreen:
        invoke SetBkMode, hdc, TRANSPARENT_BK
        invoke SetTextColor, hdc, 0000FFFFh
        invoke TextOutA, hdc, 260, 100, ADDR instrTitleMsg, 12
        invoke SetTextColor, hdc, 00FFFFFFh
        invoke TextOutA, hdc, 180, 180, ADDR hint1Msg, 25
        invoke TextOutA, hdc, 180, 220, ADDR hint2Msg, 30
        invoke TextOutA, hdc, 180, 260, ADDR hint3Msg, 38
        invoke TextOutA, hdc, 220, 350, ADDR titlePlayMsg, 24
        jmp donePaint

    drawEndScreen:
        invoke SetBkMode, hdc, TRANSPARENT_BK
        invoke SetTextColor, hdc, 0000FFFFh   
        cmp gameState, 1
        jne lostState
        invoke TextOutA, hdc, 280, 100, ADDR winMsg, 8
        jmp drawStats
    lostState:
        invoke TextOutA, hdc, 280, 100, ADDR loseMsg, 9
    drawStats:
        invoke SetTextColor, hdc, 00FFFFFFh   
        invoke TextOutA, hdc, 200, 180, ADDR endScoresMsg, 18
        invoke wsprintfA, ADDR scoreBuf, ADDR fmtStr, score
        invoke TextOutA, hdc, 380, 180, ADDR scoreBuf, eax
        invoke TextOutA, hdc, 200, 220, ADDR endLivesMsg, 17
        invoke wsprintfA, ADDR livesBuf, ADDR fmtStr, lives
        invoke TextOutA, hdc, 380, 220, ADDR livesBuf, eax
        invoke TextOutA, hdc, 200, 300, ADDR endRestartMsg, 28
        invoke TextOutA, hdc, 200, 340, ADDR endQuitMsg, 20
        jmp donePaint

    donePaint:
        invoke BitBlt, screenDC, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, hdc, 0, 0, SRCCOPY
        invoke SelectObject, hdc, hOldBitmap
        invoke DeleteObject, hBitmap
        invoke DeleteDC, hdc
        invoke EndPaint, hWin, ADDR ps       
        xor eax, eax                         
        ret

    .ELSEIF eax == WM_CREATE
        invoke SetTimer, hWin, TIMER_ID, TIMER_INTERVAL, NULL 
        xor eax, eax                         
        ret

    .ELSEIF eax == WM_TIMER
        cmp gameState, 0                     
        jne skipTimeUpdate                   
        cmp ballActive, 1                    
        jne skipTimeUpdate                   
        inc timerTicks                       
        cmp timerTicks, 125                  
        jl skipTimeUpdate                    
        mov timerTicks, 0                    
        inc timeSeconds                      
    skipTimeUpdate:

        cmp solidBaseTimer, 0                
        jle skipSolidUpdate                  
        dec solidBaseTimer                   
    skipSolidUpdate:

        ; ==================================
        ; POWERUP GENERATOR
        ; ==================================
        cmp gameState, 0                     
        jne skipPowerSpawnCheck              
        cmp ballActive, 1                    
        jne skipPowerSpawnCheck              
        
        cmp timeSeconds, 5                   
        jl skipPowerSpawnCheck               
        cmp powerActive, 1                   
        je skipPowerSpawnCheck               
        
        ; [Lab 8: Bitwise AND] Masking value for randomness
        invoke GetTickCount
        mov edx, eax
        and edx, 255                         ; Bitwise AND to keep lower 8 bits (0-255)
        cmp edx, 50                          
        jne skipPowerSpawnCheck              
        
        mov powerActive, 1
        mov powerY, BORDER_TOP
        
        shr eax, 8                           ; [Lab 8: Bitwise Shift] Divide by 256
        xor edx, edx
        mov ebx, 480                         
        div ebx                              ; [Lab 9: Division] Generate X coordinate
        add edx, BORDER_LEFT + 20            
        mov powerX, edx
        
    skipPowerSpawnCheck:

        ; ==================================
        ; POWERUP MOVEMENT & COLLISION
        ; ==================================
        cmp powerActive, 1
        jne skipPowerUpdate
        mov eax, powerY
        add eax, powerSpeed
        mov powerY, eax

        ; [Lab 7: Conditional Structures]
        mov eax, powerY
        add eax, POWERUP_SIZE 
        cmp eax, PADDLE_Y
        jl checkPowerMissed                  ; Jump if Less (JL)
        cmp eax, PADDLE_Y + PADDLE_HEIGHT
        jg checkPowerMissed                  ; Jump if Greater (JG)
        
        mov eax, powerX
        add eax, POWERUP_SIZE
        cmp eax, paddleX
        jl checkPowerMissed
        mov eax, powerX
        mov ebx, paddleX
        add ebx, PADDLE_WIDTH
        cmp eax, ebx
        jg checkPowerMissed

        ; Caught powerup! Spawn Ball 2
        mov powerActive, 0
        mov ball2Active, 1
        
        mov eax, PADDLE_WIDTH
        shr eax, 1                           ; [Lab 8: Bitwise Shift] Divide width by 2 to find center
        add eax, paddleX
        mov ball2X, eax
        
        mov eax, PADDLE_Y
        sub eax, BALL_SIZE
        mov ball2Y, eax
        mov eax, ballDX
        neg eax
        mov ball2DX, eax
        mov ball2DY, -BALL_SPEED
        jmp skipPowerUpdate

    checkPowerMissed:
        mov eax, powerY
        cmp eax, BORDER_BOTTOM
        jl skipPowerUpdate
        mov powerActive, 0
    skipPowerUpdate:

        ; ==================================
        ; BALL 1 MOVEMENT & COLLISION
        ; ==================================
        cmp gameState, 0                     
        jne skipBallMove                     
        cmp ballActive, 0                    
        je skipBallMove                      

        mov eax, ballX                       
        add eax, ballDX                      
        mov ballX, eax                       
        mov eax, ballY                       
        add eax, ballDY                      
        mov ballY, eax                       

        mov eax, ballX                       
        cmp eax, BORDER_LEFT + BORDER_THICKNESS 
        jg noLeftBounce                      
        neg ballDX                           
        mov ballX, BORDER_LEFT + BORDER_THICKNESS 
    noLeftBounce:

        mov eax, ballX                       
        add eax, BALL_SIZE                   
        cmp eax, BORDER_RIGHT - BORDER_THICKNESS 
        jl noRightBounce                     
        neg ballDX                           
        mov eax, BORDER_RIGHT - BORDER_THICKNESS 
        sub eax, BALL_SIZE
        mov ballX, eax
    noRightBounce:

        mov eax, ballY                       
        cmp eax, BORDER_TOP + BORDER_THICKNESS 
        jg noTopBounce                       
        neg ballDY                           
        mov ballY, BORDER_TOP + BORDER_THICKNESS 
    noTopBounce:

        cmp solidBaseTimer, 0                
        jle noBottomBounce                   
        mov eax, ballY                       
        add eax, BALL_SIZE                   
        cmp eax, BORDER_BOTTOM               
        jl noBottomBounce                    
        neg ballDY                           
        mov eax, BORDER_BOTTOM               
        sub eax, BALL_SIZE
        mov ballY, eax
    noBottomBounce:

        xor ecx, ecx                         
    checkBrickLoop:
        cmp ecx, TOTAL_BRICKS                
        jge doneBrickCheck                   

        movzx eax, BYTE PTR [bricks + ecx]   
        cmp eax, 0                           
        je nextBrickCheck                    

        ; [Lab 9: Multiplication and Division]
        ; Calculate 2D Array Row and Column from 1D Index (ecx)
        push ecx                             
        mov eax, ecx                         
        xor edx, edx                         
        mov ebx, BRICK_COLS                  
        div ebx                              ; DIV instruction: EDX = Remainder (Col), EAX = Quotient (Row)
        push edx                             
        
        mov ebx, BRICK_HEIGHT + BRICK_GAP    
        imul eax, ebx                        ; Multiply Row by Height
        add eax, BRICK_START_Y               
        mov esi, eax                         ; ESI holds Y pos
        
        pop edx                              
        mov eax, edx                         
        mov ebx, BRICK_WIDTH + BRICK_GAP     
        imul eax, ebx                        ; Multiply Col by Width
        add eax, BRICK_START_X               
        mov edi, eax                         ; EDI holds X pos

        ; Collision bounding box check
        mov eax, ballX                       
        add eax, BALL_SIZE                   
        cmp eax, edi                         
        jle noBrickHit                       

        mov eax, ballX                       
        mov ebx, edi                         
        add ebx, BRICK_WIDTH                 
        cmp eax, ebx                         
        jge noBrickHit                       

        mov eax, ballY                       
        add eax, BALL_SIZE                   
        cmp eax, esi                         
        jle noBrickHit                       

        mov eax, ballY                       
        mov ebx, esi                         
        add ebx, BRICK_HEIGHT                
        cmp eax, ebx                         
        jge noBrickHit                       

        ; Brick is Hit!
        pop ecx                              
        mov BYTE PTR [bricks + ecx], 0       ; [Lab 3: Memory Write]
        neg ballDY                           
        add score, 10                        
        dec bricksLeft                       
        invoke Beep, 261, 20

        mov eax, ecx                         
        xor edx, edx                         
        mov ebx, BRICK_COLS                  
        div ebx                              
        cmp eax, 2                           
        jne noPowerup1                        
        mov solidBaseTimer, 300              
    noPowerup1:

        cmp bricksLeft, 0                    
        jg doneBrickCheck                    
        
        inc currentRound                     
        mov bricksLeft, TOTAL_BRICKS
        mov ballActive, 0
        mov ball2Active, 0
        mov powerActive, 0
        
        CALL ResetBricks                     ; [Lab 6: Call Procedure to use Stack operations]
        jmp doneBrickCheck                   

    noBrickHit:
        pop ecx                              
    nextBrickCheck:
        inc ecx                              
        jmp checkBrickLoop                   
    doneBrickCheck:

        mov eax, ballY                       
        add eax, BALL_SIZE                   
        cmp eax, PADDLE_Y                    
        jl noPaddleBounce                    
        cmp eax, PADDLE_Y + PADDLE_HEIGHT    
        jg ballFell                          
        mov eax, ballX                       
        add eax, BALL_SIZE                   
        cmp eax, paddleX                     
        jl ballFell                          
        mov eax, ballX                       
        mov ecx, paddleX                     
        add ecx, PADDLE_WIDTH                
        cmp eax, ecx                         
        jg ballFell                          
        
        neg ballDY                           
        
        mov eax, BALL_SIZE
        shr eax, 1                           ; [Lab 8: Bitwise] divide by 2
        add eax, ballX                       ; eax = ball center X
        
        mov ecx, PADDLE_WIDTH
        mov ebx, 3
        xor edx, edx
        push eax
        mov eax, ecx
        div ebx                              ; [Lab 9: Division] paddle_width / 3
        mov ecx, eax
        pop eax
        
        add ecx, paddleX                     ; Left third boundary
        cmp eax, ecx                         
        jg checkRightEdge                    
        mov ballDX, -BALL_SPEED              
        jmp donePaddleEdge
    checkRightEdge:
        mov ecx, PADDLE_WIDTH
        mov ebx, 3
        push eax
        mov eax, ecx
        div ebx                              
        shl eax, 1                           ; [Lab 8: Bitwise Shift] multiply by 2 to get Right third boundary
        mov ecx, eax
        pop eax
        add ecx, paddleX                     
        cmp eax, ecx                         
        jl donePaddleEdge                    
        mov ballDX, BALL_SPEED               
    donePaddleEdge:

        mov eax, PADDLE_Y                    
        sub eax, BALL_SIZE                   
        mov ballY, eax                       
        jmp noPaddleBounce                   

    ballFell:
        cmp solidBaseTimer, 0                
        jg noPaddleBounce                    
        
        dec lives                            
        cmp lives, 0                         
        jg stillAlive                        
        mov gameState, 2                     
        mov ballActive, 0                    
        mov ball2Active, 0
        jmp noPaddleBounce                   
    stillAlive:
        mov ballActive, 0                    
        mov ball2Active, 0                   
        
        mov eax, PADDLE_WIDTH
        shr eax, 1                           ; [Lab 8: Shift] center ball
        add eax, paddleX                     
        sub eax, BALL_SIZE / 2               
        mov ballX, eax                       
        
        mov eax, PADDLE_Y                    
        sub eax, BALL_SIZE                   
        mov ballY, eax                       

    noPaddleBounce:
    skipBallMove:


        ; ==================================
        ; BALL 2 MOVEMENT & COLLISION
        ; ==================================
        cmp ball2Active, 0
        je skipBall2Move

        mov eax, ball2X                       
        add eax, ball2DX                      
        mov ball2X, eax                       
        mov eax, ball2Y                       
        add eax, ball2DY                      
        mov ball2Y, eax                       

        mov eax, ball2X                       
        cmp eax, BORDER_LEFT + BORDER_THICKNESS 
        jg noLeftBounce2                      
        neg ball2DX                           
        mov ball2X, BORDER_LEFT + BORDER_THICKNESS 
    noLeftBounce2:

        mov eax, ball2X                       
        add eax, BALL_SIZE                   
        cmp eax, BORDER_RIGHT - BORDER_THICKNESS 
        jl noRightBounce2                     
        neg ball2DX                           
        mov eax, BORDER_RIGHT - BORDER_THICKNESS 
        sub eax, BALL_SIZE
        mov ball2X, eax
    noRightBounce2:

        mov eax, ball2Y                       
        cmp eax, BORDER_TOP + BORDER_THICKNESS 
        jg noTopBounce2                       
        neg ball2DY                           
        mov ball2Y, BORDER_TOP + BORDER_THICKNESS 
    noTopBounce2:

        cmp solidBaseTimer, 0                
        jle noBottomBounce2                   
        mov eax, ball2Y                       
        add eax, BALL_SIZE                   
        cmp eax, BORDER_BOTTOM               
        jl noBottomBounce2                    
        neg ball2DY                           
        mov eax, BORDER_BOTTOM               
        sub eax, BALL_SIZE
        mov ball2Y, eax
    noBottomBounce2:

        xor ecx, ecx                         
    checkBrickLoop2:
        cmp ecx, TOTAL_BRICKS                
        jge doneBrickCheck2                   

        movzx eax, BYTE PTR [bricks + ecx]   
        cmp eax, 0                           
        je nextBrickCheck2                    

        push ecx                             
        mov eax, ecx                         
        xor edx, edx                         
        mov ebx, BRICK_COLS                  
        div ebx                              
        push edx                             
        mov ebx, BRICK_HEIGHT + BRICK_GAP    
        imul eax, ebx                        
        add eax, BRICK_START_Y               
        mov esi, eax                         
        pop edx                              
        mov eax, edx                         
        mov ebx, BRICK_WIDTH + BRICK_GAP     
        imul eax, ebx                        
        add eax, BRICK_START_X               
        mov edi, eax                         

        mov eax, ball2X                       
        add eax, BALL_SIZE                   
        cmp eax, edi                         
        jle noBrickHit2                       

        mov eax, ball2X                       
        mov ebx, edi                         
        add ebx, BRICK_WIDTH                 
        cmp eax, ebx                         
        jge noBrickHit2                       

        mov eax, ball2Y                       
        add eax, BALL_SIZE                   
        cmp eax, esi                         
        jle noBrickHit2                       

        mov eax, ball2Y                       
        mov ebx, esi                         
        add ebx, BRICK_HEIGHT                
        cmp eax, ebx                         
        jge noBrickHit2                       

        pop ecx                              
        mov BYTE PTR [bricks + ecx], 0       
        neg ball2DY                           
        add score, 10                        
        dec bricksLeft                       
        invoke Beep, 261, 20

        mov eax, ecx                         
        xor edx, edx                         
        mov ebx, BRICK_COLS                  
        div ebx                              
        cmp eax, 2                           
        jne noPowerup2                        
        mov solidBaseTimer, 300              
    noPowerup2:

        cmp bricksLeft, 0                    
        jg doneBrickCheck2                    
        
        inc currentRound                     
        mov bricksLeft, TOTAL_BRICKS
        mov ballActive, 0
        mov ball2Active, 0
        mov powerActive, 0
        
        CALL ResetBricks                     ; [Lab 6: Procedure usage]
        jmp doneBrickCheck2                   

    noBrickHit2:
        pop ecx                              
    nextBrickCheck2:
        inc ecx                              
        jmp checkBrickLoop2                   
    doneBrickCheck2:

        mov eax, ball2Y                       
        add eax, BALL_SIZE                   
        cmp eax, PADDLE_Y                    
        jl noPaddleBounce2                    
        cmp eax, PADDLE_Y + PADDLE_HEIGHT    
        jg ball2Fell                          
        mov eax, ball2X                       
        add eax, BALL_SIZE                   
        cmp eax, paddleX                     
        jl ball2Fell                          
        mov eax, ball2X                       
        mov ecx, paddleX                     
        add ecx, PADDLE_WIDTH                
        cmp eax, ecx                         
        jg ball2Fell                          
        
        neg ball2DY                           
        
        mov eax, ball2X                       
        add eax, BALL_SIZE / 2               
        mov ecx, paddleX                     
        add ecx, PADDLE_WIDTH / 3            
        cmp eax, ecx                         
        jg checkRightEdge2                    
        mov ball2DX, -BALL_SPEED              
        jmp donePaddleEdge2
    checkRightEdge2:
        mov ecx, paddleX                     
        add ecx, (PADDLE_WIDTH * 2) / 3      
        cmp eax, ecx                         
        jl donePaddleEdge2                    
        mov ball2DX, BALL_SPEED               
    donePaddleEdge2:

        mov eax, PADDLE_Y                    
        sub eax, BALL_SIZE                   
        mov ball2Y, eax                       
        jmp noPaddleBounce2                   

    ball2Fell:
        cmp solidBaseTimer, 0                
        jg noPaddleBounce2                    
        mov ball2Active, 0                   
    noPaddleBounce2:
    skipBall2Move:

        cmp ballActive, 0                    
        jne skipTrack                        
        
        mov eax, PADDLE_WIDTH
        shr eax, 1                           ; [Lab 8: Shift right] Divide by 2
        add eax, paddleX                     
        sub eax, BALL_SIZE / 2               
        mov ballX, eax                       
        mov eax, PADDLE_Y                    
        sub eax, BALL_SIZE                   
        mov ballY, eax                       
    skipTrack:

        invoke InvalidateRect, hWin, NULL, FALSE 
        xor eax, eax                         
        ret

    .ELSEIF eax == WM_KEYDOWN
        mov eax, wParam                      

        .IF eax == VK_ESCAPE
            invoke PostQuitMessage, 0
            xor eax, eax
            ret
        .ENDIF

        cmp gameState, 3                     
        je titleInput
        cmp gameState, 4                     
        je instrInput
        cmp gameState, 1                     
        je endInput
        cmp gameState, 2                     
        je endInput

        .IF eax == VK_LEFT                   
            mov eax, paddleX                 
            sub eax, PADDLE_SPEED            
            cmp eax, BORDER_LEFT + BORDER_THICKNESS 
            jl doneKey                       
            mov paddleX, eax                 
        .ELSEIF eax == VK_RIGHT              
            mov eax, paddleX                 
            add eax, PADDLE_SPEED            
            add eax, PADDLE_WIDTH            
            cmp eax, BORDER_RIGHT - BORDER_THICKNESS 
            jg doneKey                       
            sub eax, PADDLE_WIDTH            
            mov paddleX, eax                 
        .ELSEIF eax == VK_SPACE              
            cmp ballActive, 0                
            jne doneKey                      
            mov ballActive, 1                
            mov ballDX, BALL_SPEED           
            mov eax, BALL_SPEED              
            neg eax                          
            mov ballDY, eax                  
        .ENDIF
        jmp doneKey

    titleInput:
        .IF eax == VK_RETURN                 
            mov gameState, 0                 
            mov ballActive, 1                
            mov ballDX, BALL_SPEED           
            mov eax, BALL_SPEED              
            neg eax                          
            mov ballDY, eax                  
        .ELSEIF eax == VK_I                  
            mov gameState, 4                 
        .ENDIF
        jmp doneKey

    instrInput:
        .IF eax == VK_RETURN                 
            mov gameState, 0                 
            mov ballActive, 1                
            mov ballDX, BALL_SPEED           
            mov eax, BALL_SPEED              
            neg eax                          
            mov ballDY, eax                  
        .ENDIF
        jmp doneKey

    endInput:
        .IF eax == VK_R                      
            mov gameState, 0                 
            mov score, 0                     
            mov lives, 3  
            mov currentRound, 1              
            mov timeSeconds, 0               
            mov timerTicks, 0                
            mov solidBaseTimer, 0            
            mov bricksLeft, TOTAL_BRICKS     
            mov paddleX, 280                 

            CALL ResetBricks                 ; [Lab 6: Calling Stack Procedure]

            mov ballActive, 1                
            mov ball2Active, 0               
            mov powerActive, 0               
            mov ballDX, BALL_SPEED           
            mov eax, BALL_SPEED              
            neg eax                          
            mov ballDY, eax                  
            
            mov eax, PADDLE_WIDTH
            shr eax, 1                       ; [Lab 8: Bitwise Shift]
            add eax, paddleX                 
            sub eax, BALL_SIZE / 2           
            mov ballX, eax                   
            mov eax, PADDLE_Y                
            sub eax, BALL_SIZE               
            mov ballY, eax                   
        .ELSEIF eax == VK_Q                  
            invoke PostQuitMessage, 0
        .ENDIF
        jmp doneKey

    doneKey:
        xor eax, eax                         
        ret

    .ELSEIF eax == WM_DESTROY
        invoke KillTimer, hWin, TIMER_ID     
        invoke PostQuitMessage, 0            
        xor eax, eax                         
        ret
    .ENDIF

    invoke DefWindowProcA, hWin, uMsg, wParam, lParam
    ret
WndProc ENDP

main PROC
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG

    invoke GetModuleHandleA, NULL
    mov hInstance, eax

    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, OFFSET WndProc
    mov wc.cbClsExtra, 0
    mov wc.cbWndExtra, 0
    mov eax, hInstance
    mov wc.hInstance, eax
    invoke LoadIconA, NULL, IDI_APPLICATION
    mov wc.hIcon, eax
    mov wc.hIconSm, eax
    invoke LoadCursorA, NULL, IDC_ARROW
    mov wc.hCursor, eax
    invoke GetStockObject, 4                 
    mov wc.hbrBackground, eax
    mov wc.lpszMenuName, NULL
    mov wc.lpszClassName, OFFSET className

    invoke RegisterClassExA, ADDR wc

    invoke CreateWindowExA, 0, \
           ADDR className, ADDR windowTitle, \
           WS_VISIBLE or WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, \
           CW_USEDEFAULT, CW_USEDEFAULT, \
           WINDOW_WIDTH, WINDOW_HEIGHT, \
           NULL, NULL, hInstance, NULL
    mov hwndMain, eax

    invoke ShowWindow, hwndMain, SW_SHOW
    invoke UpdateWindow, hwndMain

    msgLoop:
        invoke GetMessageA, ADDR msg, NULL, 0, 0
        cmp eax, 0
        je exitLoop
        invoke TranslateMessage, ADDR msg
        invoke DispatchMessageA, ADDR msg
        jmp msgLoop

    exitLoop:
    invoke ExitProcess, 0
main ENDP

END main