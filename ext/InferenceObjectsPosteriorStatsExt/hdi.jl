# this pattern ensures that the type is completely specified at compile time
const HDI_BOUND_DIM = let
    dims = Dimensions.format(Dimensions.Dim{:hdi_bound}([:lower, :upper]), Base.OneTo(2))
    # some versions of DimensionalData return a tuple here, others return a Dim
    dims isa Tuple ? only(dims) : dims
end

@doc """
    hdi(data::InferenceData; kwargs...) -> Dataset
    hdi(data::Dataset; kwargs...) -> Dataset

Calculate the highest density interval (HDI) for each parameter in the data.
"""
function PosteriorStats.hdi(data::InferenceObjects.InferenceData; kwargs...)
    return PosteriorStats.hdi(data.posterior; kwargs...)
end
function PosteriorStats.hdi(data::InferenceObjects.Dataset; kwargs...)
    results = map(DimensionalData.data(data), DimensionalData.layerdims(data)) do var, dims
        x = _draw_chains_params_array(DimensionalData.DimArray(var, dims))
        r = PosteriorStats.hdi(x; kwargs...)
        lower, upper = map(Base.Fix2(_as_dimarray, x), r)
        return cat(lower, upper; dims=HDI_BOUND_DIM)
    end
    dims = Dimensions.combinedims((
        Dimensions.otherdims(data, InferenceObjects.DEFAULT_SAMPLE_DIMS)..., HDI_BOUND_DIM
    ))
    return DimensionalData.rebuild(
        data;
        data=map(parent, results),
        dims,
        layerdims=map(Dimensions.dims, results),
        refdims=(),
        metadata=DimensionalData.NoMetadata(),
    )
end
