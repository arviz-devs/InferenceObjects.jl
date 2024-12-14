@doc """
    waic(data::Dataset; [var_name::Symbol]) -> WAICResult{<:NamedTuple,<:Dataset}
    waic(data::InferenceData; [var_name::Symbol]) -> WAICResult{<:NamedTuple,<:Dataset}

Compute WAIC from log-likelihood values in `data`.

If more than one log-likelihood variable is present, then `var_name` must be provided.

See [`PosteriorStats.waic`](@extref) for more details.

# Examples

Calculate WAIC of a model:

```jldoctest
julia> using ArviZExampleData, PosteriorStats

julia> idata = load_example_data("centered_eight");

julia> waic(idata)
WAICResult with estimates
 elpd  elpd_mcse    p  p_mcse
  -31        1.4  0.9    0.33
```
"""
function PosteriorStats.waic(
    data::Union{InferenceObjects.InferenceData,InferenceObjects.Dataset};
    var_name::Union{Symbol,Nothing}=nothing,
)
    log_like = _draw_chains_params_array(log_likelihood(data, var_name))
    result = PosteriorStats.waic(log_like)
    pointwise = Dimensions.rebuild(
        InferenceObjects.convert_to_dataset(result.pointwise; default_dims=());
        metadata=DimensionalData.NoMetadata(),
    )
    return PosteriorStats.WAICResult(result.estimates, pointwise)
end
