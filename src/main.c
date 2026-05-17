#include <stdio.h>
#include <gmp.h>
#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include "poly.h"

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

uint64_t phi(uint64_t r) {
    uint64_t result = r;
    for (uint64_t p = 2; p * p <= r; p++) {
        if (r % p == 0) {
            while (r % p == 0) {
                r /= p;
            }
            result -= result / p;
        }
    }
    if (r > 1) {
        result -= result / r;
    }
    return result;
}

uint64_t isqrt(uint64_t n) {
    if (n <= 1) return n;
    uint64_t x = n;
    uint64_t y = x / 2;
    while (y < x) {
        x = y;
        y = (x + n / x) / 2;
    }
    return x;
}

bool aks_test(mpz_t n, bool use_unproven) {
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

    uint64_t phi_r = phi(r);
    uint64_t limit = isqrt(phi_r*bound);
    if (use_unproven) {
        printf("Agrawal's Conjecture active: limit reduced from %lu to 1\n", limit);
        limit = 1;
    }
    poly_t left;
    poly_init(left, r);

    poly_t result;
    poly_init(result, r);

    uint64_t n_mod_r = mpz_fdiv_ui(n, r);

    for (uint64_t a = 1; a <= limit; a++) {
        printf("\rTesting a = %lu out of %lu", a, limit);
        fflush(stdout);
        poly_memset(left, 0);
        mpz_set_ui(left->coefficients[0], a);
        mpz_set_ui(left->coefficients[1], 1);

        poly_power_mod(result, left, n, n);
        for(size_t i = 0; i < r; i++) {
            uint64_t expected = 0;
            if (i == 0) {
                expected = a;
            } else if (i == n_mod_r) {
                expected = 1;
            }

            if (mpz_cmp_ui(result->coefficients[i], expected) != 0) {
                poly_deinit(left);
                poly_deinit(result);
                return false;
            }
        }
    } 
    poly_deinit(left);
    poly_deinit(result);
    return true;
}

bool naive_test(mpz_t n) {
    if(mpz_cmp_ui(n, 2) < 0) return false;
    if(mpz_cmp_ui(n, 2) == 0) return true;
    if(mpz_even_p(n)) return false;

    mpz_t i, percentage_helper, limit;
    mpz_init(i);
    mpz_init(limit);
    mpz_init(percentage_helper);

    uint64_t last_percent = 101;
    uint16_t iterations = 0;

    mpz_sqrt(limit, n);

    for(mpz_set_ui(i, 3); mpz_cmp(i, limit) <= 0; mpz_add_ui(i, i, 2)) {
        if(mpz_divisible_p(n, i)) {
            mpz_clear(i);
            mpz_clear(limit);
            mpz_clear(percentage_helper);
            return false;
        }
        if(iterations == 0) {
            mpz_set(percentage_helper, i);
            mpz_mul_ui(percentage_helper, percentage_helper, 100);
            mpz_fdiv_q(percentage_helper, percentage_helper, limit);
            uint64_t percent = mpz_get_ui(percentage_helper);
            if(percent != last_percent) {
                printf("\rTesting: %lu%%", percent);
                fflush(stdout);
                last_percent = percent;
            }
        }
        iterations++;
        
    }
    mpz_clear(i);
    mpz_clear(limit);
    mpz_clear(percentage_helper);


    return true;
}

int main(int argc, char *argv[]) {
    bool use_naive = false;
    bool use_unproven = false;
    char* target_number_str = NULL;
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--naive") == 0) {
            use_naive = true;
        } else if (strcmp(argv[i], "--use-unproven") == 0) {
            use_unproven = true;
        } else if(target_number_str == NULL) {
            target_number_str = argv[i];
        } else {
            fprintf(stderr, "Usage: %s [--naive] [--use-unproven] [number]\n", argv[0]);
            return 1;
        }
    }

    if(target_number_str == NULL) {
        fprintf(stderr, "Usage: %s [--naive] [--use-unproven] [number]\n", argv[0]);
        return 1;
    }
    mpz_t n;
    mpz_init(n);

    if (mpz_set_str(n, target_number_str, 10) != 0) {
        fprintf(stderr, "Invalid number: '%s'\n", target_number_str);
        mpz_clear(n);
        return 1;
    }
    gmp_printf("n = %Zd\n", n);


    bool is_prime;
    if (use_naive) {
        printf("Using naive primality test...\n");
        is_prime = naive_test(n);
    } else {
        printf("Using AKS primality test...\n");
        is_prime = aks_test(n, use_unproven);
    }
    if (is_prime) {
        printf("\nResult: n is prime.\n");
    } else {
        printf("\nResult: n is composite.\n");
    }

    mpz_clear(n);

    return 0;
}
