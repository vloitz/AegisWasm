@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>nul

cd /d "%~dp0..\.."

REM --- Colores ANSI (con fallback) ---
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
if "!ESC!"=="" (
    set "C_CY=" & set "C_BC=" & set "C_GR=" & set "C_YE="
    set "C_RE=" & set "C_GY=" & set "C_WH=" & set "C_RS="
) else (
    set "C_CY=!ESC![36m"  & set "C_BC=!ESC![96m"
    set "C_GR=!ESC![32m"  & set "C_YE=!ESC![33m"
    set "C_RE=!ESC![31m"  & set "C_GY=!ESC![90m"
    set "C_WH=!ESC![97m"  & set "C_RS=!ESC![0m"
)

where code >nul 2>nul
if errorlevel 1 (
    echo.
    echo   !C_RE![X]!C_RS! VS Code CLI no esta en el PATH.
    echo.
    echo   !C_GY!Instala:!C_RS!
    echo      !C_WH!1.!C_RS! Abre VS Code
    echo      !C_WH!2.!C_RS! Ctrl+Shift+P
    echo      !C_WH!3.!C_RS! "Shell Command: Install 'code' command in PATH"
    echo.
    call :shell_if_double_click
    exit /b 1
)

if "%~1"=="" (
    echo   !C_GY!Abriendo proyecto en VS Code...!C_RS!
    code .
) else (
    echo   !C_GY!Abriendo en VS Code:!C_RS! !C_WH!%*!C_RS!
    code %*
)

exit /b 0

:shell_if_double_click
if "%NO_PAUSE%"=="1" goto :eof
echo %cmdcmdline% | find /i "%~nx0" >nul
if errorlevel 1 goto :eof
echo.
echo   !C_GY!Sesion interactiva. Escribe 'exit' para cerrar.!C_RS!
echo.
cmd /k
goto :eof