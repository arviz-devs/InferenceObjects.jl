using InferenceObjects
using Documenter
using DocumenterInterLinks
using MCMCDiagnosticTools: MCMCDiagnosticTools  # load extension
using NCDatasets: NCDatasets  # load extension
using PosteriorStats: PosteriorStats  # load extension
using StatsBase: StatsBase  # load extension

DocMeta.setdocmeta!(
    InferenceObjects, :DocTestSetup, :(using InferenceObjects); recursive=true
)

links = InterLinks(
    "arviz" => "https://python.arviz.org/en/stable/",
    "DimensionalData" => (
        "https://rafaqz.github.io/DimensionalData.jl/stable/",
        joinpath(@__DIR__, "inventories", "DimensionalData.toml"),
    ),
    "IntervalSets" => (
        "https://juliamath.github.io/IntervalSets.jl/stable/",
        joinpath(@__DIR__, "inventories", "IntervalSets.toml"),
    ),
    "NCDatasets" => "https://alexander-barth.github.io/NCDatasets.jl/stable/",
    "PosteriorStats" => "https://julia.arviz.org/PosteriorStats/stable/",
    "MCMCDiagnosticTools" => "https://julia.arviz.org/MCMCDiagnosticTools/stable/",
)

doctestfilters = [
    r"\s+\"created_at\" => .*",  # ignore timestamps in doctests
]

makedocs(;
    modules=[
        InferenceObjects,
        Base.get_extension(InferenceObjects, :InferenceObjectsMCMCDiagnosticToolsExt),
        Base.get_extension(InferenceObjects, :InferenceObjectsPosteriorStatsExt),
    ],
    authors="Seth Axen <seth.axen@gmail.com> and contributors",
    repo=Remotes.GitHub("arviz-devs", "InferenceObjects.jl"),
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
        "Extensions" => [
            "MCMCDiagnosticTools" => "extensions/mcmcdiagnostictools.md",
            "PosteriorStats" => "extensions/posteriorstats.md",
        ],
    ],
    doctestfilters=doctestfilters,
    warnonly=:missing_docs,
    plugins=[links],
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

deploydocs(;
    repo="github.com/arviz-devs/InferenceObjects.jl", devbranch="main", push_preview=true
)
