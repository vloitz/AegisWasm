@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>nul

cd /d "%~dp0..\.."

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

if not exist ".git" (
    echo   !C_RE![X]!C_RS! No hay repositorio Git. Ejecuta: !C_WH!init.cmd!C_RS!
    exit /b 1
)

git add -A >nul 2>nul
git diff --cached --quiet
if not errorlevel 1 (
    echo   !C_GY!Sin cambios para guardar.!C_RS!
    exit /b 0
)

echo.
echo   !C_CY!------------------------------------------------------------!C_RS!
echo   !C_BC! GUARDAR!C_RS! !C_GY!- Commit local!C_RS!
echo   !C_CY!------------------------------------------------------------!C_RS!
echo.
echo   !C_GY!Archivos a guardar:!C_RS!
git diff --cached --name-only | findstr /n "^"
echo.
echo   !C_GY!Evita usar: " # : + / , en el mensaje!C_RS!
echo.
echo   !C_BC!Mensaje del commit!C_RS! !C_GY![Enter = Sin definir]!C_RS!
set "MSG="
set /p MSG=
if "!MSG!"=="" set "MSG=Sin definir"

git commit -q -m "!MSG!"
if errorlevel 1 (
    echo.
    echo   !C_RE![X]!C_RS! Commit fallo. Revisa el mensaje.
    exit /b 1
)
echo.
echo   !C_GR![OK]!C_RS! Commit: !C_WH!!MSG!!C_RS!
echo.

if "%SKIP_HISTORIAL%"=="1" goto :skip_hist
set "NO_PAUSE=1"
call "%~dp0historial.cmd"
set "NO_PAUSE="
:skip_hist

call :shell_if_double_click
endlocal
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