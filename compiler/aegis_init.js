const fs = require('fs');
const path = require('path');

// Carpetas que el motor debe ignorar por defecto para no perder tiempo
const IGNORE_DIRS = ['.git', 'node_modules', '.vscode', 'bin', 'compiler', 'core'];

// Colores para la terminal
const C_RESET = "\x1b[0m";
const C_RED = "\x1b[31m";
const C_YELLOW = "\x1b[33m";
const C_GREEN = "\x1b[32m";
const C_CYAN = "\x1b[36m";

console.log(`${C_CYAN}=================================================${C_RESET}`);
console.log(`${C_CYAN}  🛡️  AegisWasm - Auditor de Proyecto (Fase 0)  ${C_RESET}`);
console.log(`${C_CYAN}=================================================${C_RESET}\n`);

// 1. Escáner recursivo de archivos
function scanDirectory(dir, fileList = []) {
    if (!fs.existsSync(dir)) return fileList;

    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        const stat = fs.statSync(fullPath);

        if (stat.isDirectory()) {
            if (!IGNORE_DIRS.includes(file)) {
                scanDirectory(fullPath, fileList);
            }
        } else if (fullPath.endsWith('.js')) {
            fileList.push(fullPath);
        }
    }
    return fileList;
}

// 2. Motor de Clasificación Heurística
function auditFiles(files) {
    const report = {
        red: [], // Intocables (Service Workers)
        yellow: [], // Requieren Revisión (Web Workers, Cargas Dinámicas)
        green: [] // Seguros para cifrar
    };

    files.forEach(file => {
        const fileName = path.basename(file).toLowerCase();
        const content = fs.readFileSync(file, 'utf-8');

        // REGLA ROJA: Service Workers nativos (por nombre o contenido)
        if (fileName.includes('sw.js') || fileName.includes('service-worker') || content.includes('self.addEventListener(\'fetch\'')) {
            report.red.push(file);
            return;
        }

        // REGLA AMARILLA: Web Workers o importaciones dinámicas
        if (fileName.includes('worker') || content.includes('new Worker') || content.includes('importScripts') || content.includes('import(')) {
            report.yellow.push(file);
            return;
        }

        // REGLA VERDE: Lógica estándar sin hilos ni bloqueos de red
        report.green.push(file);
    });

    return report;
}

// 3. Ejecución principal
const targetDir = process.argv[2] || process.cwd(); // Usa el dir actual o el pasado por argumento
console.log(`🔍 Analizando directorio: ${targetDir}...\n`);

const allJsFiles = scanDirectory(targetDir);
const auditResult = auditFiles(allJsFiles);

// 4. Impresión del Reporte Determinista
console.log(`${C_RED}🔴 ZONA ROJA (Bloqueo Físico Obligatorio - Excluidos del cifrado):${C_RESET}`);
if (auditResult.red.length === 0) console.log(`   Ninguno detectado.`);
auditResult.red.forEach(f => console.log(`   - ${f}`));

console.log(`\n${C_YELLOW}🟡 ZONA AMARILLA (Revisión Humana Requerida - Hilos / Dinámicos):${C_RESET}`);
if (auditResult.yellow.length === 0) console.log(`   Ninguno detectado.`);
auditResult.yellow.forEach(f => console.log(`   - ${f}`));

console.log(`\n${C_GREEN}🟢 ZONA VERDE (Seguros para AegisWasm - Lógica estándar):${C_RESET}`);
if (auditResult.green.length === 0) console.log(`   Ninguno detectado.`);
auditResult.green.forEach(f => console.log(`   - ${f}`));

// 5. Generación del Archivo de Contrato (aegis.config.json)
const configPath = path.join(process.cwd(), 'aegis.config.json');
const configData = {
    _comment: "AegisWasm Config File. Mueve los archivos de 'require_review' a 'encrypt' o 'exclude' según tu criterio.",
    encrypt: auditResult.green.map(f => f.replace(/\\/g, '/')),
    exclude: auditResult.red.map(f => f.replace(/\\/g, '/')),
    require_review: auditResult.yellow.map(f => f.replace(/\\/g, '/')),
    options: {
        xor_key: 90, // 0x5A
        out_dir: "./dist"
    }
};

fs.writeFileSync(configPath, JSON.stringify(configData, null, 4));

console.log(`\n${C_CYAN}✅ Auditoría finalizada. Se ha generado el contrato inicial en: ${configPath}${C_RESET}`);
console.log(`⚠️  Por favor, abre 'aegis.config.json' y decide qué hacer con los archivos de la Zona Amarilla antes de compilar.\n`);