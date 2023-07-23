module InferenceObjectsNetCDF

using DimensionalData: DimensionalData, Dimensions, LookupArrays
using NCDatasets: NCDatasets
using Reexport: @reexport
@reexport using InferenceObjects

function __init__()
    @warn "InferenceObjectsNetCDF is discontinued. For the same functionality, use `from_netcdf` and `to_netcdf` in InferenceObjects."
end

end  # module
