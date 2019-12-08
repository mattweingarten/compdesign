# ocaml341.mk will override LOCAL_COMMON_DIR when generating the
# test.mk for placing in the test_soln and test_stub directories
LOCAL_COMMON_DIR ?= ../../common
SERVER_COMMON_DIR = ~cis341/current/common

all: ocamlbin

define LinkCommonDir

$(1):
	if [ -d $(SERVER_COMMON_DIR)/$(1) ]; then \
	  ln -s $(SERVER_COMMON_DIR)/$(1) $(1); \
	else \
	  ln -s $(LOCAL_COMMON_DIR)/$(1) $(1); \
	fi
endef

COMMONDIRS = x86 util grading ll llprograms atprograms hw5programs

$(eval $(call LinkCommonDir,util))
$(eval $(call LinkCommonDir,x86))
$(eval $(call LinkCommonDir,ll))
$(eval $(call LinkCommonDir,llprograms))
$(eval $(call LinkCommonDir,atprograms))
$(eval $(call LinkCommonDir,hw5programs))
$(eval $(call LinkCommonDir,grading))


$(info COMPILING with OCAMLBUILD)

OPAM = /home1/c/cis341/.opam/4.06.0
BIN = $(OPAM)/bin
OCAMLC_CFLAGS = -cflags -I,$(OPAM)/lib/ocaml
OCAMLC_LFLAGS = -lflags -I,$(OPAM)/lib/ocaml,-I,$(BIN)/lib/stublibs,-I,$(OPAM)/lib/ocaml/stublibs

# TODO: change 'echo' to rm -f testbin
ocamlbin: $(COMMONDIRS)
	if [ -d $(SERVER_COMMON_DIR) ]; then \
	(~cis341/bin/ocamlbuild $(OCAMLC_CFLAGS) $(OCAMLC_LFLAGS) -ocamldep $(BIN)/ocamldep -ocamlc $(BIN)/ocamlc -ocamlopt $(BIN)/ocamlopt \
-use-menhir -menhir "$(BIN)/menhir --stdlib $(OPAM)/lib/menhir/" -Is util,x86,grading,ll -libs unix,str,nums main.native || rm -f testbin); \
	else \
	(ocamlbuild -use-menhir -Is util,x86,grading,ll -libs unix,str,nums main.native || echo "COMPILATION FAILED!"); \
	fi
	cp main.native ocamlbin

clean:
	ocamlbuild -clean
	rm -rf ocamlbin $(COMMONDIRS) output


