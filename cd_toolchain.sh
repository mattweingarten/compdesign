#!/bin/sh
# base dependencies
if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install gcc svn python zlib
elif [[ "$OSTYPE" == "linux-gnu" ]]; then
    sudo pacman -Syu gcc svn gunzip python zlib
fi

# llvm and clang
mkdir ~/llvm_build
cd ~/llvm_build

wget http://releases.llvm.org/9.0.0/llvm-9.0.0.src.tar.xz
tar -xf llvm-9.0.0.src.tar.xz    

wget http://releases.llvm.org/9.0.0/cfe-9.0.0.src.tar.xz
tar -xf cfe-9.0.0.src.tar.xz    

mv -r cfe-9.0.0.src llvm-9.0.0.src/tools/clang

mkdir llvm-build    -- create a directory parallel to /llvm
cd llvm-build
cmake -G "Unix Makefiles" ../llvm-9.0.0.src
make -j2          -- drop -j2 flag if not on multiprocessor / takes a while!
make install

# ocaml setup
if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install opam
elif [[ "$OSTYPE" == "linux-gnu" ]]; then
    sudo pacman -Syu opam
fi
opam init -a
eval `opam config env`
opam switch create 4.07.0
opam install -y ocaml ocamlbuild core core_extended menhir merlin utop
eval `opam config env`

touch ~/.ocamlinit
echo "#use "'"'"topfind"'"'";;" >> ~/.ocamlinit &&\
echo "#thread;;" >> ~/.ocamlinit &&\
echo "#require "'"'"core.top"'"'";;" >> ~/.ocamlinit &&\
echo "#require "'"'"core.syntax"'"'";;" >> ~/.ocamlinit &&\
echo "#require "'"'"num"'"'";;" >> ~/.ocamlinit &&\
echo "#mod_use "'"'"util/assert.ml"'"'";;" >> ~/.ocamlinit &&\
echo "#mod_use "'"'"X86/x86.ml"'"'";;" >> ~/.ocamlinit

