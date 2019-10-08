FROM ubuntu:latest

# install general tools
RUN apt-get update &&\
    apt-get -y install build-essential gcc zip unzip make python cmake ca-certificates gnupg wget curl m4 zlib1g-dev libssl-dev --no-install-recommends &&\
    apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# install llvm
RUN mkdir /llvm && cd /llvm &&\
    wget http://releases.llvm.org/9.0.0/llvm-9.0.0.src.tar.xz &&\
    tar -xf llvm-9.0.0.src.tar.xz &&\
    mkdir llvm-build && cd llvm-build &&\
    cmake -G "Unix Makefiles" ../llvm-9.0.0.src &&\
    make -j2 &&\
    make install &&\
    rm -rf /llvm

# add repo for opam 2
RUN apt-get update &&\
    apt-get install -y software-properties-common &&\
    add-apt-repository ppa:avsm/ppa &&\
    apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# install ocaml
RUN apt-get update &&\
    apt-get install -y ocaml ocaml-native-compilers ocamlbuild opam &&\
    apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

RUN opam init -a --disable-sandboxing --compiler=4.07.0 &&\
    eval `opam config env` &&\
    opam install -y ocamlbuild core utop menhir

# install additional tools
RUN apt-get update &&\
    apt-get -y install vim nano emacs git subversion entr &&\
    apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# add eval for opam env to bashrc to actually load it on start
RUN touch /root/.bashrc &&\
    echo ". /root/.opam/opam-init/init.sh > /dev/null 2> /dev/null || true" >> /root/.bashrc

# ocamlinit setup for toploop
RUN touch /root/.ocamlinit &&\
    echo "#use "'"'"topfind"'"'";;" >> /root/.ocamlinit &&\
    echo "#thread;;" >> /root/.ocamlinit &&\
    echo "#require "'"'"core.top"'"'";;" >> /root/.ocamlinit &&\
    echo "#require "'"'"core.syntax"'"'";;" >> /root/.ocamlinit &&\
    echo "#require "'"'"num"'"'";;" >> /root/.ocamlinit &&\
    echo "#mod_use "'"'"util/assert.ml"'"'";;" >> /root/.ocamlinit &&\
    echo "#mod_use "'"'"X86/x86.ml"'"'";;" >> /root/.ocamlinit

# create working directory
RUN mkdir /home/cd_project
WORKDIR /home/cd_project


