using InferenceObjects, DimensionalData, OffsetArrays, Test
using DimensionalData.Lookups

Dimensions.@dim foo "foo"

@testset "dimension-related functions" begin
    @testset "has_all_sample_dims" begin
        @test !InferenceObjects.has_all_sample_dims((:chain,))
        @test !InferenceObjects.has_all_sample_dims((:draw,))
        @test InferenceObjects.has_all_sample_dims((:chain, :draw))
        @test InferenceObjects.has_all_sample_dims((:draw, :chain))
        @test InferenceObjects.has_all_sample_dims((:draw, :chain, :x))

        @test !InferenceObjects.has_all_sample_dims((Dim{:chain},))
        @test !InferenceObjects.has_all_sample_dims((Dim{:draw},))
        @test InferenceObjects.has_all_sample_dims((Dim{:chain}, Dim{:draw}))
        @test InferenceObjects.has_all_sample_dims((Dim{:draw}, Dim{:chain}))
        @test InferenceObjects.has_all_sample_dims((Dim{:draw}, Dim{:chain}, Dim{:x}))

        @test !InferenceObjects.has_all_sample_dims((Dim{:chain}(1:4),))
        @test !InferenceObjects.has_all_sample_dims((Dim{:draw}(1:10),))
        @test InferenceObjects.has_all_sample_dims((Dim{:chain}(1:4), Dim{:draw}(1:10)))
        @test InferenceObjects.has_all_sample_dims((Dim{:draw}(1:10), Dim{:chain}(1:4)))
        @test InferenceObjects.has_all_sample_dims((
            Dim{:draw}(1:10), Dim{:chain}(1:4), Dim{:x}(1:2)
        ))
    end

    @testset "_name2dim" begin
        @testset for k in (:chain, :draw, :foo)
            @test InferenceObjects._name2dim(k) === Dim{k}(NoLookup())
            @test @inferred(InferenceObjects._name2dim(Dim{k})) === Dim{k}
            @test @inferred(InferenceObjects._name2dim(Dim{k}())) === Dim{k}()
            @test @inferred(InferenceObjects._name2dim(Dim{k}(1:4))) == Dim{k}(1:4)
        end
        @test InferenceObjects._name2dim((:chain, :draw, :foo)) ===
            (Dim{:chain}(NoLookup()), Dim{:draw}(NoLookup()), Dim{:foo}(NoLookup()))
    end

    @testset "_valdim" begin
        @testset for d in (X(), X(1:10))
            @test @inferred(InferenceObjects._valdim(d)) === d
        end
        @test InferenceObjects._valdim(X) === X(NoLookup())
        @test InferenceObjects._valdim(Dim{:a}) === Dim{:a}(NoLookup())
        d = Dim{:a}(1:5)
        @test InferenceObjects._valdim(d) === d
    end

    @testset "as_dimension" begin
        coords = (;)
        @testset for dim in (:foo, Dim{:foo}, Dim{:foo}(), Dim{:foo}(NoLookup()))
            @test InferenceObjects.as_dimension(dim, coords, 2:10) === Dim{:foo}(2:10)
            dim === :foo || @inferred InferenceObjects.as_dimension(dim, coords, 2:10)
        end
        @test InferenceObjects.as_dimension(Dim{:foo}(1:5), coords, 2:10) === Dim{:foo}(1:5)
        coords = (; foo=3:8)
        @testset for dim in
                     (:foo, Dim{:foo}, Dim{:foo}(), Dim{:foo}(NoLookup()), Dim{:foo}(1:5))
            @test InferenceObjects.as_dimension(dim, coords, 2:10) === Dim{:foo}(3:8)
            dim === :foo || @inferred InferenceObjects.as_dimension(dim, coords, 2:10)
        end
    end

    @testset "generate_dims" begin
        x = OffsetArray(randn(10, 4, 2, 3), 11:20, 0:3, -1:0, 2:4)
        gdims = @inferred NTuple{4,Dimensions.Dimension} InferenceObjects.generate_dims(
            x, :x
        )
        @test gdims isa NTuple{4,Dim}
        @test Dimensions.name(gdims) === (:x_dim_1, :x_dim_2, :x_dim_3, :x_dim_4)
        glooks = Dimensions.lookup(gdims)
        @test glooks isa NTuple{4,NoLookup}
        @test parent.(glooks) == (11:20, 0:3, -1:0, 2:4)

        gdims = @inferred NTuple{4,Dimensions.Dimension} InferenceObjects.generate_dims(
            x, :y; dims=(:a, :b)
        )
        @test gdims isa NTuple{4,Dim}
        @test Dimensions.name(gdims) === (:a, :b, :y_dim_3, :y_dim_4)
        glooks = Dimensions.lookup(gdims)
        @test glooks isa NTuple{4,NoLookup}
        @test parent.(glooks) == (11:20, 0:3, -1:0, 2:4)

        gdims = @inferred NTuple{4,Dimensions.Dimension} InferenceObjects.generate_dims(
            x, :z; dims=(:c, :d), default_dims=(:draw, :chain)
        )
        @test gdims isa NTuple{4,Dim}
        @test Dimensions.name(gdims) === (:draw, :chain, :c, :d)
        glooks = Dimensions.lookup(gdims)
        @test glooks isa NTuple{4,NoLookup}
        @test parent.(glooks) == (11:20, 0:3, -1:0, 2:4)

        x = randn(2, 3)
        InferenceObjects.generate_dims(x, :x; dims=(:a, :b))
        @test_throws DimensionMismatch InferenceObjects.generate_dims(
            x, :x; dims=(:a,), default_dims=[:b, :c]
        )
        @test_throws DimensionMismatch InferenceObjects.generate_dims(
            x, :x; dims=(:a, :b), default_dims=[:c]
        )
        @test_throws DimensionMismatch InferenceObjects.generate_dims(
            x, :x; dims=(:a, :b, :c), default_dims=[:c]
        )
    end

    @testset "array_to_dimarray" begin
        x = OffsetArray(randn(10, 4, 2, 3), 11:20, 0:3, -1:0, 2:4)
        da = @inferred DimArray InferenceObjects.array_to_dimarray(x, :x)
        @test da == x
        @test DimensionalData.name(da) === :x
        gdims = Dimensions.dims(da)
        @test gdims isa NTuple{4,Dim}
        @test Dimensions.name(gdims) === (:x_dim_1, :x_dim_2, :x_dim_3, :x_dim_4)
        @test parent.(Dimensions.lookup(gdims)) == (11:20, 0:3, -1:0, 2:4)

        da = @inferred DimArray InferenceObjects.array_to_dimarray(x, :y; dims=(:a, :b))
        @test da == x
        @test DimensionalData.name(da) === :y
        gdims = Dimensions.dims(da)
        @test gdims isa NTuple{4,Dim}
        @test Dimensions.name(gdims) === (:a, :b, :y_dim_3, :y_dim_4)
        @test parent.(Dimensions.lookup(gdims)) == (11:20, 0:3, -1:0, 2:4)

        da = @inferred DimArray InferenceObjects.array_to_dimarray(
            x, :z; dims=(:c, :d), default_dims=(:draw, :chain)
        )
        @test da == x
        @test DimensionalData.name(da) === :z
        gdims = Dimensions.dims(da)
        @test gdims isa NTuple{4,Dim}
        @test Dimensions.name(gdims) === (:draw, :chain, :c, :d)
        @test parent.(Dimensions.lookup(gdims)) == (11:20, 0:3, -1:0, 2:4)

        v = randn(1_000)
        da = @inferred DimArray InferenceObjects.array_to_dimarray(
            v, :v; dims=(), default_dims=(:draw, :chain)
        )
        @test da == reshape(v, :, 1)
        @test DimensionalData.name(da) === :v
        gdims = Dimensions.dims(da)
        @test gdims isa NTuple{2,Dim}
        @test Dimensions.name(gdims) === (:draw, :chain)
        @test parent.(Dimensions.lookup(gdims)) == (1:1000, 1:1)

        s = fill(1) # 0-dimensional array
        da = @inferred DimArray InferenceObjects.array_to_dimarray(
            s, :s; dims=(), default_dims=(:draw, :chain)
        )
        @test da == reshape(s, 1, 1)
        @test DimensionalData.name(da) === :s
        gdims = Dimensions.dims(da)
        @test gdims isa NTuple{2,Dim}
        @test Dimensions.name(gdims) === (:draw, :chain)
        @test parent.(Dimensions.lookup(gdims)) == (1:1, 1:1)
    end

    @testset "AsSlice" begin
        da = DimArray(randn(2), Dim{:a}(["foo", "bar"]))
        @test da[a = At("foo")] == da[1]
        da_sel = @inferred da[a = InferenceObjects.AsSlice(At("foo"))]
        @test da_sel isa DimArray
        @test Dimensions.dims(da_sel) == (Dim{:a}(["foo"]),)
        @test da_sel == da[a = At(["foo"])]

        da_sel = @inferred da[a = At(["foo", "bar"])]
        @test da_sel isa DimArray
        @test Dimensions.dims(da_sel) == Dimensions.dims(da)
        @test da_sel == da
    end

    @testset "index_to_indices" begin
        @test InferenceObjects.index_to_indices(1) == [1]
        @test InferenceObjects.index_to_indices(2) == [2]
        @test InferenceObjects.index_to_indices([2]) == [2]
        @test InferenceObjects.index_to_indices(1:10) === 1:10
        @test InferenceObjects.index_to_indices(At(1)) === InferenceObjects.AsSlice(At(1))
        @test InferenceObjects.index_to_indices(At(1)) === InferenceObjects.AsSlice(At(1))
    end
end
