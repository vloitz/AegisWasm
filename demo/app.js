import loadAegisEngine from '../bin/aegis_engine.js';

async function initAegisShield() {
    try {
        console.log("[🛡️ AegisWasm] Inicializando entorno seguro...");

        const aegisModule = await loadAegisEngine();

        // 1. Solicitamos el script protegido desde la bóveda de Wasm
        const scriptPtr = aegisModule.ccall(
            'get_secure_asset',
            'number',
            ['string'],
            ['body-particles.js']
        );

        if (!scriptPtr) {
            console.error("🚨 [AegisWasm] El script protegido no fue encontrado en la bóveda.");
            return;
        }

        // 2. Convertimos el puntero de memoria de C++ a un string de JavaScript
        const rawScriptCode = aegisModule.UTF8ToString(scriptPtr);

        // 3. Liberamos inmediatamente la memoria reservada en el heap del motor
        aegisModule.ccall('free_secure_asset', null, ['number'], [scriptPtr]);

        console.log("🔒 [AegisWasm] Script descifrado en RAM volátil de forma segura.");

        // 4. Inyección Fantasma: Creamos y ejecutamos el script dinámicamente sin archivo físico
        const dynamicScript = document.createElement('script');
        dynamicScript.textContent = rawScriptCode;
        document.head.appendChild(dynamicScript);

        console.log("✨ [AegisWasm] Código de partículas activo. Revisa la pestaña Sources: ¡el archivo .js original ya no existe!");

    } catch (error) {
        console.error("🚨 [AegisWasm] Fallo crítico de integridad en el motor:", error);
    }
}

initAegisShield();