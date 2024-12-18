target("prelude")
    set_kind("object")
    add_packages("unordered_dense")
    add_deps("slang-embed")

    add_files("$(scriptdir)/*.cpp")
    add_includedirs("$(scriptdir)", "$(projectdir)/include", { public = true })

    before_build(function ()
        for _, file_path in ipairs(os.files("$(scriptdir)/*-prelude.h")) do
            local file_name = path.filename(file_path)
            print("Generating prelude for " .. file_path)
            os.vrunv("$(projectdir)/generators/slang-embed", {
                file_path, path.join(os.scriptdir(), file_name .. ".cpp")
            })
      end
    end)
target_end()
