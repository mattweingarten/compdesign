OCBFLAGS := -r -Is util,x86
OCB := ocamlbuild $(OCBFLAGS)

.PHONY: all debug clean top profile

all: main.native calculator
debug: all main.cma

%.cma: .FORCE
	$(OCB) $@

%.cmxa: .FORCE
	$(OCB) $@

%.native: .FORCE
	$(OCB) $@

%.byte: .FORCE
	$(OCB) $@

calculator.s: main.native
	./main.native &> calculator.s

runtime.s: runtime.c
	gcc -O0 -fno-asynchronous-unwind-tables -S runtime.c

calculator: calculator.s runtime.s
	gcc -o calculator runtime.s calculator.s 

test: calculator
	./calculator 1 2 3 4 5 6 7 8

.FORCE:

clean:
	$(OCB) -clean
	rm calculator.s calculator runtime.s

top: x86.byte
	utop

