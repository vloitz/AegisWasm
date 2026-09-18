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

echo.
echo   !C_CY!============================================!C_RS!
echo   !C_BC! SUBIR!C_RS! !C_GY!- Push a GitHub!C_RS!
echo   !C_CY!============================================!C_RS!
echo.

if not exist ".git" (
    echo   !C_RE![X]!C_RS! No hay repositorio Git. Ejecuta: !C_WH!init.cmd!C_RS!
    call :shell_if_double_click
    exit /b 1
)

git diff --cached --quiet
set "STAGED=!ERRORLEVEL!"
git diff --quiet
set "UNSTAGED=!ERRORLEVEL!"

if !STAGED! NEQ 0 goto :has_changes
if !UNSTAGED! NEQ 0 goto :has_changes
goto :check_remote

:has_changes
echo   !C_YE![!]!C_RS! Hay cambios sin commitear.
echo.
set "SAVE="
set /p "SAVE=  !C_BC!Guardar cambios primero?!C_RS! !C_GY![S/n]!C_RS!: "
if /i "!SAVE!"=="n" goto :check_remote
echo.
set "SKIP_HISTORIAL=1"
set "NO_PAUSE=1"
call "%~dp0save.cmd"
set "SKIP_HISTORIAL="
set "NO_PAUSE="
echo.

:check_remote
git remote get-url origin >nul 2>nul
if errorlevel 1 (
    echo   !C_RE![X]!C_RS! No hay remote 'origin' configurado.
    echo.
    echo   !C_GY!Para vincular tu repo a GitHub:!C_RS!
    echo.
    echo     !C_WH!git remote add origin https://github.com/TU-USUARIO/TU-REPO.git!C_RS!
    echo.
    call :shell_if_double_click
    exit /b 1
)

echo   !C_GY!Subiendo a GitHub...!C_RS!
echo.

git push -u origin main --follow-tags
set "RC=!ERRORLEVEL!"

echo.
if !RC! EQU 0 (
    echo   !C_GR![OK]!C_RS! Push completado
) else (
    echo   !C_RE![ERROR]!C_RS! Push fallo con codigo !RC!
)
echo.

set "NO_PAUSE=1"
call "%~dp0historial.cmd"
set "NO_PAUSE="

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