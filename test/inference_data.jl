using InferenceObjects, DimensionalData, Test

@testset "InferenceData" begin
    var_names = (:a, :b)
    data_names = (:y,)
    coords = (
        chain=1:4, draw=1:100, shared=["s1", "s2", "s3"], dima=1:4, dimb=2:6, dimy=1:5
    )
    dims = (a=(:shared, :dima), b=(:shared, :dimb), y=(:shared, :dimy))
    metadata = Dict("inference_library" => "PPL")
    posterior = random_dataset(var_names, dims, coords, metadata, (;))
    prior = random_dataset(var_names, dims, coords, metadata, (;))
    observed_data = random_dataset(data_names, dims, coords, metadata, (;))
    group_data = Dict(pairs((; prior, observed_data, posterior)))

    @testset "constructors" begin
        idata = @inferred(InferenceData(group_data))
        @test idata isa InferenceData
        @test parent(idata) == group_data

        @test InferenceData(; group_data...) == idata
        @test InferenceData(idata) === idata
    end

    idata = InferenceData(group_data)

    @testset "properties" begin
        @test propertynames(idata) == collect(keys(group_data))
        @test getproperty(idata, :posterior) === posterior
        @test getproperty(idata, :prior) === prior
        @test hasproperty(idata, :posterior)
        @test hasproperty(idata, :prior)
        @test !hasproperty(idata, :prior_predictive)
    end

    @testset "iteration" begin
        @test keys(idata) == collect(keys(group_data))
        @test haskey(idata, :posterior)
        @test haskey(idata, :prior)
        @test !haskey(idata, :log_likelihood)
        @test values(idata) == collect(values(group_data))
        @test pairs(idata) isa AbstractDict{Symbol,Dataset}
        @test pairs(idata) == pairs(group_data)
        @test length(idata) == length(group_data)
        @test iterate(idata) == iterate(parent(idata))
        for i in 1:(length(idata) + 1)
            @test iterate(idata, i) === iterate(parent(idata), i)
        end
        @test eltype(idata) <: Pair{Symbol,Dataset}
        @test collect(idata) isa Vector{Pair{Symbol,Dataset}}
    end

    @testset "indexing" begin
        @test idata[:posterior] === posterior
        @test idata[:prior] === prior

        idata_sel = idata[dima=At(2:3), dimb=At(6)]
        @test idata_sel isa InferenceData
        @test InferenceObjects.groupnames(idata_sel) == InferenceObjects.groupnames(idata)
        @test Dimensions.index(idata_sel.posterior, :dima) == 2:3
        @test Dimensions.index(idata_sel.prior, :dima) == 2:3
        @test Dimensions.index(idata_sel.posterior, :dimb) == [6]
        @test Dimensions.index(idata_sel.prior, :dimb) == [6]

        if VERSION ≥ v"1.7"
            idata_sel = idata[[:posterior, :observed_data], dimy=1, dimb=1, shared=At("s1")]
            @test idata_sel isa InferenceData
            @test InferenceObjects.groupnames(idata_sel) == [:posterior, :observed_data]
            @test Dimensions.index(idata_sel.posterior, :dima) == coords.dima
            @test Dimensions.index(idata_sel.posterior, :dimb) == coords.dimb[[1]]
            @test Dimensions.index(idata_sel.posterior, :shared) == ["s1"]
            @test Dimensions.index(idata_sel.observed_data, :dimy) == coords.dimy[[1]]
            @test Dimensions.index(idata_sel.observed_data, :shared) == ["s1"]
        end

        ds_sel = idata[:posterior, chain=1]
        @test ds_sel isa Dataset
        @test !hasdim(ds_sel, :chain)

        idata.warmup_posterior = posterior
        @test issetequal(keys(idata), [keys(group_data)..., :warmup_posterior])
        @test idata[:warmup_posterior] == posterior
    end

    @testset "isempty" begin
        @test !isempty(idata)
        @test isempty(InferenceData())
    end

    @testset "groups" begin
        @test InferenceObjects.groups(idata) === getfield(idata, :groups)
        @test InferenceObjects.groups(InferenceData(; prior)) == pairs((; prior))
    end

    @testset "hasgroup" begin
        @test InferenceObjects.hasgroup(idata, :posterior)
        @test InferenceObjects.hasgroup(idata, :prior)
        @test !InferenceObjects.hasgroup(idata, :prior_predictive)
    end

    @testset "groupnames" begin
        @test issetequal(
            InferenceObjects.groupnames(idata), [keys(group_data)..., :warmup_posterior]
        )
        @test InferenceObjects.groupnames(InferenceData(; posterior)) == [:posterior]
    end

    @testset "show" begin
        @testset "plain" begin
            text = sprint(show, MIME("text/plain"), idata)
            @test text == """
            InferenceData with groups:
              > posterior
              > prior
              > observed_data
              > warmup_posterior"""
        end

        @testset "html" begin
            # TODO: improve test
            text = sprint(show, MIME("text/html"), idata)
            @test text isa String
            @test occursin("InferenceData", text)
            @test occursin("Dataset", text)
        end
    end
end
