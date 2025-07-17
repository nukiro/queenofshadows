#include <stdlib.h>
#include <stdio.h>

void die(const char *s)
{
    fprintf(stderr, "%s.\n", s);
    exit(EXIT_FAILURE);
}
