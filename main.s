	////////////////////////////
	// version 1.3 11/22/2021 //
	////////////////////////////
	.arch armv6				// armv6 architecture
	.arm					// arm 32-bit instruction set
	.fpu vfp				// floating point co-processor
	.syntax unified				// modern sytax

	// function import
	.extern encrypt
	.extern decrypt
	.extern stderr
	.extern fprintf
	.extern fclose
	.extern setup
	.extern encryptdelete

	// global constants
	.include "encrypter.h"

	.section .rodata
.Lmsg1:	.string "Write failed on output\n"
.Lmsg2:	.string "Bookfile is too short for message\n"
	.text

	//////////////////////////////////////////////////////
	// int main(int argc, char **argv)                  //
	// encrypter [-d | -e] -b bookfile encryption_file  //
	//////////////////////////////////////////////////////

	.global main				// main global for linking to
	.type	main, %function			// define as a function
	.equ	FP_OFF,		32		// fp offset in main stack frame
	.equ 	BUFSZ,		1024		// max for assignment is 4096 min is 1024

	//////////////////////////////////////////////////////////////////////////////
	// automatics (local variable) frame layout
	// NOTICE! odd # of regs pushed, Not 8-byte aligned at FP_OFF; add 4 bytes pad
	// 
	// local stack frame name are used with fp as base
	// format is .equ VAR_NAME, NAME_OF_PREVIOUS_VARIABLE + <size of variable>
	// first variable should use  FP_OFF as the previous variable
	//////////////////////////////////////////////////////////////////////////////
	.equ	FPBOOK,		FP_OFF+4	// FILE * to book file
	.equ	FPIN,		FPBOOK+4	// FILE * to input file
	.equ	FPOUT,		FPIN+4		// FILE * to output file
	.equ	MODE,		FPOUT+4		// decrypt or encrypt mode
	.equ	IOBUF,		MODE+BUFSZ	// buffer for input file
	.equ	BOOKBUF,	IOBUF+BUFSZ	// buffer for book file
	// add local variables here: Then adjust PAD or comment out pad line as needed 
	.equ	PAD,		BOOKBUF+4		// Stack frame PAD if needed goes here
	.equ	OUT6,		PAD+4		// output arg6
	.equ	OUT5,		OUT6+4		// output arg5 must be at bottom
	.equ	FRAMESZ,	OUT5-FP_OFF	// total space for automatics
	//////////////////////////////////////////////////////////////////////////////
	// make sure that FRAMESZ + FP_OFF + 4 divides by 8 EVENLY!
	//////////////////////////////////////////////////////////////////////////////
	
	//////////////////////////////////////////////////////////////////////////////
	// passed arg offsets used with sp as the base
	//////////////////////////////////////////////////////////////////////////////
	.equ	OARG6,		4		// Outgoing arg 6		
	.equ	OARG5,		0		// Outgoing arg 5		

main:
	// function prologue
	push	{r4-r10, fp, lr}		// WARNING! odd count register save!
	add	fp, sp, FP_OFF			// set frame pointer to frame base
	ldr	r3, =FRAMESZ			// if frame size is too big, use pseudo ldr
	SUB	sp, sp, r3			// allocate space for locals and passed args 
	
	// call int setup(argc, argv, &mode, &FPBOOK, &FPIN, &FPOUT)
	mov r0, r0                              // setup(argc, argv, mode, FPBOOK, FPIN, FPOUT);
	mov r1, r1                              // .
	sub r2, fp, #MODE                       // .
	sub r3, fp, #FPBOOK                     // .
	sub r4, fp, #FPIN                       // .
	str r4, [sp, #OARG5]                    // .
	sub r4, fp, #FPOUT                      // .
	str r4, [sp, #OARG6]                    // .
	bl  setup                               // .

	// set up for main loop

	// r4 is readcnt
	// r5 is pos
	// r6 is toread
	// r7 is bytes
	// r10 is exitstatus

	mov r10, #EXIT_OK		// exit_status = EXIT_OK;
	// main loop
.Lloop:
	// read the input
	sub r0, fp, #IOBUF		// while ((readcnt = fread(IOBUF,1,BUFSZ,*FPIN)) > 0){
	mov r1, #1				// .       
	mov r2, #BUFSZ			// .
	ldr r3, [fp, #-FPIN]	// .
	bl  fread				// .
	mov r4, r0				// .
	cmp r4, #0				// .
	ble .Ldone				// .

	mov r5, #0				// 	pos = 0;
	mov r6, r4				// 	toread = readcnt
		
	// now read the book the same number of chars
.Lloop2:
	mov r9, #BOOKBUF		//	while((bytes=
	sub r8, r9, r5			// 	       fread(&BOOKBUF[pos],1,toread,*FPBOOK))>0){
	sub r0, fp, r8 			// 	.       
	mov r1, #1				// 	.
	mov r2, r6				// 	.
	ldr r3, [fp, #-FPBOOK]	// 	.
	bl  fread				// 	.
	mov r7, r0				// 	.
	cmp r7, #0				// 	.
	ble .Ldone2				// 	.
	add r5, r5, r7			// 		if((pos=pos+bytes)==readcnt)
	cmp r5, r4				//		.
	beq .Ldone2				//			break;
	sub r6, r6, r7			//		toread = toread - bytes;
	b   .Lloop2				//	}	
.Ldone2:

	// Both buffers are full, process the input
	cmp r7, #0				//	if (bytes == 0){
	bne .Lnotequal			//	.
	ldr r8, =stderr			//		fprintf(stderr,"Bookfile is 
	ldr r0, [r8]			//		        too short for message\n");
	ldr r1, =.Lmsg2			//		.
	bl  fprintf				//		.
	mov r10, #EXIT_FAIL		//		exitstatus = EXIT_FAIL;
	b   .Ldone				//		break;
.Lnotequal:					//	}

	// based on mode: either encrypt the input
	ldr r8, [fp, #-MODE]			//	if (*MODE){
	cmp r8, #1				//	.
	bne .Ldecrypt			//	.		
	mov r5, #0				//		pos = 0;
.Lloop3:					//		while(pos<readcnt){
	cmp r5, r4				//		.
	bge .Ldone3				//		.
	mov r9, #IOBUF			//			IOBUF[pos]=encrypt(
	sub r8, r9, r5			//				IOBUF[pos],BOOKBUF[pos]);
	ldrb r0, [fp, -r8]		//			.
	mov r9, #BOOKBUF		//			.
	sub r8, r9, r5			//			.
	ldrb r1, [fp, -r8]		//			.
	bl  encrypt				//			.
	mov r9, #IOBUF			//			.
	sub r8, r9, r5			//			.
	strb r0, [fp, -r8]		//			.
	add r5, r5, #1			//			pos++;
	b   .Lloop3				//		}
.Ldone3:					//	}
	b   .Lcrypt				//	.
	// or decrypt the input
.Ldecrypt:					//	else{
	mov r5, #0				//		pos = 0;
.Lloop4:					//		while(pos<readcnt){
	cmp r5, r4				//		.
	bge .Lcrypt				//		.
	mov r9, #IOBUF			//			IOBUF[pos]=decrypt(
	sub r8, r9, r5			//				IOBUF[pos],BOOKBUF[pos]);
	ldrb r0, [fp, -r8]		//			.
	mov r9, #BOOKBUF		//			.
	sub r8, r9, r5			//			.
	ldrb r1, [fp, -r8]		//			.
	bl  decrypt				//			.
	mov r9, #IOBUF			//			.
	sub r8, r9, r5			//			.
	strb r0, [fp, -r8]		//			.
	add r5, r5, #1			//			pos++;
	b   .Lloop4				//		}
.Lcrypt:					//	}

	// write out the i/o buffer as all chars are processed
	sub r0, fp, #IOBUF		//	if(fwrite(IOBUF,1,readcnt,FPOUT)!=readcnt){
	mov r1, #1				//	.
	mov r2, r4				//	.
	ldr r3, [fp, #-FPOUT]	//	.
	bl  fwrite				//	.
	mov r8, r0				//	.
	cmp r8, r4				//	.
	beq .Lloop				//	.
	mov r10, #EXIT_FAIL		//		exit_status = EXIT_FAIL;
	ldr r8, =stderr			//		fprintf(stderr,"Write failed on output\n");
	ldr r0, [r8]			//		.
	ldr r1, =.Lmsg1			//		.
	bl  fprintf				//		.
	b   .Ldone				// }}
	// end of loop
.Ldone:
	// close the files using fclose()
	ldr r0, [fp, #-FPBOOK]	// fclose(FPBOOK*);
	bl  fclose				// .
	ldr r0, [fp, #-FPIN]	// fclose(FPIN*);
	bl  fclose				// .
	ldr r0, [fp, #-FPOUT]	// fclose(FPOUT*);
	bl  fclose				// .

	// if encrypt failed to finish all input remove the incomplete encrypt file
	cmp r10, #EXIT_FAIL		// if (exit_status){
	bne .LEXIT				// .
	ldr r8, [fp, #-MODE]	//	if (*MODE){
	cmp r8, #1				// 	.
	bne .LEXIT				//	.
	bl  encryptdelete		//		encryptiondelete();
.LEXIT:						// }}
	mov r0, r10				// set return value of main

	// function epilogue
	sub	sp, fp, FP_OFF		// restore stack frame top
	pop	{r4-r10,fp,lr}		// remove frame and restore
	bx	lr					// return to caller

	// function footer
	.size	main, (. - main)		// set size for function

	// file footer
	.section .note.GNU-stack,"",%progbits // set executable (linker)
.end
