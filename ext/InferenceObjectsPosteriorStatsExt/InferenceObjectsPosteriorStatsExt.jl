module InferenceObjectsPosteriorStatsExt

using Base: @doc
using DimensionalData: DimensionalData, Dimensions, LookupArrays
using InferenceObjects: InferenceObjects
using PosteriorStats: PosteriorStats
using StatsBase: StatsBase

import StatsBase: summarystats

maplayers = isdefined(DimensionalData, :maplayers) ? DimensionalData.maplayers : map

include("utils.jl")
include("ci.jl")
include("loo.jl")
include("waic.jl")
include("loo_pit.jl")
include("r2_score.jl")
include("summarize.jl")

end  # module
