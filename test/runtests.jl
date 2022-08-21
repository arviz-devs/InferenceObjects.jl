using Pkg
using Test

# adapted from https://github.com/SciML/Optimization.jl/blob/master/test/runtests.jl

const GROUP = get(ENV, "GROUP", "InferenceObjects")

function dev_subpkg(subpkg)
    subpkg_path = joinpath(dirname(@__DIR__), "lib", subpkg)
    Pkg.develop(PackageSpec(; path=subpkg_path))
    return nothing
end

function activate_subpkg_env(subpkg)
    subpkg_path = joinpath(dirname(@__DIR__), "lib", subpkg)
    Pkg.activate(subpkg_path)
    Pkg.develop(PackageSpec(; path=subpkg_path))
    Pkg.instantiate()
    return nothing
end

if GROUP == "InferenceObjects"
    using InferenceObjects
    @testset "InferenceObjects" begin
        include("test_helpers.jl")
        include("utils.jl")
        include("dimensions.jl")
        include("dataset.jl")
        include("inference_data.jl")
        include("convert_dataset.jl")
        include("convert_inference_data.jl")
        include("from_namedtuple.jl")
    end
else
    dev_subpkg(GROUP)
    subpkg_path = joinpath(dirname(@__DIR__), "lib", GROUP)
    Pkg.test(PackageSpec(; name=GROUP, path=subpkg_path))
end
