// mathlib.h
#ifndef MATHLIB_H
#define MATHLIB_H

typedef enum
{
    OP_ADD,
    OP_SUB,
    OP_MUL,
    OP_DIV
} OpType;

typedef struct
{
    int a;
    int b;
    OpType op;
} Operation;

int add(int a, int b);
int mul(int a, int b);
int run_operation(Operation op);

#endif
