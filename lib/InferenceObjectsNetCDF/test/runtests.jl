using InferenceObjectsNetCDF
using NCDatasets: NCDatasets
using Test

include("../../../test/test_helpers.jl")

@testset "InferenceObjectsNetCDF" begin
    idata = random_data()
    @testset "to_netcdf/from_netcdf roundtrip" begin
        mktempdir() do dir
            path = joinpath(dir, "data.nc")
            @test !isfile(path)
            to_netcdf(idata, path)
            @test isfile(path)
            idata2 = from_netcdf(path)
            test_idata_approx_equal(idata, idata2)

            ds = NCDatasets.NCDataset(path, "r")
            idata3 = from_netcdf(ds; load_mode=:lazy)
            test_idata_approx_equal(idata, idata3)
            close(ds)
        end
    end
end
