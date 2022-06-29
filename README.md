Encrypts and decrypts provided files


Program arguements are the following
./encrypter (-d|-e) -b <bookfile> <encryption_file>
-d  Sets the program to decrypt.
    Exactly 1 of -d OR -e must be provided, but not both.
-e  Sets the program to encrypt.
    Exactly 1 of -d OR -e must be provided, but not both.
-b  bookfile The path to the input bookfile (more info on this file later).
    encryption_file When encrypting, this is the path to the output file (overwrite whatever
    exists).
    The input text to be encrypted is passed in through stdin.
    (Highly recommend redirecting input from a file using "<").
    When decrypting, this is the path to the input file (contains an encrypted
    file).
    The decrypted text should be printed to stdout.
    (Highly recommend redirecting output to a file using ">").