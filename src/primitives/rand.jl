using Random: GLOBAL_RNG
using TupleVectors: chainvec

struct RandConfig{T_rng, RNG} <: AbstractTildeConfig
    rng::RNG

    RandConfig(::Type{T_rng}, rng::RNG) where {T_rng, RNG<:AbstractRNG} = new{T_rng,RNG}(rng)
end

RandConfig(rng) = RandConfig(Float64, rng)
RandConfig() = RandConfig(Float64, Random.GLOBAL_RNG)


@inline function retfun(cfg::RandConfig, r, ctx)
    r
end


export rand
EmptyNTtype = NamedTuple{(),Tuple{}} where {T<:Tuple}


@inline function Base.rand(
    rng::AbstractRNG,
    ::Type{T_rng},
    mc::ModelClosure
) where {T_rng}
    cfg = RandConfig(T_rng, rng)
    pars = NamedTuple()
    ctx = NamedTuple()
    runmodel(cfg, mc, pars, ctx)
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
    xnew = set(value(x), Lens!!(lens), retn)
    ctx′ = mymerge(ctx, NamedTuple{(X,)}((latent,)))
    (xnew, ctx′)
end



###############################################################################
# Dispatch helpers

@inline function Base.rand(m::ModelClosure, args...; kwargs...)
    rand(GLOBAL_RNG, Float64, m, args...; kwargs...)
end

@inline function Base.rand(rng::AbstractRNG, m::ModelClosure, args...; kwargs...)
    rand(rng, Float64, m, args...; kwargs...)
end

@inline function Base.rand(::Type{T_rng}, m::ModelClosure, args...; kwargs...) where {T_rng}
    rand(GLOBAL_RNG, T_rng, m, args...; kwargs...)
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