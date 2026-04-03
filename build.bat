@echo off
REM build.bat - Build Brick Breaker (Win32 GUI)
SET PATH=C:\Masm615
SET INCLUDE=C:\Masm615\INCLUDE
SET LIB=C:\Masm615\LIB

ML -Zi -c -Fl -coff %1.asm
if errorlevel 1 goto terminate

LINK32 %1.obj kernel32.lib user32.lib gdi32.lib /SUBSYSTEM:WINDOWS /DEBUG
if errorlevel 1 goto terminate

dir %1.*

:terminate
pause
