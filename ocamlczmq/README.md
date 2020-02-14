# ocamlczmq

Ocaml binding to the high-level C binding for ØMQ

## Building

The commands

    ./autogen.sh
    ./build.sh

will configure and build ZeroMQ, CZMQ and the OCaml binding. If you need to pass options to the configure script of any of ZeroMQ, CZMQ or ocamlczmq, add those to the `build.sh` call.

## Updating Dependencies

ZeroMQ and the CZMQ high-level C binding for ØMQ are included as subtrees from their respective github repositories. Nothing is needed to work with the sources, but in order to update ZeroMQ and CZMQ the git-subtree plugin is required. It is part of git, but not installed by default: get the git-subtree script and put it anywhere in the your path.

Updating the libraries (run from the project root, replace tags appropriately):

    ```bash
    git subtree add --prefix=ocamlczmq/libzmq --squash https://github.com/zeromq/libzmq tags/v4.3.2
    git subtree add --prefix=ocamlczmq/czmq --squash https://github.com/zeromq/czmq tags/v4.2.0
    ```
