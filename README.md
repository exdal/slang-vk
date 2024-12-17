slang-vk
=====

Stripped down version of [slang](https://github.com/shader-slang/slang) for xmake. Meant to be used just as a shader compiler library. Only glslang is supported.

License
-------

The Slang code itself is under the Apache 2.0 with LLVM Exception license (see [LICENSE](LICENSE)).

Builds of the core Slang tools depend on the following projects, either automatically or optionally, which may have their own licenses:

* [`glslang`](https://github.com/KhronosGroup/glslang) (BSD)
* [`lz4`](https://github.com/lz4/lz4) (BSD)
* [`miniz`](https://github.com/richgel999/miniz) (MIT)
* [`spirv-headers`](https://github.com/KhronosGroup/SPIRV-Headers) (Modified MIT)
* [`spirv-tools`](https://github.com/KhronosGroup/SPIRV-Tools) (Apache 2.0)
* [`ankerl::unordered_dense::{map, set}`](https://github.com/martinus/unordered_dense) (MIT)

Slang releases may include [slang-llvm](https://github.com/shader-slang/slang-llvm) which includes [LLVM](https://github.com/llvm/llvm-project) under the license:

* [`llvm`](https://llvm.org/docs/DeveloperPolicy.html#new-llvm-project-license-framework) (Apache 2.0 License with LLVM exceptions)

Some of the tests and example programs that build with Slang use the following projects, which may have their own licenses:

* [`glm`](https://github.com/g-truc/glm) (MIT)
* `stb_image` and `stb_image_write` from the [`stb`](https://github.com/nothings/stb) collection of single-file libraries (Public Domain)
* [`tinyobjloader`](https://github.com/tinyobjloader/tinyobjloader) (MIT)
