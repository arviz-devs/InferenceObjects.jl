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

end  # module
