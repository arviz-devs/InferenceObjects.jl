using .NCDatasets: NCDatasets

function from_netcdf(path::AbstractString; kwargs...)
    return NCDatasets.NCDataset(path, "r"; kwargs...) do ds
        return from_netcdf(ds; load_mode=:eager, kwargs...)
    end
end
function from_netcdf(
    ds::NCDatasets.NCDataset; load_mode::Symbol=:lazy, nomissing::Bool=load_mode === :eager
)
    return _from_netcdf(ds, Val(load_mode), Val(nomissing))
end

function _from_netcdf(ds, load_mode, nomissing)
    groups = map(ds.group) do (group_name, group)
        layerdims = (;
            map(NCDatasets.dimnames(group)) do dim_name
                return Symbol(dim_name) =>
                    Dimensions.Dim{Symbol(dim_name)}(collect(group[dim_name]))
            end...
        )
        var_iter = Iterators.filter(∉(keys(layerdims)) ∘ Symbol ∘ first, group)
        data = (;
            map(var_iter) do (var_name, var)
                vals = _var_to_array(var, load_mode, nomissing)
                dims = Tuple(NamedTuple{map(Symbol, NCDatasets.dimnames(var))}(layerdims))
                name = Symbol(var_name)
                da = DimensionalData.DimArray(vals, dims; name)
                return name => da
            end...
        )
        metadata = Dict{Symbol,Any}(Symbol(key) => val for (key, val) in group.attrib)
        return Symbol(group_name) => Dataset(data; metadata)
    end
    return InferenceData(; groups...)
end

_var_to_array(var, load_mode, nomissing) = var
function _var_to_array(var, load_mode::Val{:eager}, nomissing::Val{true})
    return NCDatasets.nomissing(Array(var))
end
_var_to_array(var, load_mode::Val{:eager}, nomissing::Val{false}) = Array(var)

convert_to_inference_data(ds::NCDatasets.NCDataset) = from_netcdf(ds)

function to_netcdf(path::AbstractString, data; group::Symbol=:posterior, kwargs...)
    NCDatasets.NCDataset(ds -> to_netcdf(ds, path; group), path, "c"; kwargs...)
    return path
end
function to_netcdf(ds::NCDatasets.NCDataset, data; group::Symbol=:posterior)
    idata = convert_to_inference_data(data; group)
    return ds
end
