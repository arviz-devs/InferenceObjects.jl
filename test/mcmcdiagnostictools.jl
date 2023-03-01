using DimensionalData
using EvoTrees
using InferenceObjects
using MCMCDiagnosticTools
using MLJBase
using Random
using Statistics
using Test

@testset "MCMCDiagnosticTools integration" begin
    nchains, ndraws = 4, 10
    sizes = (x=(), y=(2,), z=(3, 5))
    dims = (y=[:yx], z=[:zx, :zy])
    coords = (yx=["y1", "y2"], zx=0:2, zy=1:5)
    energy = randn(ndraws, nchains)
    dict1 = Dict(Symbol(k) => randn(ndraws, nchains, sz...) for (k, sz) in pairs(sizes))
    idata1 = from_dict(dict1; dims, coords, sample_stats=Dict(:energy => energy))
    # permute dimensions to test that diagnostics are invariant to dimension order
    post2 = map(idata1.posterior) do var
        n = ndims(var)
        permdims = ((3:n)..., 2, 1)
        return permutedims(var, permdims)
    end
    sample_stats2 = map(permutedims, idata1.sample_stats)
    idata2 = InferenceData(; posterior=post2, sample_stats=sample_stats2)

    @testset for f in (ess, rhat, ess_rhat, mcse)
        kinds = f === mcse ? (mean, std) : (:bulk, :basic)
        @testset for kind in kinds
            # currently `DimensionalData.layers` is not type-inferrable, so we can only
            # infer that the return type is a `Dataset`
            @test_broken @inferred f(idata1; kind)
            metric = @inferred Dataset f(idata1; kind)
            @test issetequal(keys(metric), keys(idata1.posterior))
            @test metric ==
                f(idata1.posterior; kind) ==
                f(idata2; kind) ==
                f(idata2.posterior; kind)
            for k in keys(sizes)
                @test all(
                    hasdim(
                        Dimensions.dims(metric[k]),
                        otherdims(Dimensions.dims(idata1.posterior[k]), (:draw, :chain)),
                    ),
                )
                if f === ess_rhat
                    @test hasdim(metric, :_metric)
                    @test lookup(metric, :_metric) == [:ess, :rhat]
                    @test (
                        ess=vec(parent(view(metric; _metric=At(:ess))[k])),
                        rhat=vec(parent(view(metric; _metric=At(:rhat))[k])),
                    ) == f(reshape(parent(idata1.posterior[k]), ndraws, nchains, :); kind)
                else
                    @test vec(parent(metric[k])) ≈
                        f(reshape(parent(idata1.posterior[k]), ndraws, nchains, :); kind)
                end
            end
        end
    end

    @testset "bfmi" begin
        @inferred bfmi(idata1)
        @inferred bfmi(idata1.sample_stats)
        @test bfmi(idata1) ==
            bfmi(idata1.sample_stats) ==
            bfmi(energy; dims=1) ≈
            bfmi(idata2) ==
            bfmi(idata2.sample_stats)
    end

    @testset "rstar" begin
        classifier(rng) = EvoTreeClassifier(; nrounds=100, eta=0.3, rng)
        @testset for subset in (0.7, 0.8)
            rng = Random.seed!(123)
            r1 = rstar(rng, classifier(rng), idata1; subset)
            rng = Random.seed!(123)
            r2 = rstar(rng, classifier(rng), idata1.posterior; subset)
            rng = Random.seed!(123)
            r3 = rstar(rng, classifier(rng), idata2; subset)
            rng = Random.seed!(123)
            r4 = rstar(rng, classifier(rng), idata2.posterior; subset)
            rng = Random.seed!(123)
            post_mat = cat(
                map(var -> reshape(parent(var), ndraws, nchains, :), idata1.posterior)...;
                dims=3,
            )
            r5 = rstar(rng, classifier(rng), post_mat; subset)
            Random.seed!(123)
            r6 = rstar(classifier(rng), idata1; subset)
            Random.seed!(123)
            r7 = rstar(classifier(rng), idata1; subset)
            @test r1 == r2 == r3 == r4 == r5 == r6 == r7
        end
    end
end
