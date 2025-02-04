@doc """
    loo(data::Dataset; [var_name::Symbol,] kwargs...) -> PSISLOOResult{<:NamedTuple,<:Dataset}
    loo(data::InferenceData; [var_name::Symbol,] kwargs...) -> PSISLOOResult{<:NamedTuple,<:Dataset}

Compute PSIS-LOO from log-likelihood values in `data`.

If more than one log-likelihood variable is present, then `var_name` must be provided.

For more details and a description of the `kwargs`, see [`PosteriorStats.loo`](@extref).

# Examples

Calculate PSIS-LOO of a model:

```jldoctest
julia> using ArviZExampleData, PosteriorStats

julia> idata = load_example_data("centered_eight");

julia> loo(idata)
PSISLOOResult with estimates
 elpd  elpd_mcse    p  p_mcse
  -31        1.4  0.9    0.33

and PSISResult with 500 draws, 4 chains, and 8 parameters
Pareto shape (k) diagnostic values:
                    Count      Min. ESS
 (-Inf, 0.5]  good  4 (50.0%)  270
  (0.5, 0.7]  okay  4 (50.0%)  307
```
"""
function PosteriorStats.loo(
    data::Union{InferenceObjects.InferenceData,InferenceObjects.Dataset};
    var_name::Union{Symbol,Nothing}=nothing,
    kwargs...,
)
    log_like = _draw_chains_params_array(log_likelihood(data, var_name))
    result = PosteriorStats.loo(log_like; kwargs...)
    pointwise = Dimensions.rebuild(
        InferenceObjects.convert_to_dataset(result.pointwise; default_dims=());
        metadata=DimensionalData.NoMetadata(),
    )
    return PosteriorStats.PSISLOOResult(result.estimates, pointwise, result.psis_result)
end
