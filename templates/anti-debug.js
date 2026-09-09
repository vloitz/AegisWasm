// Auto-ejecutable para evitar variables globales
(function() {
    console.log("[🛡️ Aegis Shield] Monitor de seguridad activado.");

    // Técnica 1: Trampa de Debugger (ralentiza y bloquea el análisis)
    setInterval(function() {
        const start = performance.now();
        debugger; // Si la consola está abierta, el navegador se detendrá aquí
        const end = performance.now();

        // Si el debugger detuvo la ejecución por más de 100ms, hay un intruso
        if (end - start > 100) {
            triggerLockdown();
        }
    }, 1000);

    function triggerLockdown() {
        console.error("🚨 [ALERTA] Intrusión detectada. Purgando memoria...");
        // Borramos el contenido de la página para proteger el código
        document.body.innerHTML = "<h1 style='color:red; text-align:center; margin-top:20vh;'>🛡️ Acceso Denegado: Entorno de depuración detectado.</h1>";
        document.body.style.background = "#000";
    }
})();