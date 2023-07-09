import_arviz() = _import_dependency("arviz", "arviz"; channel="conda-forge")

function arviz_version()
    v = arviz.__version__
    try
        VersionNumber(v)
    catch ArgumentError
        v, suff = splitext(v)
        return VersionNumber(v * suff[2:end])
    end
end

function check_needs_update(; update=true)
    if arviz_version() < _min_arviz_version
        @warn "ArviZ.jl only officially supports arviz version $(_min_arviz_version) or " *
            "greater but found version $(arviz_version())."
        if update
            if update_arviz()
                # yay, but we still already imported the old version
                msg = """
                Please rebuild ArviZ.jl with `using Pkg; Pkg.build("ArviZ")` and re-launch Julia
                to continue.
                """
            else
                msg = """
                Could not automatically update arviz. Please manually update arviz, rebuild
                ArviZ.jl with `using Pkg; Pkg.build("ArviZ")`, and then re-launch Julia to
                continue.
                """
            end
            @warn msg
        end
    end
    return nothing
end

function initialize_arviz()
    PyCall.ispynull(arviz) || return nothing
    copy!(arviz, import_arviz())
    check_needs_update(; update=true)

    PyCall.pytype_mapping(arviz.InferenceData, InferenceObjects.InferenceData)

    initialize_xarray()
    initialize_numpy()
    return nothing
end

function initialize_xarray()
    PyCall.ispynull(xarray) || return nothing
    copy!(xarray, _import_dependency("xarray", "xarray"; channel="conda-forge"))
    _import_dependency("dask", "dask"; channel="conda-forge")
    return nothing
end

function initialize_numpy()
    # Trigger NumPy initialization, see https://github.com/JuliaPy/PyCall.jl/issues/744
    PyCall.PyObject([true])
    return nothing
end

function update_arviz()
    # updating arviz can change other packages, so we always ask for permission
    if _using_conda() && _isyes(Base.prompt("Try updating arviz using conda? [Y/n]"))
        # this syntax isn't officially supported, but it works (for now)
        try
            PyCall.Conda.add("arviz>=$_min_arviz_version"; channel="conda-forge")
            return true
        catch e
            println(e.msg)
        end
    end
    if _has_pip() && _isyes(Base.prompt("Try updating arviz using pip? [Y/n]"))
        # can't specify version lower bound, so update to latest
        try
            run(PyCall.python_cmd(`-m pip install --upgrade -- arviz`))
            return true
        catch e
            println(e.msg)
        end
    end
    return false
end

function _import_dependency(modulename, pkgname=modulename; channel=nothing)
    try
        return if channel === nothing
            PyCall.pyimport_conda(modulename, pkgname)
        else
            PyCall.pyimport_conda(modulename, pkgname, channel)
        end
    catch e
        if _has_pip() && _isyes(Base.prompt("Try installing $pkgname using pip? [Y/n]"))
            # installing with pip is riskier, so we ask for permission
            run(PyCall.python_cmd(`-m pip install -- $pkgname`))
            return PyCall.pyimport(modulename)
        end
        # PyCall has a nice error message
        throw(e)
    end
end

_isyes(s) = isempty(s) || lowercase(strip(s)) ∈ ("y", "yes")
_isyes(::Nothing) = true

_using_conda() = PyCall.conda

_has_pip() = _has_pymodule("pip")

_has_pymodule(modulename) = !PyCall.ispynull(PyCall.pyimport_e(modulename))
