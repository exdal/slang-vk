add_rules("mode.debug", "mode.release", "mode.releasedbg")

local SLANG_VERSION = "2024.17"
set_project("slang")
set_version("v" .. SLANG_VERSION)
set_configvar("SLANG_VERSION", SLANG_VERSION)

-- Options --
option("embed_core_module_source")
    set_default(true)
    set_description("Embed core module source in the binary")
    add_defines("SLANG_EMBED_CORE_MODULE_SOURCE")

option("embed_core_module")
    set_default(true)
    set_description("Build slang with an embedded version of the core module")
    add_defines("SLANG_EMBED_CORE_MODULE")

option("enable_glslang")
    set_default(true)
    set_description("Enable glslang dependency and slang-glslang wrapper target")

option("enable_replayer")
    set_default(true)
    set_description("Enable slang-replay tool")

option("build_shared")
    set_default(true)

-- Global Compiler Options --

includes("tools")
includes("source")
includes("prelude")
