TITLE Brick Breaker Game (Brick_Breaker.asm)
; A simple Brick Breaker game with Windows GUI
; Uses Win32 API for window and GDI for drawing

.386
.model flat, stdcall
option casemap:none

; ============================================
; Constants
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
TRANSPARENT_BK      EQU 1
WINDOW_WIDTH        EQU 640
WINDOW_HEIGHT       EQU 500

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
; kernel32
GetModuleHandleA PROTO :DWORD
ExitProcess PROTO :DWORD

; user32
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

; gdi32
CreateSolidBrush PROTO :DWORD
DeleteObject PROTO :DWORD
SetBkMode PROTO :DWORD,:DWORD
SetTextColor PROTO :DWORD,:DWORD
TextOutA PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD

; ============================================
; Data
; ============================================
.data
className       BYTE "BrickBreakerWnd", 0
windowTitle     BYTE "Brick Breaker", 0
titleText       BYTE "BRICK BREAKER", 0
hInstance       DWORD 0
hwndMain        DWORD 0

; ============================================
; Code
; ============================================
.code

; --------------------------------------------
; Window Procedure
; --------------------------------------------
WndProc PROC hWin:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    LOCAL ps:PAINTSTRUCT
    LOCAL hdc:DWORD
    LOCAL rc:RECT
    LOCAL hBrush:DWORD

    mov eax, uMsg

    .IF eax == WM_PAINT
        invoke BeginPaint, hWin, ADDR ps
        mov hdc, eax

        ; dark background
        invoke GetClientRect, hWin, ADDR rc
        invoke CreateSolidBrush, 00400000h
        mov hBrush, eax
        invoke FillRect, hdc, ADDR rc, hBrush
        invoke DeleteObject, hBrush

        ; title text
        invoke SetBkMode, hdc, TRANSPARENT_BK
        invoke SetTextColor, hdc, 0000FFFFh
        invoke TextOutA, hdc, 250, 220, ADDR titleText, 13

        invoke EndPaint, hWin, ADDR ps
        xor eax, eax
        ret

    .ELSEIF eax == WM_DESTROY
        invoke PostQuitMessage, 0
        xor eax, eax
        ret
    .ENDIF

    invoke DefWindowProcA, hWin, uMsg, wParam, lParam
    ret
WndProc ENDP

; --------------------------------------------
; Main Entry Point
; --------------------------------------------
main PROC
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG

    invoke GetModuleHandleA, NULL
    mov hInstance, eax

    ; setup window class
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
    mov wc.hbrBackground, NULL
    mov wc.lpszMenuName, NULL
    mov wc.lpszClassName, OFFSET className

    invoke RegisterClassExA, ADDR wc

    ; create the game window
    invoke CreateWindowExA, 0, \
           ADDR className, ADDR windowTitle, \
           WS_VISIBLE or WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, \
           CW_USEDEFAULT, CW_USEDEFAULT, \
           WINDOW_WIDTH, WINDOW_HEIGHT, \
           NULL, NULL, hInstance, NULL
    mov hwndMain, eax

    invoke ShowWindow, hwndMain, SW_SHOW
    invoke UpdateWindow, hwndMain

    ; message loop
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