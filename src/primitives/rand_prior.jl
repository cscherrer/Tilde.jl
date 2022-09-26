using Random: GLOBAL_RNG
using TupleVectors: chainvec

struct RandPriorConfig{T_rng,RNG} <: AbstractConfig
    rng::RNG

    RandPriorConfig(::Type{T_rng}, rng::RNG) where {T_rng,RNG<:AbstractRNG} = new{T_rng,RNG}(rng)
end

RandPriorConfig(rng) = RandPriorConfig(Float64, rng)
RandPriorConfig() = RandPriorConfig(Float64, Random.GLOBAL_RNG)

@inline function retfun(cfg::RandPriorConfig, r, ctx)
    ctx
end

export rand_prior

EmptyNTtype = NamedTuple{(),Tuple{}} where {T<:Tuple}

"""
    rand_prior([rng=GLOBAL_RNG, T_rng=Float64,] mc::AbstractConditionalModel)

Draw a sample from the model closure `mc`. There are two optional arguments:
1. `rng` specifies an `AbstractRNG` to use for sampling
2. `T_rng` specifies a type to pass to the inner call to `rand_prior`. This makes it
   easy to sample using types other than the default `Float64`.

Note that `mc` must be a closure (a model with specified arguements). In
particular, calling `rand_prior` on a `ModelPosterior` (a closure with conditioning)
is disallowed. To ignore the conditioning for some `post::ModelPosterior`, you
can use `rand_prior(post.closure)`.

Also note that a model closure is considered to be a measure on its _latent
space_. That is, any return value in the model is ignored by `rand_prior`. Use
`predict` if you want the return value instead of a point in the latent space.
"""
@inline function rand_prior(rng::AbstractRNG, ::Type{T_rng}, mc::AbstractConditionalModel) where {T_rng}
    cfg = RandPriorConfig(T_rng, rng)
    pars = NamedTuple()
    ctx = NamedTuple()
    runmodel(cfg, mc, pars, ctx)
end

###############################################################################
# tilde

@inline function tilde(
    cfg::RandPriorConfig{T_rng,RNG},
    z_obs::Unobserved{Z},
    lens,
    d,
    ctx,
) where {Z,T_rng,RNG}
    rng = cfg.rng
    z = value(z_obs)
    zj = rand_prior(rng, T_rng, d)
    new_z = set(z, Lens!!(lens), zj)
    ctx′ = mymerge(ctx, NamedTuple{(Z,)}((new_z,)))
    xj = predict(rng, d, zj)
    (xj, ctx′)
end


@inline function tilde(
    cfg::RandPriorConfig{T_rng,RNG},
    z_obs::Observed{Z},
    lens,
    d,
    ctx,
) where {Z,T_rng,RNG}
    rng = cfg.rng
    z = value(z_obs)
    zj = lens(z)
    xj = predict(rng, d, zj)
    (xj, ctx)
end


###############################################################################
# Dispatch helpers

@inline function rand_prior(m::AbstractConditionalModel; kwargs...)
    rand_prior(GLOBAL_RNG, Float64, m; kwargs...)
end

@inline function rand_prior(rng::AbstractRNG, m::AbstractConditionalModel; kwargs...)
    rand_prior(rng, Float64, m; kwargs...)
end

@inline function rand_prior(::Type{T_rng}, m::AbstractConditionalModel; kwargs...) where {T_rng}
    rand_prior(GLOBAL_RNG, T_rng, m; kwargs...)
end

@inline function rand_prior(m::AbstractConditionalModel, N; kwargs...)
    rand_prior(GLOBAL_RNG, Float64, m, N; kwargs...)
end

@inline function rand_prior(rng::AbstractRNG, m::AbstractConditionalModel, N; kwargs...)
    rand_prior(rng, Float64, m, N; kwargs...)
end

@inline function rand_prior(::Type{T_rng}, m::AbstractConditionalModel, N; kwargs...) where {T_rng}
    rand_prior(GLOBAL_RNG, T_rng, m, N; kwargs...)
end

@inline rand_prior(rng::AbstractRNG, ::Type{T_rng}, m::AbstractMeasure) where {T_rng} = rand(rng, T_rng, m)

###############################################################################
# Specifying an Integer argument creates a TupleVector

@inline function rand_prior(m::AbstractConditionalModel, N::Integer; kwargs...)
    rand_prior(GLOBAL_RNG, Float64, m, N; kwargs...)
end

@inline function rand_prior(rng::AbstractRNG, mc::AbstractConditionalModel, N::Integer, kwargs...)
    rand_prior(rng, Float64, mc, N; kwargs...)
end

@inline function rand_prior(
    ::Type{T_rng},
    mc::AbstractConditionalModel,
    N::Integer;
    kwargs...,
) where {T_rng}
    rand_prior(GLOBAL_RNG, T_rng, mc, N; kwargs...)
end

"""
    rand_prior([rng=GLOBAL_RNG, T_rng=Float64,] mc::AbstractConditionalModel, N::Integer)

Draw `N` samples from the model closure `mc`, packaging the result in a
`TupleVector`. There are two optional arguments:
1. `rng` specifies an `AbstractRNG` to use for sampling
2. `T_rng` specifies a type to pass to the inner call to `rand_prior`. This makes it
   easy to sample using types other than the default `Float64`.

Note that `mc` must be a closure (a model with specified arguements). In
particular, calling `rand_prior` on a `ModelPosterior` (a closure with conditioning)
is disallowed. To ignore the conditioning for some `post::ModelPosterior`, you
can use `rand_prior(post.closure)`.

Also note that a model closure is considered to be a measure on its _latent
space_. That is, any return value in the model is ignored by `rand_prior`. Use
`predict` if you want the return value instead of a point in the latent space.
"""
@inline function rand_prior(
    rng::AbstractRNG,
    ::Type{T_rng},
    mc::AbstractConditionalModel,
    N::Integer,
) where {T_rng}
    r = chainvec(rand_prior(rng, T_rng, mc), N)
    for j in 2:N
        @inbounds r[j] = rand_prior(rng, T_rng, mc)
    end
    return r
end

###############################################################################
# Cases that throw errors

function rand_prior(::AbstractRNG, ::Type, m::AbstractModel, args...; kwargs...)
    @error "`rand_prior` called on Model without arugments. Try `m(args)` or `m()` if the model has no arguments"
end
