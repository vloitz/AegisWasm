// test-fixtures.js
// Test de AegisWasm CLI contra HTML output de distintos bundlers.
// Uso: node test-fixtures.js

'use strict';

const {
    extractTags
} = require('./bin/lib/html-injector');

const fixtures = {

    'vite': `
        <!doctype html>
        <html>
        <head>
            <link rel="stylesheet" crossorigin href="/assets/index-abc.css">
            <script type="module" crossorigin src="/assets/index-abc.js"></script>
        </head>
        <body><div id="app"></div></body>
        </html>
    `,

    'webpack-defer': `
        <!doctype html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>Webpack</title>
            <script defer src="bundle.js"></script>
        </head>
        <body><div id="app"></div></body>
        </html>
    `,

    'webpack-module': `
        <!doctype html>
        <html>
        <head>
            <script type="module" src="bundle.js"></script>
        </head>
        <body></body>
        </html>
    `,

    'next-js': `
        <!doctype html>
        <html>
        <head>
            <link rel="preload" as="script" href="/_next/static/chunks/main-abc.js" crossorigin="anonymous">
            <script src="/_next/static/chunks/main-abc.js" async=""></script>
        </head>
        <body><div id="__next"></div></body>
        </html>
    `,

    'parcel': `
        <!doctype html>
        <html>
        <head>
            <script type="module" src="/src.abc123.js"></script>
        </head>
        <body><div id="app"></div></body>
        </html>
    `,

    'rollup-html-plugin': `
        <!doctype html>
        <html>
        <head>
            <script type="module" src="/bundle.js"></script>
            <link rel="modulepreload" href="/chunk-abc.js">
        </head>
        <body></body>
        </html>
    `,

    'nuxt': `
        <!doctype html>
        <html>
        <head>
            <link rel="modulepreload" href="/_nuxt/vendor-abc.js" as="script" crossorigin>
            <script type="module" src="/_nuxt/entry-abc.js" crossorigin></script>
        </head>
        <body><div id="__nuxt"></div></body>
        </html>
    `

};

// Set de basenames que estarían "cifrados" por el CLI
const encryptedBasenames = new Set([
    'index-abc.js',
    'bundle.js',
    'main-abc.js',
    'src.abc123.js',
    'chunk-abc.js',
    'vendor-abc.js',
    'entry-abc.js'
]);

console.log('==============================================');
console.log('  AegisWasm CLI — Fixture Test (Ruta B)');
console.log('==============================================\n');

let passed = 0;
let failed = 0;

for (const [name, html] of Object.entries(fixtures)) {
    const {
        tags
    } = extractTags(html, encryptedBasenames);

    if (tags.length === 0) {
        console.log(`❌ [${name}]  0 tags extraídos`);
        failed++;
    } else {
        console.log(`✅ [${name}]  ${tags.length} tag(s):`);
        tags.forEach(t => {
            const detail = t.src ? t.src : (t.attrs.href || '(inline)');
            console.log(`     kind=${t.kind}  ->  ${detail}`);
        });
        passed++;
    }
    console.log('');
}

console.log('==============================================');
console.log(`Resultado: ${passed} OK / ${failed} FAIL`);
console.log('==============================================');