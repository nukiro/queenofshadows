# `zmake` - C Project Builder written in Zig

A command-line tool written in Zig to build and run C programs.

## Installation

```shell

```

## Development

After build the program `zig build`, you can run it:

Running the executable program

```shell
# Within zig-out project directory
./zmake --help
```

Create a symlink and run the command

```shell
# From your zig-out project directory
sudo ln -sf $(pwd)/zmake /usr/local/bin/zmake
# check it
which zmake
# then
zmake --help
```

## Commands

```shell
zmake build --folder toolkit --static-library
zmake build --folder playground --executable
zmake clean --folder playground
```
