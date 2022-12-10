using InferenceObjects, OrderedCollections, Test

module TestSubModule end

@testset "utils" begin
    @testset "recursive_stack" begin
        @test InferenceObjects.recursive_stack([1, 2]) == [1, 2]
        @test InferenceObjects.recursive_stack([[1, 2]]) == permutedims([1 2])
        @test InferenceObjects.recursive_stack([[1, 2], [3, 4]]) == reshape(1:4, 2, 2)
        @test InferenceObjects.recursive_stack(1) === 1
        @test InferenceObjects.recursive_stack(1:5) == 1:5
    end

    @testset "stack_draws" begin
        draws = [(x=rand(), y=rand(2), z=randn(3, 4)) for _ in 1:10]
        chain = @inferred InferenceObjects.stack_draws(draws)
        @test chain isa NamedTuple{(:x, :y, :z)}
        @test size.(values(chain)) == ((10,), (10, 2), (10, 3, 4))
    end

    @testset "stack_chains" begin
        chains = [(x=rand(10), y=rand(10, 2), z=randn(10, 3, 4)) for _ in 1:5]
        vals = @inferred InferenceObjects.stack_chains(chains)
        @test vals isa NamedTuple{(:x, :y, :z)}
        @test size.(values(vals)) == ((10, 5), (10, 5, 2), (10, 5, 3, 4))
    end

    @testset "as_array" begin
        @test InferenceObjects.as_array(3) == fill(3)
        @test InferenceObjects.as_array(2.5) == fill(2.5)
        @test InferenceObjects.as_array("var") == fill("var")
        x = randn(3)
        @test InferenceObjects.as_array(x) == x
        x = randn(2, 3)
        @test InferenceObjects.as_array(x) == x
        x = randn(2, 3, 4)
        @test InferenceObjects.as_array(x) == x
    end

    @testset "namedtuple_of_arrays" begin
        @test InferenceObjects.namedtuple_of_arrays((x=3, y=4)) == (x=fill(3), y=fill(4))
        @test InferenceObjects.namedtuple_of_arrays([(x=3, y=4), (x=5, y=6)]) ==
            (x=[3, 5], y=[4, 6])
        @test InferenceObjects.namedtuple_of_arrays([
            [(x=3, y=4), (x=5, y=6)], [(x=7, y=8), (x=9, y=10)]
        ]) == (x=[3 7; 5 9], y=[4 8; 6 10])
    end

    @testset "package_version" begin
        @test InferenceObjects.package_version(InferenceObjects) isa VersionNumber
        @test InferenceObjects.package_version(TestSubModule) === nothing
    end

    @testset "rekey" begin
        orig = (x=3, y=4, z=5)
        keymap = (x=:y, y=:a)
        @testset "NamedTuple" begin
            new = @inferred NamedTuple InferenceObjects.rekey(orig, keymap)
            @test new isa NamedTuple
            @test new == (y=3, a=4, z=5)
        end
        @testset "Dict" begin
            orig_dict = Dict(pairs(orig))
            new = @inferred InferenceObjects.rekey(orig_dict, keymap)
            @test new isa typeof(orig_dict)
            @test new == Dict(:y => 3, :a => 4, :z => 5)
        end
    end

    @testset "as_namedtuple" begin
        @test InferenceObjects.as_namedtuple(OrderedDict(:x => 3, :y => 4)) === (x=3, y=4)
        @test InferenceObjects.as_namedtuple(OrderedDict("x" => 4, "y" => 5)) === (x=4, y=5)
        @test InferenceObjects.as_namedtuple((y=6, x=7)) === (y=6, x=7)
    end
end
