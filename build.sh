#!/bin/bash

CFLAGS="-std=c99 -Wall -O2 -g"
LDFLAGS=""

gcc $CFLAGS -o forsp forsp.c $LDFLAGS
