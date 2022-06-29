// versions 1.0 11/22/2021
#ifndef _encrypter_h
#define _encrypter_h 1
#ifdef _CGUARD_
#define ENCRYPT_MODE	1
#define DECRYPT_MODE	0
#define	EXIT_OK		0
#define	EXIT_FAIL	1
#else
.equ	ENCRYPT_MODE,	1
.equ	DECRYPT_MODE,	0
.equ	EXIT_OK,        0
.equ	EXIT_FAIL,      1
#endif
#endif
