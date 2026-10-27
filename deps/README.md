SDL2 development package
=======================

The Windows build expects the official SDL2 VC development package under
`deps/sdl2/<version>/cmake/`. It is not committed here because it is a large
binary SDK. Download `SDL2-devel-2.32.10-VC.zip` from
<https://github.com/libsdl-org/SDL/releases>, unpack it, and point the build at
it either by placing it under `deps/sdl2/` or by passing `-SdlDir` to
`scripts/build-windows.ps1`.

The Linux build uses the system `libsdl2-dev` package; the AppImage packaging
script bundles the shared library into the AppImage.
