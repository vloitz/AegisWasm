'use strict';

const {
    colors
} = require('../lib/colors');

async function run(args) {
    const target = args.find(a => !a.startsWith('--'));
    if (!target) throw new Error('Falta el directorio target. Uso: aegis preview <target>');

    console.log(`${colors.yellow('⚠')} El comando preview se implementará en la Fase 5 del roadmap.`);
    console.log(`${colors.gray('   Por ahora, usa cualquier servidor estático apuntando a:')} ${target}\n`);
}

module.exports = {
    run
};