#include "poly.h"

#include <stdlib.h>
#include <stdint.h>
#include <gmp.h>

void poly_deinit(poly_t p) {
    for (size_t i = 0; i < p->length; i++) {
        mpz_clear(p->coefficients[i]);
    }
    free(p->coefficients);
    p->coefficients = NULL;
    p->length = 0;
}

void poly_init(poly_t p, size_t length) {
    p->length = length;
    p->coefficients = malloc(length * sizeof(mpz_t));
    for (size_t i = 0; i < length; i++) {
        mpz_init(p->coefficients[i]);
    }
}

void poly_memset(poly_t p, uint64_t value) {
    for (size_t i = 0; i < p->length; i++) {
        mpz_set_ui(p->coefficients[i], value);
    }
}

void poly_copy(poly_t dest, const poly_t src) {
    for (size_t i = 0; i < src->length; i++) {
        mpz_set(dest->coefficients[i], src->coefficients[i]);
    }
}

void poly_mod_multiply(poly_t result, const poly_t a, const poly_t b, const mpz_t modulus) {
    poly_memset(result, 0);
    for (size_t i = 0; i < a->length; i++) {
        if(mpz_sgn(a->coefficients[i]) == 0) continue;
        for (size_t j = 0; j < b->length; j++) {
            if(mpz_sgn(b->coefficients[j]) == 0) continue;
            uint64_t new_degree = (i+j)%a->length;
            mpz_addmul(result->coefficients[new_degree], a->coefficients[i], b->coefficients[j]);
        }
    }
    for(size_t i = 0; i < result->length; i++) {
        mpz_mod(result->coefficients[i], result->coefficients[i], modulus);
    }
}
void poly_power_mod(poly_t result, const poly_t base, const mpz_t exponent, const mpz_t modulus) {
    poly_memset(result, 0);
    mpz_set_ui(result->coefficients[0], 1);

    poly_t current_base;
    poly_init(current_base, base->length);
    poly_copy(current_base, base);

    poly_t temp;
    poly_init(temp, base->length);

    size_t exp_bits = mpz_sizeinbase(exponent, 2);
    for (size_t i = 0; i < exp_bits; i++) {
        if (mpz_tstbit(exponent, i)) {
            poly_mod_multiply(temp, result, current_base, modulus);
            poly_copy(result, temp);
        }
        if (i < exp_bits - 1) {
            poly_mod_multiply(temp, current_base, current_base, modulus);
            poly_copy(current_base, temp);
        }
    }
    poly_deinit(current_base);
    poly_deinit(temp);
}

