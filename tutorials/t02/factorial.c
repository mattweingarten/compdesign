#include <stdio.h>
#include <inttypes.h>
int64_t factorial(int64_t);
int main() {
   for (int64_t i = 0; i < 10; ++i) {
        printf("%ld, %ld\n",i ,factorial(i)); 
   }
   return 0;
}
