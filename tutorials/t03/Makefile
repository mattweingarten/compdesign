all: simple simple2 calling_conventions

simple: simple.c
	gcc -O0 -S -m32 simple.c -o simple_m32.s
	gcc -O0 -S -m64 simple.c -o simple_m64.s

simple2: simple2.c
	# gcc -O0 -S -m32 simple2.c -o simple2_m32.s
	gcc -O0 -S -m64 simple2.c -o simple2_m64.s

calling_conventions:
	gcc -O0 -S calling_conventions.c

clean:
	rm *.s