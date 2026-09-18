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

REM --- Args ---
if /i "%~1"=="ayuda"  goto :ayuda
if /i "%~1"=="--help" goto :ayuda
if /i "%~1"=="-h"     goto :ayuda
if /i "%~1"=="listar" goto :listar
if /i "%~1"=="crear"  goto :crear
if /i "%~1"=="volver" goto :volver_arg
goto :menu

REM ============================================================
REM   MENU PRINCIPAL
REM ============================================================
:menu
echo.
echo   !C_CY!============================================!C_RS!
echo   !C_BC! SNAPSHOTS!C_RS! !C_GY!- Copias de seguridad!C_RS!
echo   !C_CY!============================================!C_RS!
echo.
echo   !C_GY!Un snapshot es una copia completa del proyecto.!C_RS!
echo   !C_GY!Sirve para volver atras si algo se rompe.!C_RS!
echo.

call :count
if !SNAP_COUNT! EQU 0 (
    echo   !C_GY!No hay snapshots todavia.!C_RS!
) else (
    echo   !C_CY!.!C_RS! !C_GY!Snapshots disponibles:!C_RS! !C_WH!!SNAP_COUNT!!C_RS!
    echo.
    call :list_short
)
echo.

echo   !C_CY!------------------------------------------------------------!C_RS!
echo   !C_BC! QUE QUIERES HACER?!C_RS!
echo   !C_CY!------------------------------------------------------------!C_RS!
echo   !C_YE![c]!C_RS! Crear snapshot
if !SNAP_COUNT! GTR 0 (
    echo   !C_YE![v]!C_RS! Volver a un snapshot
)
echo   !C_YE![l]!C_RS! Listar con detalles
echo   !C_YE![Enter]!C_RS! Salir
echo   !C_CY!------------------------------------------------------------!C_RS!
echo.

set "ACTION="
set /p "ACTION=  !C_BC!Opcion!C_RS!: "

if /i "!ACTION!"=="c" goto :crear
if /i "!ACTION!"=="v" goto :volver_prompt
if /i "!ACTION!"=="l" goto :listar
goto :end

REM ============================================================
REM   CREAR SNAPSHOT
REM ============================================================
:crear
echo.
echo   !C_CY!------------------------------------------------------------!C_RS!
echo   !C_BC! CREAR SNAPSHOT!C_RS!
echo   !C_CY!------------------------------------------------------------!C_RS!
echo.
echo   !C_GY!Copia todo el proyecto en versiones\!C_RS!
echo   !C_GY!Excluye: .git, versiones, node_modules, audits, etc.!C_RS!
echo.

set "SNAP_NAME="
set /p "SNAP_NAME=  !C_BC!Nombre!C_RS! !C_GY![Enter=Sin definir]!C_RS!: "
if "!SNAP_NAME!"=="" set "SNAP_NAME=Sin definir"

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HHmmss"') do set "TS=%%i"
set "DEST=versiones\!TS!_!SNAP_NAME!"

if not exist "versiones" mkdir "versiones"
if not exist "!DEST!" mkdir "!DEST!"

echo.
echo   !C_GY!Copiando archivos...!C_RS!
robocopy "." "!DEST!" /E /XD .git versiones old_versions backup backups node_modules __pycache__ venv .venv env dist build out cache .cache .parcel-cache .vite .vscode .idea audits /XF *.log *.tmp *.bak *.orig Thumbs.db .DS_Store /NFL /NDL /NJH /NJS /NC /NS /NP >nul
set "RC=!ERRORLEVEL!"

echo.
if !RC! GEQ 8 (
    echo   !C_RE![X]!C_RS! Robocopy fallo con codigo !RC!
    goto :end
)

set "FCOUNT=0"
for /f %%c in ('dir /b /s "!DEST!" 2^>nul ^| find /c /v ""') do set "FCOUNT=%%c"

echo   !C_GR![OK]!C_RS! Snapshot creado
echo.
echo       !C_GY!Ubicacion:!C_RS!  !C_WH!!DEST!!C_RS!
echo       !C_GY!Archivos:!C_RS!   !C_WH!!FCOUNT!!C_RS!
echo.

goto :end

REM ============================================================
REM   LISTAR (short, para menu)
REM ============================================================
:list_short
set "IDX=0"
for /f "delims=" %%D in ('dir /b /o-n "versiones" 2^>nul') do (
    if !IDX! LSS 3 (
        echo       !C_YE![!IDX!]!C_RS! !C_WH!%%D!C_RS!
    )
    set /a IDX+=1
)
if !IDX! GTR 3 (
    echo       !C_GY!... y !IDX! mas en total!C_RS!
)
goto :eof

REM ============================================================
REM   LISTAR (full)
REM ============================================================
:listar
call :count
if !SNAP_COUNT! EQU 0 (
    echo.
    echo   !C_GY!No hay snapshots. Crea uno con:!C_RS! !C_WH!snapshots.cmd crear!C_RS!
    goto :end
)

echo.
echo   !C_CY!-------------------------------------------------------------!C_RS!
echo   !C_BC! SNAPSHOTS DISPONIBLES!C_RS!
echo   !C_CY!-------------------------------------------------------------!C_RS!
echo   !C_GY! IDX   NOMBRE                                       ARCHIVOS!C_RS!
echo   !C_CY!-------------------------------------------------------------!C_RS!

set "IDX=0"
for /f "delims=" %%D in ('dir /b /o-n "versiones" 2^>nul') do (
    set "S_!IDX!=%%D"
    set "FC=0"
    for /f %%c in ('dir /b /s "versiones\%%D" 2^>nul ^| find /c /v ""') do set "FC=%%c"
    echo   !C_YE![!IDX!]!C_RS!  !C_WH!%%D!C_RS!  !C_GY!(!FC! archivos)!C_RS!
    set /a IDX+=1
)

echo   !C_CY!-------------------------------------------------------------!C_RS!
echo   !C_GY!Total: !SNAP_COUNT! snapshots!C_RS!
echo.
goto :end

REM ============================================================
REM   VOLVER (prompt)
REM ============================================================
:volver_prompt
call :count
if !SNAP_COUNT! EQU 0 (
    echo   !C_RE![X]!C_RS! No hay snapshots.
    goto :end
)

call :listar_body

set "RESTORE_IDX="
set /p "RESTORE_IDX=  !C_BC!Indice a restaurar!C_RS! !C_GY![0-!SNAP_COUNT!-1]!C_RS!: "
if "!RESTORE_IDX!"=="" goto :end

call :do_restore "!RESTORE_IDX!"
goto :end

:volver_arg
if "%~2"=="" (
    echo   !C_RE![X]!C_RS! Falta el indice.
    echo   !C_GY!Uso: snapshots.cmd volver <indice>!C_RS!
    goto :end
)
call :listar_body
call :do_restore "%~2"
goto :end

REM Cuerpo compartido de listado
:listar_body
echo.
echo   !C_CY!-------------------------------------------------------------!C_RS!
echo   !C_BC! SNAPSHOTS DISPONIBLES!C_RS!
echo   !C_CY!-------------------------------------------------------------!C_RS!
set "IDX=0"
for /f "delims=" %%D in ('dir /b /o-n "versiones" 2^>nul') do (
    set "S_!IDX!=%%D"
    echo   !C_YE![!IDX!]!C_RS!  !C_WH!%%D!C_RS!
    set /a IDX+=1
)
echo   !C_CY!-------------------------------------------------------------!C_RS!
echo.
goto :eof

REM ============================================================
REM   DO RESTORE
REM ============================================================
:do_restore
set "TARGET=%~1"
set "SNAP_NAME=!S_%TARGET%!"

if "!SNAP_NAME!"=="" (
    echo   !C_RE![X]!C_RS! Indice !TARGET! no existe.
    goto :eof
)

set "SNAP_PATH=versiones\!SNAP_NAME!"
if not exist "!SNAP_PATH!" (
    echo   !C_RE![X]!C_RS! Snapshot no encontrado: !SNAP_PATH!
    goto :eof
)

echo   !C_CY!------------------------------------------------------------!C_RS!
echo   !C_BC! CONFIRMAR RESTAURACION!C_RS!
echo   !C_CY!------------------------------------------------------------!C_RS!
echo.
echo       !C_GY!Snapshot:!C_RS!  !C_WH!!SNAP_NAME!!C_RS!
echo       !C_GY!Modo:!C_RS!      !C_WH!overlay (no borra archivos)!C_RS!
echo.
echo   !C_GY!Se creara un backup automatico antes de restaurar.!C_RS!
echo   !C_YE!ATENCION: los cambios actuales pueden perderse.!C_RS!
echo.

set "CONFIRM="
set /p "CONFIRM=  !C_BC!Escribe SI para confirmar!C_RS!: "
if /i not "!CONFIRM!"=="SI" (
    echo   !C_GY!Cancelado.!C_RS!
    goto :eof
)

REM --- Backup pre-restore ---
echo.
echo   !C_GY!Creando backup de seguridad...!C_RS!
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HHmmss"') do set "TS=%%i"
set "PREBK=versiones\!TS!_pre-restore"

if not exist "!PREBK!" mkdir "!PREBK!"
robocopy "." "!PREBK!" /E /XD .git versiones old_versions backup backups node_modules __pycache__ venv .venv env dist build out cache .cache .parcel-cache .vite .vscode .idea audits /XF *.log *.tmp *.bak *.orig Thumbs.db .DS_Store /NFL /NDL /NJH /NJS /NC /NS /NP >nul
echo   !C_GR![OK]!C_RS! Backup: !C_WH!!PREBK!!C_RS!
echo.

REM --- Restore ---
echo   !C_GY!Restaurando archivos...!C_RS!
robocopy "!SNAP_PATH!" "." /E /XD .git versiones audits /XF *.log *.tmp /NFL /NDL /NJH /NJS /NC /NS /NP >nul
set "RC=!ERRORLEVEL!"

echo.
if !RC! GEQ 8 (
    echo   !C_RE![X]!C_RS! Restauracion fallo con codigo !RC!
    echo   !C_GY!Puedes volver al estado previo con:!C_RS! !C_WH!snapshots.cmd volver!C_RS!
    goto :eof
)

echo   !C_GR![OK]!C_RS! Snapshot restaurado.
echo.
echo   !C_GY!Si algo salio mal, tu estado previo esta en:!C_RS!
echo       !C_WH!!PREBK!!C_RS!
echo.
goto :eof

REM ============================================================
REM   CONTAR
REM ============================================================
:count
set "SNAP_COUNT=0"
if exist "versiones" (
    for /f %%c in ('dir /b /ad "versiones" 2^>nul ^| find /c /v ""') do set "SNAP_COUNT=%%c"
)
goto :eof

REM ============================================================
REM   AYUDA
REM ============================================================
:ayuda
echo.
echo   !C_CY!============================================!C_RS!
echo   !C_BC! SNAPSHOTS!C_RS! !C_GY!- Ayuda!C_RS!
echo   !C_CY!============================================!C_RS!
echo.
echo   !C_BC!USO:!C_RS!
echo     !C_WH!snapshots.cmd!C_RS!               Menu interactivo
echo     !C_WH!snapshots.cmd crear!C_RS!         Crear snapshot
echo     !C_WH!snapshots.cmd listar!C_RS!        Listar snapshots
echo     !C_WH!snapshots.cmd volver <idx>!C_RS!  Restaurar por indice
echo     !C_WH!snapshots.cmd --help!C_RS!        Esta ayuda
echo.
echo   !C_BC!FLUJO TIPICO:!C_RS!
echo     !C_GY!1. Antes de un cambio riesgoso:!C_RS!
echo          !C_WH!snapshots.cmd crear!C_RS!   !C_GY!(nombre: antes de refactor)!C_RS!
echo     !C_GY!2. Haces los cambios...!C_RS!
echo     !C_GY!3. Si algo se rompe:!C_RS!
echo          !C_WH!snapshots.cmd volver 0!C_RS!
echo.
echo   !C_BC!SEGURIDAD:!C_RS!
echo     !C_GY!- Preview antes de restaurar!C_RS!
echo     !C_GY!- Confirmacion con "SI" mayusculas!C_RS!
echo     !C_GY!- Backup automatico pre-restore!C_RS!
echo     !C_GY!- Modo overlay (no borra archivos)^^!C_RS!
echo.
goto :end

:end
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