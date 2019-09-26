#include<stdlib.h>
#include<errno.h>
#include<stdio.h>
#include<stdint.h>
#include<limits.h>

// external declaration of a function with 8 arguments
extern int64_t program(int64_t x1,
		       int64_t x2,
		       int64_t x3,
		       int64_t x4,
		       int64_t x5,
		       int64_t x6,
		       int64_t x7,
		       int64_t x8);


// Helper to safely read an int64 value from a string.
// Checks the error conditions and exits if the conversion fails.

int64_t get_int64(char *str) {
  char *eptr;
  errno = 0;
  int64_t result = strtoll(str, &eptr, 10);
  if ((errno == ERANGE && (result == LONG_LONG_MAX || result == LONG_LONG_MIN))
      || (errno != 0 && result == 0)) {
    perror("strtoll");
    exit(1);
  }
  return result;
}


#define NUM_ARGS 8

int main(int argc, char* argv[]) {
  if (argc != (NUM_ARGS+1)) {
    printf("usage: calculator x1 .. x%d\n", NUM_ARGS);
    exit(0);
  }
  
  // for(int i=1; i<(NUM_ARGS+1); i++) {
  //  printf("argv[%d] = %s\n", i, argv[i]);
  // }

  // read the command-line arguments
  // (Could use a loop and an array, but that complicates the generated assembly)
  int64_t x1 = get_int64(argv[1]);
  int64_t x2 = get_int64(argv[2]);
  int64_t x3 = get_int64(argv[3]);
  int64_t x4 = get_int64(argv[4]);
  int64_t x5 = get_int64(argv[5]);
  int64_t x6 = get_int64(argv[6]);
  int64_t x7 = get_int64(argv[7]);
  int64_t x8 = get_int64(argv[8]);

  // call the program  
  int64_t ret = program(x1, x2, x3, x4, x5, x6, x7, x8);
  printf("program returned: %lld\n", ret);
  return 0;
}
	 
