add_rules("mode.debug", "mode.release", "mode.releasedbg")

local SLANG_VERSION = "2024.17"
set_project("slang")
set_version("v" .. SLANG_VERSION)
set_configvar("SLANG_VERSION", SLANG_VERSION)

-- Global Compiler Options --
add_cxxflags("-fPIC")

includes("tools")
includes("source")
