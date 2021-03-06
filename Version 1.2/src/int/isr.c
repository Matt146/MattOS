#include "isr.h"

static struct IDT_Gate idt[256];
static struct IDTR idtr;

void init_interrupts() {
    struct IDT_Gate idt_default;
    uint64_t offset = (uint64_t)isr_common_stub;

    // Set the values of the default IDT gate
    idt_default.offset0 = (uint16_t)offset;
    idt_default.cs = 0x8;
    idt_default.zero0 = 0x0;
    idt_default.type = 0x8E;
    idt_default.offset1 = (uint16_t)(offset >> 16);
    idt_default.offset2 =  (uint32_t)(offset >> 32);
    idt_default.zero1 = 0x0;

    // Set the default IDT gate to all IDT entries
    for (size_t i = 0; i < 256; i++) {
        set_idt_gate(idt_default, i);
    }

    // Load IDT
    idtr.limit = 256 * sizeof(struct IDT_Gate) - 1;
    idtr.base = (uint64_t)idt;
    load_idt(&idtr);
}

void set_idt_gate(struct IDT_Gate value, int index) {
    idt[index] = value;
}