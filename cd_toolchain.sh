#!/bin/sh
# base dependencies
if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install cmake gcc svn python zlib
elif [[ "$OSTYPE" == "linux-gnu" ]]; then
    sudo pacman -Syu --noconfirm cmake gcc svn python
fi
# llvm and clang

if hash clang 2>/dev/null; then
    echo llvm and clang already installed
else
    mkdir ~/llvm_build
    cd ~/llvm_build

    wget http://releases.llvm.org/9.0.0/llvm-9.0.0.src.tar.xz
    tar -xf llvm-9.0.0.src.tar.xz

    wget http://releases.llvm.org/9.0.0/cfe-9.0.0.src.tar.xz
    tar -xf cfe-9.0.0.src.tar.xz

    mv cfe-9.0.0.src llvm-9.0.0.src/tools/clang

    mkdir llvm-build    -- create a directory parallel to /llvm
    cd llvm-build
    cmake -G "Unix Makefiles" ../llvm-9.0.0.src
    -- llvm already installed, only add clang
    if hash llvm-as 2>/dev/null; then
        cd tools/clang    --Execute this command only if you have installed llvm before, otherwise ignore this command.
    else
        echo llvm not installed
    fi
    make -j2          -- drop -j2 flag if not on multiprocessor / takes a while!
    make install
fi

# ocaml setup
ocaml_ver=4.08.1
if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install opam
elif [[ "$OSTYPE" == "linux-gnu" ]]; then
    sudo pacman -Syu --noconfirm opam
fi
opam init -a
eval `opam config env`

if opam switch $ocaml_ver; then
    opam switch $ocaml_ver
    echo switch present, just switch
else
    opam switch create $ocaml_ver
    echo switch not present, creating
fi

opam install -y ocaml ocamlbuild core core_extended menhir merlin utop ocp-indent
eval `opam config env`

touch ~/.ocamlinit
echo "#use "'"'"topfind"'"'";;" >> ~/.ocamlinit &&\
echo "#thread;;" >> ~/.ocamlinit &&\
echo "#require "'"'"core.top"'"'";;" >> ~/.ocamlinit &&\
echo "#require "'"'"core.syntax"'"'";;" >> ~/.ocamlinit &&\
echo "#require "'"'"num"'"'";;" >> ~/.ocamlinit &&\
echo "#mod_use "'"'"util/assert.ml"'"'";;" >> ~/.ocamlinit &&\
echo "#mod_use "'"'"X86/x86.ml"'"'";;" >> ~/.ocamlinit

