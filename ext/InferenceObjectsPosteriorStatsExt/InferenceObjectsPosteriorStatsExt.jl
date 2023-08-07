module InferenceObjectsPosteriorStatsExt

if isdefined(Base, :get_extension)
    using Compat: stack
    using DimensionalData: DimensionalData, Dimensions, LookupArrays
    using InferenceObjects: InferenceObjects
    using PosteriorStats: PosteriorStats
else  # using Requires
    using ..Compat: stack
    using ..DimensionalData: DimensionalData, Dimensions, LookupArrays
    using ..InferenceObjects: InferenceObjects
    using ..PosteriorStats: PosteriorStats
end

include("utils.jl")
include("hdi.jl")
include("loo.jl")
include("waic.jl")
include("loo_pit.jl")
include("r2_score.jl")

end  # module
