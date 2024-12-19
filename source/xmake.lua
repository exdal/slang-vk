--  ── Packages ────────────────────────────────────────────────────────
includes("packages.lua")

add_requires("unordered_dense v4.5.0")
add_requires("miniz 2.2.0")
add_requires("lz4 v1.10.0")
add_requires("slang-spirv-headers sync")

--  ── Functions ───────────────────────────────────────────────────────
local add_slang_target = function (name, options)
    local from_table = function (tbl, func)
        tbl = tbl or {}
        for _, i in ipairs(tbl) do
            local args = {}
            for _, v in ipairs(i) do
                if type(v) == "string" then
                    table.insert(args, v)
                elseif type(v) == "table" then
                    table.insert(args, v)
                end
            end
            func(table.unpack(args))
        end
    end

    options = options or {}
    local kind = options.kind or "static"
    target(name)
        set_kind(kind)
        set_default(options.default or false)
        set_languages("cxx17")
        set_warnings("extra")

        from_table(options.includes, add_includedirs)
        from_table(options.files, add_files)
        from_table(options.deps, add_deps)
        from_table(options.packages, add_packages)
        from_table(options.defines, add_defines)
        from_table(options.config_files, add_configfiles)

        if options.export_macro_prefix then
            if kind == "shared" then
                add_defines(options.export_macro_prefix .. "_DYNAMIC", { public = true })
                add_defines(options.export_macro_prefix .. "_DYNAMIC_EXPORT", { public = false })
            elseif kind == "static" then
                add_defines(options.export_macro_prefix .. "_STATIC", { public = true })
            end
        end

        if is_os("windows") and options.windows_files then
            add_files(options.windows_files)
        elseif is_os("linux") and options.linux_files then
            add_files(options.linux_files)
        end

        if options.rules then
            for _, rule in ipairs(options.rules) do
                add_rules(rule)
            end
        end

        if options.before_build then
            before_build(options.before_build)
        end

        if options.on_config then
            on_config(options.on_config)
        end

        set_enabled(not options.enabled or false)
        set_policy("build.fence", options.fence or false)
    target_end()
end

--  ── core ────────────────────────────────────────────────────────────
add_slang_target("core", {
    includes = {
        { "$(projectdir)/include", "$(projectdir)/source", { public = true } }
    },
    files = {
        { "core/*.cpp" }
    },
    windows_files = "core/windows/*.cpp",
    linux_files = "core/unix/*.cpp",
    packages = {
        { "miniz", "lz4", { public = false } },
        { "unordered_dense", { public = true } },
    },
})

--  ── compiler-core ───────────────────────────────────────────────────
add_slang_target("compiler-core", {
    includes = {
        { "compiler-core", { public = true } }
    },
    files = {
        { "compiler-core/*.cpp" }
    },
    deps = {
        { "core", { public = false } }
    },
    packages = {
        { "slang-spirv-headers", { public = true } }
    }
})

--  ── slang-rt ────────────────────────────────────────────────────────
add_slang_target("slang-rt", {
    kind = "shared",
    includes = {
        { "$(projectdir)/include", { public = true } },
    },
    files = {
        { "core/*.cpp" },
    },
    packages = {
        { "miniz", "lz4", { public = false } },
        { "unordered_dense", { public = true } },
    },
    export_macro_prefix = "SLANG_RT",
})

--  ── slang-core-module ───────────────────────────────────────────────
local core_module_common_args = {
    kind = get_config("lib_type"),
    files = {
        { "slang-core-module/slang-embedded-core-module.cpp" }
    },
    deps = {
        { "core", { public = false } }
    },
    export_macro_prefix = "SLANG",
}

local core_module_source_common_args = {
    kind = get_config("lib_type"),
    files = {
        { "slang-core-module/slang-embedded-core-module-source.cpp" }
    },
    deps = { {
        "core",
        "slang-generate",
        "slang-capability-defs",
        "slang-reflect-headers",
        { public = false },
    } },
    packages = {
        { "slang-spirv-headers" }
    },
    includes = {
        { "$(buildir)/core-module-meta", { public = false } }
    },
    before_build = function ()
        import("core.project.config")
        local output_dir = path.join(config.buildir(), "core-module-meta")
        local args = {}
        for _, v in ipairs(os.files("$(scriptdir)/slang/*.meta.slang")) do
            table.insert(args, v)
        end

        table.insert(args, "--target-directory")
        table.insert(args, output_dir)

        os.mkdir(output_dir)
        os.vrunv("$(projectdir)/generators/slang-generate", args)
    end
}

add_slang_target("slang-no-embedded-core-module", core_module_common_args)
add_slang_target("slang-no-embedded-core-module-source", core_module_source_common_args)

add_slang_target("slang-embedded-core-module", {
    core_module_common_args,
    defines = {
        { "SLANG_EMBED_CORE_MODULE", { public = false } }
    },
    includes = {
        { "$(buildir)", { public = false } }
    },
    enabled = get_config("embed_core_module"),
    before_build = function ()
        import("core.project.config")
        local output_dir = config.buildir()
        local generated_header = path.join(output_dir, "slang-core-module-generated.h")

        os.vrunv("$(projectdir)/generators/slang-bootstrap", {
            "-archive-type", "riff-lz4", "-save-core-module-bin-source", generated_header
        })
    end
})
add_slang_target("slang-embedded-core-module-source", {
    core_module_source_common_args,
    defines = {
        { "SLANG_EMBED_CORE_MODULE_SOURCE", { public = false } }
    },
})
--  ── slang ───────────────────────────────────────────────────────────
add_slang_target("slang-capability-defs", {
    kind = "object",
    fence = true,
    deps = {
        { "slang-capability-generator" }
    },
    includes = {
        { "$(buildir)/capabilities", "$(projectdir)/source/slang", { public = true } }
    },
    before_build = function ()
        import("core.project.config")
        local output_dir = path.join(config.buildir(), "capabilities")
        os.mkdir(output_dir)

        for _, file_path in ipairs(os.files("$(scriptdir)/slang/*.capdef")) do
            print("Generating capability defs for " .. file_path)
            os.vrunv("$(projectdir)/generators/slang-capability-generator", {
                file_path, "--target-directory", output_dir, "--doc",
                path.join(os.projectdir(), "docs/dummy.md")
            })
      end
    end,
})

add_slang_target("slang-capability-lookup", {
    kind = "object",
    deps = {
        { "core", "slang-capability-defs" }
    },
    files = {
        { "$(buildir)/capabilities/slang-lookup-capability-defs.cpp", { always_added = true } }
    },
})

add_slang_target("slang-lookup-tables", {
    kidn = "object",
    deps = {
        { "slang-lookup-generator", "slang-spirv-embed-generator" }
    },
    files = { {
        "$(buildir)/slang-lookup-tables/slang-lookup-GLSLstd450.cpp",
        "$(buildir)/slang-lookup-tables/slang-spirv-core-grammar-embed.cpp",
        { always_added = true }
    } },
    packages = {
        { "slang-spirv-headers" }
    },
    before_build = function (target)
        import("core.project.config")
        local output_dir = path.join(config.buildir(), "slang-lookup-tables")
        local spirv_path = target:pkg("slang-spirv-headers"):installdir():gsub("\\", "/")
        local grammar_dir = path.join(spirv_path, "include", "spirv", "unified1")

        local glsl_grammar_file = path.join(grammar_dir, "extinst.glsl.std.450.grammar.json")
        local glsl_generated_source = path.join(output_dir, "slang-lookup-GLSLstd450.cpp")
        local spirv_grammar_file = path.join(grammar_dir, "spirv.core.grammar.json")
        local spirv_generated_source = path.join(output_dir, "slang-spirv-core-grammar-embed.cpp")
        os.mkdir(output_dir)

        os.vrunv("$(projectdir)/generators/slang-lookup-generator", {
            glsl_grammar_file, glsl_generated_source, "GLSLstd450", "GLSLstd450",
            "spirv/unified1/GLSL.std.450.h",
        })

        os.vrunv("$(projectdir)/generators/slang-spirv-embed-generator", {
            spirv_grammar_file, spirv_generated_source
        })
    end
})

add_slang_target("slang-reflect-headers", {
    kind = "phony",
    includes = {
        { "$(buildir)/ast-reflect", { public = true } }
    },
    deps = {
        { "slang-cpp-extractor" }
    },
    before_build = function ()
        import("core.project.config")
        local working_dir = path.join(os.scriptdir(), "slang")
        local output_dir = path.absolute(path.join(config.buildir(), "ast-reflect"))

        os.mkdir(output_dir)

        local SLANG_REFLECT_INPUT = {
            "slang-ast-support-types.h",
            "slang-ast-base.h",
            "slang-ast-decl.h",
            "slang-ast-expr.h",
            "slang-ast-modifier.h",
            "slang-ast-stmt.h",
            "slang-ast-type.h",
            "slang-ast-val.h",
        }

        local args = {}
        for _, v in ipairs(SLANG_REFLECT_INPUT) do
            table.insert(args, path.join(working_dir, v))
        end
        table.insert(args, "-strip-prefix")
        table.insert(args, "slang-")
        table.insert(args, "-o")
        table.insert(args, path.join(output_dir, "slang-generated"))
        table.insert(args, "-output-fields")
        table.insert(args, "-mark-suffix")
        table.insert(args, "_CLASS")
        os.vrunv("$(projectdir)/generators/slang-cpp-extractor", args)
    end
})

add_slang_target("slang", {
    default = true,
    kind = "shared",
    includes = {
        { "$(projectdir)", "$(projectdir)/include", { public = true } },
        { "$(buildir)", { public = false } }
    },
    files = { {
        "slang/*.cpp",
        "slang-record-replay/record/*.cpp",
        "slang-record-replay/util/*.cpp",
    } },
    deps = { {
        "core",
        "prelude",
        "compiler-core",
        "slang-capability-defs",
        "slang-capability-lookup",
        "slang-reflect-headers",
        "slang-lookup-tables",
        not get_config("embed_core_module") and "slang-embedded-core-module" or "slang-no-embedded-core-module",
        not get_config("embed_core_module_source") and "slang-embedded-core-module-source" or "slang-no-embedded-core-module-source",
        { public = false }
    } },
    packages = {
        { "slang-spirv-headers" }
    },
    defines = {
        { "SLANG_USE_SYSTEM_SPIRV_HEADER" }
    },
    export_macro_prefix = "SLANG",
    config_files = {
        { "$(projectdir)/slang-tag-version.h.in", { filename = "slang-tag-version.h" } },
    },
})

add_slang_target("slang-without-embedded-core-module", {
    kind = "phony",
    deps = {
        { "slang", { public = true } }
    },
})

--  ── slang-glslang ───────────────────────────────────────────────────
if has_config("enable_glslang") then
    add_requires("slang-glslang sync")
    add_requires("slang-spirv-tools sync")

    add_slang_target("slang-glslang", {
        kind = "shared",
        includes = { {
            "$(projectdir)/source/slang-glslang",
            "$(projectdir)/include"
        } },
        files = { {
            "slang-glslang/slang-glslang.cpp",
        } },
        packages = { {
            "slang-glslang", "slang-spirv-headers", "slang-spirv-tools"
        } },
    })
end
