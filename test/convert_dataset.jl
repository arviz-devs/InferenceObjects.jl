using InferenceObjects, DimensionalData, Test

@testset "conversion to Dataset" begin
    @testset "conversion" begin
        J = 8
        K = 6
        L = 3
        nchains = 4
        ndraws = 500
        vars = (a=randn(J, ndraws, nchains), b=randn(K, L, ndraws, nchains))
        coords = (bi=2:(K + 1), draw=1:2:1_000)
        dims = (b=[:bi, nothing],)
        attrs = Dict(:mykey => 5)
        ds = namedtuple_to_dataset(vars; library="MyLib", coords, dims, attrs)
        @test convert(Dataset, ds) === ds
        ds2 = convert(Dataset, [1.0, 2.0, 3.0, 4.0])
        @test ds2 isa Dataset
        @test ds2 == convert_to_dataset([1.0, 2.0, 3.0, 4.0])
        @test convert(DimensionalData.DimStack, ds) === parent(ds)
    end

    @testset "convert_to_dataset" begin
        nchains = 4
        ndraws = 100
        nshared = 3
        xdims = (:shared, :draw, :chain)
        x = DimArray(randn(nshared, ndraws, nchains), xdims)
        ydims = (Dim{:ydim1}(Any["a", "b"]), Dim{:shared}, :draw, :chain)
        y = DimArray(randn(2, nshared, ndraws, nchains), ydims)
        metadata = Dict(:prop1 => "val1", :prop2 => "val2")
        ds = Dataset((; x, y); metadata)

        @testset "convert_to_dataset(::Dataset; kwargs...)" begin
            @test convert_to_dataset(ds) isa Dataset
            @test convert_to_dataset(ds) === ds
        end

        @testset "convert_to_dataset(::$T; kwargs...)" for T in (Dict, NamedTuple)
            data = (x=randn(100, 4), y=randn(2, 100, 4))
            if T <: Dict
                data = T(pairs(data))
            end
            ds2 = convert_to_dataset(data)
            @test ds2 isa Dataset
            @test ds2.x == data[:x]
            @test DimensionalData.name(DimensionalData.dims(ds2.x)) == (:draw, :chain)
            @test ds2.y == data[:y]
            @test DimensionalData.name(DimensionalData.dims(ds2.y)) ==
                (:y_dim_1, :draw, :chain)
        end

        @testset "convert_to_dataset(::InferenceData; kwargs...)" begin
            idata = random_data()
            @test convert_to_dataset(idata) === idata.posterior
            @test convert_to_dataset(idata; group=:prior) === idata.prior
        end
    end
end
