-- Disable annoying warnings project wide --
add_cxxflags(
    "-Wno-assume",
    "-Wno-switch",
    "-Wno-constant-logical-operand",
    "-Wno-invalid-offsetof",
    "-Wno-dangling-else",
    { tools = { "clang", "gcc" } }
)

--  ── Packages ────────────────────────────────────────────────────────
add_requires("unordered_dense v4.5.0")
add_requires("miniz 2.2.0")
add_requires("lz4 v1.10.0")
add_requires("spirv-headers 1.3.290+0")

--  ── Functions ───────────────────────────────────────────────────────
local add_slang_target = function (dir, options)
    options = options or {}
    target(dir)
        set_kind(options.kind or "static")
        set_languages("cxx17")
        set_warnings("extra")

        for _, includes in ipairs(options.includes) do
            local paths = {}
            local include_opts = {}
            for _, v in ipairs(includes) do
                if type(v) == "string" then
                    table.insert(paths, v)
                elseif type(v) == "table" then
                    include_opts = v
                end
            end
            add_includedirs(paths, include_opts)
        end

        for _, files in ipairs(options.files) do
            add_files(files)
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

        if options.deps then
            for _, dep in ipairs(options.deps) do
                local dep_names = {}
                local dep_opts = {}
                for _, v in ipairs(dep) do
                    if type(v) == "string" then
                        table.insert(dep_names, v)
                    elseif type(v) == "table" then
                        dep_opts = v
                    end
                end
                add_deps(dep_names, dep_opts)
            end
        end

        if options.packages then
            for _, packages in ipairs(options.packages) do
                local package_names = {}
                local package_opts = {}
                for _, v in ipairs(packages) do
                    if type(v) == "string" then
                        table.insert(package_names, v)
                    elseif type(v) == "table" then
                        package_opts = v
                    end
                end
                add_packages(package_names, package_opts)
            end
        end
    target_end()
end

--  ── core ────────────────────────────────────────────────────────────
add_slang_target("core", {
    includes = {
        { "$(projectdir)/include", "$(projectdir)/source", { public = true } }
    },
    files = {
        "core/*.cpp"
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
        "compiler-core/*.cpp"
    },
    deps = {
        { "core", { public = false } }
    },
    packages = {
        { "spirv-headers", { public = true } }
    }
})

--  ── slang ───────────────────────────────────────────────────────────
target("slang-capability-defs")
    set_kind("object")
    add_deps("slang-capability-generator")
    add_includedirs("$(buildir)/capabilities", "$(projectdir)/source/slang", { public = true })
    before_build(function ()
        import("core.project.config")
        local output_dir = path.join(config.buildir(), "capabilities")
        os.mkdir(output_dir)

        for _, file_path in ipairs(os.files("$(scriptdir)/slang/*.capdef")) do
            print("Generating capability defs for " .. file_path)
            os.vrunv("$(projectdir)/generators/slang-capability-generator",
                    { file_path,
                     "--target-directory", output_dir,
                     "--doc", path.join(os.projectdir(), "docs/dummy.md") })
      end
    end)
target_end()

target("slang-capability-lookup")
    set_kind("object")
    add_deps("core", "slang-capability-defs")
    add_files("$(buildir)/capabilities/slang-lookup-capability-defs.cpp")
rule_end()

target("slang-reflect-headers")
    set_kind("object")
    add_deps("slang-cpp-extractor")
    add_includedirs("$(buildir)/ast-reflect", { public = true })

    before_build(function ()
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
    end)
rule_end()

target("copy_slang_headers")
    set_kind("object")
    add_configfiles("$(projectdir)/slang-tag-version.h.in", { filename = "slang-tag-version.h" })

    before_build(function ()
    end)
target_end()

-- TODO: Source embedding

add_slang_target("slang", {
    kind = "shared",
    includes = {
        { "$(projectdir)", "$(projectdir)/include", { public = true } },
        { "$(buildir)", { public = false } }
    },
    files = {
        "slang/*.cpp"
    },
    deps = {
        -- generators
        { "slang-capability-lookup", "slang-reflect-headers", "copy_slang_headers" },
        { "core", "compiler-core", { public = false } }
    },
    header_files = { "$(buildir)/slang-tag-version.h" }
})
