using InferenceObjects
using Documenter
using NCDatasets: NCDatasets  # load extension

DocMeta.setdocmeta!(
    InferenceObjects, :DocTestSetup, :(using InferenceObjects); recursive=true
)

doctestfilters = [
    r"\s+\"created_at\" => .*",  # ignore timestamps in doctests
]

makedocs(;
    modules=[InferenceObjects],
    authors="Seth Axen <seth.axen@gmail.com> and contributors",
    repo="https://github.com/arviz-devs/InferenceObjects.jl/blob/{commit}{path}#{line}",
    sitename="InferenceObjects.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://arviz-devs.github.io/InferenceObjects.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Dataset" => "dataset.md",
        "InferenceData" => "inference_data.md",
    ],
    doctestfilters=doctestfilters,
    strict=Documenter.except(:missing_docs),
)

# run doctests on extensions
function get_extension(mod::Module, name::Symbol)
    if isdefined(Base, :get_extension)
        return Base.get_extension(mod, name)
    else
        return getproperty(mod, name)
    end
end

using MCMCDiagnosticTools: MCMCDiagnosticTools
using PosteriorStats: PosteriorStats
for extended_pkg in (MCMCDiagnosticTools, PosteriorStats)
    extension_name = Symbol("InferenceObjects", extended_pkg, "Ext")
    @info "Running doctests for extension $(extension_name)"
    mod = get_extension(InferenceObjects, extension_name)
    DocMeta.setdocmeta!(mod, :DocTestSetup, :(using $(Symbol(extended_pkg))))
    doctest(mod; manual=false)
end

deploydocs(; repo="github.com/arviz-devs/InferenceObjects.jl", devbranch="main")
