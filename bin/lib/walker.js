'use strict';

const fs = require('fs');
const path = require('path');

function walk(dir, predicate) {
    const results = [];

    function recurse(currentDir) {
        const entries = fs.readdirSync(currentDir, {
            withFileTypes: true
        });
        for (const entry of entries) {
            const abs = path.join(currentDir, entry.name);
            const rel = path.relative(dir, abs).replace(/\\/g, '/');
            if (entry.isDirectory()) {
                recurse(abs);
            } else if (entry.isFile()) {
                if (predicate(abs, rel)) results.push({
                    abs,
                    rel
                });
            }
        }
    }

    if (fs.existsSync(dir)) recurse(dir);
    return results;
}

module.exports = {
    walk
};