"""
    Dataset <: DimensionalData.AbstractDimStack{NamedTuple}

Container of dimensional arrays sharing some dimensions.

This type is an
[`DimensionalData.AbstractDimStack`](https://rafaqz.github.io/DimensionalData.jl/stable/api/#DimensionalData.AbstractDimStack)
that implements the same interface as `DimensionalData.DimStack` and has identical usage.

When a `Dataset` is passed to Python, it is converted to an `xarray.Dataset` without copying
the data. That is, the Python object shares the same memory as the Julia object. However,
if an `xarray.Dataset` is passed to Julia, its data must be copied.

# Constructors

    Dataset(data::DimensionalData.AbstractDimArray...)
    Dataset(data::Tuple{Vararg{<:DimensionalData.AbstractDimArray}})
    Dataset(data::NamedTuple{Keys,Vararg{<:DimensionalData.AbstractDimArray}})
    Dataset(
        data::NamedTuple,
        dims::Tuple{Vararg{DimensionalData.Dimension}};
        metadata=DimensionalData.NoMetadata(),
    )

In most cases, use [`convert_to_dataset`](@ref) to create a `Dataset` instead of directly
using a constructor.
"""
struct Dataset <: DimensionalData.AbstractDimStack{NamedTuple}
    data::DimensionalData.DimStack
end

Dataset(args...; kwargs...) = Dataset(DimensionalData.DimStack(args...; kwargs...))
Dataset(data::Dataset) = data

Base.parent(data::Dataset) = getfield(data, :data)

function setattribute!(data::Dataset, k::AbstractString, value)
    setindex!(DimensionalData.metadata(data), value, k)
    return value
end
@deprecate setattribute!(data::Dataset, k::Symbol, value) setattribute!(
    data, string(k), value
) false

"""
    namedtuple_to_dataset(data; kwargs...) -> Dataset

Convert `NamedTuple` mapping variable names to arrays to a [`Dataset`](@ref).

Any non-array values will be converted to a 0-dimensional array.

# Keywords

  - `attrs::AbstractDict{<:AbstractString}`: a collection of metadata to attach to the
    dataset, in addition to defaults. Values should be JSON serializable.
  - `library::Union{String,Module}`: library used for performing inference. Will be attached
    to the `attrs` metadata.
  - `dims`: a collection mapping variable names to collections of objects containing dimension
    names. Acceptable such objects are:
      + `Symbol`: dimension name
      + `Type{<:DimensionsionalData.Dimension}`: dimension type
      + `DimensionsionalData.Dimension`: dimension, potentially with indices
      + `Nothing`: no dimension name provided, dimension name is automatically generated
  - `coords`: a collection indexable by dimension name specifying the indices of the given
    dimension. If indices for a dimension in `dims` are provided, they are used even if
    the dimension contains its own indices. If a dimension is missing, its indices are
    automatically generated.
"""
function namedtuple_to_dataset end
function namedtuple_to_dataset(
    data;
    attrs=Dict{String,Any}(),
    library=nothing,
    dims=(;),
    coords=(;),
    default_dims=DEFAULT_SAMPLE_DIMS,
)
    dim_arrays = map(keys(data)) do var_name
        var_data = as_array(data[var_name])
        var_dims = get(dims, var_name, ())
        return array_to_dimarray(var_data, var_name; dims=var_dims, coords, default_dims)
    end
    attributes = merge(default_attributes(library), attrs)
    return Dataset(dim_arrays...; metadata=attributes)
end

"""
    default_attributes(library=nothing) -> NamedTuple

Generate default attributes metadata for a dataset generated by inference library `library`.

`library` may be a `String` or a `Module`.
"""
function default_attributes(library=nothing)
    return merge(
        Dict{String,Any}(
            "created_at" => Dates.format(Dates.now(), Dates.ISODateTimeFormat)
        ),
        library_attributes(library),
    )
end

library_attributes(library) = Dict{String,Any}("inference_library" => string(library))
library_attributes(::Nothing) = Dict{String,Any}()
function library_attributes(library::Module)
    return Dict{String,Any}(
        "inference_library" => string(library),
        "inference_library_version" => string(package_version(library)),
    )
end

# DimensionalData interop

for f in [:data, :dims, :refdims, :metadata, :layerdims, :layermetadata, :layers]
    @eval begin
        DimensionalData.$(f)(ds::Dataset) = DimensionalData.$(f)(parent(ds))
    end
end

# Warning: this is not an API function and probably should be implemented abstractly upstream
DimensionalData.show_after(io, mime, ::Dataset) = nothing

attributes(data::DimensionalData.AbstractDimStack) = DimensionalData.metadata(data)

Base.convert(T::Type{<:DimensionalData.DimStack}, data::Dataset) = convert(T, parent(data))

function DimensionalData.rebuild(data::Dataset; kwargs...)
    return Dataset(DimensionalData.rebuild(parent(data); kwargs...))
end
