# Raylib Kit

Raylib Wrapper Library

## Compile library

```shell
gcc -c raykit.c -o raykit.o
ar rcs libraykit.a raykit.o
```

## Link it

```shell
# Relative paths (if lib is in your project)
gcc main.c -L./lib -lraykit -o program
```
