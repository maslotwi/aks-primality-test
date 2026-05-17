#include "poly.h"

#include <stdlib.h>
#include <stdint.h>

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

