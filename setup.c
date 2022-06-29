// version 1.1 11/22/2021
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#define _CGUARD_
#include <string.h>
#include <limits.h>
#include "encrypter.h"

static char encryptname[PATH_MAX];
static int safetounlink = 0;

void
encryptdelete(void)
{
	if ((safetounlink == 0) || (encryptname[0] == '\0'))
		return;
	(void)unlink(encryptname);
	safetounlink = 0;
	encryptname[0] = '\0';
	return;
}

int
setup(int argc, char *argv[], int *mode, FILE **book, FILE **input, FILE **output)
{
	int opt;
	int error = EXIT_OK;
	int dflag = 0;
	int eflag = 0;
	char *bookname = NULL;
	FILE *FPencrypt= NULL;
	char *openmode = NULL;

	while ((opt = getopt(argc, argv, "edb:o:")) != -1) {
		switch (opt) {
		case 'e':
			eflag = 1;
			openmode = "w";
			*mode = ENCRYPT_MODE;
			break;
		case 'd':
			dflag = 1;
			openmode = "r";
			*mode = DECRYPT_MODE;
			break;
		case 'b':
			bookname = optarg;
			break;
		case '?':
			/* fall through */
		default:
			error = EXIT_FAIL; /* we have an error, do not run */
 			break;
		}
	}
	if (bookname == NULL) {
		fprintf(stderr, "%s: -b bookfile must be specified\n", argv[0]);
		error = EXIT_FAIL;
	}
	if (((dflag == 0) && (eflag == 0)) || ((dflag == 1) && (eflag == 1))) {
		fprintf(stderr, "%s: You must specify either -e or -d\n", argv[0]);
		error = EXIT_FAIL;
	}
	if ((error != EXIT_OK) || ((optind == argc) || ((optind+1) < argc))) {
		fprintf(stderr, "Usage: %s [-d|-e] -b <bookfile> <encryption_file>\n", argv[0]);
		return EXIT_FAIL;
	}

	/* options all ok, now open the files in the correct mode */
	if ((*book = fopen(bookname, "r")) == NULL) {
		fprintf(stderr, "%s: Unable to open bookfile %s\n", argv[0], bookname);
		return EXIT_FAIL;
	}
	if ((FPencrypt = fopen(argv[optind], openmode)) == NULL) {
		fprintf(stderr, "%s: Unable to open encryption_file %s\n", argv[0], argv[optind]);
		(void)fclose(*book);	
		if (eflag == 1)
			(void)unlink(argv[optind]);
		return EXIT_FAIL;
	}
	if (eflag == 1) {
		/* encrypting a file: read from stdin and write to "encryption file" */
		*output = FPencrypt;
		*input = stdin;
		if (FPencrypt != NULL) {
			safetounlink = 1;
			strncpy(encryptname, argv[optind], PATH_MAX-1);
			encryptname[PATH_MAX-1] = '\0';
		} else {
			safetounlink = 0;
			encryptname[0] = '\0';
		}
			
	} else {
		/* decrypting a file: read from the encrypted file and write to stdou */
		*input = FPencrypt;
		*output = stdout;
		safetounlink = 0;
		encryptname[0] = '\0';
	}
	return EXIT_OK;
}
