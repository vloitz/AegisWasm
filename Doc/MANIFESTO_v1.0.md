# Manifiesto AegisWasm — Versión Estable 1.0

> **Fecha de congelamiento:** 2026-09-10
> **Estado:** Producción — Capa 0 completa
> **Autor:** Kevin Italo Cajaleon Zuta (Vloitz / Gridlock)
> **Premisa rectificada:** Universalidad efectiva, no universalidad absoluta.

---

## 1. Qué es AegisWasm

AegisWasm es una librería de blindaje de activos web que cifra código JavaScript
dentro de una bóveda WebAssembly y lo descifra on-demand en la RAM volátil del
navegador, sin que el código fuente propietario toque jamás el disco del cliente
en texto plano.

**Lo que AegisWasm NO es:**
- No es un ofuscador tradicional (no transforma sintaxis, cifra bytes).
- No es un sistema de DRM (no protege audio ni video, solo código).
- No es un bundler (no agrupa módulos, se apoya en los existentes).
- No es invisible al 100% (el .wasm siempre será descargable; la promesa es que
  nadie puede leer el código fuente original sin ingeniería inversa costosa).

**Lo que AegisWasm SÍ es:**
- Un pipeline de empaquetado que cifra activos y genera superficie de carga.
- Un motor Wasm que descifra assets en RAM bajo demanda.
- Un Service Worker Adapter que intercepta red y enruta al motor.
- Un SDK de inyección fantasma que ejecuta el código sin dejar rastro en disco.

---

## 2. Arquitectura actual — 4 pilares

```
┌─────────────────────────────────────────────────────────────────┐
│  1. COMPILADOR (compiler/aegis_build.js)                        │
│     Lee aegis.config.json, cifra activos, genera artefactos.    │
│     Auto-migración idempotente, no requiere movimientos manuales.│
├─────────────────────────────────────────────────────────────────┤
│  2. BÓVEDA WASM (core/vm_core.cpp + bin/aegis_engine.wasm)      │
│     Motor C++ que descifra assets en RAM. Micro-VM con ISA.     │
├─────────────────────────────────────────────────────────────────┤
│  3. ADAPTER (aegis-sw-adapter.js, auto-generado)                │
│     Intercepta fetch en el Service Worker. Descifra segmentos   │
│     remotos (.m4s) al vuelo. Registro extensible de algoritmos. │
├─────────────────────────────────────────────────────────────────┤
│  4. SDK (aegis-sdk.js, auto-generado)                           │
│     Corre en main thread. Carga Wasm, inyecta scripts,          │
│     intercepta window.Worker, resuelve manifest.                │
└─────────────────────────────────────────────────────────────────┘
```

### Artefactos generados en cada build

| Archivo | Rol |
|---|---|
| `aegis.manifest.json` | Contrato runtime: activos, routing, crypto |
| `aegis-sw-adapter.js` | Motor de intercepción de red |
| `aegis-sdk.js` | Puente main thread ↔ bóveda Wasm |
| `bin/aegis_engine.js` + `.wasm` | Bóveda cifrada compilada |
| `sw.js` (parcheado) | Service Worker con bypass y hook |
| Micro-stubs en `out_dir/` | Conectores de ~250 bytes |

---

## 3. Premisa de universalidad — versión honesta

AegisWasm **NO** promete funcionar en cualquier proyecto web. Promete funcionar
en cualquier proyecto web moderno que cumpla las siguientes condiciones:

- Usa un bundler estándar (Vite, Webpack, Rollup, esbuild, Parcel) **o**
- Usa scripts clásicos sin módulos ES6 **o**
- Usa módulos ES6 como side-effects (sin exports consumidos por el importador).

### Cobertura real

| Tipo de proyecto | Cubierto | Motivo |
|---|---|---|
| Scripts clásicos + IIFE | ✅ | Micro-stubs + SDK |
| Módulos ES6 side-effect-only | ✅ | Heurística + `isModule=true` |
| Lazy loading de chunks propios | ✅ | Micro-stubs + manifest |
| Web Workers cifrados | ✅ | Interceptor de `window.Worker` |
| Segmentos HLS remotos | ✅ | Adapter + CRYPTO_ENGINES |
| Proyectos pure-ESM sin bundler | ⏳ Diferido | Capa 2 (v3.0) |
| Módulos con exports consumidos | ⏳ Diferido | Capa 2 (v3.0) |

**TAM efectivo:** ~95% de sitios web modernos (según HTTP Archive / Web Almanac).

---

## 4. Capacidades verificadas (checklist v2.0)

- [x] Auto-migración idempotente de fuentes a `source_dir`
- [x] Cifrado XOR en build time
- [x] Compilación automática de Wasm vía Emscripten
- [x] Generación de manifiesto declarativo con routing
- [x] Registro extensible de algoritmos de cifrado (`CRYPTO_ENGINES`)
- [x] Adapter de Service Worker con bypass universal
- [x] Blindaje de `cache.addAll` contra 404s
- [x] Interceptor de `window.Worker` con Proxy
- [x] Micro-stubs físicos en `out_dir` (primera carga en frío)
- [x] Heurística regex para detección de módulos ES6
- [x] Válvula de escape `modules: []` en config
- [x] Auto-`.gitignore` con bloque delimitado
- [x] Shims de `DOMContentLoaded` para inyección tardía
- [x] Verificación post-build de artefactos y stubs

**Todo verificado en producción** sobre el proyecto Vloitz (streaming HLS +
WebGL + workers + PWA). Primera carga en incógnito funciona sin recargar.

---

## 5. Futures — El siguiente camino evolutivo

Tras tres investigaciones arquitectónicas y un análisis de mercado ejecutivo,
la decisión estratégica es clara: **pivotar de runtime pure-ESM a wrapper
bundler-agnóstico.**

### El pivot en una línea

> Dejar de construir un runtime ESM paralelo al navegador, y en su lugar
> construir un CLI que cifre los chunks ya generados por cualquier bundler.

### La pirámide de 3 capas

```
┌─────────────────────────────────────────────────────────────┐
│  CAPA 2 (v3.0) — Diferida                                   │
│  VFS + es-module-shims + Shim Mode                          │
│  Cubre: proyectos pure-ESM con exports dinámicos            │
│  Costo: 6-10 semanas | TAM: ~5% | Construir solo si demanda │
├─────────────────────────────────────────────────────────────┤
│  CAPA 1 (v2.1) — Próxima                                   │
│  CLI wrapper bundler-agnóstico                              │
│  Cubre: ~95% de proyectos con bundler estándar              │
│  Costo: 2-4 semanas | TAM: ~95% | Alto ROI                  │
├─────────────────────────────────────────────────────────────┤
│  CAPA 0 (v2.0) — Congelada hoy                              │
│  Micro-stubs + heurística + SW Adapter                      │
│  Cubre: scripts clásicos, módulos side-effect, workers      │
│  Costo: ✅ Completado | Vloitz corre sobre esto             │
└─────────────────────────────────────────────────────────────┘
```

### La decisión argumentada

**Por qué NO construir la Capa 2 ahora:**

1. **TAM reducido:** solo 5% del mercado web usa pure-ESM sin bundler.
2. **Penalización de rendimiento:** shims + VFS añaden +100-300 ms en
   topologías complejas (según mantenedores de `es-module-shims`).
3. **Complejidad de debug exponencial:** 4 capas (polyfill + SW + IPC + Wasm).
4. **Dependencia permanente** en `es-module-shims` (~13 KB, con sus bugs).
5. **Conflictos con CSP estrictas** de entornos enterprise.
6. **No hay demanda empírica confirmada** de la funcionalidad diferencial.

**Por qué SÍ construir la Capa 1 (wrapper bundler):**

1. **Cubre el 95% del mercado** con el 30% del esfuerzo.
2. **No mantiene N plugins** (uno por bundler); un CLI universal.
3. **Source maps preservados** (cifrados en servidor, no en cliente).
4. **Lazy loading nativo del bundler** ya funciona out-of-the-box.
5. **Vloitz migra sin refactor** (Vite envuelve al output actual).
6. **2 comandos** para el usuario final: `vite build && aegis wrap ./dist`.

### Roadmap propuesto

| Fase | Alcance | Duración | Estado |
|---|---|---|---|
| **v2.0** | Congelar + tag + release | ✅ Completado | 2026-09-10 |
| **Research 3** | Diseño fino del CLI wrapper | ✅ Completado | 2026-09-11 |
| **v2.1 MVP** | CLI con soporte Vite + Rollup + Webpack | ✅ Completado | 2026-09-11 |
| **v2.1 Universal** | CLI + esbuild + Parcel + Next + Nuxt | ⏳ Pendiente | Próximo milestone |
| **v2.2 Source Maps** | Cifrado de .map + integración APM | ⏳ Pendiente | Después de universal |
| **v3.0 Diferido** | VFS + shims para pure-ESM | ⏳ Diferido | Solo si demanda real |

### Preguntas pendientes (Research 3)

1. ¿Cómo parchea el CLI el HTML de Vite/Webpack/Rollup sin romper Source Maps,
   HMR, tree-shaking ni chunk graph?
2. ¿Cómo se manejan los Source Maps cifrados en producción? ¿Debug loss
   aceptado como trade-off?
3. ¿Cómo detecta el Service Worker que un chunk es de AegisWasm? ¿Naming
   convention, manifest JSON, magic bytes?
4. ¿Cómo se compara AegisWasm con `javascript-obfuscator`, `Jscrambler`,
   `bytenode`? ¿Diferenciación real o marketing?
5. ¿Compatibilidad con edge runtimes (Cloudflare Workers, Vercel Edge, Deno
   Deploy)? ¿Funciona o requiere Node legacy?

---

## 6. Filosofía de diseño

Estos son los principios que guían cada decisión arquitectónica en AegisWasm:

1. **Cero fricción para el usuario final.** El desarrollador programa como
   siempre; el build hace la magia.
2. **Idempotencia.** Correr el compilador N veces produce el mismo resultado.
3. **Agnóstico al proyecto.** El compilador no conoce nombres, claves, ni
   lógica de negocio del usuario.
4. **Honestidad técnica.** Documentamos lo que cubrimos y lo que no.
5. **Un solo comando.** Sin configuraciones extensas, sin AST pesado, sin
   dependencias monolíticas.
6. **Defensa en profundidad.** Si una capa falla, las demás sostienen el
   sistema (ej. cache.addAll blindado, worker interceptor, manifest fallback).
7. **Cero código fuente en disco.** Ni en cliente, ni en GitHub, ni en logs.

---

## 7. Estado del proyecto

- **Estabilidad:** Producción. Corriendo sobre Vloitz sin incidencias.
- **Tests manuales:** primera carga en frío, incógnito, PWA install,
  workers cifrados, HLS con segmentos remotos, auto-loop, MediaSession.
- **Repositorio:** github.com/vloitz/AegisWasm
- **Licencia:** por definir (considerar MIT para adopción o Apache 2.0 para
  protección de patentes).

---

## 8. Próximo hito

**Construir el Research 3**, luego **v2.1 MVP del CLI wrapper** con soporte
Vite-only. Sin código antes del research. Sin promesas antes de validación.

---

> *"La universalidad efectiva es más valiosa que la universalidad teórica.
> Cubrir el 95% con el 30% del esfuerzo es ingeniería senior;
> perseguir el 5% restante con el 200% del esfuerzo es ego."*
> — Filosofía de diseño AegisWasm v1.0

---

## 9. Hitos verificados en v2.1.0 MVP

**Fecha:** 2026-09-11

**Validado end-to-end sobre Vite 5.4.11 (template vanilla):**

- [x] CLI `aegis wrap ./dist` procesa el output de Vite sin modificar el código fuente.
- [x] Cifrado in-place con Magic Bytes `\0AEGv1\0` (7 bytes).
- [x] Scanner HTML detecta `<script type="module" src>`.
- [x] Bootloader extrae los tags y los reinjecta tras `serviceWorker.ready`.
- [x] SW runtime descifra chunks al vuelo vía `crypto` (XOR temporal).
- [x] Header `X-Aegis-Served: 1` confirma intercepción en Network.
- [x] **Lazy loading de chunk cifrado funciona:** `import('./extra.js')` en runtime fue interceptado, descifrado (173 → 166 bytes) y ejecutado.
- [x] UI renders idéntica al bundle sin cifrar.

### Bundlers validados (actualizado 2026-09-11)

| Bundler | Formato HTML que emite | Estado |
|---|---|---|
| Vite 5.4.11 | `<script type="module" src="...">` | ✅ Validado |
| Rollup 4.24 | `<script type="module" src="...">` | ✅ Validado |
| Webpack 5.110 | `<script defer src=...>` minificado | ✅ Validado (caso crítico) |
| esbuild | Variantes de `type="module"` | ⏳ Pendiente |
| Parcel 2 | `<script type="module" src="...hash...">` | ⏳ Pendiente |
| Next.js | `<link preload as=script>` + `<script async>` | ⏳ Pendiente |
| Nuxt 3 | `<link modulepreload>` + `<script type="module">` | ⏳ Pendiente |

**Fixes aplicados durante validación de Webpack:**

- `html-scanner.js`: regex acepta atributos sin comillas (HTML minificado).
- `wrap.js`: el bootloader se decide por el injector, no por el scanner.
- `config.js`: `aegis-sw-runtime.js` añadido al array de exclusión.

**Pendiente para v2.1 universal:**

- [ ] Validar con esbuild, Parcel, Next.js, Nuxt 3, SvelteKit, Astro.
- [ ] Validar con proyectos multi-chunk grandes (más de 50 chunks).
- [ ] Preservación semántica de `defer`/`async` en scripts reinyectados
      (los scripts dinámicos son siempre `async` por HTML spec).
- [ ] Source Maps cifrados + integración APM (Sentry, Datadog).
- [ ] Edge runtimes (Cloudflare Workers, Vercel Edge, Deno Deploy).
- [ ] Migración a AES-GCM (`\0AEGv2\0`) con `crypto.subtle`.
```

---

## 📋 Instrucciones

1. **Crea el archivo:**
   ```
   E:\MASTER\Proyectos\2026\Web\AegisWasm\MANIFESTO_v1.0.md
   ```

2. **Pega el contenido** completo de arriba.

3. **Commit + push:**
   ```cmd
   cd /d E:\MASTER\Proyectos\2026\Web\AegisWasm
   git add MANIFESTO_v1.0.md
   git commit -m "docs: Manifiesto v1.0 - Estado estable y roadmap evolutivo"
   git push origin main
   ```

4. **Opcional pero recomendado:** añade un enlace al manifiesto en el `README.md`:
   ```markdown
   ## Estado del proyecto
   Ver [MANIFESTO_v1.0.md](./MANIFESTO_v1.0.md) para el estado actual y roadmap.
   ```

---
