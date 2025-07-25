@doc """
    loo_pit(idata::InferenceData, log_weights; kwargs...) -> DimArray

Compute LOO-PIT values using existing normalized log LOO importance weights.

# Keywords

  - `y_name`: Name of observed data variable in `idata.observed_data`. If not provided, then
    the only observed data variable is used.
  - `y_pred_name`: Name of posterior predictive variable in `idata.posterior_predictive`.
    If not provided, then `y_name` is used.
  - `kwargs`: Remaining keywords are forwarded to the base method
    [`PosteriorStats.loo_pit`](@extref).

See [`PosteriorStats.loo_pit`](@extref) for more details.

# Examples

Calculate LOO-PIT values using already computed log weights.

```jldoctest
julia> using ArviZExampleData, PosteriorStats

julia> idata = load_example_data("centered_eight");

julia> loo_result = loo(idata; var_name=:obs);

julia> loo_pit(idata, loo_result.psis_result.log_weights; y_name=:obs)
┌ 8-element DimArray{Float64, 1} loo_pit_obs ┐
├────────────────────────────────────────────┴─────────────────── dims ┐
  ↓ school Categorical{String} ["Choate", …, "Mt. Hermon"] Unordered
└──────────────────────────────────────────────────────────────────────┘
 "Choate"            0.942759
 "Deerfield"         0.641057
 "Phillips Andover"  0.32729
 "Phillips Exeter"   0.581451
 "Hotchkiss"         0.288523
 "Lawrenceville"     0.393741
 "St. Paul's"        0.886175
 "Mt. Hermon"        0.638821
```
"""
function PosteriorStats.loo_pit(
    idata::InferenceObjects.InferenceData,
    log_weights::AbstractArray;
    y_name::Union{Symbol,Nothing}=nothing,
    y_pred_name::Union{Symbol,Nothing}=nothing,
    kwargs...,
)
    (_y_name, y), (_, _y_pred) = observations_and_predictions(idata, y_name, y_pred_name)
    y_pred = _draw_chains_params_array(_y_pred)
    pitvals = PosteriorStats.loo_pit(y, y_pred, log_weights; kwargs...)
    return DimensionalData.rebuild(pitvals; name=Symbol("loo_pit_$(_y_name)"))
end

@doc """
    loo_pit(idata::InferenceData; kwargs...) -> DimArray

Compute LOO-PIT from groups in `idata` using PSIS-LOO.

# Keywords

  - `y_name`: Name of observed data variable in `idata.observed_data`. If not provided, then
    the only observed data variable is used.
  - `y_pred_name`: Name of posterior predictive variable in `idata.posterior_predictive`.
    If not provided, then `y_name` is used.
  - `log_likelihood_name`: Name of log-likelihood variable in `idata.log_likelihood`.
    If not provided, then `y_name` is used if `idata` has a `log_likelihood` group,
    otherwise the only variable is used.
  - `reff::Union{Real,AbstractArray{<:Real}}`: The relative effective sample size(s) of the
    _likelihood_ values. If an array, it must have the same data dimensions as the
    corresponding log-likelihood variable. If not provided, then this is estimated using
    `ess`.
  - `kwargs`: Remaining keywords are forwarded to [`PosteriorStats.loo_pit`](@extref).

See [`PosteriorStats.loo_pit`](@extref) for more details.

# Examples

Calculate LOO-PIT values using as test quantity the observed values themselves.

```jldoctest
julia> using ArviZExampleData, PosteriorStats

julia> idata = load_example_data("centered_eight");

julia> loo_pit(idata; y_name=:obs)
┌ 8-element DimArray{Float64, 1} loo_pit_obs ┐
├────────────────────────────────────────────┴─────────────────── dims ┐
  ↓ school Categorical{String} ["Choate", …, "Mt. Hermon"] Unordered
└──────────────────────────────────────────────────────────────────────┘
 "Choate"            0.942759
 "Deerfield"         0.641057
 "Phillips Andover"  0.32729
 "Phillips Exeter"   0.581451
 "Hotchkiss"         0.288523
 "Lawrenceville"     0.393741
 "St. Paul's"        0.886175
 "Mt. Hermon"        0.638821
```
"""
function PosteriorStats.loo_pit(
    idata::InferenceObjects.InferenceData;
    y_name::Union{Symbol,Nothing}=nothing,
    y_pred_name::Union{Symbol,Nothing}=nothing,
    log_likelihood_name::Union{Symbol,Nothing}=nothing,
    reff=nothing,
    kwargs...,
)
    (_y_name, y), (_, _y_pred) = observations_and_predictions(idata, y_name, y_pred_name)
    y_pred = _draw_chains_params_array(_y_pred)
    if log_likelihood_name === nothing
        if haskey(idata, :log_likelihood)
            _log_like = log_likelihood(idata.log_likelihood, _y_name)
        elseif haskey(idata, :sample_stats) && haskey(idata.sample_stats, :log_likelihood)
            _log_like = idata.sample_stats.log_likelihood
        else
            throw(ArgumentError("There must be a `log_likelihood` group in `idata`"))
        end
    else
        _log_like = log_likelihood(idata.log_likelihood, log_likelihood_name)
    end
    log_like = _draw_chains_params_array(_log_like)
    psis_result = PosteriorStats.loo(log_like; reff).psis_result
    pitvals = PosteriorStats.loo_pit(y, y_pred, psis_result.log_weights; kwargs...)
    return DimensionalData.rebuild(pitvals; name=Symbol("loo_pit_$(_y_name)"))
end
