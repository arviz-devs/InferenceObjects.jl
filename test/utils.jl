using InferenceObjects, Test

module TestSubModule end

@testset "utils" begin
    @testset "recursive_stack" begin
        @test InferenceObjects.recursive_stack([1, 2]) == [1, 2]
        @test InferenceObjects.recursive_stack([[1, 2]]) == permutedims([1 2])
        @test InferenceObjects.recursive_stack([[1, 2], [3, 4]]) == reshape(1:4, 2, 2)
        @test InferenceObjects.recursive_stack(1) === 1
        @test InferenceObjects.recursive_stack(1:5) == 1:5
    end

    @testset "namedtuple_of_arrays" begin
        @test InferenceObjects.namedtuple_of_arrays((x=3, y=4)) === (x=3, y=4)
        @test InferenceObjects.namedtuple_of_arrays([(x=3, y=4), (x=5, y=6)]) ==
            (x=[3, 5], y=[4, 6])
        @test InferenceObjects.namedtuple_of_arrays([
            [(x=3, y=4), (x=5, y=6)], [(x=7, y=8), (x=9, y=10)]
        ]) == (x=[3 5; 7 9], y=[4 6; 8 10])
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
end
