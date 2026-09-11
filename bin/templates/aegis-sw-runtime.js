'use strict';

// Template del Service Worker runtime de AegisWasm v2.
// Se procesa en `wrap.js` para embeber la XOR key y otros parámetros.
// NO se ejecuta en Node — es un string template para generar el SW final.

function buildSwRuntime({
    xorKey,
    magicHex
}) {
    return `// AegisWasm Service Worker Runtime v2.0.0
// Auto-generado por aegis wrap. NO EDITAR A MANO.
'use strict';

const AEGIS_XOR_KEY = ${xorKey};
const AEGIS_MAGIC = new Uint8Array([${magicHex}]);
const AEGIS_MAGIC_LEN = AEGIS_MAGIC.length;

self.addEventListener('install', (event) => {
    self.skipWaiting();
});

self.addEventListener('activate', (event) => {
    event.waitUntil(self.clients.claim());
});

function isSealed(bytes) {
    if (bytes.length < AEGIS_MAGIC_LEN) return false;
    for (let i = 0; i < AEGIS_MAGIC_LEN; i++) {
        if (bytes[i] !== AEGIS_MAGIC[i]) return false;
    }
    return true;
}

function decryptXor(bytes, key) {
    const out = new Uint8Array(bytes.length);
    for (let i = 0; i < bytes.length; i++) out[i] = bytes[i] ^ key;
    return out;
}

async function handleAegisRequest(request) {
    let response;
    try {
        response = await fetch(request);
    } catch (err) {
        return new Response('AegisWasm: fetch failed', { status: 502 });
    }

    if (!response.ok) return response;

    // Clonamos: uno para inspeccionar, otro para passthrough si no aplica.
    const cloned = response.clone();

    let bytes;
    try {
        const buf = await cloned.arrayBuffer();
        bytes = new Uint8Array(buf);
    } catch (err) {
        return response;
    }

    if (!isSealed(bytes)) {
        // No es nuestro. Passthrough original.
        return response;
    }

    // Desellamos: descartamos el header, XOR sobre el payload.
    const payload = bytes.subarray(AEGIS_MAGIC_LEN);
    const decrypted = decryptXor(payload, AEGIS_XOR_KEY);

    // Preservamos Content-Type original si estaba definido, o forzamos JS.
    const originalCT = response.headers.get('Content-Type');
    const contentType = originalCT && /javascript/i.test(originalCT)
        ? originalCT
        : 'application/javascript; charset=utf-8';

    console.log('[AegisSW] Desellado: ' + new URL(request.url).pathname +
                ' (' + bytes.length + ' → ' + decrypted.length + ' bytes)');

    return new Response(decrypted, {
        status: 200,
        statusText: 'OK',
        headers: {
            'Content-Type': contentType,
            'Cache-Control': 'no-store',
            'X-Aegis-Served': '1'
        }
    });
}

self.addEventListener('fetch', (event) => {
    const req = event.request;
    if (req.method !== 'GET') return;

    const url = new URL(req.url);
    if (url.origin !== self.location.origin) return;

    // Solo .js y .mjs. Cualquier otro recurso pasa sin inspección.
    const path = url.pathname;
    if (!path.endsWith('.js') && !path.endsWith('.mjs')) return;

    event.respondWith(handleAegisRequest(req));
});
`;
}

module.exports = {
    buildSwRuntime
};