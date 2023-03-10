module InferenceObjectsMCMCDiagnosticToolsExt

if isdefined(Base, :get_extension)
    using DimensionalData: DimensionalData, Dimensions, LookupArrays
    using InferenceObjects: InferenceObjects
    using MCMCDiagnosticTools: MCMCDiagnosticTools
    using Random: Random
else  # using Requires
    using ..DimensionalData: DimensionalData, Dimensions, LookupArrays
    using ..InferenceObjects: InferenceObjects
    using ..MCMCDiagnosticTools: MCMCDiagnosticTools
    using ..Random: Random
end

include("utils.jl")
include("bfmi.jl")
include("ess_rhat.jl")
include("mcse.jl")
include("rstar.jl")

end  # module
