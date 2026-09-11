'use strict';

const fs = require('fs');
const path = require('path');

const DEFAULT_CONFIG = {
    xor_key: 90,
    encrypt_pattern: '**/*.js',
    exclude: [
        'sw.js',
        'aegis-sw-adapter.js',
        'aegis-sdk.js',
        'aegis.manifest.json',
        'bin/**',
        '**/*.map'
    ]
};

function loadConfig(targetDir) {
    const candidates = [
        path.join(targetDir, 'aegis.config.json'),
        path.join(path.dirname(targetDir), 'aegis.config.json'),
        path.join(process.cwd(), 'aegis.config.json')
    ];

    for (const configPath of candidates) {
        if (fs.existsSync(configPath)) {
            try {
                const raw = fs.readFileSync(configPath, 'utf-8');
                const parsed = JSON.parse(raw);
                return {
                    configPath,
                    ...DEFAULT_CONFIG,
                    ...parsed
                };
            } catch (err) {
                throw new Error(`No se pudo leer ${configPath}: ${err.message}`);
            }
        }
    }

    return {
        configPath: null,
        ...DEFAULT_CONFIG
    };
}

function matchGlob(filePath, pattern) {
    const regexStr = pattern
        .replace(/\./g, '\\.')
        .replace(/\*\*/g, '@@DS@@')
        .replace(/\*/g, '[^/]*')
        .replace(/@@DS@@/g, '.*');
    const regex = new RegExp(`^${regexStr}$`);
    return regex.test(filePath) || regex.test(filePath.split('/').pop());
}

function isExcluded(relativePath, excludePatterns) {
    const normalized = relativePath.replace(/\\/g, '/');
    return excludePatterns.some(p => matchGlob(normalized, p));
}

module.exports = {
    loadConfig,
    isExcluded,
    matchGlob,
    DEFAULT_CONFIG
};