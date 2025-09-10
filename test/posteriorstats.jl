using ArviZExampleData
using DimensionalData
using InferenceObjects
using PosteriorStats
using Statistics
using StatsBase
using Test

_as_array(x) = fill(x)
_as_array(x::AbstractArray) = x

@testset "PosteriorStats integration" begin
    @testset for ci_fun in (eti, hdi)
        nt = (x=randn(1000, 3), y=randn(1000, 3, 4), z=randn(1000, 3, 4, 2))
        posterior = convert_to_dataset(nt)
        posterior_perm = convert_to_dataset((
            x=permutedims(posterior.x),
            y=permutedims(posterior.y, (3, 2, 1)),
            z=permutedims(posterior.z, (3, 2, 4, 1)),
        ))
        idata = InferenceData(; posterior)
        @testset for prob in (0.76, 0.93)
            @test_broken @inferred ci_fun(posterior; prob)
            r1 = ci_fun(posterior; prob)
            r1_perm = ci_fun(posterior_perm; prob)
            for k in (:x, :y, :z)
                rk = ci_fun(posterior[k]; prob)
                @test r1[k] == _as_array(rk)
                # equality check is safe because these are always data values
                @test r1_perm[k] == _as_array(rk)
            end
            @test_broken @inferred ci_fun(idata; prob)
            r2 = ci_fun(idata; prob)
            @test r1 == r2
        end
    end

    @testset "loo" begin
        @testset for sz in ((1000, 4), (1000, 4, 2), (100, 4, 2, 3))
            atol_perm = cbrt(eps(Float64))

            log_likelihood = DimArray(
                randn(sz), (:draw, :chain, :param1, :param2)[1:length(sz)]
            )
            loo_result = loo(log_likelihood)
            estimates = elpd_estimates(loo_result)
            pointwise = elpd_estimates(loo_result; pointwise=true)

            idata1 = InferenceData(; log_likelihood=Dataset((; x=log_likelihood)))
            loo_result1 = loo(idata1)
            @test isequal(loo_result1.estimates, loo_result.estimates)
            @test loo_result1.pointwise isa Dataset
            if length(sz) == 2
                @test issetequal(
                    keys(loo_result1.pointwise),
                    (:elpd, :elpd_mcse, :p, :reff, :pareto_shape),
                )
            else
                @test loo_result1.pointwise.elpd == loo_result.pointwise.elpd
                @test loo_result1.pointwise.elpd_mcse == loo_result.pointwise.elpd_mcse
                @test loo_result1.pointwise.p == loo_result.pointwise.p
                @test loo_result1.pointwise.reff == loo_result.pointwise.reff
                @test loo_result1.pointwise.pareto_shape ==
                    loo_result.pointwise.pareto_shape
            end

            ll_perm = permutedims(
                log_likelihood, (ntuple(x -> x + 2, length(sz) - 2)..., 2, 1)
            )
            idata2 = InferenceData(; log_likelihood=Dataset((; y=ll_perm)))
            loo_result2 = loo(idata2)
            @test loo_result2.estimates.elpd ≈ loo_result1.estimates.elpd atol = atol_perm
            @test isapprox(
                loo_result2.estimates.elpd_mcse,
                loo_result1.estimates.elpd_mcse;
                nans=true,
                atol=atol_perm,
            )
            @test loo_result2.estimates.p ≈ loo_result1.estimates.p atol = atol_perm
            @test isapprox(
                loo_result2.estimates.p_mcse,
                loo_result1.estimates.p_mcse;
                nans=true,
                atol=atol_perm,
            )
            @test isapprox(
                loo_result2.pointwise.elpd_mcse,
                loo_result1.pointwise.elpd_mcse;
                nans=true,
                atol=atol_perm,
            )
            @test loo_result2.pointwise.p ≈ loo_result1.pointwise.p atol = atol_perm
            @test loo_result2.pointwise.reff ≈ loo_result1.pointwise.reff atol = atol_perm
            @test loo_result2.pointwise.pareto_shape ≈ loo_result1.pointwise.pareto_shape atol =
                atol_perm
        end
    end

    @testset "loo_pit" begin
        draw_dim = Dim{:draw}(1:100)
        chain_dim = Dim{:chain}(0:2)
        sample_dims = (draw_dim, chain_dim)
        param_dims = (Dim{:param1}(1:2), Dim{:param2}([:a, :b, :c]))
        all_dims = (sample_dims..., param_dims...)
        y = DimArray(randn(size(param_dims)...), param_dims)
        z = DimArray(fill(randn()), ())
        y_pred = DimArray(randn(size(all_dims)...), all_dims)
        log_like = DimArray(randn(size(all_dims)...), all_dims)
        log_weights = loo(log_like).psis_result.log_weights
        pit_vals = loo_pit(y, y_pred, log_weights)

        idata1 = InferenceData(;
            observed_data=Dataset((; y)),
            posterior_predictive=Dataset((; y=y_pred)),
            log_likelihood=Dataset((; y=log_like)),
        )
        @test_throws Exception loo_pit(idata1; y_name=:z)
        @test_throws Exception loo_pit(idata1; y_pred_name=:z)
        @test_throws Exception loo_pit(idata1; log_likelihood_name=:z)
        @test loo_pit(idata1) == pit_vals
        VERSION ≥ v"1.7" && @inferred loo_pit(idata1)
        @test loo_pit(idata1; y_name=:y) == pit_vals
        @test loo_pit(idata1; y_name=:y, y_pred_name=:y, log_likelihood_name=:y) == pit_vals

        idata2 = InferenceData(;
            observed_data=Dataset((; z, y)),
            posterior_predictive=Dataset((; y_pred)),
            log_likelihood=Dataset((; log_like)),
        )
        @test_throws ArgumentError loo_pit(idata2)
        @test_throws ArgumentError loo_pit(
            idata2; y_name=:z, y_pred_name=:y_pred, log_likelihood_name=:log_like
        )
        @test_throws ArgumentError loo_pit(idata2; y_name=:y, y_pred_name=:y_pred)
        @test loo_pit(idata2; y_name=:y, log_likelihood_name=:log_like) == pit_vals
        @test loo_pit(
            idata2; y_name=:y, y_pred_name=:y_pred, log_likelihood_name=:log_like
        ) == pit_vals
        idata3 = InferenceData(;
            observed_data=Dataset((; y)),
            posterior_predictive=Dataset((; y=y_pred)),
            sample_stats=Dataset((; log_likelihood=log_like)),
        )
        @test loo_pit(idata3) == pit_vals
        VERSION ≥ v"1.7" && @inferred loo_pit(idata3)

        all_dims_perm = (param_dims..., reverse(sample_dims)...)
        idata4 = InferenceData(;
            observed_data=Dataset((; y)),
            posterior_predictive=Dataset((; y=permutedims(y_pred, all_dims_perm))),
            log_likelihood=Dataset((; y=permutedims(log_like, all_dims_perm))),
        )
        @test loo_pit(idata4) ≈ pit_vals
        VERSION ≥ v"1.7" && @inferred loo_pit(idata4)

        idata5 = InferenceData(;
            observed_data=Dataset((; y)), posterior_predictive=Dataset((; y=y_pred))
        )
        @test_throws ArgumentError loo_pit(idata5)
    end

    @testset "r2_score" begin
        @testset for name in ("regression1d", "regression10d")
            idata = load_example_data(name)
            VERSION ≥ v"1.9" && @inferred r2_score(idata)
            r2_val = r2_score(idata)
            @test r2_val == r2_score(
                idata.observed_data.y,
                PermutedDimsArray(idata.posterior_predictive.y, (:draw, :chain, :y_dim_0)),
            )
            @test r2_val == r2_score(idata; y_name=:y)
            @test r2_val == r2_score(idata; y_pred_name=:y)
            @test r2_val == r2_score(idata; y_name=:y, y_pred_name=:y)
            @test_throws Exception r2_score(idata; y_name=:z)
            @test_throws Exception r2_score(idata; y_pred_name=:z)
        end
    end

    @testset "waic" begin
        @testset for sz in ((1000, 4), (1000, 4, 2), (100, 4, 2, 3))
            atol_perm = cbrt(eps())

            log_likelihood = DimArray(
                randn(sz), (:draw, :chain, :param1, :param2)[1:length(sz)]
            )
            waic_result = waic(log_likelihood)
            estimates = elpd_estimates(waic_result)
            pointwise = elpd_estimates(waic_result; pointwise=true)

            idata1 = InferenceData(; log_likelihood=Dataset((; x=log_likelihood)))
            waic_result1 = waic(idata1)
            @test isequal(waic_result1.estimates, waic_result.estimates)
            @test waic_result1.pointwise isa Dataset
            if length(sz) == 2
                @test issetequal(keys(waic_result1.pointwise), (:elpd, :p))
            else
                @test waic_result1.pointwise.elpd == waic_result.pointwise.elpd
                @test waic_result1.pointwise.p == waic_result.pointwise.p
            end

            ll_perm = permutedims(
                log_likelihood, (ntuple(x -> x + 2, length(sz) - 2)..., 2, 1)
            )
            idata2 = InferenceData(; log_likelihood=Dataset((; y=ll_perm)))
            waic_result2 = waic(idata2)
            @test waic_result2.estimates.elpd ≈ waic_result1.estimates.elpd atol = atol_perm
            @test isapprox(
                waic_result2.estimates.elpd_mcse,
                waic_result1.estimates.elpd_mcse;
                nans=true,
                atol=atol_perm,
            )
            @test waic_result2.estimates.p ≈ waic_result1.estimates.p atol = atol_perm
            @test isapprox(
                waic_result2.estimates.p_mcse,
                waic_result1.estimates.p_mcse;
                nans=true,
                atol=atol_perm,
            )
            @test waic_result2.pointwise.p ≈ waic_result1.pointwise.p atol = atol_perm
        end
    end

    @testset "compare" begin
        eight_schools_data = (
            centered=load_example_data("centered_eight"),
            non_centered=load_example_data("non_centered_eight"),
        )
        result1 = compare(eight_schools_data)
        result2 = compare(map(loo, eight_schools_data))
        @testset for k in (:name, :rank, :elpd_diff, :elpd_diff_mcse, :weight)
            @test getproperty(result1, k) == getproperty(result2, k)
        end
    end

    @testset "summarize/summarystats" begin
        data = Dataset(
            random_dim_stack(
                (:x, :y, :z),
                (y=[:a], z=[:b, :c]),
                (chain=1:4, draw=1:100, a=0:2, b=["val 1", "val 2"], c=[:q, :r]),
                Dict(),
                (;),
            ),
        )
        slices = [
            data.x,
            data.y[a=1],
            data.y[a=2],
            data.y[a=3],
            data.z[b=1, c=1],
            data.z[b=2, c=1],
            data.z[b=1, c=2],
            data.z[b=2, c=2],
        ]
        var_names = [
            "x",
            "y[0]",
            "y[1]",
            "y[2]",
            "z[val 1,q]",
            "z[val 2,q]",
            "z[val 1,r]",
            "z[val 2,r]",
        ]
        arr = cat(map(DimensionalData.data, slices)...; dims=3)

        stats = @inferred SummaryStats summarize(data, mean, std; name="Stats")
        @test stats.name == "Stats"
        @test stats[:parameter] == var_names
        @test stats[:mean] ≈ map(mean, slices)
        @test stats[:std] ≈ map(std, slices)

        stats_def = summarize(arr; var_names)
        @test summarize(data) == stats_def

        stats2 = summarize(InferenceData(; posterior=data); name="Posterior Stats")
        @test stats2.name == "Posterior Stats"
        @test stats2 == stats_def

        stats3 = summarize(InferenceData(; prior=data); group=:prior, name="Prior Stats")
        @test stats3.name == "Prior Stats"
        @test stats3 == stats_def

        stats4 = summarystats(data; name="Stats")
        @test stats4.name == "Stats"
        @test stats4 == stats_def

        stats5 = summarystats(InferenceData(; prior=data); group=:prior, name="Prior Stats")
        @test stats5.name == "Prior Stats"
        @test stats5 == stats_def
    end
end
