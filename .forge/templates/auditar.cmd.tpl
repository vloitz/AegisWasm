@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>nul

cd /d "%~dp0..\.."

REM --- Detectar soporte ANSI (Windows 10+ / Windows Terminal) ---
set "ANSI=1"
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"

REM --- Fallback si no hay soporte ANSI ---
if "!ESC!"=="" set "ANSI=0"

if "!ANSI!"=="1" (
    set "C_CYAN=!ESC![36m"
    set "C_BCYAN=!ESC![96m"
    set "C_GREEN=!ESC![32m"
    set "C_YELLOW=!ESC![33m"
    set "C_RED=!ESC![31m"
    set "C_GRAY=!ESC![90m"
    set "C_DIM=!ESC![2m"
    set "C_WHITE=!ESC![97m"
    set "C_RESET=!ESC![0m"
) else (
    set "C_CYAN="
    set "C_BCYAN="
    set "C_GREEN="
    set "C_YELLOW="
    set "C_RED="
    set "C_GRAY="
    set "C_DIM="
    set "C_WHITE="
    set "C_RESET="
)

REM --- Help flag ---
if /i "%~1"=="--help" goto :help
if /i "%~1"=="-h"     goto :help
if /i "%~1"=="help"   goto :help

if not exist ".git" (
    echo   !C_RED![X]!C_RESET! No hay repositorio Git. Ejecuta: init.cmd
    exit /b 1
)

REM --- Banner ---
echo.
echo   !C_CYAN!============================================!C_RESET!
echo   !C_BCYAN! AUDITAR!C_RESET! !C_GRAY!- Reportes de cambios!C_RESET!
echo   !C_CYAN!============================================!C_RESET!
echo.
echo   !C_GRAY!Genera un .txt con los cambios entre dos puntos del!C_RESET!
echo   !C_GRAY!historial. Ideal para auditar con IA o revisar un rango.!C_RESET!
echo.

REM --- 1. Estado actual ---
for /f "tokens=*" %%b in ('git branch --show-current 2^>nul') do set "BRANCH=%%b"

echo   !C_CYAN!â—!C_RESET! !C_GRAY!Branch:!C_RESET!   !C_WHITE!!BRANCH!!C_RESET!

git add -A >nul 2>nul
git diff --cached --quiet
if errorlevel 1 (
    set "NCH=0"
    for /f %%c in ('git diff --cached --name-only ^| find /c /v ""') do set "NCH=%%c"
    echo   !C_CYAN!â—!C_RESET! !C_GRAY!Cambios:!C_RESET!  !C_YELLOW!!NCH! archivos sin commitear!C_RESET!
) else (
    echo   !C_CYAN!â—!C_RESET! !C_GRAY!Cambios:!C_RESET!  !C_GREEN!limpio!C_RESET!
)
echo.

REM --- 2. Cuantos commits listar ---
set "LIMIT=10"
set "INPUT="
set /p "INPUT=  !C_BCYAN!Cuantos commits listar?!C_RESET! !C_GRAY![10 por defecto, T=todos]!C_RESET!: "
if /i "!INPUT!"=="T" (
    set "LIMIT=9999"
) else if not "!INPUT!"=="" (
    set "LIMIT=!INPUT!"
)

REM --- 3. Log a temp ---
set "TMPLOG=%TEMP%\forge_git_log.txt"
git log -n !LIMIT! --date=format:"%%Y-%%m-%%d %%H:%%M:%%S" --pretty=format:"%%h %%ad %%s" > "!TMPLOG!" 2>nul

REM --- 4. Tabla con separadores ---
echo.
echo   !C_CYAN!-------------------------------------------------------------!C_RESET!
echo   !C_BCYAN! HISTORIAL!C_RESET!
echo   !C_CYAN!-------------------------------------------------------------!C_RESET!
echo   !C_GRAY! IDX    FECHA                 HASH      MENSAJE!C_RESET!
echo   !C_CYAN!-------------------------------------------------------------!C_RESET!

set "IDX=0"
set "FIRST=1"
for /f "delims=" %%L in ('type "!TMPLOG!"') do (
    if "!FIRST!"=="0" (
        echo   !C_DIM!!C_GRAY!  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .!C_RESET!
    )
    set "LINE=%%L"
    set "HASH=!LINE:~0,7!"
    set "DATETIME=!LINE:~8,19!"
    set "MSG=!LINE:~28!"
    set "H_!IDX!=!HASH!"
    echo   !C_BCYAN![!IDX!]!C_RESET! !C_GRAY!!DATETIME!!C_RESET!  !C_YELLOW!!HASH!!C_RESET!  !C_WHITE!!MSG!!C_RESET!
    set /a IDX=IDX+1
    set "FIRST=0"
)
del "!TMPLOG!" >nul 2>nul

if !IDX! EQU 0 (
    echo   !C_RED![X]!C_RESET! No hay commits.
    goto :end
)

echo   !C_CYAN!-------------------------------------------------------------!C_RESET!
echo   !C_GRAY!Total: !IDX! commits  ^(0 = mas reciente^)!C_RESET!
echo.

REM --- 5. Modos de uso (ordenados por frecuencia) ---
echo   !C_CYAN!-------------------------------------------------------------!C_RESET!
echo   !C_BCYAN! MODOS DE USO!C_RESET!
echo   !C_CYAN!-------------------------------------------------------------!C_RESET!
echo   !C_YELLOW!0,W!C_RESET!      !C_GRAY!Comparar ultimo commit vs estado actual!C_RESET!  !C_GREEN![recomendado]!C_RESET!
echo   !C_YELLOW!0,3!C_RESET!      !C_GRAY!Comparar commit [0] vs commit [3]!C_RESET!
echo   !C_YELLOW!0-3!C_RESET!      !C_GRAY!Alias de 0,3!C_RESET!
echo   !C_YELLOW![Enter]!C_RESET!  !C_GRAY!Solo ver historial (sin reporte)!C_RESET!
echo   !C_CYAN!-------------------------------------------------------------!C_RESET!
echo.

REM --- 6. Pedir rango ---
set "RANGE="
set /p "RANGE=  !C_BCYAN!Rango a auditar:!C_RESET! !C_GRAY![Enter=0,W]!C_RESET!: "
if "!RANGE!"=="" (
    set "RANGE=0,W"
    echo   !C_GRAY!Usando default: 0,W!C_RESET!
)

set "A="
set "B="
for /f "tokens=1,2 delims=,-" %%a in ("!RANGE!") do (
    set "A=%%a"
    if not "%%b"=="" set "B=%%b"
)
if "!A!"=="" (
    echo   !C_RED![X]!C_RESET! Rango invalido.
    goto :end
)
if "!B!"=="" set "B=!A!"

if /i "!A!"=="W" (
    echo   !C_RED![X]!C_RESET! El primer valor debe ser indice numerico. Formato: !C_YELLOW!5,W!C_RESET!
    goto :end
)
if /i "!A!"=="WORK" (
    echo   !C_RED![X]!C_RESET! El primer valor debe ser indice numerico. Formato: !C_YELLOW!5,W!C_RESET!
    goto :end
)
if /i "!A!"=="HEAD" (
    echo   !C_RED![X]!C_RESET! El primer valor debe ser indice numerico. Formato: !C_YELLOW!5,W!C_RESET!
    goto :end
)

set "HA=!H_%A%!"
if "!HA!"=="" (
    echo   !C_RED![X]!C_RESET! Indice !A! no existe.
    goto :end
)

set "H_NEW="
set "H_OLD=!HA!"
set "IS_WORK=0"

if /i "!B!"=="W"    set "IS_WORK=1"
if /i "!B!"=="WORK" set "IS_WORK=1"
if /i "!B!"=="HEAD" set "IS_WORK=1"

if "!IS_WORK!"=="1" (
    set "H_OLD=!HA!"
    set "H_NEW="
    set "OLD_IDX=!A!"
    set "NEW_IDX=WORK"
    set "NEW_LABEL=working tree"
) else (
    set "HB=!H_%B%!"
    if "!HB!"=="" (
        echo   !C_RED![X]!C_RESET! Indice !B! no existe.
        goto :end
    )
    set "OLD_IDX=!A!"
    set "NEW_IDX=!B!"
    if !A! LSS !B! (
        set "OLD_IDX=!B!"
        set "NEW_IDX=!A!"
    )
    set "H_OLD=!H_%OLD_IDX%!"
    set "H_NEW=!H_%NEW_IDX%!"
    set "NEW_LABEL=!H_NEW!"
)

echo.
echo   !C_CYAN!â—!C_RESET! !C_GRAY!Comparando:!C_RESET!
echo       !C_GRAY![antiguo]!C_RESET!   !C_YELLOW!!H_OLD!!C_RESET!  !C_GRAY!^(idx !OLD_IDX!^)!C_RESET!
if "!IS_WORK!"=="1" (
    echo       !C_GRAY![reciente]!C_RESET!  !C_GREEN!working tree!C_RESET!
) else (
    echo       !C_GRAY![reciente]!C_RESET!  !C_YELLOW!!H_NEW!!C_RESET!  !C_GRAY!^(idx !NEW_IDX!^)!C_RESET!
)
echo.

REM --- 7. Crear audits/ ---
if not exist "audits" mkdir "audits"

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HHmmss"') do set "TS=%%i"

if "!IS_WORK!"=="1" (
    set "REPORT=audits\audit_!TS!_!OLD_IDX!-WORK.txt"
) else (
    set "REPORT=audits\audit_!TS!_!OLD_IDX!-!NEW_IDX!.txt"
)

REM --- 8. Escribir reporte (SIN colores) ---
(
    echo # Reporte de auditoria
    echo.
    echo # Generado:  %DATE% %TIME%
    echo # Proyecto:  %CD%
    echo # Rango:     !H_OLD!  -^>  !NEW_LABEL!
    echo.
    if "!IS_WORK!"=="1" (
        echo # Comparar:  git diff !H_OLD!
    ) else (
        echo # Comparar:  git diff !H_OLD! !H_NEW!
    )
    echo.
    echo # ============================================================
    echo # COMMITS EN EL RANGO
    echo # ============================================================
    echo.
    if "!IS_WORK!"=="1" (
        git log !H_OLD!..HEAD --date=format:"%%Y-%%m-%%d %%H:%%M:%%S" --pretty=format:"  %%ad  %%h  %%s"
    ) else (
        git log !H_OLD!^..!H_NEW! --date=format:"%%Y-%%m-%%d %%H:%%M:%%S" --pretty=format:"  %%ad  %%h  %%s"
    )
    echo.
    echo.
    echo # ============================================================
    echo # DIFF COMPLETO
    echo # ============================================================
    echo.
    if "!IS_WORK!"=="1" (
        git diff !H_OLD!
    ) else (
        git diff !H_OLD! !H_NEW!
    )
    echo.
    echo.
    echo # ============================================================
    echo # ESTADO ACTUAL (sin commitear)
    echo # ============================================================
    echo.
    git status --short
) > "!REPORT!" 2>&1

REM --- 9. Resumen ---
echo   !C_GREEN![OK]!C_RESET! Reporte generado
echo.
for %%f in ("!REPORT!") do set "SIZE=%%~zf"
for /f %%l in ('find /c /v "" ^< "!REPORT!"') do set "LINES=%%l"

echo       !C_GRAY!Archivo:!C_RESET!  !C_WHITE!!REPORT!!C_RESET!
echo       !C_GRAY!Tamano:!C_RESET!   !C_WHITE!!SIZE! bytes!C_RESET!
echo       !C_GRAY!Lineas:!C_RESET!   !C_WHITE!!LINES!!C_RESET!
echo.

REM --- 10. Abrir ---
where code >nul 2>nul
if not errorlevel 1 (
    set "OPEN="
    set /p "OPEN=  !C_BCYAN!Abrir en VS Code?!C_RESET! !C_GRAY![S/n]!C_RESET!: "
    if /i not "!OPEN!"=="n" (
        echo   !C_GRAY!Abriendo...!C_RESET!
        code "!REPORT!"
    )
) else (
    echo   !C_GRAY![INFO] VS Code CLI no disponible.!C_RESET!
)

echo.
goto :end

REM ============================================================
REM   :help
REM ============================================================
:help
echo.
echo   !C_CYAN!============================================!C_RESET!
echo   !C_BCYAN! AUDITAR!C_RESET! !C_GRAY!- Ayuda!C_RESET!
echo   !C_CYAN!============================================!C_RESET!
echo.
echo   !C_BCYAN!USO:!C_RESET!
echo     !C_WHITE!auditar.cmd!C_RESET!           Modo interactivo
echo     !C_WHITE!auditar.cmd --help!C_RESET!    Esta ayuda
echo.
echo   !C_BCYAN!QUE HACE:!C_RESET!
echo     !C_GRAY!Genera un reporte .txt en audits/ con los cambios!C_RESET!
echo     !C_GRAY!entre dos puntos del historial Git.!C_RESET!
echo.
echo   !C_BCYAN!MODOS:!C_RESET!
echo     !C_YELLOW!0,W!C_RESET!      !C_GRAY!Comparar ultimo commit vs estado actual!C_RESET!  !C_GREEN![recomendado]!C_RESET!
echo     !C_YELLOW!0,3!C_RESET!      !C_GRAY!Comparar commit 0 vs commit 3!C_RESET!
echo     !C_YELLOW!0-3!C_RESET!      !C_GRAY!Alias de 0,3!C_RESET!
echo     !C_YELLOW![Enter]!C_RESET!  !C_GRAY!Solo ver historial!C_RESET!
echo.
echo   !C_BCYAN!EJEMPLOS:!C_RESET!
echo     !C_WHITE!auditar.cmd!C_RESET!
echo       !C_GRAY!Cuantos commits? 10!C_RESET!
echo       !C_GRAY!Rango: 0,W!C_RESET!
echo       !C_GRAY!-> audits\audit_2026-09-12_163200_0-WORK.txt!C_RESET!
echo.
echo   !C_BCYAN!SALIDA:!C_RESET!
echo     !C_GRAY!Los reportes se guardan en audits\!C_RESET!
echo     !C_GRAY!(excluida del repo por .gitignore^)!C_RESET!
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
echo   Sesion interactiva. Escribe 'exit' para cerrar.
echo.
cmd /k
goto :eof