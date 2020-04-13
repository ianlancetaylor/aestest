# aestest
Test that AES code in gofrontend and gc produce the same hash values.

This is only interesting for people maintaining the gofrontend hash
code found in libgo/runtime/aeshash.c.

To use this edit CPPFLAGS in aestest/c/aes.go to point to your
gofrontend sources.

The asm files are just copies of the code in the gc runtime package.
