'use strict';

const supportsColor = process.stdout.isTTY && process.env.NO_COLOR === undefined;

function wrap(code) {
    return (text) => supportsColor ? `\x1b[${code}m${text}\x1b[0m` : String(text);
}

const colors = {
    red: wrap('31'),
    green: wrap('32'),
    yellow: wrap('33'),
    blue: wrap('34'),
    magenta: wrap('35'),
    cyan: wrap('36'),
    gray: wrap('90'),
    bold: wrap('1')
};

module.exports = {
    colors
};