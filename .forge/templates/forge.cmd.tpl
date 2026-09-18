@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>nul

cd /d "%~dp0"

REM --- Colores ANSI ---
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

set "CMD_DIR=.forge\commands"

REM --- Verificar instalacion ---
if not exist "%CMD_DIR%\save.cmd" (
    echo.
    echo   !C_RE![X]!C_RS! forgeGit no esta instalado aqui.
    echo   !C_GY!Ejecuta desde un proyecto nuevo:!C_RS! forge
    echo.
    pause
    exit /b 1
)

REM --- Modo CLI directo ---
if not "%~1"=="" (
    if /i "%~1"=="save"   ( call "%CMD_DIR%\save.cmd"      & exit /b 0 )
    if /i "%~1"=="push"   ( call "%CMD_DIR%\push.cmd"      & exit /b 0 )
    if /i "%~1"=="snap"   ( call "%CMD_DIR%\snapshots.cmd" & exit /b 0 )
    if /i "%~1"=="log"    ( call "%CMD_DIR%\historial.cmd" & exit /b 0 )
    if /i "%~1"=="audit"  ( call "%CMD_DIR%\auditar.cmd"   & exit /b 0 )
    if /i "%~1"=="open"   ( call "%CMD_DIR%\abrir.cmd"     & exit /b 0 )
    if /i "%~1"=="serve"  ( call "%CMD_DIR%\serve.cmd"     & exit /b 0 )
    if /i "%~1"=="help"    goto :help
    if /i "%~1"=="-h"      goto :help
    if /i "%~1"=="--help"  goto :help
    if /i "%~1"=="version" goto :version
    if /i "%~1"=="--version" goto :version
    echo   !C_RE![X]!C_RS! Comando desconocido: %~1
    echo   !C_GY!Usa: forge help!C_RS!
    exit /b 1
)

REM ============================================================
REM   MENU PRINCIPAL
REM ============================================================
:menu
cls
echo.
echo   !C_CY!============================================!C_RS!
echo   !C_BC! forgeGit!C_RS! !C_GY!- Menu!C_RS!
echo   !C_CY!============================================!C_RS!
echo.
echo   !C_BC!Trabajo diario:!C_RS!
echo     !C_YE![1]!C_RS! Guardar cambios      !C_GY!(commit)!C_RS!
echo     !C_YE![2]!C_RS! Subir a GitHub       !C_GY!(push)!C_RS!
echo     !C_YE![3]!C_RS! Historial            !C_GY!(ver commits)!C_RS!
echo.
echo   !C_BC!Herramientas:!C_RS!
echo     !C_YE![4]!C_RS! Snapshots            !C_GY!(backup/restore)!C_RS!
echo     !C_YE![5]!C_RS! Auditar cambios      !C_GY!(diff report)!C_RS!
echo     !C_YE![6]!C_RS! Abrir en VS Code
echo     !C_YE![7]!C_RS! Servidor dev         !C_GY!(auto-detect)!C_RS!
echo.
echo   !C_BC!Sistema:!C_RS!
echo     !C_YE![0]!C_RS! Salir
echo.
echo   !C_CY!--------------------------------------------!C_RS!
echo.

set "OPT="
set /p "OPT=  !C_BC!Opcion!C_RS!: "

if "!OPT!"=="1" ( call "%CMD_DIR%\save.cmd"      & echo. & pause & goto :menu )
if "!OPT!"=="2" ( call "%CMD_DIR%\push.cmd"      & echo. & pause & goto :menu )
if "!OPT!"=="3" ( call "%CMD_DIR%\historial.cmd" & echo. & pause & goto :menu )
if "!OPT!"=="4" ( call "%CMD_DIR%\snapshots.cmd" & echo. & pause & goto :menu )
if "!OPT!"=="5" ( call "%CMD_DIR%\auditar.cmd"   & echo. & pause & goto :menu )
if "!OPT!"=="6" ( call "%CMD_DIR%\abrir.cmd"     & echo. & pause & goto :menu )
if "!OPT!"=="7" ( call "%CMD_DIR%\serve.cmd"     & echo. & pause & goto :menu )
if "!OPT!"=="0" goto :end
if /i "!OPT!"=="q" goto :end

goto :menu

REM ============================================================
REM   VERSION
REM ============================================================
:version
powershell -NoProfile -Command "$c = Get-Content -LiteralPath '%~dp0.forge\config.cmd' -Raw -ErrorAction SilentlyContinue; if ($c -match 'FG_VERSION=([\d\.]+)') { Write-Host $Matches[1] } else { Write-Host 'unknown' }"
goto :end

REM ============================================================
REM   HELP
REM ============================================================
:help
echo.
echo   !C_CY!============================================!C_RS!
echo   !C_BC! forgeGit!C_RS! !C_GY!- Ayuda!C_RS!
echo   !C_CY!============================================!C_RS!
echo.
echo   !C_BC!USO:!C_RS!
echo     !C_WH!forge!C_RS!              Menu interactivo
echo     !C_WH!forge save!C_RS!         Guardar cambios
echo     !C_WH!forge push!C_RS!         Subir a GitHub
echo     !C_WH!forge snap!C_RS!         Snapshots
echo     !C_WH!forge log!C_RS!          Historial
echo     !C_WH!forge audit!C_RS!        Auditar cambios
echo     !C_WH!forge open!C_RS!         Abrir en VS Code
echo     !C_WH!forge serve!C_RS!        Servidor de desarrollo
echo     !C_WH!forge version!C_RS!      Muestra la version
echo     !C_WH!forge help!C_RS!         Esta ayuda
echo.
goto :end

:end
endlocal
exit /b 0