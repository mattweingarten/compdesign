#include <stdio.h>

extern long long int program();

int main() {
  long long int	ret = program();
  printf("program returned: %llu\n", ret);
  return 0;
}
