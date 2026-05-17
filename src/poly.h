#ifndef POLY_H
#define POLY_H

#include <gmp.h>
#include <stddef.h>
#include <stdint.h>

typedef struct {
    size_t length;
    mpz_t* coefficients;
} __poly_struct;

typedef __poly_struct poly_t[1];

void poly_init(poly_t p, size_t length);
void poly_deinit(poly_t p);
void poly_mod_multiply(poly_t result, const poly_t a, const poly_t b, const mpz_t modulus);
void poly_power_mod(poly_t result, const poly_t base, const mpz_t exponent, const mpz_t modulus);
void poly_copy(poly_t dest, const poly_t src);
void poly_memset(poly_t p, uint64_t value);

#endif
