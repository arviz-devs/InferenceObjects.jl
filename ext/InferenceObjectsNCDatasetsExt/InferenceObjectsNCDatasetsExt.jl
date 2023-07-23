module InferenceObjectsNCDatasetsExt

if isdefined(Base, :get_extension)
    using DimensionalData: DimensionalData, Dimensions, LookupArrays
    using NCDatasets: NCDatasets
    using InferenceObjects
else
    using ..DimensionalData: DimensionalData, Dimensions, LookupArrays
    using ..NCDatasets: NCDatasets
    using ..InferenceObjects
end

function InferenceObjects.from_netcdf(path::AbstractString; kwargs...)
    return NCDatasets.NCDataset(path, "r"; kwargs...) do ds
        return from_netcdf(ds; load_mode=:eager)
    end
end
function InferenceObjects.from_netcdf(ds::NCDatasets.NCDataset; load_mode::Symbol=:lazy)
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

function InferenceObjects.to_netcdf(data, path::AbstractString; group::Symbol=:posterior, kwargs...)
    NCDatasets.NCDataset(ds -> to_netcdf(data, ds; group), path, "c"; kwargs...)
    return path
end
function InferenceObjects.to_netcdf(data, ds::NCDatasets.NCDataset; group::Symbol=:posterior)
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

end  # module
