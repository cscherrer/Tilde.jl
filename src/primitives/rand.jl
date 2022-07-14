using Random: GLOBAL_RNG
using TupleVectors: chainvec

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

@inline function Base.rand(
    rng::AbstractRNG,
    ::Type{T_rng},
    m::ModelClosure
) where {T_rng}
    @inline retfun(proj, joint, ctx) = proj(ctx => last(joint))
    proj = getproj(m)
    cfg = (rng = rng, T_rng = T_rng, retfun=retfun, proj = proj)
    ctx = NamedTuple()
    joint = _rand(rng, T_rng, jointof(m); cfg=cfg, ctx=ctx)
    latent, retn = joint
    proj(joint)
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

@inline _rand(rng, ::Type{T_rng}, m; kwargs...) where {T_rng} = rand(rng, T_rng, m)

@inline function _rand(
    rng::AbstractRNG,
    ::Type{T_rng},
    m::ModelClosure;
    cfg,
    ctx
) where {T_rng}
    retfun = cfg.retfun
    proj = cfg.proj
    # retfun(r, ctx) = (@show ctx; @show r; r)
    # retfun(r, ctx) = proj(ctx => r)
    gg_call(rand, m, NamedTuple(), cfg, ctx, retfun)
end


###############################################################################
# ctx::NamedTuple
@inline function tilde(
    ::typeof(Base.rand),
    x::Unobserved{X},
    lens,
    d,
    cfg,
    ctx::NamedTuple,
) where {X}
    proj = cfg.proj
    joint = _rand(cfg.rng, cfg.T_rng, jointof(d); cfg, ctx)
    latent, retn = joint
    ctx′ = merge(ctx, NamedTuple{(X,)}((proj(joint),)))
    xnew = set(value(x), Lens!!(lens), retn)
    (xnew, ctx′)
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
