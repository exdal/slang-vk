add_rules("mode.debug", "mode.release", "mode.releasedbg")

-- Global Compiler Options --
add_cxxflags(
    "-Wno-assume",
    "-Wno-switch",
    "-Wno-constant-logical-operand",
    "-Wno-invalid-offsetof",
    "-Wno-dangling-else",
    { force = true, tools = { "clang", "gcc", "clang_cl" } }
)

add_cxxflags("-fPIC", { tools = { "clang", "gcc" } })
set_encodings("utf-8")

local SLANG_VERSION = "2024.17"
set_project("slang")
set_version("v" .. SLANG_VERSION)
set_configvar("SLANG_VERSION", SLANG_VERSION)

-- Options --
option("enable_replayer")
    set_default(true)
    set_description("Enable slang-replay tool")
option_end()

includes("tools")
includes("source")
includes("prelude")
