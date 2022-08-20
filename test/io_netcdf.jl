using InferenceObjects, Test

@testset "NetCDF I/O" begin
    idata = random_data()
    @testset "custom error messages are raised" begin
        path = joinpath("dummy.nc")
        @test_throws MethodError to_netcdf(idata, path)
        @test_throws MethodError from_netcdf(path)
        if isdefined(Base.Experimental, :register_error_hint) && VERSION ≥ v"1.8"
            @test_throws "NCDatasets is required" to_netcdf(idata, path)
            @test_throws "NCDatasets is required" from_netcdf(path)
        end
    end
    include("integration/ncdatasets.jl")
end
