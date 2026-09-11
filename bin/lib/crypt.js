'use strict';

// Magic bytes versionados: \0AEGv1\0
// El byte 0x00 de inicio y fin delimita la firma para evitar falsos positivos.
// El "v1" permite introducir v2 (AES-GCM) sin romper versiones anteriores.
const MAGIC_HEADER = Buffer.from([0x00, 0x41, 0x45, 0x47, 0x76, 0x31, 0x00]);

function xorEncrypt(buffer, key) {
    const out = Buffer.allocUnsafe(buffer.length);
    for (let i = 0; i < buffer.length; i++) out[i] = buffer[i] ^ key;
    return out;
}

function sealBuffer(buffer, key) {
    return Buffer.concat([MAGIC_HEADER, xorEncrypt(buffer, key)]);
}

function isSealed(buffer) {
    if (buffer.length < MAGIC_HEADER.length) return false;
    for (let i = 0; i < MAGIC_HEADER.length; i++) {
        if (buffer[i] !== MAGIC_HEADER[i]) return false;
    }
    return true;
}

module.exports = {
    MAGIC_HEADER,
    xorEncrypt,
    sealBuffer,
    isSealed
};