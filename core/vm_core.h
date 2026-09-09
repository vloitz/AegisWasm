#ifndef VM_CORE_H
#define VM_CORE_H

#include <stdint.h>
#include <stddef.h>

// Conjunto de instrucciones ampliado (Advanced ISA)
typedef enum {
    OP_HALT   = 0x00,
    OP_PUSH   = 0x01,
    OP_POP    = 0x02,
    OP_ADD    = 0x03,
    OP_SUB    = 0x04,
    OP_MUL    = 0x05,
    OP_DIV    = 0x06,
    OP_LOAD   = 0x07, // Cargar variable desde la memoria local
    OP_STORE  = 0x08, // Guardar en memoria local
    OP_JMP    = 0x09, // Salto incondicional
    OP_JZ     = 0x0A, // Salto si es cero
    OP_RET    = 0x0B
} Opcode;

// Estructura de estado ampliada para la Micro-VM Sandbox
typedef struct {
    uint8_t* bytecode;
    size_t bytecode_length;
    size_t ip; // Instruction Pointer
    int32_t stack[512];
    int sp; // Stack Pointer
    int32_t memory[64]; // Memoria local aislada para variables de la aplicación
} MicroVM;

#ifdef __cplusplus
extern "C" {
#endif

    void vm_init(MicroVM* vm, uint8_t* code, size_t length);
    int32_t vm_execute(MicroVM* vm);

#ifdef __cplusplus
}
#endif

#endif