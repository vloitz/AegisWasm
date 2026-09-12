# Manifiesto AegisWasm — Versión 2.0 (Universal)

> **Fecha de release:** 2026-09-12
> **Estado:** Producción — Capa 1 Universal Completa (v2.1.3)
> **Autor:** Kevin Italo Cajaleon Zuta (Vloitz / Gridlock)
> **Premisa rectificada:** Universalidad efectiva, no universalidad absoluta.

---

## 1. Qué es AegisWasm

AegisWasm es una librería de blindaje de activos web que cifra código JavaScript dentro de una bóveda WebAssembly y lo descifra on-demand en la RAM volátil del navegador, sin que el código fuente propietario toque jamás el disco del cliente en texto plano.

**Lo que AegisWasm NO es:**
*   No es un ofuscador tradicional (no transforma sintaxis, cifra bytes).
*   No es un sistema de DRM (no protege audio ni video, solo código).
*   No es un bundler (no agrupa módulos, se apoya en los existentes).
*   No es invisible al 100% (el .wasm siempre será descargable; la promesa es que nadie puede leer el código fuente original sin ingeniería inversa costosa).

**Lo que AegisWasm SÍ es:**
*   Un pipeline de empaquetado (CLI) que cifra activos y genera superficie de carga.
*   Un motor Wasm que descifra assets en RAM bajo demanda.
*   Un Service Worker Adapter que intercepta red y enruta al motor.
*   Un SDK de inyección fantasma que ejecuta el código sin dejar rastro en disco.

---

## 2. Arquitectura Core — 4 Pilares

```text
┌─────────────────────────────────────────────────────────────────┐
│  1. COMPILADOR CLI (aegis wrap)                                 │
│     Lee aegis.config.json, cifra activos generados por el       │
│     bundler (Vite, Next, etc.). Auto-migración idempotente.     │
├─────────────────────────────────────────────────────────────────┤
│  2. BÓVEDA WASM (core/vm_core.cpp + bin/aegis_engine.wasm)      │
│     Motor C++ que descifra assets en RAM. Micro-VM con ISA.     │
├─────────────────────────────────────────────────────────────────┤
│  3. ADAPTER (aegis-sw-adapter.js, auto-generado)                │
│     Intercepta fetch en el Service Worker. Descifra chunks y    │
│     segmentos remotos al vuelo. Registro de algoritmos.         │
├─────────────────────────────────────────────────────────────────┤
│  4. BOOTLOADER & SDK (aegis-sdk.js, auto-generado)              │
│     Corre en main thread. Reinyecta scripts post-SW ready,      │
│     intercepta window.Worker, resuelve manifest.                │
└─────────────────────────────────────────────────────────────────┘

```

### Artefactos generados en cada build

| Archivo | Rol |
| --- | --- |
| `aegis.manifest.json` | Contrato runtime: activos, routing, crypto y stubs |
| `aegis-sw-adapter.js` | Motor de intercepción de red (Service Worker) |
| `aegis-sdk.js` | Puente main thread ↔ bóveda Wasm |
| `bin/aegis_engine.js` + `.wasm` | Bóveda cifrada compilada en WebAssembly |
| `sw.js` (parcheado) | Service Worker original con bypass y hook inyectado |

---

## 3. Premisa de universalidad — Versión 2.0

AegisWasm **NO** promete funcionar en cualquier proyecto web mal estructurado. Promete funcionar en cualquier proyecto web moderno que use un bundler estándar.

Tras el pivot arquitectónico hacia la **Capa 1**, AegisWasm funciona como un wrapper bundler-agnóstico.

### Cobertura de Bundlers (7/7 Validados)

| Bundler / Framework | Formato HTML que emite | Estado |
| --- | --- | --- |
| **Vite 5.4+** | `<script type="module" src="...">` | ✅ Validado |
| **Rollup 4.2x** | `<script type="module" src="...">` | ✅ Validado |
| **Webpack 5.x** | `<script defer src=...>` minificado | ✅ Validado |
| **esbuild 0.2x** | `<script type="module" src="...">` | ✅ Validado |
| **Parcel 2.1x** | `<script type=importmap>` + scripts sin `<head>` | ✅ Validado |
| **Next.js 16** | HTML hidratado (React Streaming), chunks Turbopack | ✅ Validado |
| **Nuxt 3.14** | `<script type=importmap>` + `<link modulepreload>` | ✅ Validado |

**TAM efectivo:** ~95% de sitios web modernos (según HTTP Archive / Web Almanac).

---

## 4. Evolución y Pirámide Arquitectónica

Tras múltiples investigaciones y un análisis de mercado ejecutivo, la decisión estratégica de la versión 2.0 fue: **pivotar de un runtime pure-ESM a un wrapper CLI bundler-agnóstico.**

### El pivot en una línea

> Dejar de construir un runtime ESM paralelo al navegador, y en su lugar construir un CLI que cifre los chunks ya generados por cualquier bundler.

### La pirámide de 3 capas

```text
┌─────────────────────────────────────────────────────────────┐
│  CAPA 2 (v3.0) — Diferida                                   │
│  VFS + es-module-shims + Shim Mode                          │
│  Cubre: proyectos pure-ESM con exports dinámicos sin bundler│
│  Costo: 6-10 semanas | TAM: ~5% | Construir solo si demanda │
├─────────────────────────────────────────────────────────────┤
│  CAPA 1 (v2.0 / v2.1.x) — COMPLETADA Y UNIVERSAL            │
│  CLI wrapper bundler-agnóstico (aegis wrap)                 │
│  Cubre: ~95% de proyectos con bundler estándar (React, Vue) │
│  Estado: ✅ Completado | 7 bundlers validados               │
├─────────────────────────────────────────────────────────────┤
│  CAPA 0 (v1.0) — Congelada                                  │
│  Micro-stubs + heurística + SW Adapter básico               │
│  Cubre: scripts clásicos, módulos side-effect, workers      │
│  Estado: ✅ Completado | Vloitz estable sobre esta base     │
└─────────────────────────────────────────────────────────────┘

```

### La decisión argumentada (Por qué no Capa 2 por ahora)

1. **TAM reducido:** solo el 5% del mercado web usa pure-ESM en producción sin agrupar.
2. **Penalización de rendimiento:** shims + VFS añaden +100-300 ms en topologías complejas.
3. **Complejidad de debug:** 4 capas de abstracción (polyfill + SW + IPC + Wasm).
4. **Capa 1 es superior:** No requiere plugins específicos (uno por bundler). Son solo 2 comandos para el usuario final: `npm run build && aegis wrap ./dist`.

---

## 5. Capacidades Verificadas Core

* [x] CLI `aegis wrap` bundler-agnóstico (`\0AEGv1\0` Magic Bytes).
* [x] Auto-migración idempotente (in-place o hacia `source_dir`).
* [x] Bootloader HTML inteligente con escáner de atributos sin comillas.
* [x] Re-inyección diferida de scripts garantizando `serviceWorker.ready`.
* [x] SW Adapter con descifrado XOR temporal al vuelo vía `crypto`.
* [x] Lazy loading nativo soportado (interceptado dinámicamente).
* [x] Blindaje de `cache.addAll` y soporte offline para PWA.
* [x] Soporte para Web Workers cifrados (Interceptor `window.Worker`).
* [x] Soporte para HTML minificado, ausencia de `<head>` e importmaps.

---

## 6. Casos Críticos de Bundlers Resueltos (v2.1.x)

Para alcanzar la universalidad de la Capa 1, se resolvieron las siguientes peculiaridades:

1. **Webpack 5 (HTML minificado):** Actualización del `html-scanner.js` para soportar atributos sin comillas de forma robusta. Integración exclusiva vía injector.
2. **Parcel 2 (HTML sin `<head>` e Importmaps):** Nuevo branch en `html-injector.js` para inyectar el bootloader justo después del `<!DOCTYPE>` evitando romper el modo estándar (*quirks mode*). Re-inyección de `<script type=importmap>` estrictamente antes del module script.
3. **Next.js 16 (Turbopack + Hidratación React):** Soporte nativo para múltiples tags y chunks asíncronos generados por Turbopack (`turbopack-XXXX.js`). El SW runtime maneja el árbol de dependencias sin bloquear la hidratación del framework.
4. **Nuxt 3.14 (Vue SSR/SSG):** Manejo correcto de la combinación de `importmap`, `modulepreload` y scripts de tipo módulo.

---

## 7. Roadmap y Próximos Hitos

La Capa 1 Universal está cerrada. Los próximos esfuerzos se centran en observabilidad, seguridad criptográfica y despliegue en el Edge.

* [ ] **v2.2 — Source Maps + APM:** Cifrado de `.js.map` preservando la capacidad de debug en producción vía Sentry o Datadog. Documentar trade-offs.
* [ ] **v2.3 — Edge Runtimes:** Soporte nativo para Cloudflare Workers, Vercel Edge y Deno Deploy.
* [ ] **Seguridad v2:** Migración a AES-GCM (`\0AEGv2\0`) utilizando `crypto.subtle` dentro del Service Worker.
* [ ] **Expansión de Testing:** Validar frameworks de nicho o generadores de sitios estáticos (SvelteKit y Astro) y tests de estrés en proyectos >50 chunks.

---

## 8. Filosofía de diseño

1. **Cero fricción.** El desarrollador programa como siempre; el build hace la magia.
2. **Idempotencia.** Correr el compilador N veces produce el mismo resultado.
3. **Agnóstico.** El compilador no conoce lógica de negocio ni frameworks.
4. **Honestidad técnica.** Documentamos explícitamente lo que cubrimos y lo que diferimos.
5. **Defensa en profundidad.** Si una capa falla, las demás sostienen el sistema.
6. **Cero texto plano.** Ni en el disco del cliente, ni en los repositorios, ni en logs.

---

## 9. Registro de versiones

| Versión | Fecha | Cambios Principales |
| --- | --- | --- |
| **v1.0.0** | 2026-09-10 | Congelamiento Capa 0. Proyecto Vloitz estable. |
| **v2.0.0** | 2026-09-11 | Pivot a Capa 1. CLI `aegis wrap` MVP. Vite validado. |
| **v2.1.1** | 2026-09-11 | Soporte extendido: Rollup, Webpack, esbuild. |
| **v2.1.2** | 2026-09-11 | Fixes estructurales HTML: Parcel 2 (importmaps/no-head). |
| **v2.1.3** | 2026-09-12 | Universalidad Completa: Next.js 16 (Turbopack) y Nuxt 3.14. |

---

> *"La universalidad efectiva es más valiosa que la universalidad teórica. Cubrir el 95% con el 30% del esfuerzo es ingeniería senior; perseguir el 5% restante con el 200% del esfuerzo es ego."*
> — Filosofía de diseño AegisWasm v2.0