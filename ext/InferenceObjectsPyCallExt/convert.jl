PyCall.PyObject(data::InferenceObjects.Dataset) = _to_xarray(data)

function Base.convert(::Type{InferenceObjects.Dataset}, obj::PyCall.PyObject)
    return InferenceObjects.Dataset(_dimstack_from_xarray(obj))
end

function PyCall.PyObject(data::InferenceObjects.InferenceData)
    return PyCall.pycall(
        arviz.InferenceData,
        PyCall.PyObject;
        map(PyCall.PyObject, InferenceObjects.groups(data))...,
    )
end

function InferenceObjects.convert_to_inference_data(
    obj::PyCall.PyObject; dims=nothing, coords=nothing, kwargs...
)
    if PyCall.pyisinstance(obj, arviz.InferenceData)
        group_names = obj.groups()
        groups = (
            Symbol(name) => convert(InferenceObjects.Dataset, getindex(obj, name)) for
            name in group_names
        )
        return InferenceObjects.InferenceData(; groups...)
    else
        # Python ArviZ requires dims and coords be dicts matching to vectors
        pydims = dims === nothing ? dims : Dict(k -> collect(dims[k]) for k in keys(dims))
        pycoords =
            dims === nothing ? dims : Dict(k -> collect(coords[k]) for k in keys(coords))
        return arviz.convert_to_inference_data(obj; dims=pydims, coords=pycoords, kwargs...)
    end
end

function _dimstack_from_xarray(o::PyCall.PyObject)
    PyCall.pyisinstance(o, xarray.Dataset) ||
        throw(ArgumentError("argument is not an `xarray.Dataset`."))
    var_names = collect(o.data_vars)
    data = [_dimarray_from_xarray(getindex(o, name)) for name in var_names]
    metadata = OrderedDict{String,Any}(string(k) => v for (k, v) in o.attrs)
    return DimensionalData.DimStack(data...; metadata)
end

function _dimarray_from_xarray(o::PyCall.PyObject)
    PyCall.pyisinstance(o, xarray.DataArray) ||
        throw(ArgumentError("argument is not an `xarray.DataArray`."))
    name = Symbol(o.name)
    data = _process_pyarray(o.to_numpy())
    coords = PyCall.PyDict(o.coords)
    dims = Tuple(
        map(d -> _wrap_dims(Symbol(d), _process_pyarray(coords[d].values)), o.dims)
    )
    attrs = OrderedDict{String,Any}(string(k) => v for (k, v) in o.attrs)
    metadata = isempty(attrs) ? DimensionalData.NoMetadata() : attrs
    return DimensionalData.DimArray(data, dims; name, metadata)
end

_process_pyarray(x) = x
# NOTE: sometimes strings fail to convert to Julia types, so we try to force them here
function _process_pyarray(x::Union{PyCall.PyObject,<:AbstractVector{PyCall.PyObject}})
    return map(z -> z isa PyCall.PyObject ? PyCall.PyAny(z)::Any : z, x)
end

# wrap dims in a `Dim`, converting to an AbstractRange if possible
function _wrap_dims(name::Symbol, dims::AbstractVector{<:Real})
    D = Dimensions.Dim{name}
    start = dims[begin]
    stop = dims[end]
    n = length(dims)
    step = (stop - start) / (n - 1)
    isrange = all(Iterators.drop(eachindex(dims), 1)) do i
        return (dims[i] - dims[i - 1]) ≈ step
    end
    return if isrange
        if step == 1
            D(UnitRange(start, stop))
        else
            D(range(start, stop; length=n))
        end
    else
        D(dims)
    end
end
_wrap_dims(name::Symbol, dims::AbstractVector) = Dimensions.Dim{name}(dims)

function _to_xarray(data::DimensionalData.AbstractDimStack)
    data_vars = Dict(pairs(map(_to_xarray, DimensionalData.layers(data))))
    attrs = Dict(pairs(DimensionalData.metadata(data)))
    return PyCall.pycall(xarray.Dataset, PyCall.PyObject, data_vars; attrs)
end

function _to_xarray(data::DimensionalData.AbstractDimArray)
    var_name = DimensionalData.name(data)
    data_dims = DimensionalData.dims(data)
    dims = collect(DimensionalData.name(data_dims))
    coords = Dict(zip(dims, DimensionalData.index(data_dims)))
    default_dims = String[]
    values = parent(data)
    if Missing <: eltype(values)
        # passing `missing` to Python causes the array to have a `PyCall.jlwrap` dtype
        values = replace(values, missing => NaN)
    end
    metadata = DimensionalData.metadata(data)
    da = arviz.numpy_to_data_array(values; var_name, dims, coords, default_dims)
    if !isempty(metadata)
        da.attrs = metadata
    end
    return da
end
