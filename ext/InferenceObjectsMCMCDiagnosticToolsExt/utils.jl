# reshape to (ndraws, nchains, nparams...) and drop the dimensions
function _params_array(data)
    sample_dims = Dimensions.dims(data, InferenceObjects.DEFAULT_SAMPLE_DIMS)
    param_dims = Dimensions.otherdims(data, sample_dims)
    dims_combined = Dimensions.combinedims(sample_dims, param_dims)
    Dimensions.dimsmatch(Dimensions.dims(data), dims_combined) && return data
    return PermutedDimsArray(data, dims_combined)
end

function _as_3d_array(x::AbstractArray)
    ndims(x) == 3 && return x
    return reshape(x, size(x, 1), size(x, 2), :)
end

_as_dimarray(x::DimensionalData.AbstractDimArray, ::DimensionalData.AbstractDimArray) = x
function _as_dimarray(x::Union{Real,Missing}, arr::DimensionalData.AbstractDimArray)
    return Dimensions.rebuild(arr, fill(x), ())
end
