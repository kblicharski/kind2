#!/bin/bash

# Configure 
if ./configure "$@"; then

    # Build Kind 2
    make 

fi
