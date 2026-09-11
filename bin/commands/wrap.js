'use strict';

const fs = require('fs');
const path = require('path');

const {
    colors
} = require('../lib/colors');
const {
    loadConfig,
    isExcluded
} = require('../lib/config');
const {
    sealBuffer,
    isSealed,
    MAGIC_HEADER
} = require('../lib/crypt');
const {
    walk
} = require('../lib/walker');
const {
    scanHtml
} = require('../lib/html-scanner');
const {
    applyBootloader
} = require('../lib/html-injector');
const {
    buildSwRuntime
} = require('../templates/aegis-sw-runtime');

async function run(args) {
    const opts = {
        target: null,
        legacy: false,
        dryRun: false,
        debug: false
    };

    for (const arg of args) {
        if (arg === '--legacy') opts.legacy = true;
        else if (arg === '--dry-run') opts.dryRun = true;
        else if (arg === '--debug') opts.debug = true;
        else if (!arg.startsWith('--')) opts.target = arg;
    }

    if (!opts.target) throw new Error('Falta el directorio target. Uso: aegis wrap <target>');

    const targetDir = path.resolve(opts.target);
    if (!fs.existsSync(targetDir)) throw new Error(`El directorio target no existe: ${targetDir}`);

    console.log(`${colors.cyan('=================================================')}`);
    console.log(`${colors.cyan('  🛡️  AegisWasm - Wrap (Fase 2: Bootloader)     ')}`);
    console.log(`${colors.cyan('=================================================')}\n`);

    console.log(`${colors.gray('Target:')}   ${targetDir}`);
    console.log(`${colors.gray('Modo:')}     ${opts.legacy ? 'legacy (XOR plano, sin bootloader)' : 'v2 (XOR + Magic Bytes + Bootloader)'}`);
    console.log(`${colors.gray('Dry-run:')}  ${opts.dryRun ? 'sí' : 'no'}\n`);

    const config = loadConfig(targetDir);
    if (config.configPath) {
        console.log(`${colors.green('✓')} Config cargada: ${colors.gray(config.configPath)}`);
    } else {
        console.log(`${colors.yellow('⚠')} Sin aegis.config.json — usando defaults`);
    }
    const xorKey = config.xor_key;
    console.log(`${colors.gray('  XOR key:')} ${xorKey}\n`);

    const startTime = Date.now();

    // ─── 1. Escaneo de .js elegibles ───
    const jsFiles = walk(targetDir, (abs, rel) => {
        if (!rel.endsWith('.js')) return false;
        if (isExcluded(rel, config.exclude)) return false;
        return true;
    });

    console.log(`${colors.yellow('📦 Escaneando .js elegibles...')}`);
    console.log(`   Encontrados: ${jsFiles.length} archivos\n`);

    // ─── 2. Escaneo de HTML (solo reporte) ───
    const htmlFile = path.join(targetDir, 'index.html');
    let htmlReport = null;
    if (fs.existsSync(htmlFile)) {
        htmlReport = scanHtml(fs.readFileSync(htmlFile, 'utf-8'));
        console.log(`${colors.yellow('📄 Escaneando index.html (reporte)...')}`);
        console.log(`   <script type="module" src>:     ${htmlReport.moduleScripts.length}`);
        console.log(`   <link rel="modulepreload">:     ${htmlReport.modulepreloads.length}`);
        console.log(`   <link rel="preload" as=script>: ${htmlReport.preloadScripts.length}`);
        console.log(`   <script type="module"> inline:  ${htmlReport.inlineModules}`);
        console.log(`   <script type="importmap">:      ${htmlReport.importMaps}`);
        console.log(`   Total detectado:                ${htmlReport.totalTags}\n`);
    } else {
        console.log(`${colors.yellow('⚠')} No se encontró index.html\n`);
    }

    // ─── 3. Cifrado in-place ───
    console.log(`${colors.yellow('🔒 Cifrando chunks in-place...')}`);

    let bytesBefore = 0,
        bytesAfter = 0,
        skipped = 0,
        processed = 0;
    const processedList = [];
    const encryptedBasenames = new Set();

    for (const file of jsFiles) {
        const before = fs.statSync(file.abs).size;
        const buf = fs.readFileSync(file.abs);

        if (!opts.legacy && isSealed(buf)) {
            skipped++;
            encryptedBasenames.add(path.basename(file.rel));
            continue;
        }

        const sealed = sealBuffer(buf, xorKey);
        const after = sealed.length;

        if (!opts.dryRun) fs.writeFileSync(file.abs, sealed);

        bytesBefore += before;
        bytesAfter += after;
        processed++;
        encryptedBasenames.add(path.basename(file.rel));
        processedList.push({
            rel: file.rel,
            before,
            after
        });

        if (opts.debug) {
            console.log(`   ${colors.green('🔒')} ${file.rel} (${before} → ${after})`);
        }
    }

    console.log(`   Procesados: ${processed}, saltados: ${skipped}\n`);

    // ─── 4. Bootloader del HTML (solo en modo v2) ───
    let bootStats = null;
    if (!opts.legacy && htmlReport && htmlReport.totalTags > 0) {
        console.log(`${colors.yellow('🚀 Aplicando Bootloader al HTML...')}`);

        const originalHtml = fs.readFileSync(htmlFile, 'utf-8');
        const result = applyBootloader(originalHtml, encryptedBasenames);
        bootStats = result.stats;

        if (bootStats.alreadyWrapped) {
            console.log(`   ${colors.gray('·')} HTML ya estaba envuelto (idempotencia). Skip.`);
        } else if (bootStats.tagsExtracted === 0) {
            console.log(`   ${colors.yellow('⚠')} Scanner detectó ${htmlReport.totalTags} tags pero el injector extrajo 0.`);
            console.log(`   ${colors.gray('·')} Causa probable: tags no apuntan a archivos cifrados, o el regex falló.`);
            console.log(`   ${colors.gray('·')} Bootloader NO aplicado.`); // Explícito
        } else {
            if (!opts.dryRun) fs.writeFileSync(htmlFile, result.html, 'utf-8');
            console.log(`   ${colors.green('✓')} ${bootStats.tagsExtracted} tags extraídos e inyectados al bootloader.`);
        }
        console.log('');
    } else if (opts.legacy) {
        console.log(`${colors.gray('·')} Modo legacy: HTML sin modificar.\n`);
    } else if (htmlReport && htmlReport.totalTags === 0) {
        console.log(`${colors.gray('·')} Sin tags elegibles en index.html (proyecto sin módulos ESM).\n`);
    }

    // ─── 5. Generar SW Runtime con Magic Bytes ───
    let swEmitted = false;
    if (!opts.legacy) {
        console.log(`${colors.yellow('🌐 Generando Service Worker runtime...')}`);

        const magicHex = Array.from(MAGIC_HEADER)
            .map(b => '0x' + b.toString(16).padStart(2, '0'))
            .join(', ');
        const swCode = buildSwRuntime({
            xorKey: xorKey,
            magicHex: magicHex
        });

        const swPath = path.join(targetDir, 'aegis-sw-runtime.js');
        if (!opts.dryRun) fs.writeFileSync(swPath, swCode, 'utf-8');

        console.log(`   ${colors.green('✓')} aegis-sw-runtime.js escrito (${swCode.length} bytes).`);
        swEmitted = true;
        console.log('');
    }

    const elapsed = Date.now() - startTime;

    // ─── Reporte final ───
    console.log(`${colors.cyan('=================================================')}`);
    console.log(`${colors.green('✓ Wrap completado')}`);
    console.log(`${colors.cyan('=================================================')}`);
    console.log(`  Archivos cifrados:     ${processed}`);
    if (skipped > 0) console.log(`  Ya sellados (skip):    ${skipped}`);
    if (bootStats) {
        console.log(`  HTML tags extraídos:   ${bootStats.tagsExtracted}`);
        console.log(`  HTML ya envuelto:      ${bootStats.alreadyWrapped ? 'sí' : 'no'}`);
    }
    if (swEmitted) {
        console.log(`  Service Worker:        aegis-sw-runtime.js`);
    }
    console.log(`  Bytes antes:           ${bytesBefore.toLocaleString()}`);
    console.log(`  Bytes después:         ${bytesAfter.toLocaleString()}`);
    const delta = bytesAfter - bytesBefore;
    console.log(`  Delta cifrado:         ${delta >= 0 ? '+' : ''}${delta} bytes`);
    console.log(`  Tiempo:                ${elapsed} ms`);
    console.log(`  Magic header:          ${colors.gray(MAGIC_HEADER.toString('hex'))}`);
    console.log(`  Modo:                  ${opts.dryRun ? 'DRY-RUN' : 'escritura real'}`);
    console.log(`${colors.cyan('=================================================')}\n`);

    if (opts.debug && processedList.length > 0) {
        console.log(`${colors.gray('Archivos procesados:')}`);
        processedList.forEach(f => console.log(`  ${colors.gray('·')} ${f.rel}  ${f.before} → ${f.after}`));
        console.log('');
    }

    console.log(`${colors.yellow('💡 Próximos pasos:')}`);
    console.log(`   Fase 3: SW Adapter leerá los Magic Bytes y descifrará chunks on-demand.`);
    console.log(`   Fase 5: ${colors.green('aegis preview ' + opts.target)} para test local.\n`);
}

module.exports = {
    run
};