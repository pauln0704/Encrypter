	// file header
	.arch armv6                  // armv6 architecture
	.arm                         // arm 32-bit instruction set
	.fpu vfp                     // floating point co-processor
	.syntax unified              // modern syntax

	// constant values you want to use throughout the program
	// could go below like:
	// .equ ONE, 1

	.text                        // start of text segment

	.global encrypt              // make encrypt global for linking to
	.type encrypt, %function     // define encrypt to be a function
	.equ FP_OFFSET, 4            // fp offset distance from sp

encrypt:
	// function prologue
	push {fp, lr}                // stack frame register save
	add fp, sp, FP_OFFSET        // set frame pointer to frame base

	// --- DO NOT EDIT LINES ABOVE ---

	// your code here

	// swapping halves
	//
	// shift
	ROR R0, R0, #4                 // R0 = R0 >> 4; move bits in to position
	// mask
	AND R2, R0, #0xF               // R2 = R0 & 15; mask bits 0-3
	// shift
	ROR R0, R0, #24                // R0 = R0 >> 24; move bits in to position
	// mask
	AND R3, R0, #0xF0              // R3 = R0 & 240; mask bits 4-7
        // comabine
	ORR R0, R2, R3                 // combines R2 and R3 effectively swapping the right most 8 bits

	// XORing the key
	//
	EOR R0, R0, R1                 // R0 = R0 ^ R1

	// --- DO NOT EDIT LINES BELOW ---

	// function epilogue
	sub sp, fp, FP_OFFSET        // restore stack frame top
	pop {fp, lr}                 // remove frame and restore registers
	bx lr                        // return to caller

	// function footer
	.size encrypt, (. - encrypt) // set size for function

	.global decrypt              // make encrypt global for linking to
	.type decrypt, %function     // define encrypt to be a function
	.equ FP_OFFSET, 4            // fp offset distance from sp

decrypt:
	// function prologue
	push {fp, lr}                // stack frame register save
	add fp, sp, FP_OFFSET        // set frame pointer to frame base

	// --- DO NOT EDIT LINES ABOVE ---

	// your code here

	// undo XORing the key
	//
	EOR R0, R0, R1                 // R0 = R0 ^ R1

	// undo swapping halves
	//
	// shift
	ROR R0, R0, #4                 // R0 = R0 >> 4; move bits in to position
	// mask
	AND R2, R0, #15                // R2 = R0 & 15; mask bits 0-3
	// shift
	ROR R0, R0, #24                // R0 = R0 >> 24; move bits in to position
	// mask
	AND R3, R0, #240               // R3 = R0 & 240; mask bits 4-7
	// combine
	ORR R0, R2, R3                 // combines R2 and R3 effectively swapping the right most 8 bits

	// --- DO NOT EDIT LINES BELOW ---
	// function epilogue
	sub sp, fp, FP_OFFSET        // restore stack frame top
	pop {fp, lr}                 // remove frame and restore registers
	bx lr                        // return to caller

	// function footer
	.size decrypt, (. - decrypt) // set size for function

	// file footer
	.section .note.GNU-stack, "", %progbits // stack/data non-exec (linker)
.end
	Template is Arm Procedure Call Standard Compliant (for Linux)
