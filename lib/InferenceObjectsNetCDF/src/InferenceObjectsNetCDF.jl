module InferenceObjectsNetCDF

using DimensionalData: DimensionalData, Dimensions, LookupArrays
using NCDatasets: NCDatasets
using Reexport: @reexport
@reexport using InferenceObjects

export from_netcdf, to_netcdf

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
function from_netcdf(path::AbstractString; kwargs...)
    return NCDatasets.NCDataset(path, "r"; kwargs...) do ds
        return from_netcdf(ds; load_mode=:eager)
    end
end
function from_netcdf(ds::NCDatasets.NCDataset; load_mode::Symbol=:lazy)
    return _from_netcdf(ds, Val(load_mode))
end

function _from_netcdf(ds, load_mode)
    groups = map(ds.group) do (group_name, group)
        layerdims = (;
            map(NCDatasets.dimnames(group)) do dim_name
                index = collect(group[dim_name])
                if index == eachindex(index)
                    # discard the index if it is just the default
                    index = LookupArrays.NoLookup()
                end
                return Symbol(dim_name) => Dimensions.Dim{Symbol(dim_name)}(index)
            end...
        )
        var_iter = Iterators.filter(∉(keys(layerdims)) ∘ Symbol ∘ first, group)
        data = (;
            map(var_iter) do (var_name, var)
                vals = _var_to_array(var, load_mode)
                dims = Tuple(NamedTuple{map(Symbol, NCDatasets.dimnames(var))}(layerdims))
                name = Symbol(var_name)
                attrib = if load_mode isa Val{:eager}
                    filter(!=("_FillValue") ∘ first, Dict{String,Any}(var.attrib))
                else
                    var.attrib
                end
                metadata = isempty(attrib) ? LookupArrays.NoMetadata() : attrib
                da = DimensionalData.DimArray(vals, dims; name, metadata)
                return name => da
            end...
        )
        group_metadata = if load_mode isa Val{:eager}
            Dict{String,Any}(group.attrib)
        else
            group.attrib
        end
        return Symbol(group_name) => Dataset(data; metadata=group_metadata)
    end
    return InferenceData(; groups...)
end

_var_to_array(var, load_mode) = var
function _var_to_array(var, load_mode::Val{:eager})
    arr = as_array(Array(var))
    attr = var.attrib
    try
        arr_nomissing = NCDatasets.nomissing(arr)
        if eltype(arr_nomissing) <: Integer && (get(attr, "dtype", nothing) == "bool")
            return convert(Array{Bool}, arr_nomissing)
        end
        return arr_nomissing
    catch e
        if eltype(arr) <: Union{Integer,Missing} && (get(attr, "dtype", nothing) == "bool")
            return convert(Array{Union{Missing,Bool}}, arr)
        end
        return arr
    end
end

function InferenceObjects.convert_to_inference_data(ds::NCDatasets.NCDataset; kwargs...)
    return from_netcdf(ds)
end

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
function to_netcdf(data, path::AbstractString; group::Symbol=:posterior, kwargs...)
    NCDatasets.NCDataset(ds -> to_netcdf(data, ds; group), path, "c"; kwargs...)
    return path
end
function to_netcdf(data, ds::NCDatasets.NCDataset; group::Symbol=:posterior)
    idata = convert_to_inference_data(data; group)
    for (group_name, group_data) in pairs(idata)
        group_attrib = collect(InferenceObjects.attributes(group_data))
        group_ds = NCDatasets.defGroup(ds, String(group_name); attrib=group_attrib)
        for dim in Dimensions.dims(group_data)
            dim_name = String(Dimensions.name(dim))
            NCDatasets.defDim(group_ds, dim_name, length(dim))
            index = LookupArrays.index(group_data, dim)
            var = NCDatasets.defVar(group_ds, dim_name, eltype(index), (dim_name,))
            copyto!(var, index)
        end
        for (var_name, da) in pairs(group_data)
            dimnames = map(String, Dimensions.name(Dimensions.dims(da)))
            attrib = Dict(DimensionalData.metadata(da))
            if eltype(da) <: Bool && (get(attrib, "dtype", "bool") == "bool")
                da = convert(AbstractArray{Int8}, da)
                attrib["dtype"] = "bool"
            end
            NCDatasets.defVar(
                group_ds, String(var_name), parent(da), dimnames; attrib=collect(attrib)
            )
        end
    end
    return ds
end

as_array(x) = fill(x)
as_array(x::AbstractArray) = x

end
