; NASM directives:
; org  - tells where the program is supposed to be loaded in memory
;	 in this case, 0x7c00 is where the BIOS leaves us
; bits - encodes instructions for 16 bits
[org 0x7c00]
[bits 16]

; TODO = ENABLE A20 LINE:
; So, I'm gonna try to wrap my 4 IQ head around this: if you have the a20 line disabled, the 21st bit in the physical address is always gonna be set to 0 basically, in order for the wraparound feature to work?
; The reason why they needed this to work like this was bc the intel 8086 had the wraparound feature at 1 mb, but the 286 could address 16 mb now in protected mode, and to keep compatibility with the wraparound feature, they disabled the a20 line.

; Global vars
KERNEL_OFFSET equ 0x8c00

; Set up segment registers by setting all of them, 
; except for cs, to 0
xor ax, ax  ; set ax to 0
mov ds, ax	; Setup data segment
mov es, ax	; Setup extra segment
mov ss, ax	; Setup stack segment
mov sp, 0xAAAA	; Setup stack pointer
mov bp, sp	; Setup base pointer to keep track of stack. If you're reading this, I did
		; it to do nested function calls and not have to worry about the stack.
		; Much safer to have a baser pointer here.

call load_kernel	     ; Load the kernel using BIOS functions
call enable_a20_main	     ; Enable the A20 line
xor ebx, ebx                ; Clear ebx before you query the address map. Must be 0 on the first call, and contains the "continuation value" to get the next "run" of physical memory. This value is returned by a previous call to this routine.
xor ecx, ecx                ; Clear ecx before you query the address map
MEMORY_MAP_LOCATION_ES equ 0x1000
MEMORY_MAP_LOCATION_DI equ 0x3000
xor ax, ax
mov ax, MEMORY_MAP_LOCATION_ES
mov es, ax
mov di, ax ; int 0x15, ax=0xE820 will return the memory map in es:di
call query_memory_map      ; Query the system address map from BIOS int 0x15, ax=0x820
xor eax, eax
mov es, ax
mov di, ax
jmp switch_to_protected_mode ; Now, we go to protected mode

; ===========================================
;       QUERY ADDRESS MAP OF SYSTEM
; ===========================================
query_memory_map:
    mov eax, 0xE820             ; int 0x15 function id
    add edi, 0x18                ; 24 byte entries
    mov ecx, 0x18             ; max length of that "run" of memory map
    mov edx, 0x534D4150         ; magic number
    int 0x15

    ; Return values:
    ; CF - Carry Flag - Non-Carry indicates no error
    ; EAX - Signature to verify correct BIOS revision
    ; ES:DI - Buffer pointer - returned address range descriptor pointer. Same value as on input
    ; ECX - Buffer size - Number of bytes returned by the BIOS in the address range descriptor
    ; EBX - Continuation - "Continuation" value to get the next address descriptor. Must be zero on first call. Returns 0 if it's the last valid descriptor

    ; Check for errors
    jc query_memory_map_error

    ; Check continuation value 
    cmp ebx, 0 ; compare ebx to zero to check if it's the last valid descriptor
    jne query_memory_map
    
query_memory_map_end:
    add edi, 0x18
    mov dword [edi], 0xdeadbeef
    ret

query_memory_map_error:
    mov ah, 0x0e
    mov al,'S'
    int 0x10
    jmp $


; ===========================================
;	    KERNEL LOADING FUNCTIONS
; ===========================================
load_kernel:
    call disk_load
    ret

disk_load:
    mov ah, 0x42
    mov si, DAP
    int 0x13
    jc disk_error
    ret

DAP:
    db 0x10
    db 0x0
    dw 15
    dd KERNEL_OFFSET
    dq 1

disk_error:
    mov ah, 0x0e
    mov al,'F'
    int 0x10
    jmp $

; ==========================================
;       ENABLE A20 LINE
; ==========================================
enable_a20_main:
    ; Fast a20 method - I honestly don't care about having
    ; the other methods. This will work on most CPU's.
    mov al, 2
    out 0x92, al

    ret

; ==========================================
;		SETUP THE GDT
; ==========================================
gdt_start:

gdt_null:
    dd 0x0
    dd 0x0

gdt_code:
    ; base = 0x0, limit=0xfffff
    ; 1st  flags: (present )1 (privilege )00 (descriptor  type)1 -> 1001b
    ; type  flags: (code)1 (conforming )0 (readable )1 (accessed )0 -> 1010b
    ; 2nd  flags: (granularity )1 (32-bit  default )1 (64-bit  seg)0 (AVL)0 -> 1100b
    dw 0xffff    ; Limit (bits 0-15)
    dw 0x0       ; Base (bits 0-15)
    db 0x0       ; Base (bits 16-23)
    db 10011010b ; 1st flags , type  flags
    db 11001111b ; 2nd flags , Limit (bits  16-19)
    db 0x0       ; Base (bits  24 -31)

gdt_data: ;the  data  segment  descriptor
    ; Same as code  segment  except  for  the  type  flags
    ; type  flags: (code)0 (expand  down)0 (writable )1 (accessed )0 -> 0010b
    dw 0xffff      ; Limit (bits  0-15)
    dw 0x0         ; Base (bits  0-15)
    db 0x0         ; Base (bits  16 -23)
    db 10010010b   ; 1st flags , type  flags
    db 11001111b   ; 2nd flags , Limit (bits  16-19)
    db 0x0         ; Base (bits  24 -31)

gdt_end:           ; The  reason  for  putting a label  at the  end of the
                   ; GDT is so we can  have  the  assembler  calculate
                   ; the  size of the  GDT  for  the GDT  decriptor (below)

; GDT descriptor
gdt_descriptor:
    dw  gdt_end  - gdt_start  - 1	; 16 bits for size of GDT
    dd  gdt_start			; 32 bits for where the GDT starts

; Define  some  handy  constants  for  the  GDT  segment  descriptor  offsets , which
; are  what  segment  registers  must  contain  when in  protected  mode.  For  example ,
; when we set DS = 0x10 in PM , the  CPU  knows  that we mean it to use  the
; segment  described  at  offset 0x10 (i.e. 16  bytes) in our GDT , which in our
; case is the  DATA  segment  (0x0 -> NULL; 0x08  -> CODE; 0x10  -> DATA)
CODE_SEG  equ  gdt_code  - gdt_start
DATA_SEG  equ  gdt_data  - gdt_start

; ==========================================
;	SWITCH TO PROTECTED MODE
; ==========================================
switch_to_protected_mode:
    ; Disable interrutps for rn, so that
    ; we don't screw up switching to pmode
    cli     
    
    ; Tell the CPU about the GDT we just prepared
    lgdt [gdt_descriptor]

    ; Set cr0's first bit
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    ; Far jump to set CS
    jmp CODE_SEG:init_pm

[bits 32]
init_pm:
    ; For flat memory model
    mov ax, DATA_SEG	; put the offset of the data segment descriptor in the GDT into ax
    mov ds, ax		; now put ax into ds - can't set ds directly
    mov ss, ax		; set stack segment to ax
    mov es, ax		; set extra segment to ax
    mov fs, ax		; set fs to ax
    mov gs, ax		; set gs to ax

    ; now set the base pointer and the stack pointer
    ; to set up the stack
    mov ebp, 0x90000
    mov esp, ebp

    sti ; re-enable interrupts

    ; as of now, we have completely set up protected mode
    ; jump to prepare our switch to long mode
    jmp prep_switch_to_long_mode


; ==========================================
;	    SWITCH TO COMPAT. MODE
; ==========================================
; Page tables for hierarchical paging
; We're not gonna use this bc we're gonna use huge pages
; of 2 MiB each. We need to identity map the first gigabyte
; of our kernel with 512 2 MiB pages
; https://os.phil-opp.com/entering-longmode/
P4	equ 0x15000	; Page-map level-4 table (PML4T)
P3	equ 0x16000	; Page-directory pointer table (PDPT)
P2	equ 0x17000	; Page-directory table (PDT)
; P1	equ 0x18000	; Page table (PT)

prep_switch_to_long_mode:
	; zero eax
	xor eax, eax
	mov ecx, 0x17000

zero_tables:
	mov [ecx], dword 0	; write zero
	dec ecx
	cmp ecx, 0x15000
	jne zero_tables
	jmp map_P4_P3_tables

map_P4_P3_tables:
	; Map first P4 entry to P3 table
	mov eax, P3 | 0b11 ; present + writable
	mov [P4], eax

	; Map first P3 entry to P2 table
	mov eax, P2 | 0b11 ; present + writable	
	mov [P3], eax

	mov ecx, 0

map_P2_table:
	; map ecx-th P2 entry to a huge page that starts at address 2 MiB*ecx
	mov eax, 0x200000
	mul ecx
	or eax, 0b10000011
	mov [P2 + ecx * 8], eax ; map ecx-th entry

	inc ecx
	cmp ecx, 512
	jne map_P2_table

; So here's how we get from real > protected > long mode
; =========REAL MODE==================
; 1. Disable interrupts
; 2. Make a GDT
; 3. Load the GDT using lgdt
; 4. Set CR0's first bit
; 5. Far jump to set CS:EIP
; 6. Set your segment registers to the correct value (offsets into the GDT)
; 7. Set your stack up properly (ebp and esp)
; 8. Re-enable interrupts
; =========PROTECTED MODE==============
; 9. Setup page tables
; 10. Load top page table to CR3 register
; 11. Enable PAE by setting the PAE bit in cr4
; 12. Set the long mode bit in the EFER MSR
; =========LONG MODE (COMPATIBILITY)=== 
; 13. Setup a 64-bit GDT 
; 14. Load the 64-bit GDT
; 15. Far jump
; 16. Set segment registers
; =========LONG MODE (64-BIT)==========
; 17. Jump to kernel
load_page_tables:
	; load top-level page table to cr3, so the CPU can see it
	; CR3 is the register that contains the top-level page table
	; address
	mov eax, P4
	mov cr3, eax

	; enable PAE-flag in cr4 (physical address extension)
	; Allows for 36-bit protected mode addresses
	mov eax, cr4
	or eax, 1 << 5
	mov cr4, eax

	; set the long mode bit in the EFER MSR (model specific register)
	; This allows us to switch to long mode
	mov ecx, 0xC0000080	; the MSR we are reading/writing to
	rdmsr			; put the value of the MSR specified by ecx into edx:eax
	or eax, 1 << 8		; set the long mode bit
	wrmsr			; write it back to the MSR

	; enable paging in the cr0 register
	mov eax, cr0
	or eax, 1 << 31
	mov cr0, eax

in_compatibility_mode:
	mov dword [0xb0000], 0x2f4b2f4f
	jmp get_into_64_bit_mode

; ==========================================
;    SETUP GDT AND SWITCH TO 64-BIT MODE
; ==========================================
gdt64_start:

gdt64_null:
	dq 0

gdt64_code:
	dq (1<<43) | (1<<44) | (1<<47) | (1<<53)

gdt64_end:

gdt64_descriptor:
	dw $ - gdt64_start - 1	; 2 bytes for size
	dq gdt64_start		; 8 bytes for starting address

; gdt_64 constants
GDT64_CODE_SEG  equ  gdt64_code  - gdt64_start

get_into_64_bit_mode:
	; load the 64-bit GDT
	lgdt [gdt64_descriptor]

	; Far jump to set cs:rip
	jmp GDT64_CODE_SEG:LONG_MODE_START

[bits 64]
LONG_MODE_START:
	; YAY! We're in 64-bit submode now	
	; Time to load 0 into all data segment registers
	xor ax, ax
	mov ss, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

    ; Disable the PIC, so we can use the APIC
    mov al, 0xff
    out 0xa1, al
    out 0x21, al

	; Jump to kernel
	call KERNEL_OFFSET

	jmp $	; HANG


times 510-($-$$) db 0
dw 0xaa55
