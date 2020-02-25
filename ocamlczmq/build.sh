#!/bin/bash
set -e

# get number of processors for parallel compilation
NBPROCS=`getconf _NPROCESSORS_ONLN`

pushd libzmq
./configure --prefix="$(pwd)/.."
make -j$NBPROCS
make -j$NBPROCS install
popd

pushd czmq
export CFLAGS=-I"$(pwd)/../include"
export LDFLAGS=-L"$(pwd)/../lib"
export PKG_CONFIG_PATH="$(pwd)/../lib/pkgconfig"
./configure --prefix="$(pwd)/.." --enable-drafts="no" --with-libzmq="$(pwd)/.."
make -j$NBPROCS
make -j$NBPROCS install
popd

make -j$NBPROCS