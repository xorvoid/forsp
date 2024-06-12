#!/bin/bash

CFLAGS="-std=c11 -Wall -Werror -O2 -g"
LDFLAGS=""

gcc $CFLAGS -o forsp forsp.c $LDFLAGS
