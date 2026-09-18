@echo off
REM ============================================================
REM   forge-git / lib/ui.cmd
REM   UI helpers
REM ============================================================

if "%~1"=="banner" goto :banner
if "%~1"=="step"   goto :step
if "%~1"=="done"   goto :done
if "%~1"=="abort"  goto :abort
goto :eof

:banner
echo.
echo   ############################################
echo   #  forge-git v%FG_VERSION%                        #
echo   #  Bootstrap universal de proyecto         #
echo   ############################################
echo.
echo   Proyecto: %PROJECT_NAME%
echo   Ruta:     %CD%
echo.
goto :eof

:step
echo   [%~2] %~3    %~4
goto :eof

:done
echo.
echo   ############################################
echo   #  Bootstrap completado                     #
echo   ############################################
echo.
echo   Comandos disponibles:
echo.
echo     Esenciales:
echo       init.cmd        Bootstrap
echo       forge.cmd       Menu interactivo
echo.
echo     Uso CLI directo:
echo       forge save      Commit de cambios
echo       forge push      Push a GitHub
echo       forge log       Ver commits
echo.
echo     Otros:
echo       forge snap      Snapshots
echo       forge audit     Reporte diff
echo       forge open      Abrir en VS Code
echo       forge serve     Servidor de desarrollo
echo       forge help      Ayuda completa
echo.
goto :eof

:abort
echo.
echo   Bootstrap abortado. Instala los requisitos y vuelve a intentar.
pause
goto :eof