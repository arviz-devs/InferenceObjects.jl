using InferenceObjects, Test

@testset "from_namedtuple" begin
    nchains, ndraws = 4, 10
    sizes = (x=(), y=(2,), z=(3, 5))
    dims = (y=[:yx], z=[:zx, :zy])
    coords = (yx=["y1", "y2"], zx=1:3, zy=1:5)

    nts = [
        "NamedTuple" => map(sz -> randn(ndraws, nchains, sz...), sizes),
        "Vector{Vector{NamedTuple}}" =>
            [[map(Base.splat(randn), sizes) for _ in 1:ndraws] for _ in 1:nchains],
    ]

    @testset "posterior::$(type)" for (type, nt) in nts
        @test_broken @inferred from_namedtuple(nt; dims, coords, library="MyLib")
        idata1 = from_namedtuple(nt; dims, coords, library="MyLib")
        idata2 = convert_to_inference_data(nt; dims, coords, library="MyLib")
        test_idata_approx_equal(idata1, idata2)
    end

    @testset "$(group)" for group in [
        :posterior_predictive, :sample_stats, :predictions, :log_likelihood
    ]
        library = "MyLib"
        @testset "::$(type)" for (type, nt) in nts
            idata1 = from_namedtuple(nt; group => nt, dims, coords, library)
            test_idata_group_correct(idata1, group, keys(sizes); library, dims, coords)

            idata2 = from_namedtuple(nt; group => (:x,), dims, coords, library)
            test_idata_group_correct(idata2, :posterior, (:y, :z); library, dims, coords)
            test_idata_group_correct(idata2, group, (:x,); library, dims, coords)
        end
    end

    @testset "$(group)" for group in [:prior_predictive, :sample_stats_prior]
        library = "MyLib"
        @testset "::$(type)" for (type, nt) in nts
            idata1 = from_namedtuple(; prior=nt, group => nt, dims, coords, library)
            test_idata_group_correct(idata1, :prior, keys(sizes); library, dims, coords)
            test_idata_group_correct(idata1, group, keys(sizes); library, dims, coords)

            idata2 = from_namedtuple(; prior=nt, group => (:x,), dims, coords, library)
            test_idata_group_correct(idata2, :prior, (:y, :z); library, dims, coords)
            test_idata_group_correct(idata2, group, (:x,); library, dims, coords)
        end
    end

    @testset "$(group)" for group in
                            [:observed_data, :constant_data, :predictions_constant_data]
        _, nt = nts[1]
        library = "MyLib"
        dims = (; w=[:wx])
        coords = (; wx=1:2)
        idata1 = from_namedtuple(nt; group => (w=[1.0, 2.0], v=2.5), dims, coords, library)
        test_idata_group_correct(idata1, :posterior, keys(sizes); library, dims, coords)
        test_idata_group_correct(
            idata1, group, (:w, :v); library, dims, coords, default_dims=()
        )

        # ensure that dims are matched to named tuple keys
        # https://github.com/arviz-devs/ArviZ.jl/issues/96
        idata2 = from_namedtuple(nt; group => (w=[1.0, 2.0], v=2.5), dims, coords, library)
        test_idata_group_correct(idata2, :posterior, keys(sizes); library, dims, coords)
        test_idata_group_correct(
            idata2, group, (:w, :v); library, dims, coords, default_dims=()
        )
    end

    @testset "convert_to_inference_data with non-posterior `group`" begin
        data = (x=3, y=randn(2))
        idata = convert_to_inference_data(data; group=:observed_data)
        @test issetequal(keys(idata), (:observed_data,))
        @test issetequal(keys(idata.observed_data), (:x, :y))
        @test idata.observed_data.x == fill(data.x)
        @test idata.observed_data.y == data.y
    end
end
