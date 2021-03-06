[bits 64]
global isr_common_stub
isr_common_stub:
    ; Save processor state of GPR's
    ; Notice how we don't push rsp - that's bc
    ; that's pushed on automatically when an interrupt occurs.
    ; When an interrupt occurs, here's what's pushed onto stack
    ; before the CPU jumps to the correct ISR:
    ; 1. SS
    ; 2. RSP
    ; 3. RFLAGS
    ; 4. CS
    ; 5. RIP
    ; 6. Error code (optional)
    push rax
    push rbx
    push rcx
    push rdx
    push rbp
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15

    ; Save processor state of segment registers

    ; Reload data segments to kernel data segements.
    ; When an interrupt occurs, cs is already loaded
    ; as the kernel code segment descriptor,
    ; as specified in the IDT.
    mov rax, 0
    mov ds, rax
    mov fs, rax
    mov es, rax
    mov gs, rax

    ; Do work here - INFINITE LOOP FOR DEBUG
    mov rax, 0xdeadbeaf
    jmp $
    hlt

    ; Returning from interrupt
    ; iretq pops off stuff pushed in before the ISR
    ; is called (Error code, rip, cs, etc.), but must be called
    ; last since these were pushed on first onto the stack
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rbp
    pop rdx
    pop rcx
    pop rbx
    pop rax
    iretq

global isr_0
global isr_1
global isr_2
global isr_3
global isr_4
global isr_5
global isr_6
global isr_7
global isr_8
global isr_9
global isr_10
global isr_11
global isr_12
global isr_13
global isr_14
global isr_15
global isr_16
global isr_17
global isr_18
global isr_19
global isr_20
global isr_21
global isr_22
global isr_23
global isr_24
global isr_25
global isr_26
global isr_27
global isr_28
global isr_29
global isr_30
global isr_31
global isr_32
global isr_33
global isr_34
global isr_35
global isr_36
global isr_37
global isr_38
global isr_39
global isr_40
global isr_41
global isr_42
global isr_43
global isr_44
global isr_45
global isr_46
global isr_47
global isr_48
global isr_49
global isr_50
global isr_51
global isr_52
global isr_53
global isr_54
global isr_55
global isr_56
global isr_57
global isr_58
global isr_59
global isr_60
global isr_61
global isr_62
global isr_63
global isr_64
global isr_65
global isr_66
global isr_67
global isr_68
global isr_69
global isr_70
global isr_71
global isr_72
global isr_73
global isr_74
global isr_75
global isr_76
global isr_77
global isr_78
global isr_79
global isr_80
global isr_81
global isr_82
global isr_83
global isr_84
global isr_85
global isr_86
global isr_87
global isr_88
global isr_89
global isr_90
global isr_91
global isr_92
global isr_93
global isr_94
global isr_95
global isr_96
global isr_97
global isr_98
global isr_99
global isr_100
global isr_101
global isr_102
global isr_103
global isr_104
global isr_105
global isr_106
global isr_107
global isr_108
global isr_109
global isr_110
global isr_111
global isr_112
global isr_113
global isr_114
global isr_115
global isr_116
global isr_117
global isr_118
global isr_119
global isr_120
global isr_121
global isr_122
global isr_123
global isr_124
global isr_125
global isr_126
global isr_127
global isr_128
global isr_129
global isr_130
global isr_131
global isr_132
global isr_133
global isr_134
global isr_135
global isr_136
global isr_137
global isr_138
global isr_139
global isr_140
global isr_141
global isr_142
global isr_143
global isr_144
global isr_145
global isr_146
global isr_147
global isr_148
global isr_149
global isr_150
global isr_151
global isr_152
global isr_153
global isr_154
global isr_155
global isr_156
global isr_157
global isr_158
global isr_159
global isr_160
global isr_161
global isr_162
global isr_163
global isr_164
global isr_165
global isr_166
global isr_167
global isr_168
global isr_169
global isr_170
global isr_171
global isr_172
global isr_173
global isr_174
global isr_175
global isr_176
global isr_177
global isr_178
global isr_179
global isr_180
global isr_181
global isr_182
global isr_183
global isr_184
global isr_185
global isr_186
global isr_187
global isr_188
global isr_189
global isr_190
global isr_191
global isr_192
global isr_193
global isr_194
global isr_195
global isr_196
global isr_197
global isr_198
global isr_199
global isr_200
global isr_201
global isr_202
global isr_203
global isr_204
global isr_205
global isr_206
global isr_207
global isr_208
global isr_209
global isr_210
global isr_211
global isr_212
global isr_213
global isr_214
global isr_215
global isr_216
global isr_217
global isr_218
global isr_219
global isr_220
global isr_221
global isr_222
global isr_223
global isr_224
global isr_225
global isr_226
global isr_227
global isr_228
global isr_229
global isr_230
global isr_231
global isr_232
global isr_233
global isr_234
global isr_235
global isr_236
global isr_237
global isr_238
global isr_239
global isr_240
global isr_241
global isr_242
global isr_243
global isr_244
global isr_245
global isr_246
global isr_247
global isr_248
global isr_249
global isr_250
global isr_251
global isr_252
global isr_253
global isr_254
global isr_255