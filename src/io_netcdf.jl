"""
    from_netcdf(path::AbstractString; nomissing=true, kwargs...) -> InferenceData

Load an [`InferenceData`](@ref) from an unopened NetCDF file.

Setting `nomissing=true` indicates that there are no missing values in the NetCDF file, so
eltypes of variables will not be a type union with `Missing`.

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

    from_netcdf(ds::NCDatasets.NCDataset; load_mode, nomissing) -> InferenceData

Load an [`InferenceData`](@ref) from an opened NetCDF file.

`load_mode` defaults to `:lazy`, which avoids reading variables into memory. Operations on
these arrays will be slow. `load_mode` can also be `:eager`, which copies all variables into
memory. It is then safe to close `ds`. If `load_mode` is `:lazy` and `ds` is closed after
constructing `InferenceData`, using the variable arrays will have undefined behavior.

`nomissing` defaults to `true` if `load_mode` is `:eager`, and is otherwise ignored.

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

function to_netcdf end