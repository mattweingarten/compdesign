#include <stdio.h>
#include <inttypes.h>

int64_t n_nplus1(int64_t);
int main() {
   for (int64_t i = 0; i < 10; ++i) {
        printf("%ld, %ld\n",i , n_nplus1(i)); 
   }
   return 0;
}
