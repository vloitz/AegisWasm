@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>nul

cd /d "%~dp0..\.."

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

echo.
echo   !C_CY!============================================!C_RS!
echo   !C_BC! SERVE!C_RS! !C_GY!- Iniciar servidor de desarrollo!C_RS!
echo   !C_CY!============================================!C_RS!
echo.

REM ============================================================
REM   DETECCION DE STACK
REM ============================================================
set "STACK="
set "CMD="
set "NEEDS_PYTHON=0"
set "NEEDS_NODE=0"
set "PORT="

REM --- Node.js: package.json ---
if exist "package.json" (
    findstr /C:"\"dev\"" package.json >nul 2>nul
    if not errorlevel 1 (
        set "STACK=Node.js (npm run dev)"
        set "CMD=npm run dev"
        set "NEEDS_NODE=1"
        goto :detected
    )
    findstr /C:"\"start\"" package.json >nul 2>nul
    if not errorlevel 1 (
        set "STACK=Node.js (npm start)"
        set "CMD=npm start"
        set "NEEDS_NODE=1"
        goto :detected
    )
)

REM --- Django ---
if exist "manage.py" (
    set "STACK=Django"
    set "NEEDS_PYTHON=1"
    call :find_free_port 8000
    set "CMD=python manage.py runserver !PORT!"
    goto :detected
)

REM --- Python simple ---
if exist "app.py" (
    set "STACK=Python (app.py)"
    set "NEEDS_PYTHON=1"
    set "CMD=python app.py"
    goto :detected
)
if exist "main.py" (
    set "STACK=Python (main.py)"
    set "NEEDS_PYTHON=1"
    set "CMD=python main.py"
    goto :detected
)

REM --- Node.js simple (server.js) ---
if exist "server.js" (
    set "STACK=Node.js (server.js)"
    set "NEEDS_NODE=1"
    set "CMD=node server.js"
    goto :detected
)

REM --- Rust ---
if exist "Cargo.toml" (
    set "STACK=Rust (cargo)"
    set "CMD=cargo run"
    goto :detected
)

REM --- Go ---
if exist "go.mod" (
    set "STACK=Go"
    set "CMD=go run ."
    goto :detected
)

REM --- Docker Compose ---
if exist "docker-compose.yml" (
    set "STACK=Docker Compose"
    set "CMD=docker-compose up"
    goto :detected
)
if exist "docker-compose.yaml" (
    set "STACK=Docker Compose"
    set "CMD=docker-compose up"
    goto :detected
)

REM --- HTML estatico: NODE primero, PYTHON fallback ---
if exist "index.html" (
    call :find_free_port 8080
    where node >nul 2>nul
    if not errorlevel 1 (
        set "STACK=HTML estatico (Node.js)"
        set "NEEDS_NODE=1"
        set "CMD=node .forge\serve-static.js !PORT!"
        goto :detected
    )
    where python >nul 2>nul
    if not errorlevel 1 (
        set "STACK=HTML estatico (Python)"
        set "NEEDS_PYTHON=1"
        set "CMD=python -m http.server !PORT!"
        goto :detected
    )
    echo   !C_RE![X]!C_RS! No hay Node.js ni Python para servir HTML.
    echo   !C_GY!Instala Node.js: https://nodejs.org!C_RS!
    echo   !C_GY!O Python:        https://python.org!C_RS!
    pause
    goto :end
)

REM --- No detectado ---
echo   !C_YE![!]!C_RS! No se detecto stack automaticamente.
echo.
echo   !C_GY!Archivos buscados:!C_RS!
echo     - package.json         Node.js
echo     - manage.py            Django
echo     - app.py / main.py     Flask / FastAPI
echo     - server.js            Node.js simple
echo     - Cargo.toml           Rust
echo     - go.mod               Go
echo     - docker-compose.yml   Docker
echo     - index.html           HTML estatico
echo.
pause
goto :end

:detected
REM --- Verificar dependencias ---
if "!NEEDS_PYTHON!"=="1" (
    where python >nul 2>nul
    if errorlevel 1 (
        echo   !C_RE![X]!C_RS! Python no esta instalado.
        echo   !C_GY!Descarga: https://python.org!C_RS!
        pause
        goto :end
    )
)
if "!NEEDS_NODE!"=="1" (
    where node >nul 2>nul
    if errorlevel 1 (
        echo   !C_RE![X]!C_RS! Node.js no esta instalado.
        echo   !C_GY!Descarga: https://nodejs.org!C_RS!
        pause
        goto :end
    )
)

REM --- Mostrar info ---
echo   !C_CY!-!C_RS! !C_GY!Stack:!C_RS!   !C_WH!!STACK!!C_RS!
if not "!PORT!"=="" echo   !C_CY!-!C_RS! !C_GY!Puerto:!C_RS!  !C_WH!!PORT!!C_RS!
echo   !C_CY!-!C_RS! !C_GY!Comando:!C_RS! !C_WH!!CMD!!C_RS!
echo.

REM --- Confirmar ---
set "CONFIRM="
set /p "CONFIRM=  !C_BC!Ejecutar servidor?!C_RS! !C_GY![S/n]!C_RS!: "
if /i "!CONFIRM!"=="n" goto :end

echo.
echo   !C_GR!Iniciando servidor...!C_RS!
echo   !C_GY!Ctrl+C para detener!C_RS!
echo.

REM --- Ejecutar ---
!CMD!

goto :end

:end
endlocal
exit /b 0

REM ============================================================
REM   :find_free_port  - Encuentra puerto libre desde %1
REM   Prueba %1, %1+1, ... hasta %1+20
REM ============================================================
:find_free_port
set "PORT=%~1"
set /a "MAX=%~1 + 20"
:fp_loop
netstat -an 2>nul | findstr ":!PORT! " >nul 2>nul
if errorlevel 1 goto :fp_found
set /a PORT+=1
if !PORT! LEQ !MAX! goto :fp_loop
set "PORT=%~1"
:fp_found
goto :eof