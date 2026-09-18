# Ejemplo de Uso — AegisWasm sobre Vloitz

> **Proyecto de referencia:** Vloitz (streaming HLS + WebGL + PWA)
> **Propósito:** Documentar el flujo real de integración de AegisWasm
> sobre un proyecto en producción. Caso de uso canónico.
> **Estado:** beta — 70% completado. Producción aún NO usa la librería.

---

## 1. Por qué Vloitz es el caso de prueba

Vloitz no es un "hello world". Es una PWA real con:

- **Service Worker propio** con caches fragmentados (audio HLS, peak data, hero video)
- **Web Workers** (`story-worker.js` con WebCodecs para export de video)
- **Scripts con `DOMContentLoaded`** que esperan al DOM listo
- **Módulos ES6** con `import()` dinámico (`story.js` cargado bajo demanda)
- **WebGL** (`portada_visual.js`, `body-particles.js`)
- **Segmentos de audio cifrados** en el origen (R2 + Hugging Face)
- **Deploy en GitHub Pages** sin bundler

Es el peor escenario posible para una librería de cifrado: **si funciona acá, funciona en cualquier lado**.

**Objetivo:** demostrar que AegisWasm puede cifrar los scripts críticos sin romper nada del stack existente.

---

## 2. Estructura del proyecto (antes del build)

```
TEST2/sync/
├── index.html                 (referencia a los .js como siempre)
├── style.css
├── app.js                     ← motor principal (a cifrar)
├── story.js                   ← WebCodecs story export (a cifrar)
├── story-worker.js            ← Web Worker (a cifrar como worker)
├── portada_visual.js          ← WebGL particles (a cifrar)
├── body-particles.js          ← WebGL scroll particles (a cifrar)
├── calibradores.js            ← ajustes finos (a cifrar)
├── sw.js                      ← Service Worker (EXCLUIDO — se patchea, no se cifra)
├── sets.json                  ← datos de sets (sin cifrar, JSON público)
├── manifest.json              ← PWA manifest (sin cifrar)
├── favicon/, fonts/, Artwork/, peaks/, share/
└── .git/
```

**Regla base:** solo los `.js` que contienen **lógica propietaria** se cifran. Los archivos de datos, estilos y assets binarios quedan intactos.

---

## 3. El contrato — `aegis.config.json`

Este archivo es el **contrato maestro** entre el proyecto y AegisWasm. Define qué se cifra, qué se excluye, qué va como worker, y cómo se enrutan las peticiones a recursos remotos.

```json
{
    "_comment": "Contrato Maestro de AegisWasm (Portátil, agnóstico y auto-organizativo)",
    "source_dir": "./encript",
    "encrypt": [
        "body-particles.js",
        "calibradores.js",
        "portada_visual.js",
        "app.js",
        "story.js"
    ],
    "exclude": [
        "sw.js"
    ],
    "workers": [
        "story-worker.js"
    ],
    "options": {
        "xor_key": 90,
        "out_dir": "./"
    },
    "routing": [
        {
            "id": "r2-audio-segments",
            "match_hostname": "r2.dev",
            "match_path": "\\.m4s$",
            "transform": "/v-enc/",
            "crypto": {
                "algorithm": "xor-multibyte",
                "key_utf8": "vloitz_key_2026",
                "bytes_to_decrypt": 100
            }
        },
        {
            "id": "hf-audio-segments",
            "match_hostname": "workers.dev",
            "match_path": "\\.m4s$",
            "transform": "/v-enc/",
            "crypto": {
                "algorithm": "xor-multibyte",
                "key_utf8": "vloitz_key_2026",
                "bytes_to_decrypt": 100
            }
        }
    ]
}
```

### Explicación campo por campo

| Campo | Valor | Por qué |
|---|---|---|
| `source_dir` | `./encript` | Carpeta donde el build mueve los originales. Auto-gitignored. |
| `encrypt[]` | 5 archivos | Scripts con lógica propietaria. Se cifran XOR y se reemplazan por micro-stubs. |
| `exclude[]` | `sw.js` | El SW **NO se cifra** (spec W3C: no puede interceptar su propio bootstrap). Se **patchea**. |
| `workers[]` | `story-worker.js` | Worker con WebCodecs. Se cifra dentro de la bóveda y se inyecta como Blob Worker. |
| `options.xor_key` | `90` | Clave XOR byte-a-byte. `90` = `0x5A`. |
| `options.out_dir` | `./` | Los artefactos se escriben en la raíz del proyecto (no en `./dist`). |
| `routing[]` | 2 reglas | Intercepta segmentos `.m4s` de R2/HF y descifra los primeros 100 bytes al vuelo. |

### ¿De dónde sale este config?

**NO** lo genera `aegis_init.js` completo. Ese comando genera un **borrador** con `require_review` (workers sin clasificar) y `out_dir: ./dist`.

**Este config es una versión curada a mano** que:
1. Promueve `story-worker.js` de `require_review` a `workers`
2. Agrega `source_dir: ./encript` (auto-migración)
3. Cambia `out_dir` de `./dist` a `./`
4. Agrega el array `routing` con las 2 reglas de segmentos remotos

**Recomendación:** guardar este archivo como `templates/aegis.config.vloitz.json` en el repo de AegisWasm, para reutilizarlo en futuros tests.

---

## 4. Flujo completo desde 0

### Paso 0 — Preparar el proyecto limpio

```powershell
# Copiar producción a TEST2
xcopy "E:\MASTER\Proyectos\2026\Web\Wav GitHub\Sync" "E:\MASTER\Proyectos\2026\Web\TEST2\sync" /E /I

# Borrar artefactos de AegisWasm si vinieron con la copia
Remove-Item "E:\MASTER\Proyectos\2026\Web\TEST2\sync\aegis-sdk.js" -ErrorAction SilentlyContinue
Remove-Item "E:\MASTER\Proyectos\2026\Web\TEST2\sync\aegis-sw-adapter.js" -ErrorAction SilentlyContinue
Remove-Item "E:\MASTER\Proyectos\2026\Web\TEST2\sync\aegis.manifest.json" -ErrorAction SilentlyContinue
Remove-Item "E:\MASTER\Proyectos\2026\Web\TEST2\sync\bin" -Recurse -ErrorAction SilentlyContinue
Remove-Item "E:\MASTER\Proyectos\2026\Web\TEST2\sync\encript" -Recurse -ErrorAction SilentlyContinue

# Copiar el contrato curado
Copy-Item "E:\MASTER\Proyectos\2026\Web\TEST\Sync\aegis.config.json" "E:\MASTER\Proyectos\2026\Web\TEST2\sync\aegis.config.json"
```

### Paso 1 — Auditoría (opcional)

Solo la primera vez. Genera un config preliminar.

```powershell
cd "E:\MASTER\Proyectos\2026\Web\AegisWasm"
node compiler/aegis_init.js "E:\MASTER\Proyectos\2026\Web\TEST2\sync"
```

Clasifica los `.js` en 3 zonas:
- 🔴 **Zona Roja:** SWs (excluidos del cifrado)
- 🟡 **Zona Amarilla:** workers / imports dinámicos (revisión manual)
- 🟢 **Zona Verde:** lógica estándar (a cifrar)

### Paso 2 — Editar el contrato

Revisar `aegis.config.json`. En el caso de Vloitz, el contrato ya está curado (ver sección 3).

### Paso 3 — Build

```powershell
cd "E:\MASTER\Proyectos\2026\Web\AegisWasm"
node compiler/aegis_build.js "E:\MASTER\Proyectos\2026\Web\TEST2\sync"
```

**Esto ejecuta el pipeline completo (11 sub-pasos):**

1. Crea `encript/` si no existe
2. Auto-migra cada `.js` a cifrar desde la raíz → `encript/`
3. Cifra XOR byte-a-byte con `xor_key`
4. Genera `core/encrypted_code.h` (en el repo de AegisWasm)
5. Genera `aegis.manifest.json` (lista VIP)
6. Genera `aegis-sw-adapter.js` (guardaespaldas)
7. Genera `aegis-sdk.js` (puente main thread ↔ Wasm)
8. Genera micro-stubs de ~250 bytes en la raíz con el nombre original
9. Patchea `sw.js`: importScripts + hook en fetch + blindaje de `cache.addAll`
10. Actualiza `.gitignore` con bloque AEGISWASM
11. Compila `vm_core.cpp` a `.wasm` con Emscripten → `bin/aegis_engine.{js,wasm}`

### Paso 4 — Servir

Abrir VS Code Live Server sobre `TEST2/sync`, puerto 5500.

O cualquier servidor estático (Python, `http-server`, etc.).

### Paso 5 — Abrir Chrome Dev Mode

```powershell
& "E:\MASTER\Proyectos\2026\Web\TEST\Sync\vloitz_dev.cmd"
```

**Ese `.cmd` abre Chrome con:**
- `--disable-web-security` (CORS off para tests locales)
- `--user-data-dir="C:\chrome-dev-vloitz"` (perfil aislado)
- Apunta a `http://127.0.0.1:5500`

### Paso 6 — Verificar

Ver sección 6.

### Paso 7 — Deploy a producción

Ver sección 7.

---

## 5. Qué genera el build

Después del build, la estructura queda:

```
TEST2/sync/
├── index.html                 ← intacto (referencia los stubs)
├── style.css                  ← intacto
│
├── app.js                     ← 🪶 micro-stub (~250 bytes)
├── story.js                   ← 🪶 micro-stub
├── portada_visual.js          ← 🪶 micro-stub
├── body-particles.js          ← 🪶 micro-stub
├── calibradores.js            ← 🪶 micro-stub
├── story-worker.js            ← stub de worker (mismo mecanismo)
│
├── sw.js                      ← 🔧 patcheado (importScripts + hook + cache.addAll blindado)
├── aegis-sdk.js               ← ✨ auto-generado
├── aegis-sw-adapter.js        ← ✨ auto-generado
├── aegis.manifest.json        ← ✨ auto-generado
├── aegis.config.json          ← tu contrato (sin tocar)
│
├── bin/
│   ├── aegis_engine.js        ← loader ES module del Wasm
│   └── aegis_engine.wasm      ← motor compilado con encrypted_code.h
│
├── encript/                   ← auto-gitignored
│   ├── app.js                 ← original cifrado (bytes XOR)
│   ├── story.js               ← original cifrado
│   ├── portada_visual.js      ← original cifrado
│   ├── body-particles.js      ← original cifrado
│   ├── calibradores.js        ← original cifrado
│   └── story-worker.js        ← original cifrado
│
└── .gitignore                 ← bloque AEGISWASM agregado
```

### El micro-stub

Un stub de Vloitz se ve así (una línea):

```javascript
// AEGIS-STUB-v1
(async()=>{try{const m=await import('/aegis-sdk.js');const A=m.Aegis||window.Aegis;if(!A){console.error('[Aegis Stub] SDK no disponible');return;}await A.ready;await A.injectScript('app.js');}catch(e){console.error('[Aegis Stub] Fallo en app.js:',e);}})();
```

**Flujo del stub:**
1. Importa el SDK (`/aegis-sdk.js`)
2. Espera a que el motor Wasm esté listo (`A.ready`)
3. Pide al SDK que descifre y ejecute `app.js`

**Resultado:** el código fuente real **nunca toca el disco** en el cliente. Vive cifrado en `bin/aegis_engine.wasm` y se descifra en RAM.

---

## 6. Verificación en runtime (DevTools)

Con el Dev Mode abierto y el proyecto corriendo:

### Checklist crítico

| # | Check | Dónde | Esperado |
|---|---|---|---|
| 1 | SW activo | Application → Service Workers | `sw.js` corriendo, scope `/` |
| 2 | Manifest cargado | Network → `aegis.manifest.json` | 200 OK, JSON con `vault_assets` |
| 3 | SDK cargado | Network → `aegis-sdk.js` | 200 OK, ~4 KB |
| 4 | Motor Wasm | Network → `bin/aegis_engine.wasm` | 200 OK, ~150 KB |
| 5 | `app.js` es un stub | Sources → `/app.js` | **~250 bytes**, empieza con `// AEGIS-STUB-v1` |
| 6 | Código real inyectado | Console → buscar `[AegisWasm]` | `[AegisWasm] Inyección fantasma completada: app.js` |
| 7 | Sin `404` críticos | Network → filtrar `404` | Solo `favicon.ico` y similares |
| 8 | Lógica funciona | UI | Reproductor, story export, partículas, todo OK |

### Logs esperados en Console

```
[🛡️ AegisWasm] Motor en línea. Listo para servir activos.
[🛡️ AegisWasm] Interceptor de Worker instalado.
[🛡️ AegisWasm] Inyección fantasma completada: app.js
[🛡️ AegisWasm] Inyección fantasma completada: story.js
[🛡️ AegisWasm] Inyección fantasma completada: portada_visual.js
[🛡️ AegisWasm] Inyección fantasma completada: body-particles.js
[🛡️ AegisWasm] Inyección fantasma completada: calibradores.js
[🛡️ AegisWasm] Worker protegido instanciado desde bóveda: story-worker.js
```

### Test de eficacia

1. **Abrir DevTools → Sources → buscar `app.js`** → debe mostrar el stub, NO el código real
2. **Buscar en todo el código fuente** (`Ctrl+Shift+F`) → la palabra `YTSyncBridge` (o cualquier término propietario) → **cero resultados** en el árbol de Sources
3. **El código existe** (el reproductor funciona), pero **no es legible**

**Esa es la prueba.** Si `Sources` no ve el código propietario, la protección funciona.

---

## 7. Deploy a producción (checklist)

Una vez validado en `TEST2/sync`:

### Antes de copiar

- [ ] Verificar que el proyecto corre 100% sin errores en `TEST2/sync`
- [ ] Verificar que el reproductor HLS funciona
- [ ] Verificar que el story export funciona
- [ ] Verificar que la PWA se instala
- [ ] Verificar offline (SW cache)

### Copiar a producción

```powershell
# Solo los artefactos esenciales. NO copiar encript/ ni bin/ ni aegis.config.json.
$src = "E:\MASTER\Proyectos\2026\Web\TEST2\sync"
$dst = "E:\MASTER\Proyectos\2026\Web\Wav GitHub\Sync"

Copy-Item "$src\app.js" "$dst\app.js" -Force
Copy-Item "$src\story.js" "$dst\story.js" -Force
Copy-Item "$src\portada_visual.js" "$dst\portada_visual.js" -Force
Copy-Item "$src\body-particles.js" "$dst\body-particles.js" -Force
Copy-Item "$src\calibradores.js" "$dst\calibradores.js" -Force
Copy-Item "$src\story-worker.js" "$dst\story-worker.js" -Force
Copy-Item "$src\sw.js" "$dst\sw.js" -Force
Copy-Item "$src\aegis-sdk.js" "$dst\aegis-sdk.js" -Force
Copy-Item "$src\aegis-sw-adapter.js" "$dst\aegis-sw-adapter.js" -Force
Copy-Item "$src\aegis.manifest.json" "$dst\aegis.manifest.json" -Force
Copy-Item "$src\bin" "$dst\bin" -Recurse -Force
```

### Bump del SW (crítico)

**Buscar en `Sync/sw.js`:**
```javascript
const CACHE_NAME = 'vloitz-app-v62.2';
```

**Cambiar a:**
```javascript
const CACHE_NAME = 'vloitz-app-v62.3';
```

**Por qué:** sin el bump, los usuarios con SW viejo siguen viendo los stubs viejos durante semanas.

### Subir

```powershell
cd "E:\MASTER\Proyectos\2026\Web\Wav GitHub"
.\subir_web.bat
```

**⚠️ ADVERTENCIA:** el `subir_web.bat` aplica Terser + poison a los archivos en `ARCHIVOS_VIP` (`app.js`, `story.js`, etc.). **Con AegisWasm ya activo, esos archivos son stubs de 250 bytes.** Terser no los va a romper (son válidos), pero **sí va a aplicar el poison** — y el poison se activa solo si el hostname NO es `vloitz.github.io`.

**Mitigación:** en el `subir_web.bat`, mover `app.js`, `story.js` etc. fuera de `ARCHIVOS_VIP`. AegisWasm ya cumple la función de "hacer el código ilegible".

**Alternativa:** dejarlos en `ARCHIVOS_VIP`, ya que el poison no romperá los stubs. Pero es redundante y potencialmente conflictivo con el SDK.

**Recomendación fuerte:** remover de `ARCHIVOS_VIP` los archivos cifrados por AegisWasm.

### Verificar en producción

1. Abrir `https://vloitz.github.io/` en ventana incógnita
2. `Ctrl+Shift+R`
3. F12 → Console → buscar `[AegisWasm]`
4. F12 → Sources → buscar `app.js` → debe mostrar el stub
5. F12 → Application → SW → verificar `CACHE_NAME` nuevo

---

## 8. Gotchas críticos

### 8.1 — El SW no controla la primera carga

**Problema:** en la primera carga (cold start, sin SW activo), el navegador pide `/app.js` directo al servidor. Si el servidor devuelve el micro-stub, el stub intenta cargar `/aegis-sdk.js` (que sí existe). Todo funciona.

**Pero:** en la primera carga el SW **no está activo todavía**. Los stubs usan `import()` dinámico (que no depende del SW). El SDK carga el Wasm (que tampoco depende del SW). **Todo funciona sin SW.**

**Beneficio:** la primera carga no rompe la arquitectura. La segunda carga el SW ya está cacheando todo.

### 8.2 — El `import()` dinámico rompe si el path es relativo

**Problema:** si el stub usa `import('app.js')` sin `/`, el navegador resuelve el path relativo al archivo del stub. Dependiendo del bundler (Vite, Next), puede fallar.

**AegisWasm usa `/aegis-sdk.js` con `/` inicial.** Siempre absoluto. No hay problema.

### 8.3 — Chrome bloquea `--disable-web-security` en Mac/Linux

El `vloitz_dev.cmd` es específico de Windows. En Mac/Linux usar:

```bash
# Mac
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --disable-web-security --user-data-dir=/tmp/chrome-dev

# Linux
google-chrome --disable-web-security --user-data-dir=/tmp/chrome-dev
```

### 8.4 — El `user-data-dir` limpio reinicia el SW cada vez

**Problema:** cada apertura del `.cmd` usa perfil limpio → SW arranca de cero → primera carga siempre cold.

**Beneficio:** útil para testear cold start.

**Contra:** no podés testear el ciclo de cacheo completo sin cerrar Chrome.

**Solución:** después del primer cold start, **no cierres Chrome**. Recargá con `F5` para testear warm start.

### 8.5 — Los segmentos R2/HF se descifran solo los primeros 100 bytes

El `routing[].crypto.bytes_to_decrypt: 100` significa que **solo los primeros 100 bytes de cada `.m4s` se cifran**. Esto es intencional:

- El resto del audio HLS no se cifra (overhead de CPU innecesario)
- Los primeros 100 bytes son la cabecera HLS (fMP4 box headers)
- Cifrar solo esos bytes rompe el playback para cualquiera que no pase por el adapter

**Resultado:** el audio funciona normal, pero es **inútil fuera del contexto de la app**.

### 8.6 — El `.gitignore` bloquea `encript/` automáticamente

Después del build, el `.gitignore` recibe un bloque:

```
# --- AEGISWASM_BLOCK_START ---
# ==========================================================================
# encrypt by AegisWasm
# ==========================================================================
encript/
encript/app.js
encript/story.js
...
# --- AEGISWASM_BLOCK_END ---
```

**Consecuencia:** `git status` no muestra los originales cifrados. Están en disco, pero no van a GitHub.

**Importante:** si alguna vez hacés `git clean -fdx`, `encript/` se borra. **Hacé backup antes de operaciones destructivas.**

---

## 9. Estado actual del proyecto (Vloitz)

| Fase | Estado | Nota |
|---|---|---|
| **Librería AegisWasm core** | ✅ v2.1.3 congelado | 7 bundlers validados |
| **Contrato de Vloitz** | ✅ curado a mano | `TEST/Sync/aegis.config.json` |
| **Test end-to-end en TEST2/sync** | 🟡 70% completado | Falta validación sin errores |
| **Producción Vloitz** | ❌ NO usa AegisWasm | Beta, no listo |
| **Cobertura estimada** | 70% | 30% restante: fixes de integración |

**Lo que falta para 100%:**
1. Validar el build completo en `TEST2/sync` sin errores de consola
2. Verificar los 8 checks de runtime (sección 6)
3. Verificar el ciclo completo en Chrome Dev Mode (cold + warm)
4. Documentar cualquier fix que aparezca durante el test
5. Promover a producción **solo cuando el test esté 100% verde**

**Filosofía:** no promover a producción hasta que el test bed esté verde. La librería es beta hasta que pase este test.

---

> *"Un test bed que no es idéntico a producción no es un test bed, es un experimento. La diferencia es que el test bed se promueve cuando pasa, el experimento se descarta cuando falla."*
> — Regla de validación AegisWasm
```

---
