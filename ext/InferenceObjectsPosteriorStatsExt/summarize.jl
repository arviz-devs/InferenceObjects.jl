@doc """
    summarystats(data::InferenceData; group=:posterior, kwargs...) -> SummaryStats
    summarystats(data::Dataset; kwargs...) -> SummaryStats

Compute default summary statistics for the data using
[`PosteriorStats.summarize`](@ref PosteriorStats.summarize(::InferenceData)).
"""
function StatsBase.summarystats(data::InferenceObjects.InferenceData; kwargs...)
    return PosteriorStats.summarize(data; kwargs...)
end
function StatsBase.summarystats(data::InferenceObjects.Dataset; kwargs...)
    return PosteriorStats.summarize(data; kwargs...)
end

@doc """
    summarize(data::InferenceData, stats_funs...; group=:posterior, kwargs...)
    summarize(data::Dataset, stats_funs...; kwargs...)

Compute summary statistics for the data using the provided functions.

For verbose variable labels, provide `compact_labels=false`. For details on `stats_funs` and
`kwargs`, see [`PosteriorStats.summarize`](@extref).

# Examples

Compute all default summary statistics for the eight schools model in the centered
parameterization:

```jldoctest summarize
julia> using ArviZExampleData, PosteriorStats, StatsBase

julia> data = load_example_data("centered_eight");

julia> summarize(data)
SummaryStats
                          mean  std  hdi_3%  hdi_97%  mcse_mean  mcse_std  ess ⋯
 mu                        4.2  3.3  -1.61     10.3        0.21     0.088      ⋯
 theta[Choate]             6.4  5.9  -3.68     17.9        0.25     0.20       ⋯
 theta[Deerfield]          5.0  4.9  -4.98     13.4        0.21     0.15       ⋯
 theta[Phillips Andover]   3.4  5.4  -7.54     12.9        0.23     0.17       ⋯
 theta[Phillips Exeter]    4.8  5.2  -5.11     14.1        0.21     0.21       ⋯
 theta[Hotchkiss]          3.5  4.8  -6.12     12.0        0.25     0.15       ⋯
 theta[Lawrenceville]      3.7  5.2  -6.50     12.7        0.22     0.21       ⋯
 theta[St. Paul's]         6.5  5.2  -2.67     16.9        0.22     0.15       ⋯
 theta[Mt. Hermon]         4.8  5.7  -5.97     15.4        0.24     0.23       ⋯
 tau                       4.3  3.0   0.715     9.41       0.22     0.14       ⋯
                                                               3 columns omitted
```

Compute the mean, standard deviation, median, and median absolute deviation of the `theta`
parameters:

```jldoctest summarize
julia> summarize(data.posterior[(:theta,)], (:mean, :std) => mean_and_std, median, mad)
SummaryStats
                          mean   std  median   mad
 theta[Choate]            6.42  5.85    5.80  4.95
 theta[Deerfield]         4.95  4.91    5.02  4.68
 theta[Phillips Andover]  3.42  5.43    3.74  4.84
 theta[Phillips Exeter]   4.75  5.25    4.69  4.84
 theta[Hotchkiss]         3.45  4.78    3.62  4.55
 theta[Lawrenceville]     3.66  5.23    3.90  4.88
 theta[St. Paul's]        6.51  5.24    6.09  4.57
 theta[Mt. Hermon]        4.82  5.70    4.65  4.89
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
