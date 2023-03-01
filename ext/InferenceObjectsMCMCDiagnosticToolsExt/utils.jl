# reshape to (ndraws, nchains, prod(size)) and drop the dimensions
# even though the dimensions would be preserved, it's easier to keep types inferrable and
# reduce compile time by dropping the dimensions before calling diagnostics.
function _as_marginals(data)
    sample_dims = Dimensions.dims(data, InferenceObjects.DEFAULT_SAMPLE_DIMS)
    param_dims = Dimensions.otherdims(data, sample_dims)
    dims_combined = Dimensions.combinedims(sample_dims, param_dims)
    data_perm = _unwrappermutedims(data, dims_combined)
    data_reshape = reshape(data_perm, (size(data_perm, 1), size(data_perm, 2), :))
    return data_reshape
end

# reshape to (ndraws, nchains, size...) and add back the dimensions
function _from_marginals(data, marginals)
    sample_dims = Dimensions.dims(data, InferenceObjects.DEFAULT_SAMPLE_DIMS)
    param_dims = Dimensions.otherdims(data, sample_dims)
    param_sizes = map(i -> size(data, i), Dimensions.dimnum(data, param_dims))
    data_reshape = reshape(marginals, param_sizes)
    return Dimensions.rebuild(data, data_reshape, param_dims)
end

# even though the permutation is const-propagated, this is not enough to make
# PermuteDimsArray(data, perm) type-stable
function _unwrappermutedims(da::DimensionalData.AbstractDimArray{T,N}, dims) where {T,N}
    perm = Dimensions.dimnum(da, dims)
    iperm = invperm(perm)
    data = DimensionalData.data(da)
    return PermutedDimsArray{T,N,(perm...,),(iperm...,),typeof(data)}(data)
end
