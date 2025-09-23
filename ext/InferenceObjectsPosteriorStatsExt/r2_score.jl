@doc """
    r2_score(idata::InferenceData; y_name, y_pred_name, kwargs...) -> (; r2, <ci>)

Compute ``R²`` from `idata`, automatically formatting the predictions to the correct shape.

# Keywords

  - `y_name`: Name of observed data variable in `idata.observed_data`. If not provided, then
    the only observed data variable is used.
  - `y_pred_name`: Name of posterior predictive variable in `idata.posterior_predictive`.
    If not provided, then `y_name` is used.
  - `kwargs...`: Additional keyword arguments to pass to
    [`PosteriorStats.r2_score`](@extref).

# Examples

```jldoctest
julia> using ArviZExampleData, PosteriorStats

julia> idata = load_example_data("regression10d");

julia> r2_score(idata)
(r2 = 0.998384805658226, eti = 0.9982167674001565 .. 0.9985401916739318)
```
"""
function PosteriorStats.r2_score(
    idata::InferenceObjects.InferenceData;
    y_name::Union{Symbol,Nothing}=nothing,
    y_pred_name::Union{Symbol,Nothing}=nothing,
)
    (_, y), (_, y_pred) = observations_and_predictions(idata, y_name, y_pred_name)
    y_data = y isa DimensionalData.AbstractDimArray ? parent(y) : y
    y_data, y_pred_data = map((y, _draw_chains_params_array(y_pred))) do arr
        return arr isa DimensionalData.AbstractDimArray ? parent(arr) : arr
    end
    return PosteriorStats.r2_score(y_data, y_pred_data)
end
