module InferenceObjectsPosteriorStatsExt

using Base: @doc
using DimensionalData: DimensionalData, Dimensions, LookupArrays
using InferenceObjects: InferenceObjects
using PosteriorStats: PosteriorStats
using StatsBase: StatsBase

include("utils.jl")
include("hdi.jl")
include("loo.jl")
include("waic.jl")
include("loo_pit.jl")
include("r2_score.jl")
include("summarize.jl")

end  # module
