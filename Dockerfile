FROM ubuntu:latest

# install general tools
RUN apt-get update && \
    apt-get -y install build-essential gcc zip unzip make python cmake ca-certificates gnupg wget curl m4 zlib1g-dev libssl-dev --no-install-recommends && \
    apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# install llvm
RUN mkdir /llvm && cd /llvm && \
    wget http://releases.llvm.org/9.0.0/llvm-9.0.0.src.tar.xz && \
    tar -xf llvm-9.0.0.src.tar.xz && \
    mkdir llvm-build && cd llvm-build && \
    cmake -G "Unix Makefiles" ../llvm-9.0.0.src && \
    make -j2 && \
    make install && \
    rm -rf /llvm

# build ocaml 4.04 from source
#RUN curl -OL https://github.com/ocaml/ocaml/archive/4.04.0.tar.gz && \
#    tar -zxvf 4.04.0.tar.gz && cd ocaml-4.04.0 && \
#    ./configure && \
#    make world world.opt && \
#    make install

# install ocaml
RUN apt-get update &&\
    apt-get install -y ocaml ocaml-native-compilers ocamlbuild opam && \
    apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

RUN opam init -a --compiler=4.04.0 &&\
    eval $(opam env) &&\
    opam update -uy &&\
    opam install -y core utop menhir ocamlbuild

# install additional tools
RUN apt-get update && \
    apt-get -y install vim nano emacs git subversion entr && \
    apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# add eval for opam env to bashrc to actually load it on start
RUN touch /root/.bashrc && \
    echo "eval `opam config env`" >> /root/.bashrc

# ocamlinit setup for toploop
RUN touch /root/.ocamlinit &&\
    echo "#use "'"'"topfind"'"'";;" >> /root/.ocamlinit &&\
    echo "#thread;;" >> /root/.ocamlinit &&\
    echo "#require "'"'"core.top"'"'";;" >> /root/.ocamlinit &&\
    echo "#require "'"'"core.syntax"'"'";;" >> /root/.ocamlinit

# create working directory
RUN mkdir /home/cd_project
WORKDIR /home/cd_project


