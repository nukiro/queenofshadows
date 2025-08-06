# Raylib Kit

Raylib Wrapper Library

## Compile library

Manually

```shell
gcc -c raykit.c -o raykit.o
ar rcs libraykit.a raykit.o
```

Using `zmake`:

```shell
zmake --folder raykit --static-library
```

## Link it

```shell
# Relative paths (if lib is in your project)
gcc main.c -L./lib -lraykit -o program
```

## Components

### Window

Base **raylib** window with dev parameters shown if `DEBUG` configuration variables is set.

![raylib window](window.png)

## Run it

```shell
zmake --folder playground/window
```
