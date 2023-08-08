module InferenceObjectsPosteriorStatsExt

if isdefined(Base, :get_extension)
    using Compat: stack
    using DimensionalData: DimensionalData, Dimensions, LookupArrays
    using InferenceObjects: InferenceObjects
    using PosteriorStats: PosteriorStats
    using StatsBase: StatsBase
else  # using Requires
    using ..Compat: stack
    using ..DimensionalData: DimensionalData, Dimensions, LookupArrays
    using ..InferenceObjects: InferenceObjects
    using ..PosteriorStats: PosteriorStats
    using ..StatsBase: StatsBase
end

include("utils.jl")
include("hdi.jl")
include("loo.jl")
include("waic.jl")
include("loo_pit.jl")
include("r2_score.jl")
include("summarize.jl")

end  # module
