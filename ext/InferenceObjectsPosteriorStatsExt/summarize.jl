"""
    summarystats(data::InferenceData; group=:posterior, kwargs...) -> SummaryStats
    summarystats(data::Dataset; kwargs...) -> SummaryStats

Compute default summary statistics for the data using `summarize`.
"""
function StatsBase.summarystats(data::InferenceObjects.InferenceData; kwargs...)
    return PosteriorStats.summarize(data; kwargs...)
end
function StatsBase.summarystats(data::InferenceObjects.Dataset; kwargs...)
    return PosteriorStats.summarize(data; kwargs...)
end

"""
    summarize(data::InferenceData, group=:posterior, stats_funs...; kwargs...)
    summarize(data::Dataset, stats_funs...; kwargs...)

Compute summary statistics for the data using the provided functions.

For verbose variable labels, provide `compat_labels=false`. For details on `stats_funs` and
`kwargs`, see the main `summarize` method.

# Examples

Compute all default summary statistics for the eight schools model in the centered
parameterization:

```jldoctest summarize
julia> using ArviZExampleData, PosteriorStats, StatsBase

julia> data = load_example_data("centered_eight");

julia> summarize(data)
SummaryStats
                          mean  std  hdi_3%  hdi_97%  mcse_mean  mcse_std  ess_tail  ess_bulk  rhat
 mu                        4.5  3.5  -1.62     10.7        0.23      0.11       659       241  1.02
 theta[Choate]             6.5  5.9  -4.56     17.1        0.30      0.29       710       365  1.01
 theta[Deerfield]          5.0  4.9  -4.31     14.3        0.23      0.17       851       427  1.01
 theta[Phillips Andover]   3.9  5.7  -7.77     13.7        0.23      0.28       730       515  1.01
 theta[Phillips Exeter]    4.9  5.0  -4.49     14.7        0.26      0.17       869       337  1.01
 theta[Hotchkiss]          3.7  5.0  -6.47     11.7        0.25      0.16      1034       365  1.01
 theta[Lawrenceville]      4.0  5.2  -7.04     12.2        0.22      0.22      1031       521  1.01
 theta[St. Paul's]         6.6  5.1  -3.09     16.3        0.30      0.19       586       276  1.01
 theta[Mt. Hermon]         4.8  5.7  -5.86     16.0        0.26      0.25       754       452  1.01
 tau                       4.1  3.1   0.896     9.67       0.26      0.17        38        67  1.06
```

Compute the mean, standard deviation, median, and median absolute deviation of the `theta`
parameters:

```jldoctest summarize
julia> summarize(data.posterior[(:theta,)], (:mean, :std) => mean_and_std, median, mad)
SummaryStats
                          mean   std  median   mad
 theta[Choate]            6.46  5.87    6.08  4.64
 theta[Deerfield]         5.03  4.88    5.01  4.96
 theta[Phillips Andover]  3.94  5.69    4.23  4.67
 theta[Phillips Exeter]   4.87  5.01    5.02  4.82
 theta[Hotchkiss]         3.67  4.96    3.89  4.70
 theta[Lawrenceville]     3.97  5.19    4.14  4.64
 theta[St. Paul's]        6.58  5.11    6.07  4.47
 theta[Mt. Hermon]        4.77  5.74    4.71  4.95
```
"""
function PosteriorStats.summarize(
    data::InferenceObjects.InferenceData, stats_funs...; group::Symbol=:posterior, kwargs...
)
    return PosteriorStats.summarize(data[group], stats_funs...; kwargs...)
end
function PosteriorStats.summarize(data::InferenceObjects.Dataset, stats_funs...; kwargs...)
    return _summarize(PosteriorStats.SummaryStats, data, stats_funs; kwargs...)
end

function _summarize(
    ::Type{PosteriorStats.SummaryStats},
    data::InferenceObjects.Dataset,
    stats_funs;
    compact_labels::Bool=true,
    kwargs...,
)
    dims = InferenceObjects.DEFAULT_SAMPLE_DIMS
    marginals = collect(_marginal_iterator(data, dims; compact_labels))
    var_names = map(first, marginals)
    # TODO: use a custom array type to avoid copying
    draws = stack(map(last, marginals))
    return PosteriorStats.summarize(draws, stats_funs...; var_names, kwargs...)
end

function _marginal_iterator(ds, dim; compact_labels::Bool=true)
    return Iterators.map(_indices_iterator(ds, dim)) do (var, indices)
        var_select = isempty(indices) ? var : view(var, indices...)
        return _indices_to_name(var, indices, compact_labels) => var_select
    end
end

function _indices_iterator(ds::DimensionalData.AbstractDimStack, dims)
    return Iterators.flatten(
        Iterators.map(Base.Fix2(_indices_iterator, dims), DimensionalData.layers(ds))
    )
end
function _indices_iterator(var::DimensionalData.AbstractDimArray, dims)
    dims_flatten = Dimensions.otherdims(var, dims)
    isempty(dims_flatten) && return ((var, ()),)
    indices_iter = DimensionalData.DimKeys(dims_flatten)
    return zip(Iterators.cycle((var,)), indices_iter)
end

function _indices_to_name(var, dims, compact)
    name = DimensionalData.name(var)
    isempty(dims) && return string(name)
    elements = if compact
        map(string ∘ Dimensions.val ∘ Dimensions.val, dims)
    else
        map(dims) do d
            val = Dimensions.val(Dimensions.val(d))
            val_str = sprint(show, "text/plain", val)
            return "$(Dimensions.name(d))=At($val_str)"
        end
    end
    return "$name[" * join(elements, ',') * "]"
end
