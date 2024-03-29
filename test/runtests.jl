using InferenceObjects, Test

@testset "InferenceObjects" begin
    include("test_helpers.jl")
    include("utils.jl")
    include("dimensions.jl")
    include("dataset.jl")
    include("inference_data.jl")
    include("convert_dataset.jl")
    include("convert_inference_data.jl")
    include("from_namedtuple.jl")
    include("from_dict.jl")

    include("mcmcdiagnostictools.jl")
    include("ncdatasets.jl")
    include("posteriorstats.jl")
end
