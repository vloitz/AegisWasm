# {{PROJECT_NAME}}

Proyecto inicializado con `forge.cmd`.

## Estructura

- `forge.cmd` - Menu interactivo + CLI
- `.forge/` - Infraestructura (helpers, templates, lib)

## Comandos

### CLI directo

    forge           Menu interactivo
    forge save      Commit de cambios
    forge push      Push a GitHub
    forge log       Ver commits recientes
    forge snap      Crear/restaurar snapshots
    forge audit     Generar reporte diff
    forge open      Abrir en VS Code
    forge help      Ayuda completa

### Helper scripts en .forge/commands/

- save.cmd - Commit
- push.cmd - Push a GitHub
- snapshots.cmd - Backups
- historial.cmd - Log
- auditar.cmd - Reportes
- abrir.cmd - VS Code

---

Generado por forge-git v{{FG_VERSION}}