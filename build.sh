#!/bin/bash

CFLAGS="-std=c99 -Wall -Werror -O2 -g"
LDFLAGS=""

gcc $CFLAGS -o forsp forsp.c $LDFLAGS
