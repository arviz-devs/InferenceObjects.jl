"""
    log_likelihood(data::InferenceData[, var_name]) -> DimArray
    log_likelihood(data::Dataset[, var_name]) -> DimArray

Get the log-likelihood array for the specified variable in `data`.

`var_name` must be provided if the `log_likelihood` group has more than one variable.

To support older InferenceData versions, if the `log_likelihood` group is not present, then
the `sample_stats` group is checked for a `log_likelihood` variable or for `var_name` if
provided
"""
function log_likelihood(
    data::InferenceObjects.InferenceData, var_name::Union{Symbol,Nothing}=nothing
)
    if haskey(data, :log_likelihood)
        return log_likelihood(data.log_likelihood, var_name)
    elseif haskey(data, :sample_stats)
        # for old InferenceData versions, log-likelihood was stored in sample_stats
        _var_name = var_name === nothing ? :log_likelihood : var_name
        return log_likelihood(data.sample_stats, _var_name)
    else
        throw(ArgumentError("Data must contain `log_likelihood` or `sample_stats` group"))
    end
end
function log_likelihood(
    log_like::InferenceObjects.Dataset, var_name::Union{Symbol,Nothing}=nothing
)
    if !(var_name === nothing)
        haskey(log_like, var_name) ||
            throw(ArgumentError("Variable `$(var_name)` not found in group"))
        return log_like[var_name]
    else
        var_names = keys(log_like)
        length(var_names) == 1 || throw(
            ArgumentError(
                "`var_name` must be specified if there are multiple variables in group"
            ),
        )
        return log_like[first(var_names)]
    end
end

function _only_observed_data_key(idata::InferenceObjects.InferenceData; var_name=nothing)
    haskey(idata, :observed_data) ||
        throw(ArgumentError("Data must contain an `observed_data` group."))
    ks = keys(idata.observed_data)
    isempty(ks) && throw(ArgumentError("`observed_data` group must not be empty."))
    if length(ks) > 1
        msg = "More than one observed data variable: $(ks)."
        if var_name !== nothing
            msg = "$msg `$var_name` must be specified."
        end
        throw(ArgumentError(msg))
    end
    return first(ks)
end

# get name of group and group itself most likely to contain posterior predictive draws
function _post_pred_or_post_name_group(idata)
    haskey(idata, :posterior_predictive) &&
        return :posterior_predictive => idata.posterior_predictive
    haskey(idata, :posterior) && return :posterior => idata.posterior
    throw(ArgumentError("No `posterior_predictive` or `posterior` group"))
end

"""
    observations_and_predictions(data::InferenceData[, y_name[, y_pred_name]])

Get arrays of observations and predictions for the specified variable in `data`.

If `y_name` and/or `y_pred_name` is not provided, then they are inferred from the data.
Generally this requires that either there is a single variable in `observed_data` or that
there is only one variable in `posterior` or `posterior_predictive` that has a matching name
in `observed_data`, optionally with the suffix `_pred`.

The return value has the structure `(y_name => y, y_pred_name => y_pred)`, where `y_name`
and `y_pred_name` are the actual names found.
"""
function observations_and_predictions end
function observations_and_predictions(
    idata::InferenceObjects.InferenceData, y_name::Union{Symbol,Nothing}=nothing
)
    return observations_and_predictions(idata, y_name, nothing)
end
function observations_and_predictions(
    idata::InferenceObjects.InferenceData, y_name::Symbol, y_pred_name::Symbol
)
    haskey(idata, :observed_data) ||
        throw(ArgumentError("Data must contain `observed_data` group"))
    y = idata.observed_data[y_name]
    _, post_pred = _post_pred_or_post_name_group(idata)
    y_pred = post_pred[y_pred_name]
    return (y_name => y, y_pred_name => y_pred)
end
function observations_and_predictions(
    idata::InferenceObjects.InferenceData, ::Nothing, y_pred_name::Symbol
)
    y_name = _only_observed_data_key(idata; var_name=:y_name)
    y = idata.observed_data[y_name]
    _, post_pred = _post_pred_or_post_name_group(idata)
    y_pred = post_pred[y_pred_name]
    return (y_name => y, y_pred_name => y_pred)
end
function observations_and_predictions(
    idata::InferenceObjects.InferenceData, y_name::Symbol, ::Nothing
)
    haskey(idata, :observed_data) ||
        throw(ArgumentError("Data must contain `observed_data` group"))
    observed_data = idata.observed_data
    y = observed_data[y_name]
    post_pred_name, post_pred = _post_pred_or_post_name_group(idata)
    y_pred_names = (y_name, Symbol("$(y_name)_pred"))
    for y_pred_name in y_pred_names
        if haskey(post_pred, y_pred_name)
            y_pred = post_pred[y_pred_name]
            return (y_name => y, y_pred_name => y_pred)
        end
    end
    throw(
        ArgumentError(
            "Could not find names $y_pred_names in group `$post_pred_name`. `y_pred_name` must be specified.",
        ),
    )
end
function observations_and_predictions(
    idata::InferenceObjects.InferenceData, ::Nothing, ::Nothing
)
    haskey(idata, :observed_data) ||
        throw(ArgumentError("Data must contain `observed_data` group"))
    observed_data = idata.observed_data
    obs_keys = keys(observed_data)
    if length(obs_keys) == 1
        y_name = first(obs_keys)
        return observations_and_predictions(idata, y_name, nothing)
    else
        _, post_pred = _post_pred_or_post_name_group(idata)
        var_name_pairs = filter(
            !isnothing,
            map(obs_keys) do k
                for k_pred in (k, Symbol("$(k)_pred"))
                    haskey(post_pred, k_pred) && return (k, k_pred)
                end
                return nothing
            end,
        )
        if length(var_name_pairs) == 1
            y_name, y_pred_name = first(var_name_pairs)
            y = observed_data[y_name]
            y_pred = post_pred[y_pred_name]
            return (y_name => y, y_pred_name => y_pred)
        else
            throw(
                ArgumentError(
                    "No unique pair of variable names. `y_name` and/or `y_pred_name` must be specified.",
                ),
            )
        end
    end
end

_as_dimarray(x::DimensionalData.AbstractDimArray, ::DimensionalData.AbstractDimArray) = x
function _as_dimarray(x::Union{Real,Missing}, arr::DimensionalData.AbstractDimArray)
    return Dimensions.rebuild(arr, fill(x), ())
end

function _draw_chains_params_array(x::DimensionalData.AbstractDimArray)
    sample_dims = Dimensions.dims(x, InferenceObjects.DEFAULT_SAMPLE_DIMS)
    param_dims = Dimensions.otherdims(x, sample_dims)
    dims_combined = Dimensions.combinedims((sample_dims..., param_dims...))
    Dimensions.dimsmatch(Dimensions.dims(x), dims_combined) && return x
    return PermutedDimsArray(x, dims_combined)
end
