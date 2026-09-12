# AegisWasm — Estado actual (2026-09-12)

## Versión estable actual
v2.1.3 — Capa 1 Universal completa

## ¿Qué está funcionando hoy?
- CLI `aegis wrap` sobre 7 bundlers (Vite, Rollup, Webpack, esbuild, Parcel, Next.js, Nuxt)
- Cifrado XOR + Magic Bytes `\0AEGv1\0`
- Bootloader + SW runtime
- Lazy loading, workers cifrados, PWA offline

## ¿Qué NO está implementado todavía?
- Cifrado de `.js.map` (por eso están en `exclude` del config)
- AES-GCM (la criptografía actual es XOR temporal)
- Edge runtimes (Cloudflare, Vercel, Deno)
- SvelteKit y Astro (sin validar)

## ¿Dónde está la verdad de la arquitectura?
- Documento canónico: `Doc/MANIFESTO_v2.0.md`
- Histórico: `Doc/OLD_MANIFESTO_v1.0.md`

## ¿Cómo verifico que funciona?
- Correr los test fixtures en `test-fixtures.js`
- Proyectos de prueba en `E:\MASTER\Proyectos\2026\Web\TEST\{Vite,Rollup,Webpack,Esbuild,Parcel,Next,Nuxt}Test`

## Estado de desarrollo (Freeze Notice)

**El desarrollo de AegisWasm se detiene en este punto de forma intencional.**

La librería alcanzó la Capa 1 Universal completa: cubre el ~95% de proyectos web modernos con bundler estándar y cumple la premisa original del proyecto. Los hitos v2.2, v2.3 y Seguridad v2 listados en el manifiesto **no se construirán hasta que exista demanda empírica real** (reportes de usuarios, casos de uso concretos, o necesidades propias en producción).

**Motivo del congelamiento:**
- La universalidad efectiva ya está cumplida (7/7 bundlers validados).
- Los hitos pendientes son mejoras incrementales, no cierres de la premisa.
- Construir features especulativas viola la filosofía #4 del manifiesto (honestidad técnica).

**Reapertura del desarrollo:**
Si en el futuro aparece una demanda real (bug crítico, framework faltante, caso de uso bloqueante), se reabre el ciclo con evidencia concreta. Sin esa evidencia, el proyecto permanece estable en v2.1.3.

## Convenciones de trabajo
- No proponer features fuera del roadmap sin evidencia empírica de demanda
- Cualquier cambio se hace sobre `dist/` post-build, nunca sobre fuentes
- Commits con formato: `tipo(scope): descripción`