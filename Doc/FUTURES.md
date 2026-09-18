# AegisWasm — Futures

> **Fecha:** 2026-09-12
> **Estado base:** v2.1.3 — Capa 1 Universal congelada.
> **Propósito:** Análisis de los siguientes niveles de protección posibles,
> con justificación técnica, costo real y criterios de activación.
> **Audiencia:** Futuro mantenedor del proyecto, colaboradores senior,
> cualquier IA que analice el repo y necesite contexto de decisiones.

---

## 1. Por qué los métodos actuales caducan

AegisWasm v2.1.3 usa tres capas de protección:

1. **Cifrado XOR** de los chunks con Magic Bytes versionados.
2. **Bootloader HTML** que difiere la carga hasta que el Service Worker está activo.
3. **SW runtime** que descifra on-demand en RAM volátil.

Esto es suficiente para detener al 99% de atacantes humanos hoy. Pero el
modelo de amenaza está cambiando por dos razones concretas:

### Razón 1 — Los LLMs pueden desofuscar código en minutos

Modelos como Claude 4.x y Gemini 2.x ya desofuscan scripts comerciales
(javascript-obfuscator, Jscrambler básico) en cuestión de horas. La evidencia
pública (2024-2026) muestra que:

- Ofuscación por renombrado de variables: **minutos**.
- Aplanamiento de flujo de control: **horas**.
- Cifrado con clave embebida: **horas-días**.
- Bytecode V8 (bytenode): **días** con ayuda de LLMs.

En 12-24 meses, este proceso se va a automatizar por completo. Un atacante
con acceso a un LLM frontier podrá pedirle "descompilá este archivo `.wasm`
y devolveme el código JavaScript original" y obtener una respuesta plausible.

### Razón 2 — El análisis dinámico ya es accesible

Con WASM todavía joven en herramientas de análisis, pero con avances visibles:

- **wasm2wat** ya descompila bytecode a WebAssembly Text format.
- **wasm-decompile** (Binaryen) reconstruye pseudocódigo C.
- **Ghidra con plugins WASM** (2025+) permite análisis de flujo de control.
- **Frida-wasm** permite hooks en tiempo real en módulos Wasm.

Un analista con estas herramientas + un LLM tiene capacidad de análisis
dinámico sobre AegisWasm hoy. No es trivial, pero es viable.

**Conclusión:** la Capa 1 es universal pero tiene fecha de vencimiento
técnica. El próximo nivel debe empezar a diseñarse antes de que el mercado
lo exija.

---

## 2. El siguiente nivel: Virtualización de Código

Existen cuatro niveles evolutivos posibles sobre AegisWasm v2.1.3. Los
analizamos del más simple al más complejo.

### Nivel A — Rotación de clave por build

**Qué es:** cada build genera una clave XOR distinta.

**Costo:** 20 minutos.
**Ganancia:** cada versión de producción tiene firma única. Bloquea análisis
por patrones estáticos entre versiones.
**Límite:** un atacante que capture una versión igual la rompe en el mismo
tiempo. No detiene análisis. Solo impide diffing.

**Veredicto:** vale la pena como complemento, no como salto.

### Nivel B — Bytecode propietario + VM oculta en Wasm

**Qué es:** el código JavaScript se compila a un **bytecode personalizado**
(no estándar Wasm). Una VM intérprete pequeña, embebida dentro del binario
`.wasm`, es la única que sabe ejecutarlo.

Arquitectura:
```

┌──────────────────────────────────────────────────────────────┐
│  Build time                                                  │
│  JS fuente → Compilador AegisVM → bytecode propietario (.aeg)│
│                                     + tabla de opcodes cifrada│
└──────────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────────┐
│  Runtime (browser)                                           │
│  aegis_engine.wasm contiene:                                 │
│    - Intérprete (loop dispatch)                              │
│    - Tabla de opcodes (cifrada)                              │
│    - Bytecode del usuario (cifrado)                          │
│  El intérprete descifra el bytecode en RAM y lo ejecuta.     │
└──────────────────────────────────────────────────────────────┘

```

**Por qué rompe a los LLMs actuales:**
- El bytecode no se parece a nada que hayan visto.
- No hay "código JavaScript" que desofuscar. Hay instrucciones `0x1A 0x2B`
  que solo tu VM sabe interpretar.
- La IA tendría que emular tu VM para entender qué hace cada byte. Ese es
  un problema de emulación de estado, no de reconocimiento de patrones.
- Si randomizás los opcodes en cada build, cada versión es un idioma único.

**Costo:** 4-8 semanas de desarrollo concentrado.
- Diseño de ISA propietario y compilador JS→bytecode: 2 semanas.
- Implementación de VM intérprete en C++: 2 semanas.
- Cifrado de tabla de opcodes + rotación por build: 1 semana.
- Tests, integración con CLI, documentación: 2-3 semanas.

**Ganancia:** el costo para el atacante sube de **horas a semanas/meses**.
Un LLM sin acceso a la tabla de opcodes no puede hacer nada útil.

**Límite:** análisis dinámico avanzado (hookear el dispatcher con Frida-wasm
y dump del bytecode descifrado en RAM). Requiere instrumentación profesional.

**Veredicto:** **este es el siguiente salto natural.** Es la técnica que usan
protectores comerciales (Themida, VMProtect) para software nativo, adaptada a
WebAssembly.

### Nivel C — VM con mutación por build

**Qué es:** el Nivel B + regeneración completa de la ISA (instruction set)
en cada build.

**Qué cambia:** los opcodes cambian de nombre semántico, orden de bits,
número de operandos. El atacante que rompió la versión de agosto no puede
reutilizar nada para la versión de septiembre.

**Costo:** +1-2 semanas sobre el Nivel B.
**Ganancia:** cada deploy es un binario único que no se parece a ningún otro
AegisWasm del mundo.
**Límite:** mismo que Nivel B. Análisis dinámico sigue siendo viable.
**Veredicto:** refuerzo natural una vez que Nivel B funciona.

### Nivel D — Bytecode + intérprete cifrado en ejecución

**Qué es:** el intérprete de la VM nunca existe completo en RAM. Sus
instrucciones se descifran **solo cuando van a ejecutarse**, y se cifran de
nuevo inmediatamente después. El bytecode del usuario sigue la misma lógica.

**Costo:** +4-6 semanas sobre el Nivel C.
**Ganancia:** incluso con Frida-wasm en el proceso, el atacante no puede
dumpear el intérprete completo de una sola vez. Solo ve un byte a la vez.
**Límite:** latencia. La ejecución se vuelve lenta (10-100x) por el coste de
descifrar/recifrar en cada instrucción.
**Veredicto:** viable solo para código crítico puntual (validaciones,
licencias), no para la app entera.

---

## 3. Tabla comparativa

| Nivel | Costo | Ganancia | Detiene IA actual | Detiene IA 2027 |
|---|---|---|---|---|
| Actual (v2.1.3) | ✅ Hecho | 99% atacantes humanos | ❌ Parcialmente | ❌ No |
| A — Rotación de clave | 20 min | Firmas mutantes | ❌ No | ❌ No |
| B — VM oculta | 4-8 sem | Análisis estático roto | ✅ Sí | ⚠️ Parcialmente |
| C — VM mutante | +1-2 sem | Cada build único | ✅ Sí | ✅ Sí |
| D — VM cifrada en ejecución | +4-6 sem | Análisis dinámico roto | ✅ Sí | ✅ Sí |

---

## 4. Criterios de activación (cuándo construir cada nivel)

La filosofía de AegisWasm prohíbe construir features especulativas.
**Cada nivel se activa solo con evidencia empírica.**

### Nivel A — Rotación de clave

**Criterio:** siempre. Es 20 minutos y suma defensa real sin costo.
**Prioridad:** hacerlo en la próxima iteración activa (v2.2).

### Nivel B — VM oculta

**Criterio de activación (uno de estos):**
1. Un usuario del proyecto reporta que su código fue copiado usando IA.
2. Un cliente enterprise paga por nivel de protección superior.
3. Vloitz (el proyecto actual) enfrenta clones automatizados reales.
4. El manifiesto quiere pasar de "universal" a "enterprise-grade".

**Prioridad:** cuando el criterio se cumpla. Antes, no.

### Nivel C — VM mutante

**Criterio:** el Nivel B está en producción y estable, y hay al menos un
usuario real usándolo.

### Nivel D — VM cifrada en ejecución

**Criterio:** solo para código puntual (validaciones de licencia, firmas),
no para toda la app.

---

## 5. Otras técnicas que NO valen la pena

Lista explícita de técnicas que se han considerado y descartado, con motivo:

| Técnica | Motivo del descarte |
|---|---|
| **AES-GCM vía crypto.subtle** | La llave sigue en el cliente. Un LLM extrae igual. No cambia el modelo de amenaza. |
| **Cifrado asimétrico** | Sin backend, imposible de gestionar. La clave privada debe vivir en el cliente. |
| **Anti-debugging con `debugger`** | Fácilmente evadido. Bloquea al usuario legítimo, no al atacante. |
| **Domain locking estricto** | Rompe tests y previews. Fricción alta, ganancia marginal. |
| **Time-bombs (código que expira)** | Fricción operativa. Los usuarios legítimos ven el código morir. |
| **Ofuscación de JS antes del cifrado** | Incompatible con Terser optimizado. Aumenta peso sin cambiar modelo de amenaza. |

**Regla:** si una técnica no sube el costo del atacante, no se implementa.

---

## 6. Recomendación del mantenedor

Para el estado actual v2.1.3:

1. **Congelar** AegisWasm v2.1.3 como release estable.
2. **Añadir rotación de clave (Nivel A)** en el próximo build, sin cambiar arquitectura. 20 minutos.
3. **Documentar Nivel B** (VM oculta) como el siguiente salto evolutivo, con
   el criterio de activación explícito.
4. **No construir Nivel B hasta que** el criterio de activación se cumpla.
5. **Reevaluar** el modelo de amenaza cada 6 meses. Si los LLMs evolucionan
   más rápido de lo esperado, adelantar el Nivel B.

---

## 7. Reflexión final

La carrera entre ofuscación y análisis es un juego de suma no-cero. Cada salto
en IA redefine el piso mínimo de protección. AegisWasm v2.1.3 es sólido hoy.
El Nivel B lo mantiene sólido en 2027-2028. No existe un nivel final que sea
inmune para siempre.

**La premisa correcta no es "cifrado imposible de romper", sino "protección
comercialmente viable contra el 99.9% de atacantes actuales".** Esa premisa
se sostiene mientras el siguiente salto esté diseñado antes de que el
anterior caduque.

> *"No existe protección absoluta. Existe protección suficiente para que el
> atacante racional elija otro objetivo. Y esa protección se redefine cada
> vez que la tecnología de análisis avanza."*
> — Filosofía de diseño AegisWasm, Nivel Futures
```

---

## 📋 Después de crear el documento

Commit + push:

```cmd
cd /d E:\MASTER\Proyectos\2026\Web\AegisWasm
git add Doc/FUTURES.md
git commit -m "docs: FUTURES.md - Análisis del siguiente salto evolutivo (VM oculta) y criterios de activación"
git push origin main
```

---

## 🎯 Veredicto honesto sobre tu pregunta

**Sí, el siguiente salto es la virtualización de código (Nivel B).** Y sí, está justificado en tu situación por tres razones:

1. **Tu instinto es correcto:** los LLMs ya desofuscan lo que tenés. El plazo real es 12-24 meses antes de que sea trivial.
2. **El costo es real:** 4-8 semanas, no 2 días. Es un proyecto de compiladores, no de scripts.
3. **El timing es correcto:** empezar a diseñarlo **ahora** y construirlo **solo si la demanda aparece**. Si esperás a que el mercado lo pida, ya llegás tarde.

**La diferencia con la Capa 2 (VFS + shims) que descartaste:** esa era sobreingeniería para un TAM del 5%. La VM oculta **no es sobreingeniería** — es la defensa natural contra una amenaza que ya existe y va a empeorar.

**Ese es el verdadero siguiente paso de AegisWasm.** No más bundlers, no más edge runtimes. El siguiente salto es **compilador de bytecode propietario + VM oculta en Wasm**.

---
