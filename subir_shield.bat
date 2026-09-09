@echo off
cd /d "%~dp0"
echo [AegisWasm] Sincronizando cambios con el repositorio central...
git add .
set /p "commit_msg=Mensaje de commit (Enter para usar por defecto): "
if "%commit_msg%"=="" set "commit_msg=Actualizacion automatica AegisWasm"
git commit -m "%commit_msg%"
git push origin main
echo [AegisWasm] Despliegue en GitHub completado con exito.
pause