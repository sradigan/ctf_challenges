#!/bin/sh

cat > time_lord.c << "EOF"
#include <time.h>

time_t time(time_t* timer)
{
	//ignore args, just return 0
	return 0;
}
EOF

#Build the binary
gcc -shared -fPIC time_lord.c -o time_lord.so

#Hook the binary's function
LD_PRELOAD=$PWD/time_lord.so ./dec_flag
