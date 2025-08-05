# Project Setup

## Ubuntu

### `c_cpp_properties.json`

```json
{
  "configurations": [
    {
      "name": "Linux",
      "cStandard": "c23",
      "defines": ["true=1", "false=0"],
      "includePath": ["${workspaceFolder}/**"]
    }
  ],
  "version": 4
}
```

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

### `c_cpp_properties.json`

```json
{
  "configurations": [
    {
      "name": "Mac",
      "includePath": [
        "${workspaceFolder}/**",
        "/opt/homebrew/opt/raylib/include"
      ],
      "compilerPath": "/usr/bin/clang",
      "cStandard": "c23",
      "defines": ["true=1", "false=0"],
      "intelliSenseMode": "macos-clang-arm64"
    }
  ],
  "version": 4
}
```
