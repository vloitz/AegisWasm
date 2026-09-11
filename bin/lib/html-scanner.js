'use strict';

// Escáner tolerante (sin DOM parser) para reportar qué tags hay que
// reemplazar en Fase 2. NO muta nada.

const RE_SCRIPT_SRC = /<script\b([^>]*?)\bsrc\s*=\s*["']([^"']+)["']([^>]*?)>/gi;
const RE_LINK_TAG = /<link\b([^>]*?)\bhref\s*=\s*["']([^"']+)["']([^>]*?)>/gi;
const RE_REL_MODULEPRELOAD = /\brel\s*=\s*["']modulepreload["']/i;
const RE_REL_PRELOAD = /\brel\s*=\s*["']preload["']/i;
const RE_AS_SCRIPT = /\bas\s*=\s*["']script["']/i;
const RE_INLINE_MODULE = /<script\b[^>]*\btype\s*=\s*["']module["'][^>]*>([\s\S]*?)<\/script>/gi;
const RE_IMPORTMAP = /<script\b[^>]*\btype\s*=\s*["']importmap["'][^>]*>([\s\S]*?)<\/script>/gi;

function scanHtml(html) {
    const report = {
        moduleScripts: [],
        modulepreloads: [],
        preloadScripts: [],
        inlineModules: 0,
        importMaps: 0,
        totalTags: 0
    };

    let match;

    RE_SCRIPT_SRC.lastIndex = 0;
    while ((match = RE_SCRIPT_SRC.exec(html)) !== null) {
        const attrs = (match[1] + ' ' + match[3]);
        const src = match[2];
        if (/\btype\s*=\s*["']module["']/i.test(attrs)) {
            report.moduleScripts.push(src);
            report.totalTags++;
        }
    }

    RE_LINK_TAG.lastIndex = 0;
    while ((match = RE_LINK_TAG.exec(html)) !== null) {
        const attrs = (match[1] + ' ' + match[3]);
        const href = match[2];
        if (RE_REL_MODULEPRELOAD.test(attrs)) {
            report.modulepreloads.push(href);
            report.totalTags++;
        } else if (RE_REL_PRELOAD.test(attrs) && RE_AS_SCRIPT.test(attrs)) {
            report.preloadScripts.push(href);
            report.totalTags++;
        }
    }

    RE_INLINE_MODULE.lastIndex = 0;
    while ((match = RE_INLINE_MODULE.exec(html)) !== null) {
        if (!/\bsrc\s*=/i.test(match[0])) {
            report.inlineModules++;
            report.totalTags++;
        }
    }

    RE_IMPORTMAP.lastIndex = 0;
    while ((match = RE_IMPORTMAP.exec(html)) !== null) {
        report.importMaps++;
        report.totalTags++;
    }

    return report;
}

module.exports = {
    scanHtml
};