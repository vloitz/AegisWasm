#!/usr/bin/env node

'use strict';

const {
    colors
} = require('./lib/colors');

const COMMANDS = {
    wrap: () => require('./commands/wrap'),
    preview: () => require('./commands/preview')
};

function showHelp() {
    console.log(`
${colors.cyan('🛡️  AegisWasm CLI')} ${colors.gray('v2.0.0-skeleton')}

${colors.bold('Uso:')}
  aegis <comando> [target] [opciones]

${colors.bold('Comandos:')}
  ${colors.green('wrap')} <target>     Cifra chunks JS in-place y reporta métricas
                       Opciones: --legacy (XOR plano, sin Magic Bytes)
                                 --dry-run (no escribe, solo reporta)
                                 --debug (listado por archivo)
  ${colors.green('preview')} <target>  Levanta un servidor local con SW activo (Fase 5)
  ${colors.green('help')}              Muestra esta ayuda

${colors.bold('Ejemplos:')}
  aegis wrap ./dist
  aegis wrap ./dist --dry-run
  aegis wrap ./dist --legacy
`);
}

function main() {
    const args = process.argv.slice(2);

    if (args.length === 0 || args[0] === 'help' || args[0] === '--help' || args[0] === '-h') {
        showHelp();
        process.exit(0);
    }

    const commandName = args[0];
    const loader = COMMANDS[commandName];

    if (!loader) {
        console.error(colors.red(`❌ Comando desconocido: "${commandName}"`));
        console.error(colors.gray(`   Usa "aegis help" para ver los comandos disponibles.`));
        process.exit(1);
    }

    const command = loader();
    command.run(args.slice(1)).catch(err => {
        console.error(colors.red(`\n❌ Error en "${commandName}": ${err.message}`));
        if (process.env.AEGIS_DEBUG) console.error(err.stack);
        process.exit(1);
    });
}

main();