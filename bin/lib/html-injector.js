'use strict';

const fs = require('fs');
const path = require('path');

// Marcador de idempotencia: si está en el HTML, ya fue procesado.
const MARKER_COMMENT = '<!-- AegisWasm Bootloader v1 -->';
const MARKER_ATTR = 'data-aegis-wrapped';

/**
 * Extrae los tags relevantes del HTML en orden de aparición.
 * Solo extrae tags cuyo `src`/`href` apunte a un archivo en `encryptedSet`.
 *
 * @param {string} html - HTML completo
 * @param {Set<string>} encryptedBasenames - Basenames de archivos cifrados
 * @returns {{ tags: Array, removedRanges: Array<{start:number,end:number}> }}
 */
function extractTags(html, encryptedBasenames) {
    const tags = [];
    const removedRanges = [];

    const SCRIPT_REGEX = /<script\b([^>]*?)>([\s\S]*?)<\/script>/gi;
    const LINK_REGEX = /<link\b([^>]*?)\/?>/gi;

    let match;

    while ((match = SCRIPT_REGEX.exec(html)) !== null) {
        const full = match[0];
        const attrs = parseAttrs(match[1]);
        const content = match[2] || '';
        const start = match.index;
        const end = start + full.length;

        const isModule = (attrs.type || '').toLowerCase() === 'module';
        const isImportMap = (attrs.type || '').toLowerCase() === 'importmap';
        const hasSrc = typeof attrs.src === 'string';

        if (isImportMap) {
            tags.push({ kind: 'importmap', attrs: {}, content: content, order: start });
            removedRanges.push({ start, end });
            continue;
        }

        if (hasSrc) {
            const srcBase = basename(attrs.src);
            if (!encryptedBasenames.has(srcBase)) continue;
            tags.push({ kind: 'external-script', attrs: attrs, src: attrs.src, order: start });
            removedRanges.push({ start, end });
            continue;
        }

        if (isModule && !hasSrc) {
            tags.push({
                kind: 'inline-script',
                attrs: { type: 'module' },
                content: content,
                order: start
            });
            removedRanges.push({ start, end });
        }
    }

    while ((match = LINK_REGEX.exec(html)) !== null) {
        const full = match[0];
        const attrs = parseAttrs(match[1]);
        const start = match.index;
        const end = start + full.length;

        const rel = (attrs.rel || '').toLowerCase();
        const as = (attrs.as || '').toLowerCase();
        const href = attrs.href || '';

        if (rel === 'modulepreload') {
            const srcBase = basename(href);
            if (!encryptedBasenames.has(srcBase)) continue;
            tags.push({ kind: 'external-link', attrs: attrs, order: start });
            removedRanges.push({ start, end });
            continue;
        }
        if (rel === 'preload' && as === 'script') {
            const srcBase = basename(href);
            if (!encryptedBasenames.has(srcBase)) continue;
            tags.push({ kind: 'external-link', attrs: attrs, order: start });
            removedRanges.push({ start, end });
        }
    }

    tags.sort((a, b) => a.order - b.order);
    return { tags, removedRanges };
}

function parseAttrs(raw) {
    const attrs = {};
    const RE = /([a-zA-Z_:][a-zA-Z0-9_:.-]*)\s*(?:=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'=<>`]+)))?/g;
    let m;
    while ((m = RE.exec(raw)) !== null) {
        const name = m[1];
        const value = m[2] !== undefined ? m[2] :
            m[3] !== undefined ? m[3] :
            m[4] !== undefined ? m[4] : '';
        attrs[name] = value;
    }
    return attrs;
}

function basename(urlPath) {
    if (!urlPath) return '';
    const clean = urlPath.split('?')[0].split('#')[0];
    return clean.split('/').pop();
}

function removeRanges(html, ranges) {
    const sorted = [...ranges].sort((a, b) => b.start - a.start);
    let out = html;
    for (const r of sorted) {
        out = out.slice(0, r.start) + out.slice(r.end);
    }
    return out;
}

function buildBootloaderScript(tags) {
    const payload = JSON.stringify(tags).replace(/<\/script>/gi, '<\\/script>');
    return `
(function () {
    'use strict';
    var TAGS = ${payload};
    var REINJECTED = false;

    function createElementForTag(tag) {
        var el;
        if (tag.kind === 'importmap') {
            el = document.createElement('script');
            el.type = 'importmap';
            el.textContent = tag.content;
            return el;
        }
        if (tag.kind === 'external-script' || tag.kind === 'inline-script') {
            el = document.createElement('script');
            if (tag.kind === 'inline-script') {
                el.type = tag.attrs.type || 'module';
                el.textContent = tag.content;
            } else {
                Object.keys(tag.attrs).forEach(function (k) {
                    el.setAttribute(k, tag.attrs[k]);
                });
            }
            return el;
        }
        if (tag.kind === 'external-link') {
            el = document.createElement('link');
            Object.keys(tag.attrs).forEach(function (k) {
                el.setAttribute(k, tag.attrs[k]);
            });
            return el;
        }
        return null;
    }

    function reinject() {
        if (REINJECTED) return;
        REINJECTED = true;

        var importmaps = TAGS.filter(function (t) { return t.kind === 'importmap'; });
        var rest = TAGS.filter(function (t) { return t.kind !== 'importmap'; });

        importmaps.forEach(function (t) {
            var el = createElementForTag(t);
            if (el) document.head.appendChild(el);
        });

        rest.forEach(function (t) {
            var el = createElementForTag(t);
            if (el) document.head.appendChild(el);
        });

        console.log('[AegisWasm] Bootloader: ' + TAGS.length + ' tags reinjectados.');
    }

    function fallbackReinject(err) {
        console.warn('[AegisWasm] Service Worker no disponible, reinyectando de todas formas:', err);
        reinject();
    }

    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.register('/aegis-sw-runtime.js', { scope: '/' })
            .then(function () {
                console.log('[AegisWasm] SW runtime registrado.');
                return navigator.serviceWorker.ready;
            })
            .then(reinject)
            .catch(fallbackReinject);
    } else {
        fallbackReinject('navigator.serviceWorker no soportado');
    }
})();
`.trim();
}

/**
 * Aplica el bootloader al HTML.
 * @returns {{ html: string, stats: { tagsExtracted: number, alreadyWrapped: boolean } }}
 */
function applyBootloader(html, encryptedBasenames) {
    if (html.includes(MARKER_ATTR)) {
        return {
            html,
            stats: { tagsExtracted: 0, alreadyWrapped: true }
        };
    }

    const { tags, removedRanges } = extractTags(html, encryptedBasenames);

    if (tags.length === 0) {
        return {
            html,
            stats: { tagsExtracted: 0, alreadyWrapped: false }
        };
    }

    const withoutTags = removeRanges(html, removedRanges);
    const bootloader = buildBootloaderScript(tags);

    const block =
        '\n' + MARKER_COMMENT + '\n' +
        '<script ' + MARKER_ATTR + '="1">\n' + bootloader + '\n</script>\n';

    // Estrategia de inyección por prioridad:
    //   1. Si existe <head>: inyectar justo después de su apertura.
    //   2. Si no hay <head> pero sí <!DOCTYPE>: inyectar justo después del doctype
    //      (Parcel 2 emite HTML sin <head>, con el doctype seguido del contenido).
    //   3. Fallback extremo: inyectar al inicio.
    const headOpen = /<head\b[^>]*>/i;
    const headMatch = withoutTags.match(headOpen);

    let out;
    if (headMatch) {
        const insertAt = headMatch.index + headMatch[0].length;
        out = withoutTags.slice(0, insertAt) + block + withoutTags.slice(insertAt);
    } else {
        const doctypeMatch = withoutTags.match(/<!DOCTYPE[^>]*>/i);
        if (doctypeMatch) {
            const insertAt = doctypeMatch.index + doctypeMatch[0].length;
            out = withoutTags.slice(0, insertAt) + block + withoutTags.slice(insertAt);
        } else {
            out = block + withoutTags;
        }
    }

    return {
        html: out,
        stats: { tagsExtracted: tags.length, alreadyWrapped: false }
    };
}

module.exports = {
    applyBootloader,
    extractTags
};