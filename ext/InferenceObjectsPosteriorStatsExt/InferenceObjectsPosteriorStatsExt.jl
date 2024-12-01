module InferenceObjectsPosteriorStatsExt

using Base: @doc
using DimensionalData: DimensionalData, Dimensions, LookupArrays
using InferenceObjects: InferenceObjects
using PosteriorStats: PosteriorStats
using StatsBase: StatsBase

import PosteriorStats: hdi, loo, loo_pit, r2_score, summarize, waic
import StatsBase: summarystats

export hdi, loo, loo_pit, r2_score, summarize, waic, summarystats

include("utils.jl")
include("hdi.jl")
include("loo.jl")
include("waic.jl")
include("loo_pit.jl")
include("r2_score.jl")
include("summarize.jl")

end  # module
