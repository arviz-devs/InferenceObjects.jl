using InferenceObjects, DimensionalData, PyCall, Test

arviz = PyNULL()
xarray = PyNULL()
has_python_arviz = false

try
    copy!(arviz, pyimport("arviz"))
    copy!(xarray, pyimport("xarray"))
    global has_python_arviz = true
catch e
    e isa PyError || rethrow()
    @warn "Python ArviZ could not be loaded in PyCall's Python environment, skipping PyCall tests"
end

has_python_arviz && @testset "PyCall integration" begin
    @testset "xarray interop" begin
        @testset "Dataset <-> xarray" begin
            nchains = 4
            ndraws = 100
            nshared = 3
            xdims = (:chain, :draw, :shared)
            x = DimArray(randn(nchains, ndraws, nshared), xdims)
            ydims = (:chain, :draw, Dim{:ydim1}(Any["a", "b"]), :shared)
            y = DimArray(randn(nchains, ndraws, 2, nshared), ydims)
            metadata = Dict("prop1" => "val1", "prop2" => "val2")
            ds = Dataset((; x, y); metadata)
            o = PyObject(ds)
            @test o isa PyObject
            @test pyisinstance(o, xarray.Dataset)

            @test issetequal(Symbol.(o.coords.keys()), (:chain, :draw, :shared, :ydim1))
            for (dim, coord) in o.coords.items()
                @test collect(coord.values) == DimensionalData.index(ds, Symbol(dim))
            end

            variables = Dict(collect(o.data_vars.variables.items()))
            @test "x" ∈ keys(variables)
            @test x == variables["x"].values
            @test variables["x"].dims == String.(xdims)

            @test "y" ∈ keys(variables)
            @test y == variables["y"].values
            @test variables["y"].dims == ("chain", "draw", "ydim1", "shared")

            # check that the Python object accesses the underlying Julia array
            x[1] = 1
            @test x == variables["x"].values

            ds2 = convert(Dataset, o)
            @test ds2 isa Dataset
            @test ds2.x ≈ ds.x
            @test ds2.y ≈ ds.y
            dims1 = sort(collect(DimensionalData.dims(ds)); by=DimensionalData.name)
            dims2 = sort(collect(DimensionalData.dims(ds2)); by=DimensionalData.name)
            for (dim1, dim2) in zip(dims1, dims2)
                @test DimensionalData.name(dim1) === DimensionalData.name(dim2)
                @test DimensionalData.index(dim1) == DimensionalData.index(dim2)
                if DimensionalData.index(dim1) isa AbstractRange
                    @test DimensionalData.index(dim2) isa AbstractRange
                end
            end
            @test DimensionalData.metadata(ds2) == DimensionalData.metadata(ds)
        end

        @testset "InferenceData <-> PyObject" begin
            idata1 = random_data()
            pyidata1 = PyObject(idata1)
            @test pyidata1 isa PyObject
            @test pyisinstance(pyidata1, arviz.InferenceData)
            idata2 = convert(InferenceData, pyidata1)
            # drop observed_data, since it has zero-dim arrays, which are unsupported by
            # xarray
            idata1 = idata1[filter(!=(:observed_data), keys(idata1))]
            idata2 = idata2[filter(!=(:observed_data), keys(idata2))]
            test_idata_approx_equal(idata2, idata1)
        end

        @testset "convert_to_inference_data(obj::PyObject)" begin
            data = Dict(:z => randn(4, 100, 10))
            idata1 = convert_to_inference_data(data)
            idata2 = convert_to_inference_data(PyObject(data))
            @test idata2 isa InferenceData
            @test idata2.posterior.z ≈ collect(idata1.posterior.z)
        end
    end
end
