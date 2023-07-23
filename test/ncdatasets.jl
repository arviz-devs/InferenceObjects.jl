using InferenceObjects
using NCDatasets: NCDatasets
using Test

@testset "NCDatasets integration" begin
    idata = random_data()
    @testset "to_netcdf/from_netcdf roundtrip" begin
        mktempdir() do dir
            path = joinpath(dir, "data.nc")
            @test !isfile(path)
            to_netcdf(idata, path)
            @test isfile(path)
            idata2 = from_netcdf(path)
            test_idata_approx_equal(idata, idata2)

            NCDatasets.NCDataset(path, "r") do ds
                idata3 = from_netcdf(ds; load_mode=:lazy)
                test_idata_approx_equal(idata, idata3; check_eltypes=false)

                idata4 = convert_to_inference_data(ds; group=:posterior)
                test_idata_approx_equal(idata, idata4)
            end
        end
    end
end
