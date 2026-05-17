#include <stdio.h>
#include <gmp.h>
#include <math.h>
#include <stdbool.h>
#include <stdint.h>


// d*2^exp = n
// log2(d*2^exp) = log2(n)
// log2(2^exp) + log2(d) = log2(n)
// exp + log2(d) = log2(n)
uint64_t floor_log2_squared(const mpz_t n) {
    signed long int exp;

    double d = mpz_get_d_2exp(&exp, n);
    double log2_n = (double)exp + log2(d);
    double res_double = floor(log2_n * log2_n);

    return (uint64_t)res_double;
}

bool aks_test(mpz_t n) {
    if(mpz_perfect_power_p(n)) return false;
    uint64_t bound = floor_log2_squared(n);
    printf("Found bound = %lu\n", bound);

    uint64_t r = 2;
    while(true) {
        if(mpz_cmp_ui(n, r) <= 0) return true;
        
        uint64_t remainder = mpz_fdiv_ui(n, r);
        if (remainder == 0) return false;

        bool is_order_large_enough = true;
        
        uint64_t current_remainder = remainder;

        for (uint64_t k = 1; k <= bound; k++) {
            if (current_remainder == 1) {
                is_order_large_enough = false;
                break;
            }
            current_remainder = ((__uint128_t)current_remainder * (__uint128_t)remainder) % r;
        }
        if(is_order_large_enough) break;
        r++;
    }
    printf("Found r: %lu\n", r);

    return true;
}

int main() {
    mpz_t n;

    mpz_init(n);
    mpz_set_str(n, "31", 10);
    gmp_printf("n = %Zd\n", n);

    if(aks_test(n)) {
        puts("n is prime");
    } else {
        puts("n is composite");
    }

    mpz_clear(n);

    return 0;
}
