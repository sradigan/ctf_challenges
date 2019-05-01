#!/bin/sh

startdir="$(pwd)"
workdir="$(mktemp -d)"

cd ${workdir}

cat > common.h << "EOF"
unsigned int sum(unsigned char *in, size_t len);
void xor(unsigned char *in, unsigned char *key, unsigned char *out, size_t len);
void genbuf(unsigned char *buf, size_t len, unsigned int seed);
EOF

cat > common.c << "EOF"
#include <stdlib.h>
#include <string.h>

unsigned int sum(unsigned char *in, size_t len)
{
	unsigned int ret = 0;
	for (size_t i = 0; i < len; i++) {
		ret += in[i];
	}
	return ret;
}

void xor(unsigned char *in, unsigned char *key, unsigned char *out, size_t len)
{
	for (size_t i = 0; i < len; i++) {
		out[i] = in[i] ^ key[i];
	}
}

void genbuf(unsigned char *buf, size_t len, unsigned int seed)
{
	int rnum;
	int i = 0;
	int j = 0;
	unsigned char *rbytes = (unsigned char *) &rnum;
	srand(seed);
	memset(buf, 0, len);
	while (i < len) {
		rnum = rand();
		for (j = 0; j < sizeof(int); j++) {
			if (i+j < len) {
				buf[i+j] = rbytes[j];
			} else {
				break;
			}
		}
		i+=j;
	}
}
EOF

cat > enc_flag.c << "EOF"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "common.h"

int print_buf(unsigned char *buf, size_t bufsz, char *msg)
{
	int i = 0;
	printf("%s", msg);
	for (i = 0; i < bufsz-1; i++) {
		if (0 == (i % 8)) {
			printf("\n");
		}
		printf("0x%02x, ", buf[i]);
	}
	printf("0x%02x };\n", buf[bufsz-1]);
}

int main(int argc, char **argv)
{
	size_t bufsz = 0;
	unsigned char *buf = NULL;
	unsigned char *buf2 = NULL;

	if (2 != argc) {
		printf("Usage: %s \"flag{enteryourflaglikethis}\"\n", argv[0]);
		return 1;
	}

	bufsz = strlen(argv[1]) + 1;
	buf = malloc(bufsz);
	buf2 = malloc(bufsz);
	if (!(buf && buf2)) {
		printf("Malloc failed, you really don't have enough memory?\n");
		return 1;
	}
	memset(buf, 0, bufsz);
	memset(buf2, 0, bufsz);

	//Generate a random buffer with a zero seed
	genbuf(buf, bufsz, 0);
	xor(buf, argv[1], buf2, bufsz);
	printf("unsigned int keysum = %u;", sum(buf, bufsz));
	print_buf(buf2, bufsz, "\nunsigned char enc_flag[] = {");

	return 0;
}
EOF

cat > dec_flag.c << "EOF"
#include <stdio.h>
#include <time.h>
#include <string.h>
#include "common.h"
#include "key.h"

int main(int argc, char **argv)
{
	int diff = 1;
	size_t bufsz = sizeof(enc_flag);
	unsigned char buf[sizeof(enc_flag)];
	unsigned char buf2[sizeof(enc_flag)];

	genbuf(buf, bufsz, time(NULL));
	if (keysum != sum(buf, bufsz)) {
		printf("No dice, keep trying. No time to lose.\n");
		return 1;
	}

	xor(buf, enc_flag, buf2, bufsz);
	printf("%s\n", (char*) buf2);

	return 0;
}
EOF

gcc -o enc_flag common.c enc_flag.c
./enc_flag "flag{HookingLikeAChamp}" > key.h
gcc -o dec_flag common.c dec_flag.c

#copy just the final binary back
mv ./dec_flag ${startdir}/dec_flag

#return to where we started
cd ${startdir}

#clean up all the working files
rm -rf ${workdir}

