has_all_sample_dims(dims) = all(Dimensions.hasdim(dims, DEFAULT_SAMPLE_DIMS))

# Like Dimensions.name2dim but doesn't allow users to inject their own dimensions using
# Dimensions.@dim. See https://github.com/arviz-devs/InferenceObjects.jl/issues/37
_name2dim(d::Symbol) = Dimensions.Dim{d}(Lookups.NoLookup())
_name2dim(d::Tuple) = map(_name2dim, d)
_name2dim(d) = d

# make sure dim has a lookup value accessible with `val`
_valdim(d) = d
_valdim(d::Type{<:Dimensions.Dimension}) = d(Lookups.NoLookup())

"""
    as_dimension(dim, coords, axis) -> DimensionsionalData.Dimension

Convert `dim`, `coords`, and `axis` to a `Dimension` object.

# Arguments

  - `dim`: An object specifying the name and potentially indices of a dimension. Can be the
    following types:

      + `Symbol`: dimension name.
      + `Type{<:DimensionsionalData.Dimension}`: dimension type
      + `DimensionsionalData.Dimension`: dimension, potentially with indices

  - `coords`: a collection indexable by dimension name specifying the indices of the given
    dimension. If indices are provided, they are used even if `dim` contains its own
    indices. If a dimension is missing, its indices are automatically generated.
  - `axis`: A default axis to be used if `coords` and `dim` indices are not provided.
"""
function as_dimension(dim, coords, axis)
    cdim = _valdim(_name2dim(dim))
    val = Lookups.val(cdim)
    inds = val isa Union{Colon,Lookups.NoLookup} ? axis : val
    coords_inds = get(coords, Dimensions.name(cdim), inds)
    return Dimensions.rebuild(cdim, coords_inds)
end

"""
    generate_dims(array, name; dims, coords, default_dims)

Generate `DimensionsionalData.Dimension` objects for each dimension of `array`.

`name` indicates the name of the variable represented by array.

# Keywords

  - `dims`: A collection of objects indicating dimension names. If any dimensions are not
    provided, their names are automatically generated. Acceptable types of entries are:

      + `Symbol`: dimension name
      + `Type{<:DimensionsionalData.Dimension}`: dimension type
      + `DimensionsionalData.Dimension`: dimension, potentially with indices
      + `Nothing`: no dimension name provided, dimension name is automatically generated

  - `coords`: a collection indexable by dimension name specifying the indices of the given
    dimension. If indices for a dimension in `dims` are provided, they are used even if
    the dimension contains its own indices. If a dimension is missing, its indices are
    automatically generated.
  - `default_dims`: A collection of dims to be prepended to `dims` whose elements have the
    same constraints.
"""
function generate_dims(array, name; dims=(), coords=(;), default_dims=())
    num_default_dims = length(default_dims)
    if length(dims) + num_default_dims > ndims(array)
        dim_names = Dimensions.name(_name2dim((default_dims..., dims...)))
        throw(
            DimensionMismatch(
                "Provided dimensions $dim_names more than dimensions of array: $(ndims(array))",
            ),
        )
    end
    dims_length = length(dims)
    dims_named = ntuple(ndims(array) - length(default_dims)) do i
        dim = i ≤ dims_length ? dims[i] : nothing
        dim === nothing && return Symbol("$(name)_dim_$(i)")
        return dim
    end
    dims_all = (default_dims..., dims_named...)
    # default to the axes if no coords are provided
    axes_all = map(_ -> Lookups.NoLookup(), dims_all)
    T = NTuple{ndims(array),Dimensions.Dimension}
    dims_with_coords = as_dimension.(dims_all, Ref(coords), axes_all)::T
    return Dimensions.format(dims_with_coords, array)::T
end

"""
    array_to_dimarray(array, name; kwargs...) -> DimensionalData.AbstractDimArray

Convert `array` to a `AbstractDimArray` with name `name`.

If `array` is already an `AbstractDimArray`, then it is returned without modification.
See [`generate_dims`](@ref) for a description of `kwargs`.
"""
function array_to_dimarray(data, name; dims=(), coords=(;), default_dims=())
    array = if ndims(data) < 2 && has_all_sample_dims(default_dims)
        reshape(data, :, 1)
    else
        data
    end
    array_dims = generate_dims(array, name; dims, coords, default_dims)
    return DimensionalData.DimArray(array, array_dims; name)
end
function array_to_dimarray(array::DimensionalData.AbstractDimArray, name; kwargs...)
    return DimensionalData.rebuild(array; name)
end

"""
    AsSlice{T<:Lookups.Selector} <: Lookups.Selector{T}

    AsSlice(selector)

Selector that ensures selected indices are arrays so that slicing occurs.

This is useful to ensure that selecting a single index still returns an array.
"""
struct AsSlice{T<:Lookups.Selector} <: Lookups.Selector{T}
    val::T
end

function Lookups.selectindices(l::Lookups.LookupArray, sel::AsSlice; kw...)
    i = Lookups.selectindices(l, Lookups.val(sel); kw...)
    inds = i isa AbstractVector ? i : [i]
    return inds
end

"""
    index_to_indices(index)

Convert `index` to a collection of indices or a selector representing such a collection.
"""
index_to_indices(i) = i
index_to_indices(i::Int) = [i]
index_to_indices(sel::Lookups.Selector) = AsSlice(sel)
