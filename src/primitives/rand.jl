using Random: GLOBAL_RNG
using TupleVectors: chainvec

struct RandConfig{T_rng, RNG, P} <: AbstractTildeConfig
    rng::RNG
    proj::P

    RandConfig(::Type{T_rng}, rng::RNG, proj::P) where {T_rng, RNG<:AbstractRNG, P} = new{T_rng,RNG,P}(rng,proj)
end

RandConfig(rng,proj) = RandConfig(Float64, rng, proj)
RandConfig(proj) = RandConfig(Float64, Random.GLOBAL_RNG, proj)


export rand
EmptyNTtype = NamedTuple{(),Tuple{}} where {T<:Tuple}

@inline function Base.rand(m::ModelClosure, args...; kwargs...)
    rand(GLOBAL_RNG, Float64, m, args...; kwargs...)
end

@inline function Base.rand(rng::AbstractRNG, m::ModelClosure, args...; kwargs...)
    rand(rng, Float64, m, args...; kwargs...)
end

@inline function Base.rand(::Type{T_rng}, m::ModelClosure, args...; kwargs...) where {T_rng}
    rand(GLOBAL_RNG, T_rng, m, args...; kwargs...)
end

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
    N;
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

@inline Base.rand(mc::ModelClosure, N::Int) = rand(GLOBAL_RNG, mc, N)

@inline function Base.rand(mc::ModelClosure; kwargs...)
    rand(GLOBAL_RNG, Float64, mc; kwargs...)
end

@inline Base.rand(rng::AbstractRNG, mc::ModelClosure) = rand(rng, Float64, mc)

@inline function retfun(::RandConfig, proj::P, joint::Pair{X,Y}, ctx::NamedTuple{N,T}) where {P,X,Y,N,T}
    proj(ctx => last(joint))
end

@inline function Base.rand(
    rng::AbstractRNG,
    ::Type{T_rng},
    m::ModelClosure
) where {T_rng}
    cfg = RandConfig(T_rng, rng, getproj(m))
    _rand(cfg, m)
    # latent, retn = joint
    # proj(joint)
end


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

@inline _rand(cfg::RandConfig{T_rng}, m) where {T_rng} = rand(cfg.rng, T_rng, m)

@inline function _rand(
    cfg::RandConfig{T_rng, RNG,P},
    m::ModelClosure,
) where {T_rng,RNG,P}
    gg_call(cfg, m, NamedTuple(), NamedTuple())
end


###############################################################################
# ctx::NamedTuple
@inline function tilde(
    cfg::RandConfig{T_rng},
    x::Unobserved{X},
    lens,
    d,
    ctx::NamedTuple,
) where {T_rng,X}
    proj = cfg.proj
    joint = _rand(cfg, jointof(d))
    latent = first(joint)
    retn = last(joint)
    # latent, retn = joint
    ctx′ = mymerge(ctx, NamedTuple{(X,)}((proj(joint),)))
    xnew = set(value(x), Lens!!(lens), retn)
    (xnew, ctx′)
end
