# this pattern ensures that the type is completely specified at compile time
const HDI_BOUND_DIM = Dimensions.format(
    Dimensions.Dim{:hdi_bound}([:lower, :upper]), Base.OneTo(2)
)

"""
    hdi(data::InferenceData; kwargs...) -> Dataset
    hdi(data::Dataset; kwargs...) -> Dataset

Calculate the highest density interval (HDI) for each parameter in the data.

# Examples

Calculate HDI for all parameters in the `posterior` group of an `InferenceData`:

```jldoctest hdi_infdata
julia> using ArviZExampleData, PosteriorStats

julia> idata = load_example_data("centered_eight");

julia> hdi(idata)
Dataset with dimensions:
  Dim{:school} Categorical{String} String[Choate, Deerfield, …, St. Paul's, Mt. Hermon] Unordered,
  Dim{:hdi_bound} Categorical{Symbol} Symbol[:lower, :upper] ForwardOrdered
and 3 layers:
  :mu    Float64 dims: Dim{:hdi_bound} (2)
  :theta Float64 dims: Dim{:school}, Dim{:hdi_bound} (8×2)
  :tau   Float64 dims: Dim{:hdi_bound} (2)
```

We can also calculate the HDI for a subset of variables:

```jldoctest hdi_infdata
julia> hdi(idata.posterior[(:theta,)]).theta
8×2 DimArray{Float64,2} theta with dimensions:
  Dim{:school} Categorical{String} String[Choate, Deerfield, …, St. Paul's, Mt. Hermon] Unordered,
  Dim{:hdi_bound} Categorical{Symbol} Symbol[:lower, :upper] ForwardOrdered
                        :lower    :upper
  "Choate"            -4.56375  17.1324
  "Deerfield"         -4.31055  14.2535
  "Phillips Andover"  -7.76922  13.6755
  "Phillips Exeter"   -4.48955  14.6635
  "Hotchkiss"         -6.46991  11.7191
  "Lawrenceville"     -7.04111  12.2087
  "St. Paul's"        -3.09262  16.2685
  "Mt. Hermon"        -5.85834  16.0143
```
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
    dims = Dimensions.combinedims(
        Dimensions.otherdims(data, InferenceObjects.DEFAULT_SAMPLE_DIMS), HDI_BOUND_DIM
    )
    return DimensionalData.rebuild(
        data;
        data=map(parent, results),
        dims,
        layerdims=map(Dimensions.dims, results),
        refdims=(),
        metadata=DimensionalData.NoMetadata(),
    )
end
