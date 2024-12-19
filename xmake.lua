add_rules("mode.debug", "mode.release", "mode.releasedbg")

-- Global Compiler Options --
add_cxxflags(
    "-Wno-assume",
    "-Wno-switch",
    "-Wno-constant-logical-operand",
    "-Wno-invalid-offsetof",
    "-Wno-dangling-else",
    { tools = { "clang", "gcc", "clang_cl" } }
)

add_cxxflags("-fPIC", { tools = { "clang", "gcc" } })
set_encodings("utf-8")

local SLANG_VERSION = "2024.17"
set_project("slang")
set_version("v" .. SLANG_VERSION)
set_configvar("SLANG_VERSION", SLANG_VERSION)

-- Options --
option("embed_core_module_source")
    set_default(true)
    set_description("Embed core module source in the binary")
    add_defines("SLANG_EMBED_CORE_MODULE_SOURCE")
option_end()

option("embed_core_module")
    set_default(true)
    set_description("Build slang with an embedded version of the core module")
    add_defines("SLANG_EMBED_CORE_MODULE")
option_end()

option("enable_glslang")
    set_default(true)
    set_description("Enable glslang dependency and slang-glslang wrapper target")
option_end()

option("enable_replayer")
    set_default(true)
    set_description("Enable slang-replay tool")
option_end()

option("lib_type")
    set_default("static")
option_end()

includes("tools")
includes("source")
includes("prelude")
