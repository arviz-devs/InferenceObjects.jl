using InferenceObjects, DimensionalData, Test

@testset "dataset" begin
    @testset "Dataset" begin
        @testset "Constructors" begin
            nchains = 4
            ndraws = 100
            nshared = 3
            xdims = (:shared, :draw, :chain)
            x = DimArray(randn(nshared, ndraws, nchains), xdims)
            ydims = (:ydim1, :shared, :draw, :chain)
            y = DimArray(randn(2, nshared, ndraws, nchains), ydims)
            metadata = Dict("prop1" => "val1", "prop2" => "val2")

            @testset "from NamedTuple" begin
                data = (; x, y)
                ds = Dataset(data; metadata)
                @test ds isa Dataset
                @test DimensionalData.data(ds) == data
                for dim in xdims
                    @test DimensionalData.hasdim(ds, dim)
                end
                for dim in ydims
                    @test DimensionalData.hasdim(ds, dim)
                end
                for (var_name, dims) in ((:x, xdims), (:y, ydims))
                    da = ds[var_name]
                    @test DimensionalData.name(da) === var_name
                    @test DimensionalData.name(DimensionalData.dims(da)) === dims
                end
                @test DimensionalData.metadata(ds) == metadata
            end

            @testset "from DimArrays" begin
                data = (
                    DimensionalData.rebuild(x; name=:x), DimensionalData.rebuild(y; name=:y)
                )
                ds = Dataset(data...; metadata)
                @test ds isa Dataset
                @test values(DimensionalData.data(ds)) == data
                for dim in xdims
                    @test DimensionalData.hasdim(ds, dim)
                end
                for dim in ydims
                    @test DimensionalData.hasdim(ds, dim)
                end
                for (var_name, dims) in ((:x, xdims), (:y, ydims))
                    da = ds[var_name]
                    @test DimensionalData.name(da) === var_name
                    @test DimensionalData.name(DimensionalData.dims(da)) === dims
                end
                @test DimensionalData.metadata(ds) == metadata
            end

            @testset "idempotent" begin
                ds = Dataset((; x, y); metadata)
                @test Dataset(ds) === ds
            end

            @testset "errors with mismatched dimensions" begin
                data_bad = (
                    x=DimArray(randn(3, 100, 3), (:chains, :draws, :shared)),
                    y=DimArray(randn(2, 3, 100, 4), (:chains, :draws, :ydim1, :shared)),
                )
                @test_throws Exception Dataset(data_bad)
            end
        end

        nchains = 4
        ndraws = 100
        nshared = 3
        xdims = (:shared, :draw, :chain)
        x = DimArray(randn(nshared, ndraws, nchains), xdims)
        ydims = (:ydim1, :shared, :draw, :chain)
        y = DimArray(randn(2, nshared, ndraws, nchains), ydims)
        metadata = Dict("prop1" => "val1", "prop2" => "val2")
        ds = Dataset((; x, y); metadata)

        @testset "parent" begin
            @test parent(ds) isa DimStack
            @test parent(ds) == ds
        end

        @testset "properties" begin
            @test propertynames(ds) == (:x, :y)
            @test ds.x isa DimArray
            @test ds.x == x
            @test ds.y isa DimArray
            @test ds.y == y
        end

        @testset "getindex" begin
            @test ds[:x] isa DimArray
            @test ds[:x] == x
            @test ds[:y] isa DimArray
            @test ds[:y] == y
        end

        @testset "copy/deepcopy" begin
            @test copy(ds) == ds
            @test deepcopy(ds) == ds
        end

        @testset "attributes" begin
            @test InferenceObjects.attributes(ds) == metadata
            dscopy = deepcopy(ds)
            InferenceObjects.setattribute!(dscopy, "prop3", "val3")
            @test InferenceObjects.attributes(dscopy)["prop3"] == "val3"
            @test_deprecated InferenceObjects.setattribute!(dscopy, :prop3, "val4")
            @test InferenceObjects.attributes(dscopy)["prop3"] == "val4"
        end
    end

    @testset "namedtuple_to_dataset" begin
        J = 8
        K = 6
        L = 3
        nchains = 4
        ndraws = 500
        vars = (a=randn(J, ndraws, nchains), b=randn(K, L, ndraws, nchains))
        coords = (bi=2:(K + 1), draw=1:2:1_000)
        dims = (b=[:bi, nothing],)
        expected_dims = (
            a=(
                Dimensions.Dim{:a_dim_1}(1:J),
                Dimensions.Dim{:draw}(1:2:1_000),
                Dimensions.Dim{:chain}(1:nchains),
            ),
            b=(
                Dimensions.Dim{:bi}(2:(K + 1)),
                Dimensions.Dim{:b_dim_2}(1:L),
                Dimensions.Dim{:draw}(1:2:1_000),
                Dimensions.Dim{:chain}(1:nchains),
            ),
        )
        attrs = Dict("mykey" => 5)
        @test_broken @inferred namedtuple_to_dataset(
            vars; library="MyLib", coords, dims, attrs
        )
        ds = namedtuple_to_dataset(vars; library="MyLib", coords, dims, attrs)
        @test ds isa Dataset
        for (var_name, var_data) in pairs(DimensionalData.layers(ds))
            @test var_data isa DimensionalData.DimArray
            @test var_name === DimensionalData.name(var_data)
            @test var_data == vars[var_name]
            _dims = DimensionalData.dims(var_data)
            @test _dims == expected_dims[var_name]
        end
        metadata = DimensionalData.metadata(ds)
        @test metadata isa AbstractDict{<:AbstractString}
        @test haskey(metadata, "created_at")
        @test metadata["inference_library"] == "MyLib"
        @test !haskey(metadata, "inference_library_version")
        @test metadata["mykey"] == 5
    end
end
