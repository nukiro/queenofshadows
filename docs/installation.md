# Project Setup

## MacOS

Install `brew` and project dependencies.

```shell
# install brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# after brew installation finishes, install project dependencies
brew install git make zig raylib pkgconf
```

Compile and run the program.

```shell
make queen --OS=macos
./queen
```
