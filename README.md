# Queen of Shadows

## Setup

### Install all dependencies

```shell
sudo apt update
sudo apt install build-essential git \
 libasound2-dev libx11-dev libxrandr-dev libxi-dev \
 libxcursor-dev libxinerama-dev libwayland-dev libxkbcommon-dev \
 libgl1-mesa-dev libglu1-mesa-dev
```

### Compile and Install

```shell
git clone --depth 1 https://github.com/raysan5/raylib.git
cd raylib/src
make PLATFORM=PLATFORM_DESKTOP RAYLIB_LIBTYPE=SHARED
sudo make install RAYLIB_LIBTYPE=SHARED
rm -rf raylib
```

Running `make install` will copy and add headers to the system.
