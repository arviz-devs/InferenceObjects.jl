using .NCDatasets: NCDatasets

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
                return Symbol(dim_name) =>
                    Dimensions.Dim{Symbol(dim_name)}(collect(group[dim_name]))
            end...
        )
        var_iter = Iterators.filter(∉(keys(layerdims)) ∘ Symbol ∘ first, group)
        data = (;
            map(var_iter) do (var_name, var)
                vals = _var_to_array(var, load_mode)
                dims = Tuple(NamedTuple{map(Symbol, NCDatasets.dimnames(var))}(layerdims))
                name = Symbol(var_name)
                attrib = OrderedDict{Symbol,Any}(
                    Symbol(key) => val for (key, val) in var.attrib if key != "_FillValue"
                )
                metadata = isempty(attrib) ? LookupArrays.NoMetadata() : attrib
                da = DimensionalData.DimArray(vals, dims; name, metadata)
                return name => da
            end...
        )
        group_metadata = OrderedDict{Symbol,Any}(
            Symbol(key) => val for (key, val) in group.attrib
        )
        return Symbol(group_name) => Dataset(data; metadata=group_metadata)
    end
    return InferenceData(; groups...)
end

_var_to_array(var, load_mode) = var
function _var_to_array(var, load_mode::Val{:eager})
    arr = Array(var)
    try
        return NCDatasets.nomissing(arr)
    catch e
        return arr
    end
end

convert_to_inference_data(ds::NCDatasets.NCDataset) = from_netcdf(ds)

function to_netcdf(data, path::AbstractString; group::Symbol=:posterior, kwargs...)
    NCDatasets.NCDataset(ds -> to_netcdf(data, ds; group), path, "c"; kwargs...)
    return path
end
function to_netcdf(data, ds::NCDatasets.NCDataset; group::Symbol=:posterior)
    idata = convert_to_inference_data(data; group)
    for (group_name, group_data) in pairs(idata)
        group_attrib = [String(k) => v for (k, v) in pairs(attributes(group_data))]
        group_ds = NCDatasets.defGroup(ds, String(group_name); attrib=group_attrib)
        for dim in Dimensions.dims(group_data)
            dim_name = String(Dimensions.name(dim))
            NCDatasets.defDim(group_ds, dim_name, length(dim))
            val = LookupArrays.val(dim)
            var = NCDatasets.defVar(group_ds, dim_name, eltype(val), (dim_name,))
            copyto!(var, val)
        end
        for (var_name, da) in pairs(group_data)
            dimnames = map(String, Dimensions.name(Dimensions.dims(da)))
            attrib = [String(k) => v for (k, v) in pairs(DimensionalData.metadata(da))]
            NCDatasets.defVar(group_ds, String(var_name), parent(da), dimnames; attrib)
        end
    end
    return ds
end
