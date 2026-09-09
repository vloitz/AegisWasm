#include "vm_core.h"
#include "encrypted_code.h"
#include <vector>
#include <string>
#include <emscripten/emscripten.h>

extern "C" {
    void vm_init(MicroVM* vm, uint8_t* code, size_t length) {
        vm->bytecode = code;
        vm->bytecode_length = length;
        vm->ip = 0;
        vm->sp = -1;
        for(int i = 0; i < 64; i++) vm->memory[i] = 0;
    }

    int32_t vm_execute(MicroVM* vm) {
        while (vm->ip < vm->bytecode_length) {
            uint8_t opcode = vm->bytecode[vm->ip++];

            switch (opcode) {
                case OP_HALT:
                    return vm->sp >= 0 ? vm->stack[vm->sp] : 0;

                case OP_PUSH: {
                    int32_t val = (int32_t)(vm->bytecode[vm->ip] |
                                  (vm->bytecode[vm->ip + 1] << 8) |
                                  (vm->bytecode[vm->ip + 2] << 16) |
                                  (vm->bytecode[vm->ip + 3] << 24));
                    vm->ip += 4;
                    vm->stack[++vm->sp] = val;
                    break;
                }
                case OP_POP:
                    if (vm->sp >= 0) vm->sp--;
                    break;

                case OP_ADD: {
                    int32_t b = vm->stack[vm->sp--];
                    int32_t a = vm->stack[vm->sp--];
                    vm->stack[++vm->sp] = a + b;
                    break;
                }
                case OP_SUB: {
                    int32_t b = vm->stack[vm->sp--];
                    int32_t a = vm->stack[vm->sp--];
                    vm->stack[++vm->sp] = a - b;
                    break;
                }
                case OP_MUL: {
                    int32_t b = vm->stack[vm->sp--];
                    int32_t a = vm->stack[vm->sp--];
                    vm->stack[++vm->sp] = a * b;
                    break;
                }
                case OP_DIV: {
                    int32_t b = vm->stack[vm->sp--];
                    int32_t a = vm->stack[vm->sp--];
                    vm->stack[++vm->sp] = b != 0 ? a / b : 0;
                    break;
                }
                case OP_LOAD: {
                    uint8_t mem_idx = vm->bytecode[vm->ip++];
                    vm->stack[++vm->sp] = vm->memory[mem_idx];
                    break;
                }
                case OP_STORE: {
                    uint8_t mem_idx = vm->bytecode[vm->ip++];
                    vm->memory[mem_idx] = vm->stack[vm->sp--];
                    break;
                }
                case OP_JMP: {
                    uint16_t target = (uint16_t)(vm->bytecode[vm->ip] | (vm->bytecode[vm->ip + 1] << 8));
                    vm->ip = target;
                    break;
                }
                case OP_JZ: {
                    uint16_t target = (uint16_t)(vm->bytecode[vm->ip] | (vm->bytecode[vm->ip + 1] << 8));
                    vm->ip += 2;
                    int32_t val = vm->stack[vm->sp--];
                    if (val == 0) vm->ip = target;
                    break;
                }
                case OP_RET:
                    return vm->stack[vm->sp];

                default:
                    return -999;
            }
        }
        return 0;
    }

    // NUEVA FUNCIÓN: Descifra y devuelve el código fuente JS en texto plano de forma segura a JS
    EMSCRIPTEN_KEEPALIVE
    char* get_secure_asset(const char* filename) {
        for (size_t i = 0; i < SECURE_ASSETS_COUNT; ++i) {
            // Comparamos el nombre del archivo solicitado con el catálogo cifrado
            std::string current_name(SECURE_ASSETS[i].filename);
            if (current_name == filename) {
                size_t len = SECURE_ASSETS[i].length;

                // Reservamos memoria heap en el entorno Wasm para alojar el script descifrado
                char* decrypted_script = (char*)malloc(len + 1);
                for (size_t j = 0; j < len; ++j) {
                    decrypted_script[j] = (char)(SECURE_ASSETS[i].bytecode[j] ^ XOR_KEY);
                }
                decrypted_script[len] = '\0'; // Terminador de cadena para JavaScript
                return decrypted_script;
            }
        }
        return nullptr; // Si no existe el asset
    }

    // Liberación de memoria reservada por Wasm para evitar fugas (Memory Leaks)
    EMSCRIPTEN_KEEPALIVE
    void free_secure_asset(char* ptr) {
        free(ptr);
    }

    EMSCRIPTEN_KEEPALIVE
    int32_t execute_secure_logic() {
        // Mantenedor del flujo operativo base de la Micro-VM de pruebas
        return 150;
    }
}