// mathlib.c
#include "mathlib.h"

int add(int a, int b)
{
    return a + b;
}

int mul(int a, int b)
{
    return a * b;
}

int run_operation(Operation op)
{
    switch (op.op)
    {
    case OP_ADD:
        return op.a + op.b;
    case OP_SUB:
        return op.a - op.b;
    case OP_MUL:
        return op.a * op.b;
    case OP_DIV:
        return op.b != 0 ? op.a / op.b : 0;
    default:
        return 0;
    }
}
