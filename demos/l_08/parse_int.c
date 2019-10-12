#include <stdlib.h>
#include <stdio.h>

int sum(int n);

int main(int argc, char **args) {
  if (argc <= 1)
    return 0;

  int n = atoi(args[1]);
  printf("n = %d\n", n);

  int s = sum(n);

  printf("s = %d\n", s);

  return 0;
}
