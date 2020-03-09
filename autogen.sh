#!/bin/bash

# Generate aclocal.m4 from include files in m4
aclocal -I m4

# Generate our configuration
autoreconf -v

