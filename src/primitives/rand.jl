using Random: GLOBAL_RNG
using TupleVectors: chainvec

struct RandConfig{T_rng, RNG, P} <: AbstractTildeConfig
    rng::RNG
    proj::P

    RandConfig(::Type{T_rng}, rng::RNG, proj::P) where {T_rng, RNG, P} = new{T_rng,RNG,P}(rng,proj)
end

RandConfig(rng,proj) = RandConfig(Float64, rng,proj)

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

@inline function Base.rand(m::ModelClosure, d::Integer, dims::Integer...; kwargs...)
    rand(GLOBAL_RNG, Float64, m, d, dims...; kwargs...)
end

@inline function Base.rand(
    rng::AbstractRNG,
    m::ModelClosure,
    d::Integer,
    dims::Integer...;
    kwargs...,
)
    rand(rng, Float64, m, d, dims...; kwargs...)
end

@inline function Base.rand(
    ::Type{T_rng},
    m::ModelClosure,
    d::Integer,
    dims::Integer...;
    kwargs...,
) where {T_rng}
    rand(GLOBAL_RNG, T_rng, m, d, dims...; kwargs...)
end

@inline function Base.rand(
    rng::AbstractRNG,
    ::Type{T_rng},
    d::ModelClosure,
    N::Integer,
    v::Vararg{Integer},
) where {T_rng}
    @assert isempty(v)
    r = chainvec(rand(rng, T_rng, d), N)
    for j in 2:N
        @inbounds r[j] = rand(rng, T_rng, d)
    end
    return r
end

@inline Base.rand(d::ModelClosure, N::Int) = rand(GLOBAL_RNG, d, N)

@inline function Base.rand(m::ModelClosure; kwargs...)
    rand(GLOBAL_RNG, Float64, m; kwargs...)
end

@inline Base.rand(rng::AbstractRNG, m::ModelClosure) = rand(rng, Float64, m)

@inline function retfun(::typeof(rand), proj::P, joint::Pair{X,Y}, ctx::NamedTuple{N,T}) where {P,X,Y,N,T}
    proj(ctx => last(joint))
end

@inline function Base.rand(
    rng::AbstractRNG,
    ::Type{T_rng},
    m::ModelClosure
) where {T_rng}
    cfg = RandConfig(T_rng, getproj(m), rng)
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
    gg_call(rand, m, NamedTuple(), cfg, NamedTuple())
end


###############################################################################
# ctx::NamedTuple
@inline function tilde(
    ::typeof(Base.rand),
    x::Unobserved{X},
    lens,
    d,
    cfg::RandConfig{T_rng},
    ctx::NamedTuple,
) where {T_rng,X}
    proj = cfg.proj
    joint = _rand(cfg, jointof(d))
    latent = first(joint)
    retn = last(joint)
    # latent, retn = joint
    ctx′ = rand_merge(ctx, x, proj, joint) 
    # ctx′ = merge(ctx, NamedTuple{(X,)}((proj(joint),)))
    xnew = set(value(x), Lens!!(lens), retn)
    (xnew, ctx′)
end

@inline function rand_merge(ctx, ::Unobserved{X}, proj::P, joint) where {X,P}
    mymerge(ctx, NamedTuple{(X,)}((proj(joint),)))
end


# @inline function tilde(
#     ::typeof(Base.rand),
#     x::Observed{X},
#     lens,
#     d,
#     cfg,
#     ctx::NamedTuple,
# ) where {X}
#     (value(x), ctx, nothing)
# end
