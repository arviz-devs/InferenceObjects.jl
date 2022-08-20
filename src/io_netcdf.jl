"""
    from_netcdf(path::AbstractString; kwargs...) -> InferenceData

Load an [`InferenceData`](@ref) from an unopened NetCDF file.

Remaining `kwargs` are passed to [`NCDatasets.NCDataset`](https://alexander-barth.github.io/NCDatasets.jl/stable/dataset/#NCDatasets.NCDataset).
This method loads data eagerly. To instead load data lazily, pass an opened `NCDataset` to
`from_netcdf`.

# Examples

```julia
julia> idata = from_netcdf("centered_eight.nc")
InferenceData with groups:
  > posterior
  > posterior_predictive
  > sample_stats
  > prior
  > observed_data
```

    from_netcdf(ds::NCDatasets.NCDataset; load_mode) -> InferenceData

Load an [`InferenceData`](@ref) from an opened NetCDF file.

`load_mode` defaults to `:lazy`, which avoids reading variables into memory. Operations on
these arrays will be slow. `load_mode` can also be `:eager`, which copies all variables into
memory. It is then safe to close `ds`. If `load_mode` is `:lazy` and `ds` is closed after
constructing `InferenceData`, using the variable arrays will have undefined behavior.

# Examples

Here is how we might load an `InferenceData` from an `InferenceData` lazily from a
web-hosted NetCDF file.

```julia
julia> using HTTP, NCDatasets

julia> resp = HTTP.get("https://github.com/arviz-devs/arviz_example_data/blob/main/data/centered_eight.nc?raw=true");

julia> ds = NCDataset("centered_eight", "r"; memory = resp.body);

julia> idata = from_netcdf(ds)
InferenceData with groups:
  > posterior
  > posterior_predictive
  > sample_stats
  > prior
  > observed_data

julia> idata_copy = copy(idata); # disconnect from the loaded dataset

julia> close(ds);
```
"""
function from_netcdf end

"""
    to_netcdf(data, dest::AbstractString; group::Symbol=:posterior, kwargs...)
    to_netcdf(data, dest::NCDatasets.NCDataset; group::Symbol=:posterior)

Write `data` to a NetCDF file.

`data` is any type that can be converted to an [`InferenceData`](@ref) using
[`convert_to_inference_data`](@ref). If not an `InferenceData`, then `group` specifies which
group the data represents.

`dest` specifies either the path to the NetCDF file or an opened NetCDF file.
If `dest` is a path, remaining `kwargs` are passed to
[`NCDatasets.NCDataset`](https://alexander-barth.github.io/NCDatasets.jl/stable/dataset/#NCDatasets.NCDataset).

# Examples

```julia
julia> using NCDatasets

julia> idata = from_namedtuple((; x = randn(4, 100, 3), z = randn(4, 100)))
InferenceData with groups:
  > posterior

julia> to_netcdf(idata, "data.nc")
"data.nc"
```
"""
function to_netcdf end
