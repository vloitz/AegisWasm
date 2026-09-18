// serve-static.js - Minimal static file server (no dependencies)
// Usage: node serve-static.js [port] [root]

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = parseInt(process.argv[2] || '8080', 10);
const ROOT = path.resolve(process.argv[3] || process.cwd());

const MIME = {
    '.html': 'text/html; charset=utf-8',
    '.htm':  'text/html; charset=utf-8',
    '.js':   'application/javascript; charset=utf-8',
    '.mjs':  'application/javascript; charset=utf-8',
    '.css':  'text/css; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.xml':  'application/xml; charset=utf-8',
    '.txt':  'text/plain; charset=utf-8',
    '.md':   'text/markdown; charset=utf-8',
    '.png':  'image/png',
    '.jpg':  'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif':  'image/gif',
    '.svg':  'image/svg+xml',
    '.webp': 'image/webp',
    '.ico':  'image/x-icon',
    '.wasm': 'application/wasm',
    '.woff': 'font/woff',
    '.woff2': 'font/woff2',
    '.ttf':  'font/ttf',
    '.mp4':  'video/mp4',
    '.webm': 'video/webm',
    '.mp3':  'audio/mpeg',
    '.wav':  'audio/wav'
};

const server = http.createServer((req, res) => {
    let urlPath;
    try {
        urlPath = decodeURIComponent(req.url.split('?')[0]);
    } catch (e) {
        res.writeHead(400); res.end('400 Bad Request'); return;
    }

    if (urlPath === '/') urlPath = '/index.html';

    const filePath = path.resolve(path.join(ROOT, urlPath));

    // Bloqueo de path traversal
    if (!filePath.startsWith(ROOT)) {
        res.writeHead(403); res.end('403 Forbidden'); return;
    }

    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
            res.end('404 Not Found: ' + urlPath);
            return;
        }
        const ext = path.extname(filePath).toLowerCase();
        res.writeHead(200, {
            'Content-Type': MIME[ext] || 'application/octet-stream',
            'Cache-Control': 'no-cache'
        });
        res.end(data);
    });
});

server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
        console.error('[ERROR] Port ' + PORT + ' is already in use.');
        process.exit(1);
    }
    console.error('[ERROR] ' + err.message);
    process.exit(1);
});

server.listen(PORT, '127.0.0.1', () => {
    console.log('');
    console.log('  Serving ' + ROOT);
    console.log('  -> http://localhost:' + PORT + '/');
    console.log('');
    console.log('  Press Ctrl+C to stop');
    console.log('');
});