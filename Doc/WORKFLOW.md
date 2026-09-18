# Workflow — AegisWasm

> Manual operativo. Cómo usar AegisWasm sobre un proyecto real.
> Caso de referencia: Vloitz (ver `Doc/EJEMPLO_USO_VLOITZ.md`).

---

## 0. Requisitos previos

| Requisito | Versión mínima | Verificar con |
|---|---|---|
| Node.js | 18+ | `node --version` |
| Git | 2.30+ | `git --version` |
| Emscripten (`em++`) | última estable | `em++ --version` |

**Emscripten** es la única dependencia no trivial. Instalación:

- **Windows:** descargar el SDK desde https://emscripten.org/docs/getting_started/downloads.html
- **Verificar:** `em++ --version` debe responder sin error
- **Si no está en PATH:** el build falla al final, pero los primeros 10 pasos igual corren

---

## 1. Estructura de carpetas (proyecto típico)

```
mi-proyecto/
├── index.html
├── app.js                    ← a cifrar
├── story.js                  ← a cifrar
├── story-worker.js           ← a cifrar (worker)
├── portada_visual.js         ← a cifrar
├── sw.js                     ← EXCLUIDO (se patchea, no se cifra)
├── aegis.config.json         ← contrato (lo escribís vos)
├── sets.json / manifest.json ← sin cifrar (datos públicos)
└── (resto del proyecto)
```

**Regla base:** solo se cifran los `.js` con **lógica propietaria**. Todo lo demás queda intacto.

---

## 2. Los 3 comandos

### Comando 1 — Auditoría inicial (solo la primera vez)

```cmd
cd "E:\MASTER\Proyectos\2026\Web\AegisWasm"
node compiler/aegis_init.js "E:\ruta\al\proyecto"
```

**Qué hace:**
- Escanea recursivamente todos los `.js`
- Clasifica en 3 zonas:
  - 🔴 **Roja:** SWs nativos (excluidos del cifrado)
  - 🟡 **Amarilla:** workers / imports dinámicos (revisión manual)
  - 🟢 **Verde:** lógica estándar (a cifrar)
- Genera un `aegis.config.json` **preliminar** en el proyecto

**Salida esperada:**
```
🔴 ZONA ROJA (Bloqueo Físico Obligatorio - Excluidos del cifrado):
   - sw.js

🟡 ZONA AMARILLA (Revisión Humana Requerida - Hilos / Dinámicos):
   - story-worker.js

🟢 ZONA VERDE (Seguros para AegisWasm - Lógica estándar):
   - app.js
   - story.js
   - portada_visual.js
   - body-particles.js
   - calibradores.js

✅ Auditoría finalizada. Se ha generado el contrato inicial en:
   E:\ruta\al\proyecto\aegis.config.json
```

**Importante:** este config es un **borrador**. **NO lo uses directo.** Editá a mano (Comando 2).

### Comando 2 — Editar el contrato

Abrí `aegis.config.json` en el proyecto y ajustá:

1. Promover workers de `require_review` a `workers` (si corresponde)
2. Ajustar `options.out_dir` (`./` vs `./dist`)
3. Agregar `source_dir` si querés auto-migración
4. Agregar `routing[]` si querés proteger segmentos remotos

**Template curado de Vloitz:** `templates/configs/aegis.config.vloitz.json`
**Usalo como punto de partida.** Copialo, renombralo a `aegis.config.json`, ajustá lo específico.

### Comando 3 — Build

```cmd
cd "E:\MASTER\Proyectos\2026\Web\AegisWasm"
node compiler/aegis_build.js "E:\ruta\al\proyecto"
```

**Qué hace (11 sub-pasos):**

| # | Acción | Resultado |
|---|---|---|
| 1 | Crea `source_dir` (`./encript/`) si no existe | Carpeta nueva |
| 2 | Auto-migra: mueve los `.js` a cifrar → `encript/` | Originales salen de la raíz |
| 3 | Cifra XOR byte-a-byte con `xor_key` | En memoria |
| 4 | Genera `core/encrypted_code.h` | Arrays C++ |
| 5 | Genera `aegis.manifest.json` | Lista VIP |
| 6 | Genera `aegis-sw-adapter.js` | Guardaespaldas |
| 7 | Genera `aegis-sdk.js` | Puente main ↔ Wasm |
| 8 | Genera micro-stubs (~250 bytes) en la raíz | Mismo nombre que el original |
| 9 | Patch `sw.js`: importScripts + hook + blindaje `cache.addAll` | SW modificado |
| 10 | Actualiza `.gitignore` con bloque AEGISWASM | Evita subir `encript/` |
| 11 | Compila `vm_core.cpp` → `.wasm` con Emscripten | `bin/aegis_engine.{js,wasm}` |

**Salida esperada:** logs de cada paso + confirmación final.

---

## 3. Estructura después del build

```
mi-proyecto/
├── app.js                    ← 🪶 micro-stub (~250 bytes)
├── story.js                  ← 🪶 micro-stub
├── portada_visual.js         ← 🪶 micro-stub
├── body-particles.js         ← 🪶 micro-stub
├── calibradores.js           ← 🪶 micro-stub
├── story-worker.js           ← stub de worker
├── sw.js                     ← 🔧 patcheado
├── aegis-sdk.js              ← ✨ auto-generado
├── aegis-sw-adapter.js       ← ✨ auto-generado
├── aegis.manifest.json       ← ✨ auto-generado
├── aegis.config.json         ← tu contrato (sin tocar)
├── bin/
│   ├── aegis_engine.js       ← loader ES module
│   └── aegis_engine.wasm     ← motor compilado
└── encript/                  ← auto-gitignored
    ├── app.js                ← original cifrado (bytes XOR)
    └── ...
```

---

## 4. Verificación en runtime

Abrir Chrome con DevTools (`F12`). Checklist:

| # | Check | Dónde | Esperado |
|---|---|---|---|
| 1 | SW activo | Application → Service Workers | `sw.js` corriendo, scope `/` |
| 2 | Manifest cargado | Network → `aegis.manifest.json` | 200 OK, JSON con `vault_assets` |
| 3 | SDK cargado | Network → `aegis-sdk.js` | 200 OK, ~4 KB |
| 4 | Motor Wasm | Network → `bin/aegis_engine.wasm` | 200 OK, ~150 KB |
| 5 | `app.js` es un stub | Sources → `/app.js` | ~250 bytes, empieza con `// AEGIS-STUB-v1` |
| 6 | Código inyectado | Console → buscar `[AegisWasm]` | `[AegisWasm] Inyección fantasma completada: app.js` |
| 7 | Sin 404 críticos | Network → filtrar `404` | Solo `favicon.ico` |
| 8 | Lógica funciona | UI | Reproductor, story export, partículas OK |

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

1. Abrir DevTools → Sources → buscar `app.js` → debe mostrar el **stub**, NO el código real
2. `Ctrl+Shift+F` → buscar término propietario (ej. `YTSyncBridge`) → **cero resultados** en el árbol de Sources
3. La app funciona (el reproductor, el story export, todo). Pero el código **no es legible**.

**Esa es la prueba.** Si `Sources` no ve el código propietario, la protección funciona.

---

## 5. Gotchas críticos

### 5.1 — El SW no controla la primera carga

En la primera carga, el navegador pide `/app.js` directo al servidor. El stub usa `import()` dinámico (que no depende del SW). El SDK carga el Wasm. **Todo funciona sin SW activo.**

**La segunda carga** el SW ya está cacheando todo.

### 5.2 — Paths absolutos en stubs

El SDK usa `/aegis-sdk.js` con `/` inicial. **Siempre absoluto.** No hay problema con paths relativos.

### 5.3 — Perfil de Chrome limpio = SW desde cero

Si usás `--user-data-dir` nuevo cada vez, el SW se registra desde cero cada sesión. Útil para testear cold start, malo para testear cacheo.

**Solución:** después del primer cold start, **no cierres Chrome**. Recargá con `F5` para warm start.

### 5.4 — El cifrado de segmentos remotos es parcial

`bytes_to_decrypt: 100` significa que **solo los primeros 100 bytes** de cada `.m4s` se cifran.

**Por qué:** el resto del audio no se cifra (overhead innecesario). Los primeros 100 bytes son la cabecera HLS (fMP4 box headers). Cifrar esos bytes rompe el playback para cualquiera que no pase por el adapter.

**Resultado:** el audio funciona normal, pero es **inútil fuera del contexto de la app**.

### 5.5 — `.gitignore` bloquea `encript/` automáticamente

Después del build, `.gitignore` recibe un bloque:

```
# --- AEGISWASM_BLOCK_START ---
encript/
encript/app.js
...
# --- AEGISWASM_BLOCK_END ---
```

**Consecuencia:** `git status` no muestra los originales cifrados. Están en disco pero no van a GitHub.

**⚠️ Si hacés `git clean -fdx`:** `encript/` se borra. **Backup antes de operaciones destructivas.**

### 5.6 — Terser + AegisWasm = conflicto

Si tu proyecto usa Terser (o cualquier ofuscador) **antes** de AegisWasm, podés tener conflictos.

**Regla:** AegisWasm va **después** del bundler/ofuscador, no antes.

**Ejemplo correcto:**
```
1. vite build       → genera dist/
2. aegis wrap dist  → cifra dist/
```

**Ejemplo incorrecto:**
```
1. terser app.js    → ofusca
2. aegis wrap       → cifra el ofuscado
```

---

## 6. Rescate — si algo falla

### 6.1 — El build rompe el proyecto

**Restaurar desde git:**

```cmd
git checkout -- .
git clean -fd
```

Vuelve al último commit. **Cuidado:** borra archivos no commiteados.

### 6.2 — El código cifrado no se descifra

**Debug rápido:**

1. F12 → Network → buscar `aegis_engine.wasm` → debe estar 200 OK
2. F12 → Console → buscar `[AegisWasm]` → ver si hay errores
3. F12 → Application → SW → verificar que `aegis-sw-runtime.js` está importado

**Si el SW no importa el adapter:** revisar que `sw.js` tenga `importScripts('/aegis-sw-adapter.js')` en la línea 1.

### 6.3 — El stub no se inyecta

**Si ves `// AEGIS-STUB-v1` en Sources pero el código nunca se ejecuta:**

1. Verificar que `aegis-sdk.js` existe en la raíz
2. Verificar que `bin/aegis_engine.wasm` existe
3. Verificar que `aegis.manifest.json` existe
4. F12 → Console → buscar el error exacto

### 6.4 — Restaurar desde snapshot (si usás forgeGit)

```cmd
forge snap
# Elegir la versión anterior
# Confirmar con SI
```

---

## 7. Flujo resumido (para copiar/pegar)

```cmd
:: 1. Auditoría (solo primera vez)
cd "E:\MASTER\Proyectos\2026\Web\AegisWasm"
node compiler/aegis_init.js "E:\ruta\al\proyecto"

:: 2. Editar aegis.config.json a mano
code "E:\ruta\al\proyecto\aegis.config.json"

:: 3. Build
node compiler/aegis_build.js "E:\ruta\al\proyecto"

:: 4. Servir (cualquier servidor estático)
:: VS Code Live Server en puerto 5500

:: 5. Abrir Chrome Dev Mode
& "E:\ruta\al\vloitz_dev.cmd"

:: 6. Verificar (ver sección 4)

:: 7. Deploy
:: Copiar artefactos (NO copiar encript/ ni bin/)
:: Bump CACHE_NAME en sw.js
:: forge save + forge push
```

---

## 8. Estado del proyecto (referencia)

| Fase | Estado |
|---|---|
| Librería AegisWasm core | ✅ v2.1.3 congelado |
| Contrato de Vloitz | ✅ Curado en `templates/configs/aegis.config.vloitz.json` |
| Test end-to-end en TEST2/sync | 🟡 En progreso |
| Producción Vloitz | ❌ NO usa AegisWasm (beta) |

**Estado del desarrollo:** ver `Doc/STATUS.md`.

---