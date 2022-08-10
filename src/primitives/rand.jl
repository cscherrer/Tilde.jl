using Random: GLOBAL_RNG
using TupleVectors: chainvec

struct RandConfig{T_rng, RNG} <: AbstractConfig
    rng::RNG

    RandConfig(::Type{T_rng}, rng::RNG) where {T_rng, RNG<:AbstractRNG} = new{T_rng,RNG}(rng)
end

RandConfig(rng) = RandConfig(Float64, rng)
RandConfig() = RandConfig(Float64, Random.GLOBAL_RNG)


@inline function retfun(cfg::RandConfig, r, ctx)
    ctx
end


export rand
EmptyNTtype = NamedTuple{(),Tuple{}} where {T<:Tuple}

"""
    rand([rng=GLOBAL_RNG, T_rng=Float64,] mc::ModelClosure)

Draw a sample from the model closure `mc`. There are two optional arguments:
1. `rng` specifies an `AbstractRNG` to use for sampling
2. `T_rng` specifies a type to pass to the inner call to `rand`. This makes it
   easy to sample using types other than the default `Float64`.

Note that `mc` must be a closure (a model with specified arguements). In
particular, calling `rand` on a `ModelPosterior` (a closure with conditioning)
is disallowed. To ignore the conditioning for some `post::ModelPosterior`, you
can use `rand(post.closure)`.

Also note that a model closure is considered to be a measure on its _latent
space_. That is, any return value in the model is ignored by `rand`. Use
`predict` if you want the return value instead of a point in the latent space.
"""
@inline function Base.rand(
    rng::AbstractRNG,
    ::Type{T_rng},
    mc::ModelClosure
) where {T_rng}
    cfg = RandConfig(T_rng, rng)
    pars = NamedTuple()
    ctx = NamedTuple()
    runmodel(cfg, anyfy(mc), pars, ctx)
end

###############################################################################
# tilde

@inline function tilde(
    cfg::RandConfig{T_rng, RNG},
    x::Unobserved{X},
    lens,
    d,
    ctx,
) where {X,T_rng, RNG}
    r = rand(cfg.rng, T_rng, d)
    xnew = set(value(x), Lens!!(lens), r)
    ctx′ = mymerge(ctx, NamedTuple{(X,)}((xnew,)))
    (predict(d, xnew), ctx′)
end


###############################################################################
# Dispatch helpers

@inline function Base.rand(m::ModelClosure; kwargs...)
    rand(GLOBAL_RNG, Float64, m; kwargs...)
end

@inline function Base.rand(rng::AbstractRNG, m::ModelClosure; kwargs...)
    rand(rng, Float64, m; kwargs...)
end

@inline function Base.rand(::Type{T_rng}, m::ModelClosure; kwargs...) where {T_rng}
    rand(GLOBAL_RNG, T_rng, m; kwargs...)
end

@inline function Base.rand(m::ModelClosure, N; kwargs...)
    rand(GLOBAL_RNG, Float64, m, N; kwargs...)
end

@inline function Base.rand(rng::AbstractRNG, m::ModelClosure, N; kwargs...)
    rand(rng, Float64, m, N; kwargs...)
end

@inline function Base.rand(::Type{T_rng}, m::ModelClosure, N; kwargs...) where {T_rng}
    rand(GLOBAL_RNG, T_rng, m, N; kwargs...)
end

###############################################################################
# Specifying an Integer argument creates a TupleVector



@inline function Base.rand(m::ModelClosure, N::Integer; kwargs...)
    rand(GLOBAL_RNG, Float64, m, N; kwargs...)
end

@inline function Base.rand(
    rng::AbstractRNG,
    mc::ModelClosure,
    N::Integer,
    kwargs...,
)
    rand(rng, Float64, mc, N; kwargs...)
end


@inline function Base.rand(
    ::Type{T_rng},
    mc::ModelClosure,
    N::Integer;
    kwargs...,
) where {T_rng}
    rand(GLOBAL_RNG, T_rng, mc, N; kwargs...)
end

"""
    rand([rng=GLOBAL_RNG, T_rng=Float64,] mc::ModelClosure, N::Integer)

Draw `N` samples from the model closure `mc`, packaging the result in a
`TupleVector`. There are two optional arguments:
1. `rng` specifies an `AbstractRNG` to use for sampling
2. `T_rng` specifies a type to pass to the inner call to `rand`. This makes it
   easy to sample using types other than the default `Float64`.

Note that `mc` must be a closure (a model with specified arguements). In
particular, calling `rand` on a `ModelPosterior` (a closure with conditioning)
is disallowed. To ignore the conditioning for some `post::ModelPosterior`, you
can use `rand(post.closure)`.

Also note that a model closure is considered to be a measure on its _latent
space_. That is, any return value in the model is ignored by `rand`. Use
`predict` if you want the return value instead of a point in the latent space.
"""
@inline function Base.rand(
    rng::AbstractRNG,
    ::Type{T_rng},
    mc::ModelClosure,
    N::Integer,
) where {T_rng}
    r = chainvec(rand(rng, T_rng, mc), N)
    for j in 2:N
        @inbounds r[j] = rand(rng, T_rng, mc)
    end
    return r
end

###############################################################################
# Cases that throw errors

function Base.rand(
    ::AbstractRNG,
    ::Type,
    m::AbstractModel,
    args...;
    kwargs...
)
    @error "`rand` called on Model without arugments. Try `m(args)` or `m()` if the model has no arguments"
end

function Base.rand(
    ::AbstractRNG,
    ::Type,
    m::ModelPosterior,
    args...;
    kwargs...
)
    @error "`rand` called on ModelPosterior. `rand` does not allow conditioning; try `predict`"
end

###############################################################################
# Internal method allowing `ModelPosterior` 

@inline function _rand(
    rng::AbstractRNG,
    ::Type{T_rng},
    d) where {T_rng}
    return rand(rng, T_rng, d)
end

@inline function _rand(
    rng::AbstractRNG,
    ::Type{T_rng},
    mc::AbstractConditionalModel
) where {T_rng}
    cfg = RandConfig(T_rng, rng)
    pars = NamedTuple()
    ctx = NamedTuple()
    runmodel(cfg, anyfy(mc), pars, ctx)
end


@inline function tilde(
    cfg::RandConfig{T_rng, RNG},
    obj::Observed{X},
    lens,
    d,
    ctx,
) where {X,T_rng, RNG}
    r = _rand(cfg.rng, T_rng, d)
    x = value(obj)
    xj = lens(x)
    # TODO: account for cases where `xj == missing`
    (x, ctx)
end

@inline function _rand(m::AbstractConditionalModel; kwargs...)
    _rand(GLOBAL_RNG, Float64, m; kwargs...)
end

@inline function _rand(rng::AbstractRNG, m::AbstractConditionalModel; kwargs...)
    _rand(rng, Float64, m; kwargs...)
end

@inline function _rand(::Type{T_rng}, m::AbstractConditionalModel; kwargs...) where {T_rng}
    _rand(GLOBAL_RNG, T_rng, m; kwargs...)
end
